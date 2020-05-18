local Functions = require "modules.fjei.functions"
local math_ceil = math.ceil
local string_find = string.find
local table_remove = table.remove
local table_insert = table.insert
local main_window_width = 278
local recipe_window_width = 480
local recipe_window_amount_width = 38
local recipe_window_item_name_width = 128
local recipe_window_position = "center"
local column_count = 6
local line_count = 5
local items_per_page = column_count * line_count
local Public = {}

local function get_total_page_count(player)
	if not global.fjei.player_data[player.index].filtered_list then Functions.set_filtered_list(player) end
	local count = math_ceil(global.fjei.player_data[player.index].size_of_filtered_list / items_per_page)
	if count < 1 then count = 1 end
	return count
end

local function set_page_count_caption(player)
	if not player.gui.left.fjei_main_window then return end
	if not global.fjei.player_data[player.index].filtered_list then Functions.set_filtered_list(player) end
	local active_page = global.fjei.player_data[player.index].active_page
	local element = player.gui.left.fjei_main_window.fjei_main_window_control_table.fjei_main_window_page_counter
	element.caption = active_page .. "/" .. get_total_page_count(player)
end

local function get_formatted_amount(amount)
	if amount < 1000 then
		amount = amount .. " x "
		return amount
	end
	if amount >= 1000000 then 	
		amount = math.floor(amount * 0.00001) * 0.1 .. "m "
		return amount
	end
	if amount >= 1000 then 	
		amount = math.floor(amount * 0.01) * 0.1 .. "k "
		return amount
	end
end

local function get_localised_name(name)
	local item = game.item_prototypes[name]
	if item then return item.localised_name end
	local fluid = game.fluid_prototypes[name]
	if fluid then return fluid.localised_name end
	local recipe = game.recipe_prototypes[name]
	if recipe then return recipe.localised_name end
	return name
end

local function get_sprite_type(name)
	if game.item_prototypes[name] then return "item" end
	if game.fluid_prototypes[name] then return "fluid" end
	if game.entity_prototypes[name] then return "entity" end
	if game.recipe_prototypes[name] then return "recipe" end
	return false
end

local function get_active_recipe_name(player)
	local fjei_recipe_window = player.gui[recipe_window_position]["fjei_recipe_window"]
	if not fjei_recipe_window then return end
	if not fjei_recipe_window.recipe_container then return end
	local container = fjei_recipe_window.recipe_container.children[1]
	if not container then return end
	return container.children[1].name		
end

local function add_choose_elem_button(element, name, is_recipe)
	local elem_type
	if is_recipe then
		elem_type = "recipe"
	else
		elem_type = get_sprite_type(name)
	end
	if not elem_type then return end
	
	local elem_type = get_sprite_type(name)
	local choose_elem_button = element.add({type = "choose-elem-button", name = name, elem_type = elem_type})
	choose_elem_button.locked = true
	choose_elem_button.elem_value = name

	choose_elem_button.style.minimal_width = 36
	choose_elem_button.style.minimal_height = 36
	choose_elem_button.style.maximal_width = 36
	choose_elem_button.style.maximal_height = 36
	choose_elem_button.style.margin = -1
	choose_elem_button.style.right_margin = 2
	choose_elem_button.style.padding = 2
end

local function add_sprite_icon(element, name, is_recipe, use_localised_name)
	local sprite_type = false
	if is_recipe then
		sprite_type = "recipe"
	else
		sprite_type = get_sprite_type(name)
	end

	if not sprite_type then return end
	
	local sprite
	if use_localised_name then 	
		sprite = element.add({type = "sprite", name = name, sprite = sprite_type .. "/" .. name, tooltip = get_localised_name(name)})
	else
		sprite = element.add({type = "sprite", name = name, sprite = sprite_type .. "/" .. name, tooltip = name})	
	end
	
	sprite.style.minimal_width = 32
	sprite.style.minimal_height = 32
	sprite.style.maximal_width = 32
	sprite.style.maximal_height = 32
	sprite.style.margin = 4	
	sprite.style.padding = 0
