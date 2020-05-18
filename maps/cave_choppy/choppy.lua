--choppy-- mewmew made this --
-- modified by gerkiz

require "on_tick_schedule"
require "modules.dynamic_landfill"
require "modules.satellite_score"
require "modules.spawners_contain_biters"
--require "maps.choppy_map_intro"

local unearthing_worm = require "functions.unearthing_worm"
local unearthing_biters = require "functions.unearthing_biters"
local tick_tack_trap = require "functions.tick_tack_trap"
local create_entity_chain = require "functions.create_entity_chain"
local create_tile_chain = require "functions.create_tile_chain"
local Module = require "modules.infinity_chest"

local simplex_noise = require 'utils.simplex_noise'.d2
local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random
local map_functions = require "tools.map_functions"

local disabled_for_deconstruction = {
		["fish"] = true,
		["rock-huge"] = true,
		["rock-big"] = true,
		["sand-rock-big"] = true,
		["mineable-wreckage"] = true
	}

local tile_replacements = {
	["dirt-1"] = "grass-1",
	["dirt-2"] = "grass-2",
	["dirt-3"] = "grass-3",
	["dirt-4"] = "grass-4",
	["dirt-5"] = "grass-1",
	["sand-1"] = "grass-1",
	["sand-2"] = "grass-2",
	["sand-3"] = "grass-3",
	["dry-dirt"] = "grass-2",	
	["red-desert-0"] = "grass-1",
	["red-desert-1"] = "grass-2",
	["red-desert-2"] = "grass-3",
	["red-desert-3"] = "grass-4",
}

local rocks = {"rock-big", "rock-big", "rock-huge"}
local decos = {"green-hairy-grass", "green-hairy-grass", "green-hairy-grass", "green-hairy-grass", "green-hairy-grass", "green-hairy-grass", "green-carpet-grass", "green-carpet-grass","green-pita"}
local decos_inside_forest = {"brown-asterisk","brown-asterisk", "brown-carpet-grass","brown-hairy-grass"}

local noises = {
	["forest_location"] = {{modifier = 0.006, weight = 1}, {modifier = 0.01, weight = 0.25}, {modifier = 0.05, weight = 0.15}, {modifier = 0.1, weight = 0.05}},
	["forest_density"] = {{modifier = 0.01, weight = 1}, {modifier = 0.05, weight = 0.5}, {modifier = 0.1, weight = 0.025}}
}
local function get_noise(name, pos, seed)
	local noise = 0
	for _, n in pairs(noises[name]) do
		noise = noise + simplex_noise(pos.x * n.modifier, pos.y * n.modifier, seed) * n.weight
		seed = seed + 10000
	end
	return noise
end

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math_random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end


local entities_to_convert = {
	["coal"] = true,
	["copper-ore"] = true,
	["iron-ore"] = true,
	["uranium-ore"] = true,
	["stone"] = true,
	["angels-ore1"] = true,
	["angels-ore2"] = true,
	["angels-ore3"] = true,
	["angels-ore4"] = true,
	["angels-ore5"] = true,
	["angels-ore6"] = true,
	["thorium-ore"] = true
}

local trees_to_remove = {
	["dead-dry-hairy-tree"] = true,
	["dead-grey-trunk"] = true,
	["dead-tree-desert"] = true,
	["dry-hairy-tree"] = true,
	["dry-tree"] = true,
	["tree-01"] = true,
	["tree-02"] = true,
	["tree-02-red"] = true,
	["tree-03"] = true,
	["tree-04"] = true,
	["tree-05"] = true,
	["tree-06"] = true,
	["tree-06-brown"] = true,
	["tree-07"] = true,
	["tree-08"] = true,
	["tree-08-brown"] = true,
	["tree-08-red"] = true,
	["tree-09"] = true,
	["tree-09-brown"] = true,
	["tree-09-red"] = true
}

local info = [[
	You are a lumberjack with a passion to chop.	
	
	Different kinds of trees, yield different kinds of ore and wood. 	
	Yes, they seem to draw minerals out of the ground and manifesting it as "fruit".
	Their yield increases with distance. Mining Productivity Research will increase chopping speed and backpack size.
	
	Beware, sometimes there are some bugs hiding underneath the trees.
	Even dangerous traps have been encountered before.
	
	These mysterious ore trees don't burn very well, so do not worry if some of them catch on fire.

	Also, there seems to be an elevator that goes down to the mine. Who knows what one can find down there...
	
	Choppy Choppy Wood
]]

