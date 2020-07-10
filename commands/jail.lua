local Server = require 'utils.server'
local Event = require 'utils.event'

local function on_console_command(event)
    local cmd = event.command
    if not event.player_index then
        return
    end
    local player = game.players[event.player_index]
    local reason = event.parameters
    if not reason then
        return
    end
    if not player.admin then
        return
    end
    if cmd == 'ban' then
        if player then
            Server.to_banned_embed(table.concat {player.name .. ' banned ' .. reason})
            return
        else
            Server.to_banned_embed(table.concat {'Server banned ' .. reason})
            return
        end
    elseif cmd == 'unban' then
        if player then
            Server.to_banned_embed(table.concat {player.name .. ' unbanned ' .. reason})
            return
        else
            Server.to_banned_embed(table.concat {'Server unbanned ' .. reason})
            return
        end
    end
end

Event.add(defines.events.on_console_command, on_console_command)
