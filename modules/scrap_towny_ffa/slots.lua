-- called whenever a player places an item
local function on_built_entity(event)
    local entity = event.created_entity
    if not entity.valid then return end
    if entity.name ~= "laser-turret" then return end
    local player = game.players[event.player_index]
    local force = player.force
    local town_center = global.towny.town_centers[force.name]
    local surface = entity.surface
    if force == game.forces["player"] or force == game.forces["rogue"] or town_center == nil then
        surface.create_entity({
            name = "flying-text",
            position = entity.position,
            text = "You are not acclimated to this technology!",
            color = {r=0.77, g=0.0, b=0.0}
        })
        player.insert({name = "laser-turret", count = 1})
        entity.destroy()
        return
    end
    local slots = town_center.upgrades.laser_turret.slots
    local locations = town_center.upgrades.laser_turret.locations
    if table_size(locations) >= slots then
        surface.create_entity({
            name = "flying-text",
            position = entity.position,
            text = "You do not have enough slots!",
            color = {r=0.77, g=0.0, b=0.0}
        })
        player.insert({name = "laser-turret", count = 1})
        entity.destroy()
        return
    end
    local position = entity.position
    local key = tostring("{" .. position.x .. "," .. position.y .. "}")
    locations[key] = true
end

-- called whenever a player mines an entity but before it is removed from the map
-- will have the contents of the drops
local function on_player_mined_entity(event)
    local player = game.players[event.player_index]
    local force = player.force
    local entity = event.entity
    if entity.name == "laser-turret" then
        local town_center = global.towny.town_centers[force.name]
        if force == game.forces["player"] or force == game.forces["rogue"] or town_center == nil then return end
        local locations = town_center.upgrades.laser_turret.locations
        local position = entity.position
        local key = tostring("{" .. position.x .. "," .. position.y .. "}")
        locations[key] = nil
    end
end

local Event = require 'utils.event'
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