local choppy_messages = {
	"We should branch out.",
	"Wood? Well that's the root of the problem.",
	"Going out for chopping? Son of a birch.",
	"Why do trees hate tests? Because they get stumped by the questions.",
	"What happens to the most lovely trees every Valentine’s Day? They get all sappy.",
	"Ever wondered how trees get online? They just log in."
	}

local function create_map_intro_button(player)
	if player.gui.top["map_intro_button"] then return end
	local b = player.gui.top.add({type = "sprite-button", caption = "?", name = "map_intro_button", tooltip = "Map Info"})
	b.style.font_color = {r = 0.1, g = 0.8, b = 0.1}
	b.style.font = "heading-1"
	b.style.minimal_height = 38
	b.style.minimal_width = 38
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2
end

local function create_choppy_stats_gui(player)	
	if player.gui.top["choppy_stats_frame"] then player.gui.top["choppy_stats_frame"].destroy() end
	
	local captions = {}
	local caption_style = {{"font", "default-bold"}, {"font_color",{ r=0.63, g=0.63, b=0.63}}, {"top_padding",2}, {"left_padding",0},{"right_padding",0},{"minimal_width",0}}
	local stat_numbers = {}
	local stat_number_style = {{"font", "default-bold"}, {"font_color",{ r=0.77, g=0.77, b=0.77}}, {"top_padding",2}, {"left_padding",0},{"right_padding",0},{"minimal_width",0}}
	local separators = {}
	local separator_style = {{"font", "default-bold"}, {"font_color",{ r=0.15, g=0.15, b=0.89}}, {"top_padding",2}, {"left_padding",2},{"right_padding",2},{"minimal_width",0}}
			
	
	local frame = player.gui.top.add { type = "frame", name = "choppy_stats_frame" }
	
	local t = frame.add { type = "table", column_count = 16 }						
	
	captions[1] = t.add { type = "label", caption = '[img=item/iron-ore] :' }
	
	global.total_ores_mined = global.stats_ores_found + game.forces.player.item_production_statistics.get_input_count("coal") + game.forces.player.item_production_statistics.get_input_count("iron-ore") + game.forces.player.item_production_statistics.get_input_count("copper-ore") + game.forces.player.item_production_statistics.get_input_count("uranium-ore")	
	
	stat_numbers[1] = t.add { type = "label", caption = global.total_ores_mined }
			
	separators[1] = t.add { type = "label", caption = "|"}

	captions[2] = t.add { type = "label", caption = '[img=entity.tree-04] :' }
	stat_numbers[2] = t.add { type = "label", caption = global.stats_wood_chopped }
							
	separators[2] = t.add { type = "label", caption = "|"}
	
	captions[3] = t.add { type = "label", caption = '[img=item.productivity-module] :' }
	local x = math.floor(game.forces.player.manual_mining_speed_modifier * 100)
	local str = ""
	if x > 0 then str = str .. "+" end
	str = str .. tostring(x)
	str = str .. "%"		
	stat_numbers[3] = t.add { type = "label", caption = str }
		
	if game.forces.player.manual_mining_speed_modifier > 0 or game.forces.player.mining_drill_productivity_bonus > 0 then	
		separators[3] = t.add { type = "label", caption = "|"}
		
		captions[3] = t.add { type = "label", caption = '[img=utility.hand] :' }	
		local str = "+"
		str = str .. tostring(game.forces.player.mining_drill_productivity_bonus * 100)
		str = str .. "%"	
		stat_numbers[3] = t.add { type = "label", caption = str }
		
	end	
	
	for _, s in pairs (caption_style) do
		for _, l in pairs (captions) do
			l.style[s[1]] = s[2]
		end
	end
	for _, s in pairs (stat_number_style) do
		for _, l in pairs (stat_numbers) do
			l.style[s[1]] = s[2]
		end
	end
	for _, s in pairs (separator_style) do
		for _, l in pairs (separators) do
			l.style[s[1]] = s[2]
		end
	end
	stat_numbers[1].style.minimal_width = 9 * string.len(tostring(global.stats_ores_found))
	stat_numbers[2].style.minimal_width = 9 * string.len(tostring(global.stats_rocks_broken))
end

