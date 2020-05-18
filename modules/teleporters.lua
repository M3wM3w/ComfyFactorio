local event = require 'utils.event' 
local key_item = "computer"
local blacklisted_tiles = {"out-of-map", "water", "deepwater", "water-green", "lab-white", "lab-dark-1"}
local teleporter_names = {"Stuedrik", "Wrirrirb", "Cekoht", "Deokels", "Gnaecl", "Yffolf", "Xuohsywae", "Flublodoe", "Dicyhnea", "Ruovyk", "Truecuhz", "Vaux'ers", "Gyttux", "Flys", "Qlammed", "Gynneo", "Xraeqoeht", "Phuashlk", "Cuahnennu", "Kneizigh", "Zruex'iz", "Stux'ar", "Zrihq", "Opsyms", "Ogigh", "Nek'oke", "Knoebhybeo", "Kluetryrceo", "Chahz", "Xralarb", "Wrib", "Breipuhz", "Nueglahloe", "Wuammea", "Iblameo", "Wuansyrfua", "Flohlilue", "Vev'unnae", "Deivrym", "Atahz", "Zrux'ysk", "Kyq'yks", "Gnyf'ilm", "Knaegnom", "Gnaelphiss", "Kmaek'irba", "Zruffira", "Kicremme", "Tuot'az", "Ouprard", "Tyv'im", "Get'yks", "Essyh", "Vliln", "Glucutha", "Teoblux", "Feohshowtha", "Dedrapt", "Isom", "Xoxxywth", "Qrokmeg", "Uzzuhz", "Achumea", "Caelhume", "Diewylfi", "Deak'yrbie", "Bepsilp", "Uogeptue", "Gouq'oht", "Strauyb", "Evvyks", "Riux", "Ielfahs", "Myls", "Dael'eth", "Tluymnyrbu", "Qluephaulpie", "Bruetheltua"}

local charged_accumulators_required = 8
function get_power_status(teleporter_index, drain_power)
	local surface = game.surfaces[global.teleporters[teleporter_index].surface]
	local a = {
				left_top = {x = global.teleporters[teleporter_index].position.x - 5, y = global.teleporters[teleporter_index].position.y - 5},
				right_bottom = {x = global.teleporters[teleporter_index].position.x + 6, y = global.teleporters[teleporter_index].position.y + 6}
				}
	local power_cells = surface.find_entities_filtered({area = a, name = "accumulator"})
	if not power_cells[1] then return "No energy source found - Operation not possible" end
	if #power_cells < charged_accumulators_required then return "Low Energy - More energy sources needed" end
	local charged_cells = {}
	for _, cell in pairs(power_cells) do
		if cell.energy >= 5000000 then table.insert(charged_cells, cell) end
		if #charged_cells == charged_accumulators_required then break end
	end
	if #charged_cells < charged_accumulators_required then return "Low Energy - Not enough accumulator charge" end
	if drain_power == true then
		for _, cell in pairs(charged_cells) do
			cell.energy = 0
		end
	end
	return true	
end

local function gui_spawn_new_teleporter(player)		
	if player.gui.left["spawn_new_teleporter_button"] then player.gui.left["spawn_new_teleporter_button"].destroy() end	
	local b = player.gui.left.add({ type = "button", name = "spawn_new_teleporter_button", caption = "Deploy Teleporter"})
	b.style.minimal_height = 38
	b.style.minimal_width = 38
	b.style.top_padding = 6
	b.style.left_padding = 12
	b.style.right_padding = 12
	b.style.bottom_padding = 6
	b.style.font = "default-listbox"
	b.style.font_color = {r = 0.35, g = 0.5, b = 1}
end

