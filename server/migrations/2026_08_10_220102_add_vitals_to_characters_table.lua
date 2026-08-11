--- Migration: Add vitals/position columns to characters table
return {
    up = function()
        Schema.table('characters', function(table)
            table:float('health'):default(200)
            table:float('armor'):default(0)
            table:float('air'):default(100)
            table:float('x'):default(0)
            table:float('y'):default(0)
            table:float('z'):default(72)
            table:integer('dimension'):default(0)
            table:float('food'):nullable()
            table:float('drink'):nullable()
            table:float('stamina'):nullable()
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