end

local function display_item_list(player)
	if not player.gui.left.fjei_main_window then return end
	if not global.fjei.player_data[player.index].filtered_list then Functions.set_filtered_list(player) end
	
	local active_page = global.fjei.player_data[player.index].active_page
	local starting_index = 1 + (active_page - 1) * items_per_page
	local sorted_item_list = global.fjei.sorted_item_list
	local filtered_list = global.fjei.player_data[player.index].filtered_list	
	local item_list_table = player.gui.left.fjei_main_window.fjei_main_window_item_list_table
	item_list_table.clear()	
	
	for i = starting_index, starting_index + items_per_page - 1, 1 do
		if not filtered_list[i] then return end
		add_sprite_icon(item_list_table, sorted_item_list[filtered_list[i]], false)	
	end
end

local function display_history(player)
	if not player.gui.left.fjei_main_window then return end
	local player_data = global.fjei.player_data[player.index]
	local history = player_data.history	
	if not history then return end
	local history_table = player.gui.left.fjei_main_window.fjei_main_window_history_table
	history_table.clear()	
	
	for i = player_data.size_of_history - column_count, player_data.size_of_history, 1 do
		local name = history[i]
		if name then
			add_sprite_icon(history_table, name, false)
		end
	end
end

function Public.refresh_main_window(player)
	set_page_count_caption(player)
	display_item_list(player)
	display_history(player)
end

local function draw_main_window(player)
	if player.gui.left["fjei_main_window"] then player.gui.left["fjei_main_window"].destroy() end
	local frame = player.gui.left.add({type = "frame", name = "fjei_main_window", direction = "vertical"})
	frame.style.minimal_width = main_window_width
	frame.style.maximal_width = main_window_width
	frame.style.padding = 4
	frame.style.margin = 2
	
	local t = frame.add({type = "table", name = "fjei_main_window_control_table",  column_count = 4})
	local element = t.add({type = "label", name = "fjei_main_window_page_counter",  caption = " "})
	element.style.font = "heading-2"
	element.style.font_color = {222, 222, 222}
	element.style.right_margin = 4
	
	local element = t.add({type = "sprite-button", name = "fjei_main_window_previous_page", caption = "←"})
	element.style.font = "heading-1"
	element.style.maximal_height = 32
	element.style.maximal_width = 32
	local element = t.add({type = "sprite-button", name = "fjei_main_window_next_page", caption = "→"})
	element.style.font = "heading-1"
	element.style.maximal_height = 32
	element.style.maximal_width = 32
	local text = global.fjei.player_data[player.index].active_filter
	if not text then text = "" end
	local textfield = t.add({ type = "textfield", name = "fjei_main_window_search_textfield", text = text})
	textfield.style.left_margin = 4
	textfield.style.minimal_width = 140	
	textfield.style.maximal_width = 140
	
	frame.add({type = "line"})
		
	local t = frame.add({type = "table", name = "fjei_main_window_item_list_table", column_count = column_count})
	
	frame.add({type = "line"})
	
	local t = frame.add({type = "table", name = "fjei_main_window_history_table", column_count = column_count})
		
	Public.refresh_main_window(player)
end

local function refresh_recipe_bar(player, selected_recipe)
	local old_recipe_name = get_active_recipe_name(player)
	if not old_recipe_name then return end
	
	if not player.gui[recipe_window_position]["fjei_recipe_window"] then return end
	if not player.gui[recipe_window_position]["fjei_recipe_window"].header_container then return end	
	local fjei_recipe_window_select_table = player.gui[recipe_window_position]["fjei_recipe_window"].header_container.header_table.scroll_pane.fjei_recipe_window_select_table
	
	local container = fjei_recipe_window_select_table[old_recipe_name]	
	container.clear()
	add_sprite_icon(container, old_recipe_name, true)
	
	local container = fjei_recipe_window_select_table[selected_recipe]	
	container.clear()
	local element = container.add({ type = "frame", name = "fjei_recipe_window_selected_recipe"})
	element.style.margin = 0
	element.style.padding = -4
	add_sprite_icon(element, selected_recipe, true)
