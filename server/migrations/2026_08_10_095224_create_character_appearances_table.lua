--- Migration: Create character_appearances table
return {
    up = function()
        Schema.create('character_appearances', function(table)
            table:id()
            table:integer('character_id'):unique()
            table:string('ped_model', 100):nullable()
            table:json('data'):nullable()
            table:timestamps()

            table:foreign('character_id'):references('id'):on('characters'):onDelete('CASCADE')
        end)

        print('[Migration] Created character_appearances table')
    end,

    down = function()
        Schema.drop('character_appearances')
        print('[Migration] Dropped character_appearances table')
    end
}
