--- Migration: Create characters table
return {
    up = function()
        Schema.create('characters', function(table)
            table:id()
            table:integer('account_id'):notNullable()
            table:integer('slot'):notNullable()
            table:string('first_name', 100):notNullable()
            table:string('last_name', 100):notNullable()
            table:string('gender', 20)
            table:date('dob')
            table:text('bio')
            table:datetime('last_played_at')
            table:datetime('deleted_at')
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
