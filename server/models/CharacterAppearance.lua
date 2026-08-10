--- CharacterAppearance Model - ped customization for one Character.
--- ped_model is its own column since it determines which base model to
--- spawn; everything else (head blend, overlays, components, props,
--- hair/eye color) lives in data as the long tail, same convention as
--- Vehicle.body_damage.
CharacterAppearance = BaseModel:extend('character_appearances')

CharacterAppearance.primaryKey = 'id'
CharacterAppearance.timestamps = true
CharacterAppearance.fillable = { 'character_id', 'ped_model', 'data' }
CharacterAppearance.hidden = {}

CharacterAppearance.casts = {
    data = 'json',
}

function CharacterAppearance:characterRelation()
    return self:belongsTo(Character, 'character_id', 'id')
end

return CharacterAppearance