end

local function draw_recipe_window_header(player, container, item_name, recipes, mode, recipe_name)
	
	local t = container.add({type = "table", name = "header_table", column_count = 4})
	
	add_sprite_icon(t, item_name, false)
	
	local element = t.add({type = "label", caption = ""})
	if mode == 1 then element.caption = "Product\nof recipe: " else element.caption = "Ingredient\nin recipe: " end
	element.style.single_line = false
	element.style.font = "heading-2"
	element.style.font_color = {222, 222, 222}
	element.style.minimal_width = 78
	element.style.maximal_width = 78
	
	local scroll_pane = t.add({ type = "scroll-pane", name = "scroll_pane", horizontal_scroll_policy = "always", vertical_scroll_policy = "never"})	
	scroll_pane.style.minimal_width = recipe_window_width - 190
	scroll_pane.style.maximal_width = recipe_window_width - 190
	scroll_pane.style.minimal_height = 60
	scroll_pane.style.maximal_height = 60
	local tt = scroll_pane.add({type = "table", name = "fjei_recipe_window_select_table", column_count = 8192})
	
	for key, name in pairs(recipes) do
		if not tt[name] then
			local ttt = tt.add({type = "table", name = name, column_count = 1})
			if recipe_name == name then
				local element = ttt.add({type = "frame", name = "fjei_recipe_window_selected_recipe"})
				element.style.margin = 0
				element.style.padding = -4
				add_sprite_icon(element, name, true)
			else
				add_sprite_icon(ttt, name, true)
			end
		end
	end
	
	local element = t.add {type = "sprite-button", caption = "X", name = "fjei_close_recipe_window"}
	element.style.font = "heading-1"
	element.style.margin = 8
	element.style.padding = 4
	element.style.minimal_width = 34
	element.style.maximal_width = 34
	element.style.minimal_height = 34
	element.style.maximal_height = 34
	
	local element = container.add({type = "line"})
	element.style.right_margin = 6
end

