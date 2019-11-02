local event = require 'utils.event'
local math_random = math.random

local valid_entities = {
	["rock-big"] = true,
	["rock-huge"] = true,
	["sand-rock-big"] = true	
}

local rock_mining_chance_weights = {
	{"iron-ore", 25},
	{"copper-ore",18},
	{"mixed",15},
	{"coal",14},
	{"stone",8},
	{"uranium-ore",3}
}

local ore_raffle = {}				
for _, t in pairs (rock_mining_chance_weights) do
	for x = 1, t[2], 1 do
		table.insert(ore_raffle, t[1])
	end			
end

local mixed_ores = {"iron-ore", "copper-ore", "stone", "coal"}

local size_raffle = {
		{"giant", 65, 96},
		{"huge", 33, 64},
		{"big", 17, 32},
		{"small", 9, 16},
		{"tiny", 4, 8},
	}

local ore_prints = {
		["coal"] = {"dark", "coal", "[img=entity/coal]"},
		["iron-ore"] = {"shiny", "iron", "[img=entity/iron-ore]"},
		["copper-ore"] = {"glimmering", "copper", "[img=entity/copper-ore]"}, 
		["uranium-ore"] = {"glowing", "uranium", "[img=entity/uranium-ore]"},
		["stone"] = {"solid", "stone", "[img=entity/stone]"},
		["mixed"] = {"glitter", "mixed ore", " "},
	}


local function get_amount(position)
	local distance_to_center = math.sqrt(position.x^2 + position.y^2) * 4 + 1500	
	local m = (75 + math_random(0, 50)) * 0.01
	return distance_to_center * m
end

local function draw_chain(surface, count, ore, ore_entities, ore_positions)
	local vectors = {{0,-1},{-1,0},{1,0},{0,1}}
	local r = math_random(1, #ore_entities)
	local position = {x = ore_entities[r].position.x, y = ore_entities[r].position.y}
	for _ = 1, count, 1 do
		table.shuffle_table(vectors)		
		for i = 1, 4, 1 do
			local p = {x = position.x + vectors[i][1], y = position.y + vectors[i][2]}
			if surface.can_place_entity({name = "coal", position = p, amount = 1}) then
				if not ore_positions[p.x .. "_" .. p.y] then
					position.x = p.x
					position.y = p.y
					ore_positions[p.x .. "_" .. p.y] = true
					local name = ore
					if ore == "mixed" then name = mixed_ores[math_random(1, #mixed_ores)] end
					ore_entities[#ore_entities + 1] = {name = name, position = p, amount = get_amount(position)}
					break
				end
			end			
		end
	end
end

local function ore_vein(event)
	local surface = event.entity.surface
	local size = size_raffle[math_random(1, #size_raffle)]	
	local ore = ore_raffle[math_random(1, #ore_raffle)]
	
	local player = game.players[event.player_index]
	for _, p in pairs(game.connected_players) do
		if p.index == player.index then
			p.print("You notice something " .. ore_prints[ore][1] .. " underneath the rubble. It's a " .. size[1] .. " vein of " ..  ore_prints[ore][2] .. "!! " .. ore_prints[ore][3], { r=0.80, g=0.80, b=0.80})
		else
			game.print(
			"[color=" .. player.chat_color.r .. "," .. player.chat_color.g .. "," .. player.chat_color.b .. "]" .. player.name
			.. "[/color] found a " .. size[1] .. " vein of " ..  ore_prints[ore][2] .. "! " .. ore_prints[ore][3], { r=0.80, g=0.80, b=0.80})
		end
	end	
	
	local ore_entities = {{name = ore, position = {x = event.entity.position.x, y = event.entity.position.y}, amount = get_amount(event.entity.position)}}
	if ore == "mixed" then
		ore_entities = {{name = mixed_ores[math_random(1, #mixed_ores)], position = {x = event.entity.position.x, y = event.entity.position.y}, amount = get_amount(event.entity.position)}} 
	end
	
	local ore_positions = {[event.entity.position.x .. "_" .. event.entity.position.y] = true}
	local count = math_random(size[2], size[3])

	for _ = 1, 128, 1 do
		local c = math_random(math.floor(size[2] * 0.25) + 1, size[2])
		if count < c then c = count end
				
		local placed_ore_count = #ore_entities	
		
		draw_chain(surface, c, ore, ore_entities, ore_positions)	
		
		count = count - (#ore_entities - placed_ore_count)		
		
		if count <= 0 then break end
	end
	
	for _, e in pairs(ore_entities) do surface.create_entity(e) end
end

local function on_player_mined_entity(event)
	if not event.entity.valid then return end
	if not valid_entities[event.entity.name] then return end
	if math_random(1,768) ~= 1 then return end	
	ore_vein(event)
end

event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
