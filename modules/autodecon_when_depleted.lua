local event = require 'utils.event' 
local function is_depleted(drill, entity)
    local position = drill.position
    local area
    if drill.name == 'electric-mining-drill' then
        area = {{position.x - 2.5, position.y - 2.5}, {position.x + 2.5, position.y + 2.5}}
    else
        area = {{position.x - 1, position.y - 1}, {position.x + 1, position.y + 1}}
    end

    for _, resource in pairs(drill.surface.find_entities_filtered {type = 'resource', area = area}) do
        if resource ~= entity and resource.name ~= 'crude-oil' then
            return false
        end
    end
    return true
end

local function on_resource_depleted(event)
    local entity = event.entity
    if entity.name == 'uranium-ore' then
        return nil
    end

    local position = entity.position
    local area = {{position.x - 1, position.y - 1}, {position.x + 1, position.y + 1}}
    local drills = event.entity.surface.find_entities_filtered {area = area, type = 'mining-drill'}
    for _, drill in ipairs(drills) do
        if drill.name ~= 'pumpjack' and is_depleted(drill, entity) then
            drill.order_deconstruction(drill.force)
        end
    end
end

event.add(defines.events.on_resource_depleted, on_resource_depleted)