local function draw_recipe(player, container, recipe_name)
	local recipe = game.recipe_prototypes[recipe_name]

	local t = container.add({type = "table", column_count = 2})	
	add_choose_elem_button(t, recipe.name, true)
	
	local tt = t.add({type = "table", column_count = 1})
	local ttt = tt.add({type = "table", column_count = 2})	
	local element_1 = ttt.add({type = "label", caption = recipe.localised_name})
	element_1.style.font = "heading-1"
	element_1.style.single_line = false
	local element_2 = ttt.add({type = "label", caption = " "})
	element_2.style.font = "heading-1"
	if not player.force.recipes[recipe_name].enabled then
		element_2.style.font_color = {200, 0, 0}
		element_2.caption = "*"
		local str = "Further research is required to unlock this recipe."
		element_2.tooltip = str
		element_1.tooltip = str
	end
	
	local element = tt.add({type = "label", caption = "◷ " .. math.round(recipe.energy, 2) .. " seconds crafting time"})
	element.style.font = "default"
	element.style.font_color = {215, 215, 215}
	element.style.top_margin = -4
	
	container.add({type = "line"})
		
	local element = container.add({type = "label", caption = "Products:"})
	element.style.font = "heading-2"		
	local t = container.add({type = "table", column_count = 2})
	
	for _, product in pairs(recipe.products) do
		local tt = t.add({type = "table", column_count = 3})
		
		local amount = product.amount
		if not amount then amount = 1 end		
		amount = amount * product.probability

		local element = tt.add({type = "label", caption = get_formatted_amount(amount)})
		element.style.minimal_width = recipe_window_amount_width
		element.style.maximal_width = recipe_window_amount_width
		element.style.single_line = false
		element.style.horizontal_align = "right"
		add_choose_elem_button(tt, product.name)
		if product.temperature then
			local ttt = tt.add({type = "table", column_count = 1})
			local element = ttt.add({type = "label", caption = get_localised_name(product.name)})
			element.style.minimal_width = recipe_window_item_name_width
			element.style.maximal_width = recipe_window_item_name_width
			element.style.single_line = false
			element.style.font = "default"
			local element = ttt.add({type = "label", caption = product.temperature .. " °C"})
		else
			local element = tt.add({type = "label", caption = get_localised_name(product.name)})
			element.style.minimal_width = recipe_window_item_name_width
			element.style.maximal_width = recipe_window_item_name_width
			element.style.single_line = false
			element.style.font = "default"
		end	
	end
	
	local element = container.add({type = "label", caption = "Ingredients:"})
	element.style.font = "heading-2"		
	local t = container.add({type = "table", column_count = 2})
	
	for key, ingredient in pairs(recipe.ingredients) do
		local tt = t.add({type = "table", column_count = 3})
		local element = tt.add({type = "label", caption = get_formatted_amount(ingredient.amount)})
		element.style.minimal_width = recipe_window_amount_width
		element.style.maximal_width = recipe_window_amount_width
		element.style.single_line = false
		element.style.horizontal_align = "right"
		
		add_choose_elem_button(tt, ingredient.name)
		if ingredient.temperature then
			local ttt = tt.add({type = "table", column_count = 1})
			local element = ttt.add({type = "label", caption = get_localised_name(ingredient.name)})
			element.style.minimal_width = recipe_window_item_name_width
			element.style.maximal_width = recipe_window_item_name_width	
			element.style.single_line = false
			element.style.font = "default"
			local element = ttt.add({type = "label", caption = ingredient.temperature .. " °C"})
		else		
			local element = tt.add({type = "label", caption = get_localised_name(ingredient.name)})
			element.style.minimal_width = recipe_window_item_name_width
			element.style.maximal_width = recipe_window_item_name_width
			element.style.single_line = false
			element.style.font = "default"
		end
	end
	
	local machines = Functions.get_crafting_machines_for_recipe(player.force.name, recipe)
		
	local element = container.add({type = "line"})
	element.style.top_margin = 2
	element.style.bottom_margin = 2
		
	if #machines == 0 then 
		local t = container.add({type = "table", column_count = 10})	
		local element = t.add({type = "label", caption = "Made by:"})
		element.style.font = "heading-2"
		local element = t.add({type = "label", caption = "Crafting method unknown."})
		element.style.font = "heading-2"
		element.style.font_color = {150, 150, 150}
		return
	end
		
	local t = container.add({type = "table", column_count = 10})	
	local element = t.add({type = "label", caption = "Made by:"})
	element.style.right_margin = 2
	element.style.font = "heading-2"
	
	for key, machine in pairs(machines) do
		local prototype = game.entity_prototypes[machine]
		if prototype then			
			add_choose_elem_button(t, machine)
		end
	end
end

