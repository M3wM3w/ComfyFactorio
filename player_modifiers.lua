--Central to add all player modifiers together.
--Will overwrite character stats from other mods.

local Global = require 'utils.global'

local this = {}

Global.register(
    this,
    function(t)
        this = t
    end
)

local Public = {}

function Public.get_table()
    return this
end

local modifiers = {
    'character_build_distance_bonus',
    'character_crafting_speed_modifier',
    'character_health_bonus',
    'character_inventory_slots_bonus',
    'character_item_drop_distance_bonus',
    'character_item_pickup_distance_bonus',
    'character_loot_pickup_distance_bonus',
    'character_mining_speed_modifier',
    'character_reach_distance_bonus',
    'character_resource_reach_distance_bonus',
    'character_running_speed_modifier'
}

function Public.update_player_modifiers(player)
    for _, modifier in pairs(modifiers) do
        local sum_value = 0
        for _, value in pairs(this[player.index][modifier]) do
            sum_value = sum_value + value
        end
        if player.character then
            player[modifier] = sum_value
        end
    end
end

local function on_player_joined_game(event)
    if this[event.player_index] then
        Public.update_player_modifiers(game.players[event.player_index])
        return
    end
    this[event.player_index] = {}
    for _, modifier in pairs(modifiers) do
        this[event.player_index][modifier] = {}
    end
end

local function on_player_respawned(event)
    Public.update_player_modifiers(game.players[event.player_index])
end

local Event = require 'utils.event'
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)

return Public