local function create_map_intro(player)
	if player.gui.left["map_intro_frame"] then player.gui.left["map_intro_frame"].destroy() end
	local frame = player.gui.left.add {type = "frame", name = "map_intro_frame", direction = "vertical"}
	
	local t = frame.add {type = "table", column_count = 1}	
	
	local b = frame.add {type = "button", caption = "Close", name = "close_map_intro_frame", align = "right"}	
	b.style.font = "default"
	b.style.minimal_height = 30
	b.style.minimal_width = 30
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2
	
	local frame = t.add {type = "frame"}
	local l = frame.add {type = "label", caption = info}
	l.style.single_line = false
	l.style.font = "heading-3"
	l.style.font_color = {r=0.95, g=0.95, b=0.95}			
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end		
	local player = game.players[event.element.player_index]
	local name = event.element.name
	local frame = player.gui.top["choppy_stats_frame"]	

	if name == "map_intro_button" and frame == nil then create_choppy_stats_gui(player) end	
	if name == "map_intro_button" and frame then
		if player.gui.left["map_intro_frame"] then
			frame.destroy()
			player.gui.left["map_intro_frame"].destroy()
		else	
			create_map_intro(player)
		end
		return					
	end
	if name == "close_map_intro_frame" then player.gui.left["map_intro_frame"].destroy() end
end

local function refresh_gui()
	for _, player in pairs(game.connected_players) do
		local frame = player.gui.top["choppy_stats_frame"]
		if (frame) then			
			create_choppy_stats_gui(player)
			create_map_intro_button(player)					
		end
	end
end

