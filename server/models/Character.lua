--- Character Model - one character slot on an Account. Soft-deleted
--- (deleted_at) rather than hard-deleted, since Item/Vehicle rows may
--- already reference a character via owner_id and this module has no way
--- to know what else points at a characters.id. See
--- docs/superpowers/specs/2026-08-10-characters-module-design.md.
Character = BaseModel:extend('characters')

Character.primaryKey = 'id'
Character.timestamps = true
Character.fillable = {
    'account_id', 'slot', 'first_name', 'last_name', 'gender', 'dob', 'place_of_birth', 'bio', 'last_played_at', 'deleted_at',
    'health', 'armor', 'air', 'x', 'y', 'z', 'dimension', 'food', 'drink', 'stamina',
    'fingerprint_id', 'blood_type',
}
Character.hidden = {}

--- Return this persisted character's identity as an item owner.
--- @return table|nil identity { type = string, id = any }
--- @return string|nil reason
function Character:itemOwner()
    if self.exists ~= true then
        return nil, 'Item owner must be persisted'
    end

    local id = self.id
    if id == nil then
        return nil, 'Item owner has no primary key'
    end

    return { type = 'character', id = id }, nil
end

function Character:accountRelation()
    return self:belongsTo(Account, 'account_id', 'id')
end

function Character:appearanceRelation()
    return self:hasOne(CharacterAppearance, 'character_id', 'id')
end

HasPermissions.apply(Character, 'character')

return Character
