-- luacheck: ignore
local Token = require 'utils.token'
local Server = require 'utils.server'
local Event = require 'utils.event'

local color_data_set = 'colors'
local set_data = Server.set_data
local try_get_data = Server.try_get_data


local Public = {}

if _DEBUG then
printinfo =
    Token.register(
    function(data)
        game.print(serpent.block(data))
    end
)
end

local color_table = {
    default = {},
    red = {},
    green = {},
    blue = {},
    orange = {},
    yellow = {},
    pink = {},
    purple = {},
    white = {},
    black = {},
    gray = {},
    brown = {},
    cyan = {},
    acid = {}
}

local fetch =
    Token.register(
    function(data)
        local key = data.key
        local value = data.value
        local player = game.players[key]
        if not player then return end
        if value then
            player.color = value.color[1]
            player.chat_color = value.chat[1]
        --else
        --    set_data(color_data_set, player.name, {color={player.color},chat={player.chat_color}})
        end
    end
)

--- Tries to get data from the webpanel and applies the value to the player.
-- @param data_set player token
function Public.fetch(key)
    try_get_data(color_data_set, key, fetch)
end

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)
        if not player then
            return
        end
        if game.is_multiplayer() then
            Public.fetch(player.name)
        end
    end
)

Event.add(
    defines.events.on_console_command,
    function(event)
        local player_index = event.player_index
        if not player_index or event.command ~= 'color' then
            return
        end

        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end

        local param = event.parameters
        local color = player.color
        local chat = player.chat_color
        param = string.lower(param)
        if param then
            for word in param:gmatch('%S+') do
                if color_table[word] then
                    set_data(color_data_set, player.name, {color={color},chat={chat}})
                    player.print("Your color was globally saved!", {r=0.22, g=0.99, b=0.99})
                return true
                end
            end
        end
    end
)

return Public