local function gui_teleporter(player, visited_teleporter_index)
	if player.gui.left["gui_teleporter"] then player.gui.left["gui_teleporter"].destroy() end	
	local frame = player.gui.left.add({ type = "frame", name = "gui_teleporter", direction = "vertical"})
	local t = frame.add({type = "table", column_count = 2, name = "teleporter_heading"})
	local l = t.add({type = "label", caption = "<Teleporter> "})
	l.style.font_color = {r = 0.35, g = 0.5, b = 1}
	l.style.font = "heading-1"
	local l = t.add({type = "label", caption = global.teleporters[visited_teleporter_index].name, name = visited_teleporter_index})
	l.style.font_color = {r = 0.77, g = 0.77, b = 0.77}
	l.style.font = "default-bold"
	l.style.top_padding = 4
	
	local frame2 = frame.add({ type = "frame", direction = "vertical"})
	frame2.style.maximal_height = 400
	frame2.style.top_padding = 8
	frame2.style.font = "default-bold"
	frame2.style.font_color = {r = 0.88, g = 0.22, b = 0.22}
		
	if #global.teleporters < 2 then
		frame2.caption = "No connected teleporters found."
		frame2.style.top_padding = 14
		frame2.style.bottom_padding = 0
		return
	end		
	
	local power_status = get_power_status(visited_teleporter_index)
	if power_status ~= true then
		frame2.caption = power_status
		frame2.style.top_padding = 14
		frame2.style.bottom_padding = 0
		return
	end
		
	local scroll_pane = frame2.add({ type = "scroll-pane", direction = "vertical", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"})
	
	for x = #global.teleporters, 1, -1 do
		local surface = game.surfaces[global.teleporters[x].surface]
		local tile = surface.get_tile(global.teleporters[x].position)
		if x ~= visited_teleporter_index and tile.name == "lab-white" then
		
			local t = scroll_pane.add({ type = "table", column_count = 2})
			
			local b = t.add({type = "button", caption = "> " .. global.teleporters[x].name .. " <", name = "teleporter_" .. x})
			b.style.minimal_width = 250
			b.style.font_color = {r = 0.35, g = 0.5, b = 1}
			b.style.font = "default-listbox"
			b.style.top_padding = 7
			b.style.bottom_padding = 7
						
			local tt = t.add({ type = "table", column_count = 2})
			
			local l = tt.add({type = "label", caption = global.teleporters[x].surface .. ": "})
			l.style.font_color = {r = 0.22, g = 0.88, b = 0.44}
			l.style.font = "default-bold"
			l.style.minimal_width = 65
			l.style.top_padding = 0
			l.style.bottom_padding = 0 
			l.style.left_padding = 8
			
			local l = tt.add({type = "label", caption = "X: " .. tostring(global.teleporters[x].position.x) .. "  Y: " .. tostring(global.teleporters[x].position.y)})
			l.style.font = "default"
			l.style.font_color = {r = 0.77, g = 0.77, b = 0.77}
			l.style.minimal_width = 100
			l.style.top_padding = 0
			l.style.bottom_padding = 0
			
			local l = tt.add({type = "label", caption = "Distance: "})
			l.style.font_color = {r = 0.22, g = 0.88, b = 0.44}
			l.style.font = "default-bold"
			l.style.minimal_width = 65
			l.style.top_padding = 0
			l.style.bottom_padding = 0
			l.style.left_padding = 8
			
			local l = tt.add({type = "label", caption = tostring(math.ceil(math.sqrt((global.teleporters[x].position.x - player.position.x)^2 + (global.teleporters[x].position.y - player.position.y)^2), 0)) .. " Units"})
			l.style.font = "default"
			l.style.font_color = {r = 0.77, g = 0.77, b = 0.77}
			l.style.minimal_width = 100
			l.style.top_padding = 0
			l.style.bottom_padding = 0
			
			if #global.teleporters > 2 and x ~= 1 then
				local l = scroll_pane.add({ type = "label", caption = "-----------------------------------------------------------------"})
				l.style.font_color = {r = 0.77, g = 0.77, b = 0.77}
				l.style.font = "default"
				l.style.top_padding = 0
				l.style.bottom_padding = 0				
			end
		end
	end
end

local function spawn_teleporter(player)
	if not global.teleporters then global.teleporters = {} end
	local surface = player.surface
	local pos = {x = math.floor(player.position.x, 0), y = math.floor(player.position.y, 0)}
	local a = {
				left_top = {x = pos.x - 3, y = pos.y - 3},
				right_bottom = {x = pos.x + 3, y = pos.y + 3}
				}
	local c = surface.count_tiles_filtered{area = a, name = blacklisted_tiles, limit = 1}		
	if c == 0 then
		local i = player.get_main_inventory()
		local removed_item_count = i.remove({name = key_item, count = 1})				
		if removed_item_count ~= 1 then return end		
		local str = teleporter_names[math.random(1, #teleporter_names)]
		local str2 = str
		while str == str2 do
			str2 = teleporter_names[math.random(1, #teleporter_names)]
		end		
		table.insert(global.teleporters, {position = {x = pos.x, y = pos.y}, name = str .. " " .. str2, surface = surface.name})
		local tiles = {
						{name = "lab-white", position = pos},	
						{name = "lab-dark-1", position = {pos.x - 1, pos.y - 1}},
						{name = "lab-dark-1", position = {pos.x, pos.y - 1}},
						{name = "lab-dark-1", position = {pos.x + 1, pos.y - 1}},
						{name = "lab-dark-1", position = {pos.x + 1, pos.y}},
						{name = "lab-dark-1", position = {pos.x + 1, pos.y + 1}},
						{name = "lab-dark-1", position = {pos.x, pos.y + 1}},
						{name = "lab-dark-1", position = {pos.x - 1, pos.y + 1}},
						{name = "lab-dark-1", position = {pos.x - 1, pos.y}},						
						}		
		surface.set_tiles(tiles, true)
		game.print(player.name .. " has deployed a Teleporter!", {r = 0.35, g = 0.5, b = 1})
	end
end

local function check_inventory_for_key_item(player_index)
	local player = game.players[player_index]
	if player.get_item_count(key_item) > 0 then
		gui_spawn_new_teleporter(player)
	else
		if player.gui.left["spawn_new_teleporter_button"] then player.gui.left["spawn_new_teleporter_button"].destroy() end
	end
end

local function on_player_changed_position(event)
	if not global.teleporters then return end
	local player = game.players[event.player_index]
	if player.character.driving == true then return end
	--if game.tick % 2 == 1 then return end	
	local a = {
				left_top = {x = player.position.x - 1, y = player.position.y - 1},
				right_bottom = {x = player.position.x + 1, y = player.position.y + 1}
				}
	local tile = player.surface.find_tiles_filtered{area = a, name = "lab-white", limit = 1}
	if not tile[1] then
		if player.gui.left["gui_teleporter"] then player.gui.left["gui_teleporter"].destroy() end
		return 
	end	
	for x, teleporter in pairs(global.teleporters) do
		if teleporter.position.x == tile[1].position.x and teleporter.position.y == tile[1].position.y then
			gui_teleporter(player, x)
			break
		end
	end
end

local function on_player_main_inventory_changed(event)
	check_inventory_for_key_item(event.player_index)
end

local function on_player_dropped_item(event)
	check_inventory_for_key_item(event.player_index)
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end	
	local player = game.players[event.element.player_index]
	local name = event.element.name
	if name == "spawn_new_teleporter_button" then spawn_teleporter(player) end	
	if string.sub(name, 1, 10) ~= "teleporter" then return end
	local index = tonumber(string.sub(name, 12))
	local visited_teleporter_index = tonumber(player.gui.left["gui_teleporter"]["teleporter_heading"].children[2].name)	
	local status = get_power_status(visited_teleporter_index, true)	
	if status == true then	
		local surface = game.surfaces[global.teleporters[index].surface]
		for _, p in pairs(game.connected_players) do			
			p.play_sound{path="utility/armor_insert", volume_modifier=1, position = global.teleporters[visited_teleporter_index].position}			
			p.play_sound{path="utility/armor_insert", volume_modifier=1, position = global.teleporters[index].position}			
		end
		surface.create_entity({name = "water-splash", position = player.position})
		surface.create_entity({name = "blood-explosion-big", position = player.position})		
		local p = surface.find_non_colliding_position("character",global.teleporters[index].position, 2,0.5)
		if p then
			player.teleport(p, global.teleporters[index].surface)
		else
			player.teleport(global.teleporters[index].position, global.teleporters[index].surface)
		end		
	end
end

event.add(defines.events.on_player_changed_position, on_player_changed_position)
event.add(defines.events.on_player_dropped_item, on_player_dropped_item)
event.add(defines.events.on_player_main_inventory_changed, on_player_main_inventory_changed)
event.add(defines.events.on_gui_click, on_gui_click)