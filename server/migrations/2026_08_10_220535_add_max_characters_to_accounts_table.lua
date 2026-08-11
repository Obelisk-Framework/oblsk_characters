--- Migration: Add max_characters column to accounts table
--- Lives in oblsk_characters, not oblsk_accounts, since the character-slot
--- limit is a characters-module concept; oblsk_characters already depends
--- on oblsk_accounts (characters.account_id is a foreign key to
--- accounts.id), so altering accounts here doesn't add a new dependency.
return {
    up = function()
        Schema.table('accounts', function(table)
            table:integer('max_characters'):default(3)
        end)

        print('[Migration] Added max_characters column to accounts table')
    end,

    down = function()
        Schema.dropColumn('accounts', 'max_characters')
        print('[Migration] Dropped max_characters column from accounts table')
    end
}
