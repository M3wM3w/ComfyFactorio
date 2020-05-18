local math_random = math.random
local Global = require 'utils.global'
local visuals_delay = 1800
local level_up_floating_text_color = {0, 205, 0}
local xp_floating_text_color = {157, 157, 157}
local experience_levels = {0}

local xp_t = {}
local last_built_entities = {}

Global.register(
    {xp_t=xp_t},
    function(tbl)
        xp_t = tbl.xp_t
		last_built_entities = tbl.last_built_entities
    end
)

local Public = {}

function Public.get_table()
	return xp_t
end
function Public.lost_xp(player, amount)
  xp_t[player.index].xp = xp_t[player.index].xp - amount
end
local xp_yield = {
	["behemoth-biter"] = 16,
	["behemoth-spitter"] = 16,
	["behemoth-worm-turret"] = 64,
	["big-biter"] = 8,
	["big-spitter"] = 8,
	["big-worm-turret"] = 48,
	["biter-spawner"] = 64,
	["character"] = 16,
	["gun-turret"] = 8,
	["laser-turret"] = 16,
	["medium-biter"] = 4,
	["medium-spitter"] = 4,
	["medium-worm-turret"] = 32,
	["small-biter"] = 1,
	["small-spitter"] = 1,
	["small-worm-turret"] = 16,
	["spitter-spawner"] = 64,
}

local function gain_xp(player, amount)
  if not player.force == "spectator" then
  	amount = math.round(amount, 2)
  	xp_t[player.index].xp = xp_t[player.index].xp + amount
  	xp_t[player.index].xp_since_last_floaty_text = xp_t[player.index].xp_since_last_floaty_text + amount
  	if xp_t[player.index].last_floaty_text > game.tick then return end
  	player.create_local_flying_text{text="+" .. xp_t[player.index].xp_since_last_floaty_text .. " xp", position=player.position, color=xp_floating_text_color, time_to_live=120, speed=2}
  	xp_t[player.index].xp_since_last_floaty_text = 0
  	xp_t[player.index].last_floaty_text = game.tick + visuals_delay
  end
end
function Public.xp_reset_player(player)
	if not player.character then
		player.set_controller({type=defines.controllers.god})
		player.create_character()
	end
	xp_t[player.index] = {
		xp = 0, points_to_distribute = 0,	last_floaty_text = visuals_delay, xp_since_last_floaty_text = 0,
		rotated_entity_delay = 0, last_mined_entity_position = {x = 0, y = 0},
	}
end

function Public.xp_reset_all_players()
	for _, p in pairs(game.players) do
		rpg_t[p.index] = nil
	end
	for _, p in pairs(game.connected_players) do
		Public.xp_reset_player(p)
	end
end

local function on_entity_died(event)
	if not event.entity.valid then return end

	--Grant XP for hand placed land mines
	if event.entity.last_user then
		if event.entity.type == "land-mine" then
			if event.cause then
				if event.cause.valid then
					if event.cause.force.index == event.entity.force.index then return end
				end
			end
			gain_xp(event.entity.last_user, 1)
			return
		end
	end

	if not event.cause then return end
	if not event.cause.valid then return end
	if event.cause.force.index == event.entity.force.index then return end
	if not get_cause_player[event.cause.type] then return end

	local players = get_cause_player[event.cause.type](event.cause)
	if not players then return end
	if not players[1] then return end

	--Grant modified XP for health boosted units
	if global.biter_health_boost then
		if event.entity.type == "unit" then
			for _, player in pairs(players) do
				if xp_yield[event.entity.name] then
					gain_xp(player, xp_yield[event.entity.name] * global.biter_health_boost)
				else
					gain_xp(player, 0.5 * global.biter_health_boost)
				end
			end
			return
		end
	end

	--Grant normal XP
	for _, player in pairs(players) do
		if xp_yield[event.entity.name] then
			gain_xp(player, xp_yield[event.entity.name])
		else
			gain_xp(player, 0.5)
		end
	end
end
local function on_player_repaired_entity(event)
	if math_random(1, 4) ~= 1 then return end
	local player = game.players[event.player_index]
	if not player.character then return end
	gain_xp(player, 0.40)
end

local function on_player_rotated_entity(event)
	local player = game.players[event.player_index]
	if not player.character then return end
	if xp_t[player.index].rotated_entity_delay > game.tick then return end
	xp_t[player.index].rotated_entity_delay = game.tick + 20
	gain_xp(player, 0.20)
end

local function on_player_changed_position(event)
	if math_random(1, 64) ~= 1 then return end
	local player = game.players[event.player_index]
	if not player.character then return end
	if player.character.driving then return end
	gain_xp(player, 1.0)
end

local building_and_mining_blacklist = {
	["tile-ghost"] = true,
	["entity-ghost"] = true,
	["item-entity"] = true,
}

local function is_replaced_entity(entity)
	if not last_built_entities[entity.position.x .. "_" .. entity.position.y] then return end
	for key, tick in pairs(last_built_entities) do
		if tick < game.tick then last_built_entities[key] = nil end
	end
	return true
end

local function on_pre_player_mined_item(event)
	local entity = event.entity
	if not entity.valid then return end
	if building_and_mining_blacklist[entity.type] then return end

	local player = game.players[event.player_index]

	if is_replaced_entity(entity) then
		gain_xp(player, -0.1)
		return
	end

	if xp_t[player.index].last_mined_entity_position.x == event.entity.position.x and xp_t[player.index].last_mined_entity_position.y == event.entity.position.y then return end
	xp_t[player.index].last_mined_entity_position.x = entity.position.x
	xp_t[player.index].last_mined_entity_position.y = entity.position.y
	if entity.type == "resource" then gain_xp(player, 0.5) return end
	if entity.force.name == "neutral" then gain_xp(player, 1.5 + event.entity.prototype.max_health * 0.0035) return end
	gain_xp(player, 0.1 + event.entity.prototype.max_health * 0.0005)
end

local function on_built_entity(event)
	local created_entity = event.created_entity
	if not created_entity.valid then return end
	if building_and_mining_blacklist[created_entity.type] then return end
	last_built_entities[created_entity.position.x .. "_" .. created_entity.position.y] = game.tick + 1800
	local player = game.players[event.player_index]
	gain_xp(player, 0.1)
end

local function on_player_crafted_item(event)
	if not event.recipe.energy then return end
	local player = game.players[event.player_index]
	gain_xp(player, event.recipe.energy * 0.20)
end

local function on_player_respawned(event)
	local player = game.players[event.player_index]
	if not xp_t[player.index] then Public.xp_reset_player(player) return end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not xp_t[player.index] then Public.xp_reset_player(player) end
end

local function on_init(event)
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_player_changed_position, on_player_changed_position)
event.add(defines.events.on_player_crafted_item, on_player_crafted_item)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_repaired_entity, on_player_repaired_entity)
event.add(defines.events.on_player_respawned, on_player_respawned)
event.add(defines.events.on_player_rotated_entity, on_player_rotated_entity)
event.add(defines.events.on_pre_player_mined_item, on_pre_player_mined_item)

return Public
