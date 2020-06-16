local math_random = math.random

local valid_entities = {
	["rock-big"] = true,
	["rock-huge"] = true,
	["sand-rock-big"] = true
}

local size_raffle = {
		{"giant", 256, 512},
		{"huge", 128, 256},
		{"big", 64, 128},
		{"small", 32, 64},
		{"tiny", 16, 32},
	}

local function get_chances()
	local chances = {}
	table.insert(chances, {"iron-ore", 25})
	table.insert(chances, {"copper-ore", 18})
	table.insert(chances, {"mixed", 15})
	table.insert(chances, {"coal", 14})
	table.insert(chances, {"stone", 8})
	table.insert(chances, {"uranium-ore", 3})

	return chances
end

local function set_raffle()
	global.rocks_yield_ore_veins.raffle = {}
	for _, t in pairs(get_chances()) do
		for _ = 1, t[2], 1 do
			table.insert(global.rocks_yield_ore_veins.raffle, t[1])
		end			
	end
	global.rocks_yield_ore_veins.mixed_ores = {"iron-ore", "copper-ore", "stone", "coal"}
end

local function get_amount(position)
	local m = (75 + math_random(0, 50)) * 0.01
end

local function draw_chain(surface, count, ore, ore_entities, ore_positions)
	local vectors = {{0,-1},{-1,0},{1,0},{0,1}}
	local r = math_random(1, #ore_entities)
	local position = {x = ore_entities[r].position.x, y = ore_entities[r].position.y}
	for _ = 1, count, 1 do
		table.shuffle_table(vectors)		
		for i = 1, 4, 1 do
			local p = {x = position.x + vectors[i][1], y = position.y + vectors[i][2]}
			local name = ore
			if ore == "mixed" then name = global.rocks_yield_ore_veins.mixed_ores[math_random(1, #global.rocks_yield_ore_veins.mixed_ores)] end
			if surface.can_place_entity({name = name, position = p, amount = 1}) then
				if not ore_positions[p.x .. "_" .. p.y] then
					position.x = p.x
					position.y = p.y
					ore_positions[p.x .. "_" .. p.y] = true
					ore_entities[#ore_entities + 1] = {name = name, position = p, amount = (75 + math_random(0, 50)) * 0.01}
					break
				end
			else
				if surface.can_fast_replace({name = name, position = p}) then
					if math_random(1, 2) == 1 then
						if not ore_positions[p.x .. "_" .. p.y] then
							position.x = p.x
							position.y = p.y
							ore_positions[p.x .. "_" .. p.y] = true
							ore_entities[#ore_entities + 1] = {name = name, position = p, amount = get_amount(position)}
							break
						end
					end
				end
			end
		end
	end
end

local function ore_vein(event)
	local surface = event.entity.surface
	local size = size_raffle[math_random(1, #size_raffle)]	
	local ore = global.rocks_yield_ore_veins.raffle[math_random(1, #global.rocks_yield_ore_veins.raffle)]
	local icon
	if game.entity_prototypes[ore] then
		icon = "[img=entity/" .. ore .. "]"
	else
		icon = " "
	end
		
	local player = game.players[event.player_index]
	for _, p in pairs(game.connected_players) do
		if p.index == player.index then			
			p.print(
				{"rocks_yield_ore_veins.player_print",
					{"rocks_yield_ore_veins_colors." .. ore},
					{"rocks_yield_ore_veins." .. size[1]},
					{"rocks_yield_ore_veins." .. ore},
					icon
				},
				{r=0.80, g=0.80, b=0.80}
			)
		else
			if p.force == player.force then
				game.print(
					{"rocks_yield_ore_veins.game_print",
						"[color=" .. player.chat_color.r .. "," .. player.chat_color.g .. "," .. player.chat_color.b .. "]" .. player.name .. "[/color]",
						{"rocks_yield_ore_veins." .. size[1]},
						{"rocks_yield_ore_veins." .. ore},
						icon
					},
					{r=0.80, g=0.80, b=0.80}
				)
			end
		end
	end	

	local position = event.entity.position
	local amount = math_random(0, 200) + 50
	local ore_entities = {{name = ore, position = {x = position.x, y = position.y}, amount = amount}}
	if ore == "mixed" then
		ore_entities = {{name = global.rocks_yield_ore_veins.mixed_ores[math_random(1, #global.rocks_yield_ore_veins.mixed_ores)], position = {x = position.x, y = position.y}, amount = amount}}
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
	if math_random(1, global.rocks_yield_ore_veins.chance) ~= 1 then return end	
	ore_vein(event)
end

local function on_init()
	global.rocks_yield_ore_veins = {}
	global.rocks_yield_ore_veins.raffle = {}
	global.rocks_yield_ore_veins.mixed_ores = {}
	global.rocks_yield_ore_veins.chance = 4		-- 25% chance to spawn ores
	set_raffle()
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)