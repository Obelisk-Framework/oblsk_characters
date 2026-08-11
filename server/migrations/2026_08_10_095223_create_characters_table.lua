--- Migration: Create characters table
return {
    up = function()
        Schema.create('characters', function(table)
            table:id()
            table:integer('account_id')
            table:integer('slot')
            table:string('first_name', 100)
            table:string('last_name', 100)
            table:string('gender', 20):nullable()
            table:date('dob'):nullable()
            table:text('bio'):nullable()
            table:datetime('last_played_at'):nullable()
            table:datetime('deleted_at'):nullable()
            table:timestamps()

            table:index({'account_id'})
            table:foreign('account_id'):references('id'):on('accounts'):onDelete('CASCADE')
        end)

        print('[Migration] Created characters table')
    end,

    down = function()
        Schema.drop('characters')
        print('[Migration] Dropped characters table')
    end
}
