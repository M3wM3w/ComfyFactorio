local Event = require 'utils.event'
local FDT = require 'maps.fish_defender.table'

local function on_player_changed_position(event)
    local vehicle_nanobots_unlocked = FDT.get('vehicle_nanobots_unlocked')

    if not vehicle_nanobots_unlocked then
        return
    end
    local player = game.players[event.player_index]
    if not player.character then
        return
    end
    if not player.character.driving then
        return
    end
    if not player.vehicle then
        return
    end
    if not player.vehicle.valid then
        return
    end
    if player.vehicle.health == player.vehicle.prototype.max_health then
        return
    end
    player.vehicle.health = player.vehicle.health + player.vehicle.prototype.max_health * 0.005
end

Event.add(defines.events.on_player_changed_position, on_player_changed_position)
