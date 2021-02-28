local RPG_T = require 'modules.rpg.table'
local radius = 3
local random = math.random
local floor = math.floor
local sqrt = math.sqrt

local Public = {}

local function splash_damage(surface, position, final_damage_amount)
    local create = surface.create_entity
    local damage = random(floor(final_damage_amount * 3), floor(final_damage_amount * 4))
    for _, e in pairs(surface.find_entities_filtered({area = {{position.x - radius, position.y - radius}, {position.x + radius, position.y + radius}}})) do
        if e.valid and e.health then
            local distance_from_center = sqrt((e.position.x - position.x) ^ 2 + (e.position.y - position.y) ^ 2)
            if distance_from_center <= radius then
                local damage_distance_modifier = 1 - distance_from_center / radius
                if damage > 0 then
                    if random(1, 3) == 1 then
                        create({name = 'explosion', position = e.position})
                    end
                    e.damage(damage * damage_distance_modifier, 'player', 'explosion')
                end
            end
        end
    end
end

function Public.explosive_bullets(event)
    local is_explosive_bullets_enabled = RPG_T.get_explosive_bullets()
    if not is_explosive_bullets_enabled then
        return
    end

    if random(1, 3) ~= 1 then
        return false
    end
    local cause = event.cause
    if not cause or not cause.valid then
        return
    end

    if cause.name ~= 'character' then
        return
    end

    if event.damage_type.name ~= 'physical' then
        return
    end

    local player = event.cause
    if not player or not player.valid then
        return
    end

    local p = event.cause.player
    if not p or not p.valid then
        return
    end

    local player_data = RPG_T.get('rpg_t')
    local rpg_player = player_data[p.index]
    if not rpg_player.explosive_bullets then
        return
    end

    if player.shooting_state.state == defines.shooting.not_shooting then
        return
    end

    local weapon = player.get_inventory(defines.inventory.character_guns)[player.selected_gun_index]
    local ammo = player.get_inventory(defines.inventory.character_ammo)[player.selected_gun_index]
    if not weapon.valid_for_read or not ammo.valid_for_read then
        return
    end
    if ammo.name ~= 'firearm-magazine' and ammo.name ~= 'piercing-rounds-magazine' and ammo.name ~= 'uranium-rounds-magazine' then
        return
    end
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local surface = player.surface
    local create = surface.create_entity

    if entity.force.index ~= player.force.index then
        create({name = 'explosion', position = entity.position})
        splash_damage(surface, entity.position, event.final_damage_amount)
    end
end

return Public
