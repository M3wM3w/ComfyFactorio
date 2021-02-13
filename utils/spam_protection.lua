local Event = require 'utils.event'
local Global = require 'utils.global'
local Public = {}

local this = {
    prevent_spam = {}, -- the default table where all player indexes will be stored
    default_tick = 10, -- this defines the default tick to check weather or not a user is spamming a button.
    _DEBUG = false
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local function debug_str(str)
    if not this._DEBUG then
        return
    end
    print(str)
end

function Public.reset_spam_table()
    local players = game.connected_players
    this.prevent_spam = {}
    for i = 1, #players do
        local player = players[i]
        this.prevent_spam[player.index] = game.tick
    end
end

function Public.set_new_value(player)
    if this.prevent_spam[player.index] then
        this.prevent_spam[player.index] = game.tick
        return this.prevent_spam[player.index]
    end
    return false
end

function Public.is_spamming(player, value_to_compare, text)
    if not this.prevent_spam[player.index] then
        return false
    end

    if text then
        debug_str('Frame: ' .. text)
    end

    if game.tick_paused then
        return false -- game is paused - shoo
    end

    local tick = game.tick
    local value = value_to_compare or this.default_tick
    if this.prevent_spam[player.index] then
        if (tick - this.prevent_spam[player.index]) > value then
            Public.set_new_value(player)
            debug_str(player.name .. ' is not spamming.')
            return false -- is not spamming
        else
            debug_str(player.name .. ' is spamming.')
            return true -- is spamming
        end
    end
    return false
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.get_player(event.player_index)

        if not this.prevent_spam[player.index] then
            this.prevent_spam[player.index] = game.tick
        end
    end
)
Event.on_init(
    function()
        Public.reset_spam_table()
    end
)

return Public
