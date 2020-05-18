-- luacheck: ignore

local Global = require 'utils.global'
local Game = require 'utils.game'
local Token = require 'utils.token'
local Server = require 'utils.server'
local Event = require 'utils.event'
local table = require 'utils.table'
local Print = require('utils.print_override')
local raw_print = Print.raw_print

local session_data_set = 'sessions'
local error_offline = '[ERROR] Webpanel is offline.'
local session = {}
local online_track = {}
local trusted = {}
local set_data = Server.set_data
local try_get_data = Server.try_get_data
local concat = table.concat
local nth_tick = 54001 -- nearest prime to 15 minutes in ticks

Global.register(
    {
        session = session,
        online_track = online_track,
        trusted = trusted
    },
    function(tbl)
        session = tbl.session
        online_track = tbl.online_track
        trusted = tbl.trusted
    end
)

local Public = {}

if _DEBUG then
    printinfo =
        Token.register(
        function(data)
            game.print(serpent.block(data))
        end
    )
end

local try_download_data =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value
        if value then
            session[key] = value
            if value > 2592000 then
                trusted[key] = true
            end
        else
            session[key] = 0
            trusted[key] = false
            set_data(session_data_set, key, session[key])
        end
    end
)

local try_upload_data =
    Token.register(
    function(data)
        local key = data.key
        local player = game.get_player(key)
        local value = data.value
        if value then
            local old_time = session[key]
            if not online_track[player.name] then
                online_track[player.name] = 0
            end
            local new_time = old_time + player.online_time - online_track[player.name]
            set_data(session_data_set, key, new_time)
            online_track[player.name] = player.online_time
            session[key] = value
        end
    end
)

local function tick()
    for _, p in pairs(game.connected_players) do
        Public.try_ul_data(p.name)
    end
end

--- Tries to get data from the webpanel and updates the local table with values.
-- @param data_set player token
function Public.try_dl_data(key)
    local key = tostring(key)
    local secs = Server.get_current_time()
    if secs == nil then
        raw_print(error_offline)
        return
    else
        try_get_data(session_data_set, key, try_download_data)
        secs = nil
    end
end

--- Tries to get data from the webpanel and updates the local table with values.
-- @param data_set player token
function Public.try_ul_data(key)
    local key = tostring(key)
    local secs = Server.get_current_time()
    if secs == nil then
        raw_print(error_offline)
        return
    else
        try_get_data(session_data_set, key, try_upload_data)
        secs = nil
    end
end

--- Checks if a player exists within the table
-- @param player_name <string>
-- @return <boolean>
function Public.exists(player_name)
    return session[player_name] ~= nil
end

--- Prints a list of all players in the player_session table.
function Public.print_sessions()
    local result = {}

    for k, _ in pairs(session) do
        result[#result + 1] = k
    end

    result = concat(result, ', ')
    Game.player_print(result)
end

--- Returns the table of session
-- @return <table>
function Public.get_session_table()
    return session
end

--- Returns the table of online_track
-- @return <table>
function Public.get_tracker_table()
    return online_track
end

--- Returns the table of trusted
-- @return <table>
function Public.get_trusted_table()
    return trusted
end

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player then
            return
        end
        if game.is_multiplayer() then
            Public.try_dl_data(player.name)
        else
            session[player.name] = player.online_time
        end
    end
)

Event.add(
    defines.events.on_player_left_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player then
            return
        end
        if game.is_multiplayer() then
            Public.try_ul_data(player.name)
        end
    end
)

Event.on_nth_tick(nth_tick, tick)

Server.on_data_set_changed(
    session_data_set,
    function(data)
        session[data.key] = data.value
    end
)

return Public
