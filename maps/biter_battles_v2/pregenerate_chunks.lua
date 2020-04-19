local bb_config = require "maps.biter_battles_v2.config"
local event = require 'utils.event' 

local function set_chunk_coords_old(radius)
	global.chunk_gen_coords = {}
	for r = radius, 1, -1 do
		for x = r * -1, r - 1, 1 do
			local pos = {x = x, y = r * -1}
			if math.sqrt(pos.x ^ 2 + pos.y ^ 2) <= radius then table.insert(global.chunk_gen_coords, pos) end			
		end
		for y = r * -1, r - 1, 1 do
			local pos = {x = r, y = y}
			if math.sqrt(pos.x ^ 2 + pos.y ^ 2) <= radius then table.insert(global.chunk_gen_coords, pos) end
		end	
		for x = r, r * -1 + 1, -1 do
			local pos = {x = x, y = r}
			if math.sqrt(pos.x ^ 2 + pos.y ^ 2) <= radius then table.insert(global.chunk_gen_coords, pos) end
		end	
		for y = r, r * -1 + 1, -1 do
			local pos = {x = r * -1, y = y}
			if math.sqrt(pos.x ^ 2 + pos.y ^ 2) <= radius then table.insert(global.chunk_gen_coords, pos) end
		end	
	end
end

local function shrink_table()
	local t = {}
	for k, chunk in pairs(global.chunk_gen_coords) do
		t[chunk.x .. "_" .. chunk.y] = {key = k, chunk = {x = chunk.x, y = chunk.y}}
	end
	global.chunk_gen_coords = {}
	for k, chunk in pairs(t) do
		global.chunk_gen_coords[#global.chunk_gen_coords + 1] = {x = chunk.x, y = chunk.y}
	end
	game.print(global.chunk_gen_coords[#global.chunk_gen_coords])
end

local vectors = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}}
function set_chunk_coords(position, radius)
	if not global.chunk_gen_coords then global.chunk_gen_coords = {} end
	position.x = position.x - radius
	position.y = position.y - radius
	for r = radius, 1, -1 do		
		for _, v in pairs(vectors) do
			for a = 1, r * 2 - 1, 1 do
				position.x = position.x + v[1]
				position.y = position.y + v[2]
				global.chunk_gen_coords[#global.chunk_gen_coords + 1] = {x = position.x, y = position.y}
			end
		end
		position.x = position.x + 1
		position.y = position.y + 1
	end
	global.chunk_gen_coords[#global.chunk_gen_coords + 1] = {x = position.x, y = position.y}
end

local function draw_gui()
	for _, player in pairs(game.connected_players) do		
		if global.map_generation_complete then
			if player.gui.left["map_pregen"] then player.gui.left["map_pregen"].destroy() end
		else
			local caption = "Map is generating... " ..  #global.chunk_gen_coords .. " chunks left. Please get comfy."
			if player.gui.left["map_pregen"] then
				player.gui.left["map_pregen"].caption = caption
			else
				local frame = player.gui.left.add({
					type = "frame",
					caption = caption,
					name = "map_pregen"
				})
				frame.style.font_color = {r = 150, g = 0, b = 255}
				frame.style.font = "heading-1"
				frame.style.maximal_height = 42
			end
		end
	end
end

local function process_chunk(surface)	
	if global.map_generation_complete then return end
	if game.tick < 300 then return end
	if not global.chunk_gen_coords then
		set_chunk_coords({x = bb_config.map_pregeneration_radius * 2, y = 0}, bb_config.map_pregeneration_radius)
		set_chunk_coords({x = bb_config.map_pregeneration_radius * -2, y = 0}, bb_config.map_pregeneration_radius)
		set_chunk_coords({x = 0, y = 0}, bb_config.map_pregeneration_radius)
		--shrink_table()
		--set_chunk_coords()
		--table.shuffle_table(global.chunk_gen_coords)
	end
	if #global.chunk_gen_coords == 0 then
		global.map_generation_complete = true
		draw_gui()
		for _, player in pairs(game.connected_players) do
			player.play_sound{path="utility/new_objective", volume_modifier=0.75}
		end
		return
	end
	
	if not game then return end
	local surface = game.surfaces["biter_battles"]
	if not surface then return end
	
	local force_chunk_requests = 3
	if bb_config.fast_pregen then force_chunk_requests = 16 end
	
	for i = #global.chunk_gen_coords, 1, -1 do
		if surface.is_chunk_generated(global.chunk_gen_coords[i]) then
			--game.forces.player.chart(surface, {{(global.chunk_gen_coords[i].x * 32), (global.chunk_gen_coords[i].y * 32)}, {(global.chunk_gen_coords[i].x * 32) + 32, (global.chunk_gen_coords[i].y * 32) + 32}})
			global.chunk_gen_coords[i] = nil
		else
			--game.forces.player.chart(surface, {{(global.chunk_gen_coords[i].x * 32), (global.chunk_gen_coords[i].y * 32)}, {(global.chunk_gen_coords[i].x * 32) + 32, (global.chunk_gen_coords[i].y * 32) + 32}})
			surface.request_to_generate_chunks({x = (global.chunk_gen_coords[i].x * 32), y = (global.chunk_gen_coords[i].y * 32)}, 1)
			surface.force_generate_chunk_requests()
			global.chunk_gen_coords[i] = nil
			force_chunk_requests = force_chunk_requests - 1
			if force_chunk_requests <= 0 then
				break
			end
		end		
	end
	draw_gui()
end

return process_chunk