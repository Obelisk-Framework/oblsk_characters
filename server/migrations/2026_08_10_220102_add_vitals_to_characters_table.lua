--- Migration: Add vitals/position columns to characters table
return {
    up = function()
        Schema.table('characters', function(table)
            table:float('health'):notNullable():default(200)
            table:float('armor'):notNullable():default(0)
            table:float('air'):notNullable():default(100)
            table:float('x'):notNullable():default(0)
            table:float('y'):notNullable():default(0)
            table:float('z'):notNullable():default(72)
            table:integer('dimension'):notNullable():default(0)
            table:float('food')
            table:float('drink')
            table:float('stamina')
        end)

        print('[Migration] Added vitals/position columns to characters table')
    end,

    down = function()
        Schema.dropColumn('characters', 'health')
        Schema.dropColumn('characters', 'armor')
        Schema.dropColumn('characters', 'air')
        Schema.dropColumn('characters', 'x')
        Schema.dropColumn('characters', 'y')
        Schema.dropColumn('characters', 'z')
        Schema.dropColumn('characters', 'dimension')
        Schema.dropColumn('characters', 'food')
        Schema.dropColumn('characters', 'drink')
        Schema.dropColumn('characters', 'stamina')
        print('[Migration] Dropped vitals/position columns from characters table')
    end
}