local function create_recipe_window(item_name, player, button, selected_recipe)
	local mode
	if button == defines.mouse_button_type.left then mode = 1 else mode = 2 end

	if selected_recipe and player.gui[recipe_window_position]["fjei_recipe_window"] then
		refresh_recipe_bar(player, selected_recipe)
		local container = player.gui[recipe_window_position]["fjei_recipe_window"].recipe_container
		container.clear()
		draw_recipe(player, container, selected_recipe)
		return
	end

	if not global.fjei.item_list[item_name] then return end
	
	--shift researched recipes forward in the list
	local recipes = {}
	local size_of_recipes = 0
	local researched_recipes = {}
	local size_of_researched_recipes = 0
	local unknown_recipes = {}
	local size_of_unknown_recipes = 0
	local force_recipes = player.force.recipes
	
	for k, recipe_name in pairs(global.fjei.item_list[item_name][mode]) do
		if k > 512 then break end
		if force_recipes[recipe_name] then
			if force_recipes[recipe_name].enabled then
				size_of_researched_recipes = size_of_researched_recipes + 1
				researched_recipes[size_of_researched_recipes] = recipe_name
			else
				size_of_unknown_recipes = size_of_unknown_recipes + 1
				unknown_recipes[size_of_unknown_recipes] = recipe_name
			end
		end		
	end
	
	for k, recipe_name in pairs(researched_recipes) do
		size_of_recipes = size_of_recipes + 1
		recipes[size_of_recipes] = recipe_name
	end
	for k, recipe_name in pairs(unknown_recipes) do
		size_of_recipes = size_of_recipes + 1
		recipes[size_of_recipes] = recipe_name
	end
	
	if size_of_recipes == 0 then return end
	
	if not selected_recipe then
		for key, recipe_name in pairs(recipes) do
			if #Functions.get_crafting_machines_for_recipe(player.force.name, game.recipe_prototypes[recipe_name]) > 0 then
				selected_recipe = recipe_name
				break
			end
			if key > 16 then break end
		end
	end	
	
	local recipe_name = recipes[1]
	if selected_recipe then
		for k, v in pairs(recipes) do if v == selected_recipe then recipe_name = recipes[k] end end
	end
	
	if player.gui[recipe_window_position]["fjei_recipe_window"] then player.gui[recipe_window_position]["fjei_recipe_window"].destroy() end
	local frame = player.gui[recipe_window_position].add({type = "frame", name = "fjei_recipe_window", direction = "vertical"})
	frame.style.minimal_width = recipe_window_width
	frame.style.maximal_width = recipe_window_width
	frame.style.padding = 4
	frame.style.left_padding = 6
	frame.style.right_padding = 6
	
	local container = frame.add({type = "table", name = "header_container", column_count = 1})	
	draw_recipe_window_header(player, container, item_name, recipes, mode, recipe_name)

	local container = frame.add({type = "table", name = "recipe_container", column_count = 1})
	draw_recipe(player, container, recipe_name)
	
	return true
end

local function add_to_history(item_name, player)
	if not game.item_prototypes[item_name] and not game.fluid_prototypes[item_name] then return end

	local player_data = global.fjei.player_data[player.index]
	if not player_data.history then
		player_data.history = {item_name}
		player_data.size_of_history = 1
		return
	end
	
	--avoid double elements
	for _, v in pairs(player_data.history) do
		if v == item_name then return end
	end
	
	player_data.size_of_history = player_data.size_of_history + 1
	player_data.history[player_data.size_of_history] = item_name	
	if player_data.size_of_history > column_count then player_data.history[player_data.size_of_history - column_count] = nil end
end

local function show_cursor_stack_item(element, player, button)
	local cursor_stack = player.cursor_stack
	if not cursor_stack then return end
	if not cursor_stack.valid_for_read then return end
	if not global.fjei then Functions.build_tables() end
	if not global.fjei.player_data[player.index] then global.fjei.player_data[player.index] = {} end
	if not global.fjei.item_list[cursor_stack.name] then return end
	add_to_history(cursor_stack.name, player)
	draw_main_window(player)
	create_recipe_window(cursor_stack.name, player, button)
	return true
end

local function toggle_main_window(element, player, button)
	if show_cursor_stack_item(element, player, button) then return true end
	if player.gui.left.fjei_main_window then
		player.gui.left.fjei_main_window.destroy()
		if player.gui[recipe_window_position].fjei_recipe_window then player.gui[recipe_window_position].fjei_recipe_window.destroy() end
	else
		draw_main_window(player)	
	end
	return true
