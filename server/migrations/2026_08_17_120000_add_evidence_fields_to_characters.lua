--- Migration: Add fingerprint_id and blood_type columns to characters
return {
    up = function()
        Schema.table('characters', function(table)
            table:string('fingerprint_id', 16):nullable()
            table:string('blood_type', 3):nullable()
        end)
        print('[Migration] Added fingerprint_id and blood_type to characters table')
    end,

    down = function()
        Schema.dropColumn('characters', 'fingerprint_id')
        Schema.dropColumn('characters', 'blood_type')
        print('[Migration] Dropped fingerprint_id and blood_type from characters table')
    end
}
