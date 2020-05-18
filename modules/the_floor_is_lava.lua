-- stepping or driving on anything other than concrete or stone-path will melt you into molten state -- by mewmew

local event = require 'utils.event' 

local immune_tiles = {
	["concrete"] = true,
	["hazard-concrete-left"] = true,
	["hazard-concrete-right"] = true,
	["refined-concrete"] = true,
	["refined-hazard-concrete-left"] = true,
	["refined-hazard-concrete-right"] = true,
	["stone-path"] = true
}

local messages = {
	" likes to play in magma.",
	" got melted.",
	" tried to swim in lava.",
	" was incinerated.",
	" couldn't put the fire out.",
	" was turned into their molten form."
}

local function is_entity_on_lava(entity)
	if immune_tiles[entity.surface.get_tile(entity.position).name] then return false end
	return true
end

local function damage_entity(entity, player)
	if math.random(1,5) == 1 then
		entity.surface.create_entity({name = "fire-flame", position = player.position})
	end
	entity.health = entity.health - entity.prototype.max_health / 75
	if entity.health <= 0 then
		if entity.name == "character" then
			game.print(player.name .. messages[math.random(1, #messages)], {r = 200, g = 0, b = 0})
		end
		entity.die() 
	end
end

local function process_player(player)
	if not player.character then return end
	local entity = player.character
	if player.vehicle then
		if player.vehicle.type == "car" then
			entity = player.vehicle
		else
			return
		end
	end
	if is_entity_on_lava(entity) then
		damage_entity(entity, player)
	end
end

--local function on_player_changed_position(event)
	--if math.random(1,2) == 1 then return end
	--local player = game.players[event.player_index]
	--process_player(player)
--end

local function tick(event)
	for _, p in pairs(game.connected_players) do
		process_player(p)
	end
end

local function on_player_joined_game(event)	
	
	local player = game.players[event.player_index]
	
	if player.online_time == 0 then
		player.insert({name = "stone-brick", count = 64})
	end
end

event.on_nth_tick(5, tick)
--event.add(defines.events.on_player_changed_position, on_player_changed_position)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