end

local function main_window_next_page(element, player, button)
	local player_data = global.fjei.player_data[player.index]
	if button == defines.mouse_button_type.right then
		for _ = 1, 5, 1 do
			if player_data.active_page == get_total_page_count(player) then
				player_data.active_page = 1
			else
				player_data.active_page = player_data.active_page + 1
			end	
		end
	else
		if player_data.active_page == get_total_page_count(player) then
			player_data.active_page = 1
		else
			player_data.active_page = player_data.active_page + 1
		end	
	end
	Public.refresh_main_window(player)
	return true
end

local function main_window_previous_page(element, player, button)
	local player_data = global.fjei.player_data[player.index]
	if button == defines.mouse_button_type.right then
		for _ = 1, 5, 1 do
			if player_data.active_page == 1 then
				player_data.active_page = get_total_page_count(player)
			else
				player_data.active_page = player_data.active_page - 1
			end
		end
	else
		if player_data.active_page == 1 then
			player_data.active_page = get_total_page_count(player)
		else
			player_data.active_page = player_data.active_page - 1
		end
	end		
	Public.refresh_main_window(player)
	return true
end

local function clear_search_textfield(element, player, button)
	if show_cursor_stack_item(element, player, button) then return true end
	if button ~= defines.mouse_button_type.right then return end	
	global.fjei.player_data[player.index].active_filter = false
	element.text = ""
	Functions.set_filtered_list(player)
	Public.refresh_main_window(player)
	return true
end

local function close_recipe_window(element, player, button)
	local recipe_window = player.gui[recipe_window_position]["fjei_recipe_window"]
	if recipe_window then recipe_window.destroy() end
	return true
end

local gui_actions = {
	["fjei_toggle_button"] = toggle_main_window,
	["fjei_main_window_next_page"] = main_window_next_page,
	["fjei_main_window_previous_page"] = main_window_previous_page,
	["fjei_main_window_search_textfield"] = clear_search_textfield,
	["fjei_close_recipe_window"] = close_recipe_window,
}

function Public.gui_click_actions(element, player, button)
	if not gui_actions[element.name] then return end
	if not global.fjei then Functions.build_tables() end
	if not global.fjei.player_data[player.index] then global.fjei.player_data[player.index] = {} end
	gui_actions[element.name](element, player, button)
	return true
end

function Public.draw_top_toggle_button(player)
	if player.gui.top["fjei_toggle_button"] then return end
	local button = player.gui.top.add({type = "sprite-button", name = "fjei_toggle_button", caption = "FJEI"})
	button.style.font = "heading-1"
	button.style.font_color = {222, 222, 222}
	button.style.minimal_height = 38
	button.style.minimal_width = 50
	button.style.padding = -2
end

function Public.open_recipe(element, player, button)
	if not global.fjei then Functions.build_tables() end
	if not global.fjei.player_data[player.index] then global.fjei.player_data[player.index] = {} end
	
	local item_name = element.name
	local selected_recipe = false
	
	if element.parent.name == "fjei_recipe_window_selected_recipe" then return end
	if element.parent then
		if element.parent.parent then
			if element.parent.parent.name == "fjei_recipe_window_select_table" then selected_recipe = item_name end
		end
	end
	if element.parent.name == "fjei_main_window_item_list_table" or element.parent.name == "fjei_main_window_history_table" then
		local recipe_window = player.gui[recipe_window_position]["fjei_recipe_window"]
		if recipe_window then
			local active_item = recipe_window.header_container.header_table.children[1].name
			if active_item == element.name and global.fjei.player_data[player.index].last_button == button then
				recipe_window.destroy()
				return
			end
		end
	end
	
	add_to_history(item_name, player)
	if not create_recipe_window(item_name, player, button, selected_recipe) then return end
	display_history(player)
	
	global.fjei.player_data[player.index].last_button = button
end

return Public