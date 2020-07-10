local Global = require 'utils.global'
local Session = require 'utils.session_data'
local Game = require 'utils.game'
local Token = require 'utils.token'
local Task = require 'utils.task'
local Server = require 'utils.server'
local Event = require 'utils.event'
local Utils = require 'utils.core'

local jailed_data_set = 'jailed'
local jailed = {}
local votejail = {}
local votejail_count = 3
local set_data = Server.set_data
local try_get_data = Server.try_get_data
local concat = table.concat

local jail_messages = {
    'You´re done bud!',
    'Busted!'
}

local freedom_messages = {
    'Yaay!',
    'Welcome back!'
}

local valid_commands = {
    ['free'] = true,
    ['jail'] = true
}

Global.register(
    {
        jailed = jailed,
        votejail = votejail
    },
    function(t)
        jailed = t.jailed
        votejail = t.votejail
    end
)

local Public = {}

local jail = function(target_player, player)
    if jailed[target_player] then
        if player then
            Utils.print_to(player, target_player .. ' is already jailed!')
            return false
        else
            return false
        end
    end

    if not game.players[target_player] then
        return
    end

    local permission_group = game.permissions.get_group('prisoner')
    if not permission_group then
        permission_group = game.permissions.create_group('prisoner')
        for action_name, _ in pairs(defines.input_action) do
            permission_group.set_allows_action(defines.input_action[action_name], false)
        end
        permission_group.set_allows_action(defines.input_action.write_to_console, true)
        permission_group.set_allows_action(defines.input_action.gui_click, true)
        permission_group.set_allows_action(defines.input_action.gui_selection_state_changed, true)
    end
    permission_group.add_player(target_player)
    local message
    if player then
        message =
            target_player .. ' has been jailed by ' .. player .. '. ' .. jail_messages[math.random(1, #jail_messages)]
    else
        message =
            target_player ..
            ' has been jailed automatically since they have griefed. ' .. jail_messages[math.random(1, #jail_messages)]
    end

    if
        game.players[target_player].character and game.players[target_player].character.valid and
            game.players[target_player].character.driving
     then
        game.players[target_player].character.driving = false
    end

    Utils.print_to(nil, message)
    Utils.action_warning_embed('{Jailed}', message)
    Utils.print_admins('Jailed ' .. target_player, player)

    game.players[target_player].clear_console()
    Utils.print_to(target_player, message)
    return true
end

local free = function(target_player, player)
    if not jailed[target_player] then
        if player then
            Utils.print_to(player, target_player .. ' is not jailed!')
            return false
        else
            return false
        end
    end

    if not game.players[target_player] then
        return
    end

    local permission_group = game.permissions.get_group('Default')
    permission_group.add_player(target_player)
    local message
    if player then
        message =
            target_player ..
            ' was set free from jail by ' .. player .. '. ' .. freedom_messages[math.random(1, #freedom_messages)]
    else
        message = target_player .. ' was set free from jail. ' .. freedom_messages[math.random(1, #freedom_messages)]
    end

    jailed[target_player] = nil

    if votejail[target_player] then
        votejail[target_player] = nil
    end

    Utils.print_to(nil, message)
    Utils.action_warning_embed('{Jailed}', message)
    Utils.print_admins('Free´d ' .. target_player .. ' from jail.', player)
    return true
end

local is_jailed =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value
        if value then
            if value.jailed then
                jail(key)
                jailed[key] = {jailed = true, actor = value.actor}
            end
        end
    end
)

local update_jailed =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value
        local player = data.player or 'script'
        if value then
            jail(key)
            set_data(jailed_data_set, key, {jailed = true, actor = player})
        else
            free(key)
            set_data(jailed_data_set, key, nil)
        end
    end
)

--- Tries to get data from the webpanel and updates the local table with values.
-- @param data_set player token
function Public.try_dl_data(key)
    key = tostring(key)

    local secs = Server.get_current_time()

    if not secs then
        return
    else
        try_get_data(jailed_data_set, key, is_jailed)
    end
end

--- Tries to get data from the webpanel and updates the local table with values.
-- @param data_set player token
function Public.try_ul_data(key, value, player)
    key = tostring(key)

    local data = {
        key = key,
        value = value,
        player = player or nil
    }

    Task.set_timeout_in_ticks(1, update_jailed, data)
end

--- Checks if a player exists within the table
-- @param player_name <string>
-- @return <boolean>
function Public.exists(player_name)
    return jailed[player_name] ~= nil
end

--- Prints a list of all players in the player_jailed table.
function Public.print_jailed()
    local result = {}

    for k, _ in pairs(jailed) do
        result[#result + 1] = k
    end

    result = concat(result, ', ')
    Game.player_print(result)
end

--- Returns the table of jailed
-- @return <table>
function Public.get_jailed_table()
    return jailed
end

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid then
            return
        end

        Public.try_dl_data(player.name)
    end
)

Event.add(
    defines.events.on_console_command,
    function(event)
        local tracker = Session.get_session_table()
        local script = 'script'
        local cmd = event.command
        local _10d = 51840000 -- 10d
        local _12h = 2592000 --  12h

        if not valid_commands[cmd] then
            return
        end

        local griefer = event.parameters
        if not griefer then
            return
        end

        if event.player_index then
            local player = game.players[event.player_index]

            if game.players[griefer] then
                griefer = game.players[griefer].name
            end

            if not game.players[griefer] then
                return Utils.print_to(player, 'Invalid name.')
            end

            local playtime = player.online_time
            if tracker[player.name] then
                playtime = player.online_time + tracker[player.name]
            end

            if votejail[player.name] and not player.admin then
                return Utils.print_to(player, 'You are currently being investigated since you have griefed.')
            end

            if jailed[player.name] and not player.admin then
                return Utils.print_to(player, 'You are jailed, you can´t run this command.')
            end

            if player.name == griefer then
                return Utils.print_to(player, 'You can´t select yourself.')
            end

            if game.players[griefer].admin and not player.admin then
                return Utils.print_to(player, 'You can´t select an admin.')
            end

            if playtime >= _12h and playtime < _10d and not player.admin then
                if not votejail[griefer] then
                    votejail[griefer] = {}
                    local message = player.name .. ' has started a vote to jail player ' .. griefer
                    Utils.print_to(nil, message)
                end
                if not votejail[griefer][player.name] then
                    votejail[griefer][player.name] = true
                    Utils.print_to(player, 'You have voted to jail player ' .. griefer .. '.')
                    if
                        #votejail[griefer] >= votejail_count or
                            (#votejail[griefer] == 2 and 3 == #game.connected_players)
                     then
                        local message = griefer .. ' has been jailed by player vote.'
                        Utils.print_to(nil, message)
                        Public.try_ul_data(griefer, true, script)
                    end
                else
                    Utils.print_to(player, 'You have already voted to kick ' .. griefer .. '.')
                end
                return
            elseif playtime < _10d and not player.admin then
                return Utils.print_to(player, 'You are not trusted enough to run this command.')
            end

            if cmd == 'jail' then
                Public.try_ul_data(griefer, true, player.name)
                return
            elseif cmd == 'free' then
                Public.try_ul_data(griefer, false, player.name)
                return
            end
        else
            if cmd == 'jail' then
                Public.try_ul_data(griefer, true, script)
                return
            elseif cmd == 'free' then
                Public.try_ul_data(griefer, false, script)
                return
            end
        end
    end
)

Server.on_data_set_changed(
    jailed_data_set,
    function(data)
        if data and data.value then
            if data.value.jailed and data.value.actor then
                jail(data.key)
                jailed[data.key] = {jailed = true, actor = data.value.actor}
            end
        else
            free(data.key)
        end
    end
)

commands.add_command(
    'jail',
    'Sends the player to gulag!',
    function()
        return
    end
)

commands.add_command(
    'free',
    'Brings back the player from gulag.',
    function()
        return
    end
)

return Public
