local Event = require 'utils.event'
local FDT = require 'maps.fish_defender.table'

local function on_player_changed_position(event)
    local flame_boots = FDT.get('flame_boots')
    if not flame_boots then
        return
    end
    local player = game.players[event.player_index]
    if not player.character then
        return
    end
    if player.character.driving then
        return
    end

    if not flame_boots[player.index] then
        flame_boots[player.index] = {}
    end

    if not flame_boots[player.index].fuel then
        return
    end

    if flame_boots[player.index].fuel < 0 then
        player.print('Your flame boots have worn out.', {r = 0.22, g = 0.77, b = 0.44})
        flame_boots[player.index] = {}
        return
    end

    if flame_boots[player.index].fuel % 500 == 0 then
        player.print('Fuel remaining: ' .. flame_boots[player.index].fuel, {r = 0.22, g = 0.77, b = 0.44})
    end

    if not flame_boots[player.index].step_history then
        flame_boots[player.index].step_history = {}
    end

    local elements = #flame_boots[player.index].step_history

    flame_boots[player.index].step_history[elements + 1] = {x = player.position.x, y = player.position.y}

    if elements < 50 then
        return
    end

    player.surface.create_entity({name = 'fire-flame', position = flame_boots[player.index].step_history[elements - 2]})

    flame_boots[player.index].fuel = flame_boots[player.index].fuel - 1
end

Event.add(defines.events.on_player_changed_position, on_player_changed_position)
