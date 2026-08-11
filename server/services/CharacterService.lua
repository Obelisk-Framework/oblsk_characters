--- CharacterService (server) - a slot-limited character-select data layer
--- on top of Account, plus vitals/position storage (health, armor, air,
--- x/y/z, dimension, food/drink/stamina). No event handlers, no native
--- calls, no sync to a live ped yet, getVitals/saveVitals are a data layer
--- only, nothing calls them yet. See
--- docs/superpowers/specs/2026-08-10-characters-module-design.md.
CharacterService = {}
CharacterService.sessionCharacters = {} -- source -> character_id, runtime only, set by a future UI-wiring pass

--- @param accountId number
--- @return table[] non-deleted characters, ordered by slot
function CharacterService.list(accountId)
    return QueryBuilder.new('characters')
        :where('account_id', accountId)
        :whereNull('deleted_at')
        :orderBy('slot', 'asc')
        :getSync()
end

--- The slot limit lives on accounts.max_characters (added by this module's
--- own migration, since the limit is a characters-module concept, not an
--- oblsk_accounts one), not a constant here, so an admin can raise or lower
--- one specific account's limit without a code change.
--- @param accountId number
--- @return number|nil nil if the account doesn't exist
local function getMaxCharacters(accountId)
    local account = QueryBuilder.new('accounts'):where('id', accountId):firstSync()
    if not account then
        return nil
    end
    return account.max_characters
end

local function findFreeSlot(accountId, maxCharacters)
    local taken = {}
    for _, character in ipairs(CharacterService.list(accountId)) do
        taken[character.slot] = true
    end
    for slot = 0, maxCharacters - 1 do
        if not taken[slot] then
            return slot
        end
    end
    return nil
end

--- Creates a Character in the lowest free slot for this account, plus a
--- blank CharacterAppearance linked to it. Returns an error instead of
--- creating anything once accounts.max_characters non-deleted characters
--- already exist for this account, or if the account doesn't exist.
--- @param accountId number
--- @param attributes table { first_name, last_name, gender, dob, bio }
--- @return Character|nil
--- @return string|nil err set only when the return is nil
function CharacterService.create(accountId, attributes)
    local maxCharacters = getMaxCharacters(accountId)
    if not maxCharacters then
        return nil, 'account not found'
    end

    local slot = findFreeSlot(accountId, maxCharacters)
    if not slot then
        return nil, 'no free character slots'
    end

    local character = Character:createSync({
        account_id = accountId,
        slot = slot,
        first_name = attributes.first_name,
        last_name = attributes.last_name,
        gender = attributes.gender,
        dob = attributes.dob,
        bio = attributes.bio,
    })

    CharacterAppearance:createSync({
        character_id = character.attributes.id,
        ped_model = attributes.ped_model or 'mp_m_freemode_01',
        data = {},
    })

    return character
end

--- @param characterId number
function CharacterService.delete(characterId)
    return QueryBuilder.new('characters'):where('id', characterId):update({ deleted_at = Database.now() })
end

--- @param source number
--- @param characterId number
function CharacterService.setActiveCharacterId(source, characterId)
    CharacterService.sessionCharacters[source] = characterId
end

--- @param source number
--- @return number|nil
function CharacterService.getActiveCharacterId(source)
    return CharacterService.sessionCharacters[source]
end

--- Reverse lookup: is this character currently online, and if so under which
--- source. Generically useful for any module that needs to reach a specific
--- character's live session (e.g. routing a phone call), not phone-specific.
--- @param characterId number
--- @return number|nil source, nil if that character isn't an active session
function CharacterService.findSourceByCharacterId(characterId)
    for source, activeId in pairs(CharacterService.sessionCharacters) do
        if activeId == characterId then
            return source
        end
    end
    return nil
end

local VITAL_FIELDS = {
    'health', 'armor', 'air', 'x', 'y', 'z', 'dimension', 'food', 'drink', 'stamina',
}

--- @param characterId number
--- @return table|nil { health, armor, air, x, y, z, dimension, food, drink, stamina }, nil if the character doesn't exist
function CharacterService.getVitals(characterId)
    local character = QueryBuilder.new('characters'):where('id', characterId):firstSync()
    if not character then
        return nil
    end

    local vitals = {}
    for _, field in ipairs(VITAL_FIELDS) do
        vitals[field] = character[field]
    end
    return vitals
end

--- Partial update: only the keys present in `vitals` are written.
--- @param characterId number
--- @param vitals table any subset of { health, armor, air, x, y, z, dimension, food, drink, stamina }
function CharacterService.saveVitals(characterId, vitals)
    QueryBuilder.new('characters'):where('id', characterId):update(vitals)
end

return CharacterService