local function process_entity(e)
	if not e.valid then return end
	if trees_to_remove[e.name] then
		e.destroy()
		return
	end
	if entities_to_convert[e.name] then
		if math_random(1,100) > 33 then e.surface.create_entity({name = rocks[math_random(1, #rocks)], position = e.position}) end
		e.destroy()
		return
	end
end

local function process_tile(surface, pos, tile, seed)
	if tile.collides_with("player-layer") then return end	
	if not surface.can_place_entity({name = "tree-01", position = pos}) then return end
	
	if math_random(1, 100000) == 1 then
		local wrecks = {"big-ship-wreck-1", "big-ship-wreck-2", "big-ship-wreck-3"}
		local e = surface.create_entity{name = wrecks[math_random(1,#wrecks)], position = pos, force = "neutral"}
		e.insert({name = "raw-fish", count = math_random(3, 25)})
		if math_random(1, 3) == 1 then e.insert({name = "wood", count = math_random(11, 44)}) end
	end
	
	local noise_forest_location = get_noise("forest_location", pos, seed)
	--local r = math.ceil(math.abs(get_noise("forest_density", pos, seed + 4096)) * 10)
	--local r = 5 - math.ceil(math.abs(noise_forest_location) * 3)
	--r = 2			
	
	if noise_forest_location > 0.095 then
		if noise_forest_location > 0.6 then
			if math_random(1,100) > 42 then surface.create_entity({name = "tree-08-brown", position = pos}) end
		else
			if math_random(1,100) > 42 then surface.create_entity({name = "tree-01", position = pos}) end
		end
		surface.create_decoratives({check_collision=false, decoratives={{name = decos_inside_forest[math_random(1, #decos_inside_forest)], position = pos, amount = math_random(1, 2)}}})
		return
	end
	
	if noise_forest_location < -0.095 then
		if noise_forest_location < -0.6 then
			if math_random(1,100) > 42 then surface.create_entity({name = "tree-04", position = pos}) end
		else
			if math_random(1,100) > 42 then surface.create_entity({name = "tree-02-red", position = pos}) end
		end
		surface.create_decoratives({check_collision=false, decoratives={{name = decos_inside_forest[math_random(1, #decos_inside_forest)], position = pos, amount = math_random(1, 2)}}})
		return
	end
		
	surface.create_decoratives({check_collision=false, decoratives={{name = decos[math_random(1, #decos)], position = pos, amount = math_random(1, 2)}}})
end

local function on_chunk_generated(event)
	local surface = event.surface
	if surface.name ~= "choppy" then return end
	local left_top = event.area.left_top
	local tiles = {}
	local entities = {}		
	local seed = game.surfaces[1].map_gen_settings.seed
	
	--surface.destroy_decoratives({area = event.area})
	
	for _, e in pairs(surface.find_entities_filtered({area = event.area})) do
		process_entity(e)		
	end
	
	for x = 0.5, 31.5, 1 do
		for y = 0.5, 31.5, 1 do
			local tile_to_insert = false
			local pos = {x = left_top.x + x, y = left_top.y + y}
											
			local tile = surface.get_tile(pos)
			if tile_replacements[tile.name] then
				table_insert(tiles, {name = tile_replacements[tile.name], position = pos})
			end
			
			process_tile(surface, pos, tile, seed)
		end
	end
	surface.set_tiles(tiles, true)
	
	for _, e in pairs(surface.find_entities_filtered({area = event.area, type = "unit-spawner"})) do
		for _, entity in pairs (e.surface.find_entities_filtered({area = {{e.position.x - 7, e.position.y - 7},{e.position.x + 7, e.position.y + 7}}, force = "neutral"})) do
			if entity.valid then entity.destroy() end
		end
	end
	
	if global.spawn_generated then return end
	if left_top.x < 96 then return end	 
	
	for _, e in pairs (surface.find_entities_filtered({area = {{-50, -50},{50, 50}}})) do
		local distance_to_center = math.sqrt(e.position.x^2 + e.position.y^2)
		if e.valid then
			if distance_to_center < 8 and e.type == "tree" and math_random(1,5) ~= 1 then e.destroy() end
		end		
	end
	global.spawn_generated = true		
end
	
local function on_marked_for_deconstruction(event)	
	if disabled_for_deconstruction[event.entity.name] then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
	if event.entity.type == "tree" then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	local surface = player.surface
	if global.map_choppy_init_done then return end
	
	--game.map_settings.pollution.min_pollution_to_damage_trees = 1000000
	--game.map_settings.pollution.pollution_per_tree_damage = 0
	--game.map_settings.pollution.pollution_restored_per_tree_damage = 0

	game.surfaces["choppy"].ticks_per_day = game.surfaces["choppy"].ticks_per_day * 2
	
	global.entity_yield = {
		["tree-01"] = {"iron-ore"},
		["tree-02-red"] = {"copper-ore"},
		["tree-04"] = {"coal"},
		["tree-08-brown"] = {"stone"},
		["rock-big"] = {"uranium-ore"},
		["rock-huge"] = {"uranium-ore"}
	}
	
	if game.item_prototypes["angels-ore1"] then
		global.entity_yield["tree-01"] = {"angels-ore1", "angels-ore2"}
		global.entity_yield["tree-02-red"] = {"angels-ore5", "angels-ore6"}
		global.entity_yield["tree-04"] = {"coal"}
		global.entity_yield["tree-08-brown"] = {"angels-ore3", "angels-ore4"}
	else
		game.map_settings.pollution.ageing = 0
	end
	
	if game.item_prototypes["thorium-ore"] then
		global.entity_yield["rock-big"] = {"uranium-ore", "thorium-ore"}
		global.entity_yield["rock-huge"] = {"uranium-ore", "thorium-ore"}
	end
		
	global.map_choppy_init_done = true
end	

local function changed_surface(event)	
	local player = game.players[event.player_index]
	local surface = player.surface
	if surface.name ~= "choppy" then goto continue end
	player.print("Warped to Choppy!", { r=0.10, g=0.75, b=0.5})
	player.play_sound {path = 'utility/mining_wood', volume_modifier = 1}
	if player.gui.top["caver_miner_stats_toggle_button"] then player.gui.top["caver_miner_stats_toggle_button"].destroy() end
	if player.gui.left["cave_miner_info"] then player.gui.left["cave_miner_info"].destroy() end
	if player.gui.top["hunger_frame"] then player.gui.top["hunger_frame"].destroy() end
	if player.gui.top["caver_miner_stats_frame"] then player.gui.top["caver_miner_stats_frame"].destroy() end
	--create_map_intro(player)
	create_map_intro_button(player)
	create_choppy_stats_gui(player)

	player.print(choppy_messages[math_random(1,#choppy_messages)], { r=0.10, g=0.75, b=0.5})
	::continue::
end	

local function get_amount(entity)
	local distance_to_center = math.sqrt(entity.position.x^2 + entity.position.y^2)
	local amount = 25 + (distance_to_center * 0.1)
	if amount > 1000 then amount = 1000 end
	amount = math.random(math.ceil(amount * 0.5), math.ceil(amount * 1.5))	
	return amount
end

local function trap(entity)
	if math_random(1,1024) == 1 then tick_tack_trap(entity.surface, entity.position) return end
	if math_random(1,256) == 1 then unearthing_worm(entity.surface, entity.position) end
	if math_random(1,128) == 1 then unearthing_biters(entity.surface, entity.position, math_random(4,8)) end	
end

local function on_player_mined_entity(event)
	local entity = event.entity
	local surface = entity.surface
	if surface ~= game.surfaces["choppy"] then return end
	if not entity.valid then return end
	
	if entity.type == "tree" then 	
		trap(entity)
	end
		
	if global.entity_yield[entity.name] then		
		if event.buffer then event.buffer.clear() end			
		if not event.player_index then return end
		local amount = get_amount(entity)
		local second_item_amount = math_random(2,5)
		local second_item = "wood"
		
		if entity.type == "simple-entity" then
			amount = amount * 2
			second_item_amount = math_random(8,16)
			second_item = "stone"
		end
		
		local main_item = global.entity_yield[entity.name][math_random(1,#global.entity_yield[entity.name])]
		local amount_of_choppie = math.round(amount * 0.15,0)
		
		entity.surface.create_entity({
			name = "flying-text",
			position = entity.position,
			text = "+" .. amount .. " [item=" .. main_item .. "] +" .. second_item_amount .. " [item=" .. second_item .. "]",
			color = {r=0.8,g=0.8,b=0.8}})	
		
		global.stats_ores_found = global.stats_ores_found + amount
		global.stats_wood_chopped = global.stats_wood_chopped + 1
		refresh_gui()

		local player = game.players[event.player_index]
		
		local inserted_count = player.insert({name = main_item, count = amount})				
		amount = amount - inserted_count
		if amount > 0 then
			entity.surface.spill_item_stack(entity.position,{name = main_item, count = amount}, true)
		end
				
		local inserted_count = player.insert({name = second_item, count = second_item_amount})				
		second_item_amount = second_item_amount - inserted_count
		if second_item_amount > 0 then
			entity.surface.spill_item_stack(entity.position,{name = second_item, count = second_item_amount}, true)
		end 
	end					
end

local function on_research_finished(event)
	event.research.force.character_inventory_slots_bonus = game.forces.player.mining_drill_productivity_bonus * 500
	if not event.research.force.technologies["steel-axe"].researched then return end
	event.research.force.manual_mining_speed_modifier = 1 + game.forces.player.mining_drill_productivity_bonus * 2
	refresh_gui()
end

local function on_entity_died(event)
	if event.entity.surface.name ~= "choppy" then return end
	on_player_mined_entity(event)
	
	if not event.entity.valid then return end
	if event.entity.type == "tree" then 
		for _, entity in pairs (event.entity.surface.find_entities_filtered({area = {{event.entity.position.x - 4, event.entity.position.y - 4},{event.entity.position.x + 4, event.entity.position.y + 4}}, name = "fire-flame-on-tree"})) do
			if entity.valid then entity.destroy() end
		end
	end		
end

local function init_surface(surface)
  surface.map_gen_settings = {}
  return surface
end

local function init()
  local storage = {}
  local newPlace = init_surface(game.create_surface("choppy"))
  local surface = game.surfaces["choppy"]
  newPlace.request_to_generate_chunks({0,0}, 4)
  global.surface_choppy_elevator = surface.create_entity({name = "player-port", position = {1, -4}, force = game.forces.neutral})
  global.surface_choppy_chest = Module.create_chest(surface, {1, -8}, storage)

  rendering.draw_text{
    text = "Storage",
    surface = surface,
    target = global.surface_choppy_chest,
    target_offset = {0, 0.4},
    color = { r=0.98, g=0.66, b=0.22},
    alignment = "center"
  }

  rendering.draw_text{
    text = "Elevator",
    surface = surface,
    target = global.surface_choppy_elevator,
    target_offset = {0, 1},
    color = { r=0.98, g=0.66, b=0.22},
    alignment = "center"
  }

  global.surface_choppy_chest.minable = false
  global.surface_choppy_chest.destructible = false
  global.surface_choppy_elevator.minable = false
  global.surface_choppy_elevator.destructible = false
end
	
event.on_init(init)
event.add(defines.events.on_player_changed_surface, changed_surface)
event.add(defines.events.on_research_finished, on_research_finished)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
