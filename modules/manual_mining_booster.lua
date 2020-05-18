--manually mining continuously will speed it up 

local event = require 'utils.event'

local valid_entities = {
	["rock-big"] = true,
	["rock-huge"] = true,
	["sand-rock-big"] = true,
}

local function mining_speed_cooldown(p)
	if not global.manual_mining_booster[p.index] then return end
	if game.tick - global.manual_mining_booster[p.index] < 180 then return end
	--if not p.character then p.character.character_mining_speed_modifier = 0 return end
	if not p.character then return end
	p.character.character_mining_speed_modifier = p.character.character_mining_speed_modifier - 1
	if p.character.character_mining_speed_modifier <= 0 then
		p.character.character_mining_speed_modifier = 0
		global.manual_mining_booster[p.index] = nil
	end
end

local function on_player_mined_entity(event)
	if not valid_entities[event.entity.name] then return end
	local player = game.players[event.player_index]
	player.character.character_mining_speed_modifier = player.character.character_mining_speed_modifier + (math.random(25, 50) * 0.01)
	if player.character.character_mining_speed_modifier > 10 then player.character.character_mining_speed_modifier = 10 end
	global.manual_mining_booster[event.player_index] = game.tick	
end

local function tick()
	for _, p in pairs(game.connected_players) do
		mining_speed_cooldown(p)
	end
end

local function on_init(event)
	global.manual_mining_booster = {}
end

event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.on_nth_tick(60, tick)
event.on_init(on_init)