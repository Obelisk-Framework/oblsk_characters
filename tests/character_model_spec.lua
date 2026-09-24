--- Unit tests for Character's permission and item-owner opt-ins.
--- Run from the repository root:  lua5.4 tests/character_model_spec.lua
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
dofile(CORE_ROOT .. '/core/server/Models/Permission.lua')
dofile(CORE_ROOT .. '/core/server/Services/PermissionService.lua')
dofile(CORE_ROOT .. '/core/server/Traits/HasPermissions.lua')

-- Character.lua declares belongsTo(Account, ...)/hasOne(CharacterAppearance, ...)
-- relationships; the classes only need to exist as globals, never resolved
-- in these tests.
_G.Account = _G.Account or {}
_G.CharacterAppearance = _G.CharacterAppearance or {}

dofile(scriptDir .. '../server/models/Character.lua')
dofile(CORE_ROOT .. '/modules/oblsk_items/server/services/HasItems.lua')

local makeFakeQueryBuilderModule = dofile(CORE_ROOT .. '/tests/support/fake_query_builder.lua')

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

test('Character.permissionType is "character"', function()
    eq(Character.permissionType, 'character')
end)

test('a persisted Character exposes its stable item-owner identity', function()
    local character = Character.new({ id = 11 })
    character.exists = true
    local owner = character:itemOwner()
    eq(owner.type, 'character')
    eq(owner.id, 11)
end)

test('an unsaved Character cannot own items', function()
    local owner, reason = Character.new({ id = 11 }):itemOwner()
    eq(owner, nil)
    eq(reason, 'Item owner must be persisted')
end)

test('a Character instance can grant and check its own permission', function()
    local tables = { characters = { { id = 11, account_id = 3, slot = 0, first_name = 'Jane', last_name = 'Doe' } } }
    local original = QueryBuilder
    QueryBuilder = makeFakeQueryBuilderModule(tables)

    local ok, err = pcall(function()
        local instance = Character:find(11)
        eq(instance:can('manage_bank'), false)
        instance:grant('manage_bank')
        truthy(instance:can('manage_bank'))
    end)

    QueryBuilder = original
    if not ok then error(err, 2) end
end)

print('Running Character model unit tests\n')
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
