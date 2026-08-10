--- Unit tests for CharacterService: slot assignment, soft-delete/slot
--- reuse, the slot limit, and the session map.
--- Run from the repository root:  lua5.4 tests/character_service_spec.lua
---
--- CORE_ROOT is a relative walk-up from this file to the core repo root.
--- oblsk_characters must live at <core-root>/modules/oblsk_characters/ for
--- FXServer to load it as part of core at all, so this file is always
--- three levels below the core root (tests/ -> oblsk_characters/ ->
--- modules/ -> core-root).
local scriptDir = arg[0]:match('(.*/)') or './'
local CORE_ROOT = scriptDir .. '../../..'

dofile(CORE_ROOT .. '/tests/support/fivem_stubs.lua')
dofile(CORE_ROOT .. '/core/server/ORM/Dialects/Init.lua')
dofile(CORE_ROOT .. '/core/server/ORM/Dialects/MySQL.lua')
dofile(CORE_ROOT .. '/core/server/ORM/Dialects/Postgres.lua')
dofile(CORE_ROOT .. '/core/server/ORM/Database.lua')
dofile(CORE_ROOT .. '/core/server/ORM/QueryBuilder.lua')
dofile(CORE_ROOT .. '/core/server/ORM/Schema.lua')
dofile(CORE_ROOT .. '/core/server/ORM/BaseModel.lua')

-- Character:accountRelation() references the global Account, from the
-- separate oblsk_accounts module, never loaded here. That reference is
-- inside the relation function's body, not evaluated at file-load time, so
-- Character.lua loads fine without Account existing; these tests never call
-- accountRelation() anyway.
dofile(scriptDir .. '../server/models/Character.lua')
dofile(scriptDir .. '../server/models/CharacterAppearance.lua')
dofile(scriptDir .. '../server/services/CharacterService.lua')

local makeFakeQueryBuilderModule = dofile(scriptDir .. 'support/fake_query_builder.lua')

local tests, failures, passed = {}, {}, 0
local function test(name, fn) tests[#tests + 1] = {name = name, fn = fn} end

local function eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format('%s\n     expected: %s\n     actual:   %s',
            msg or 'assertion failed', tostring(expected), tostring(actual)), 2)
    end
end

local function truthy(v, msg)
    if not v then error(msg or 'expected a truthy value', 2) end
end

--- Swaps the real global QueryBuilder for the fake for the duration of fn,
--- so CharacterService (and the Character/CharacterAppearance models it
--- drives via BaseModel:newQuery, which reads the global QueryBuilder at
--- call time) operate on a fresh in-memory table set per test.
local function withFakeDb(fn)
    local tables = {}
    local original = QueryBuilder
    QueryBuilder = makeFakeQueryBuilderModule(tables)

    local ok, err = pcall(fn, tables)

    QueryBuilder = original
    if not ok then error(err, 2) end
end

--------------------------------------------------------------------------------
-- create / slot assignment
--------------------------------------------------------------------------------

test('create: the first character on an account gets slot 0', function()
    withFakeDb(function()
        local character = CharacterService.create(1, { first_name = 'John', last_name = 'Doe' })
        eq(character.attributes.slot, 0)
    end)
end)

test('create: a second character on the same account gets the next free slot', function()
    withFakeDb(function()
        CharacterService.create(1, { first_name = 'John', last_name = 'Doe' })
        local second = CharacterService.create(1, { first_name = 'Jane', last_name = 'Doe' })
        eq(second.attributes.slot, 1)
    end)
end)

test('create: also creates a blank CharacterAppearance linked to the new character', function()
    withFakeDb(function(tables)
        local character = CharacterService.create(1, { first_name = 'John', last_name = 'Doe' })
        eq(#tables.character_appearances, 1)
        eq(tables.character_appearances[1].character_id, character.attributes.id)
    end)
end)

test('create: different accounts do not share slot assignment', function()
    withFakeDb(function()
        local charA = CharacterService.create(1, { first_name = 'John', last_name = 'Doe' })
        local charB = CharacterService.create(2, { first_name = 'Jane', last_name = 'Doe' })
        eq(charA.attributes.slot, 0)
        eq(charB.attributes.slot, 0)
    end)
end)

test('create: returns an error once CHARACTER_SLOT_LIMIT characters already exist', function()
    withFakeDb(function()
        for i = 1, CharacterService.CHARACTER_SLOT_LIMIT do
            CharacterService.create(1, { first_name = 'Char', last_name = tostring(i) })
        end
        local character, err = CharacterService.create(1, { first_name = 'One', last_name = 'Too Many' })
        eq(character, nil)
        truthy(err ~= nil, 'expected an error message')
    end)
end)

--------------------------------------------------------------------------------
-- delete / slot reuse
--------------------------------------------------------------------------------

test('delete: sets deleted_at', function()
    withFakeDb(function(tables)
        local character = CharacterService.create(1, { first_name = 'John', last_name = 'Doe' })
        CharacterService.delete(character.attributes.id)
        eq(tables.characters[1].deleted_at ~= nil, true)
    end)
end)

test('delete: frees the slot for a new character on the same account', function()
    withFakeDb(function()
        local first = CharacterService.create(1, { first_name = 'John', last_name = 'Doe' })
        CharacterService.create(1, { first_name = 'Jane', last_name = 'Doe' })
        CharacterService.delete(first.attributes.id)

        local third = CharacterService.create(1, { first_name = 'Jack', last_name = 'Doe' })
        eq(third.attributes.slot, 0)
    end)
end)

--------------------------------------------------------------------------------
-- list
--------------------------------------------------------------------------------

test('list: returns only non-deleted characters, ordered by slot', function()
    withFakeDb(function()
        CharacterService.create(1, { first_name = 'John', last_name = 'Doe' })
        CharacterService.create(1, { first_name = 'Jane', last_name = 'Doe' })
        local third = CharacterService.create(1, { first_name = 'Jack', last_name = 'Doe' })
        CharacterService.delete(third.attributes.id)

        local characters = CharacterService.list(1)
        eq(#characters, 2)
        eq(characters[1].slot, 0)
        eq(characters[1].first_name, 'John')
        eq(characters[2].slot, 1)
        eq(characters[2].first_name, 'Jane')
    end)
end)

--------------------------------------------------------------------------------
-- session map
--------------------------------------------------------------------------------

test('getActiveCharacterId: returns nil before setActiveCharacterId is called', function()
    eq(CharacterService.getActiveCharacterId(999), nil)
end)

test('getActiveCharacterId: returns the value set by setActiveCharacterId', function()
    CharacterService.setActiveCharacterId(42, 7)
    eq(CharacterService.getActiveCharacterId(42), 7)
    CharacterService.sessionCharacters[42] = nil
end)

--------------------------------------------------------------------------------
-- Runner
--------------------------------------------------------------------------------
print('Running CharacterService unit tests\n')
for _, t in ipairs(tests) do
    local ok, err = pcall(t.fn)
    if ok then
        passed = passed + 1
        print('  ok   - ' .. t.name)
    else
        failures[#failures + 1] = t.name
        print('  FAIL - ' .. t.name)
        print('         ' .. tostring(err):gsub('\n', '\n         '))
    end
end

print(string.format('\n%d passed, %d failed', passed, #failures))
os.exit(#failures == 0 and 0 or 1)
