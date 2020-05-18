local table_insert = table.insert
local string_find = string.find

local Public = {}

function Public.get_crafting_machines_for_recipe(force_name, recipe)
	local item_whitelist = global.fjei.item_whitelist[force_name]
	local crafting_machines = global.fjei.crafting_machines
	local recipe_category = recipe.category
	local result = {}
	local i = 1
	for _, name in pairs(crafting_machines) do
		if item_whitelist[name] or name == "character" then
			local crafting_categories = game.entity_prototypes[name].crafting_categories
			for category, _ in pairs(crafting_categories) do
				if recipe_category == category then
					result[i] = name
					i = i + 1
					break
				end
			end
		end
	end
	return result
end

local function set_crafting_machines()
	global.fjei.crafting_machines = {}
	local list = global.fjei.crafting_machines
	local i = 1
	for _, prototype in pairs(game.entity_prototypes) do
		if prototype.crafting_categories then
			list[i] = prototype.name
			i = i + 1
		end
	end
end

local uncommon_recipes = {"barrel", "void", "blackhole"}
local function is_uncommon_recipe(recipe_name)
	for _, name in pairs(uncommon_recipes) do
		local a, b = string_find(recipe_name, name, 1, true)
		if a then return true end
	end
end

local function shift_uncommon_recipe_names(tbl)
	local list_common = {}
	local list_uncommon = {}
	
	for key, recipe_name in pairs(tbl) do
		if is_uncommon_recipe(recipe_name) then
			table_insert(list_uncommon, recipe_name)
		else
			table_insert(list_common, recipe_name)
		end
	end
	if #list_uncommon == 0 then return end
	
	local i = 1
	for _, recipe_name in pairs(list_common) do
		tbl[i] = recipe_name
		i = i + 1
	end
	for _, recipe_name in pairs(list_uncommon) do
		tbl[i] = recipe_name
		i = i + 1
	end
end

local function add_item_list_product(item_list, product_name, recipe_name)
	if not item_list[product_name] then item_list[product_name] = {{}, {}} end
	table_insert(item_list[product_name][1], recipe_name)
end

local function add_item_list_ingredient(item_list, ingredient_name, recipe_name)
	if not item_list[ingredient_name] then item_list[ingredient_name] = {{}, {}} end
	table_insert(item_list[ingredient_name][2], recipe_name)
end

local function set_item_list()	
	global.fjei.item_list = {}		
	local item_list = global.fjei.item_list	
	for recipe_name, recipe in pairs(game.recipe_prototypes) do	
		for key, product in pairs(recipe.products) do
			add_item_list_product(item_list, product.name, recipe_name)
		end
		for key, ingredient in pairs(recipe.ingredients) do
			add_item_list_ingredient(item_list, ingredient.name, recipe_name)
		end	
	end
	
	for key, v in pairs(item_list) do
		if v[1] then
			if v[1][2] then
				table.sort(v[1], function (a, b) return a < b end)				
				shift_uncommon_recipe_names(v[1])
			end
		end
		if v[2] then
			if v[2][2] then
				table.sort(v[2], function (a, b) return a < b end)
				shift_uncommon_recipe_names(v[2])
			end
		end	
	end
end

local function set_sorted_item_list()
	global.fjei.sorted_item_list = {}
	local sorted_item_list = global.fjei.sorted_item_list
	local item_list = global.fjei.item_list
	local item_prototypes = game.item_prototypes
	local fluid_prototypes = game.fluid_prototypes
	
	local sorted_items = {}
	local i = 1
	for key, value in pairs(item_list) do
		if item_prototypes[key] then
			sorted_items[i] = key
			i = i + 1
		end
	end
	table.sort(sorted_items, function (a, b) return a < b end)
	
	local sorted_fluids = {}
	local i = 1
	for key, value in pairs(item_list) do
		if fluid_prototypes[key] then
			sorted_fluids[i] = key
			i = i + 1
		end
	end
	table.sort(sorted_fluids, function (a, b) return a < b end)
	
	local i = 1
	for key, name in pairs(sorted_items) do	
		sorted_item_list[i] = name
		i = i + 1		
	end
	for key, name in pairs(sorted_fluids) do		
		sorted_item_list[i] = name
		i = i + 1		
	end
end

local function add_recipe_to_whitelist(item_whitelist, recipe)
	for key, product in pairs(recipe.products) do
		item_whitelist[product.name] = true
	end
	for key, ingredient in pairs(recipe.ingredients) do
		item_whitelist[ingredient.name] = true
	end
end

function Public.add_research_to_whitelist(force, effects)
	if not effects then return end
	local item_whitelist = global.fjei.item_whitelist[force.name]
	local items_have_been_added = false
	for _, effect in pairs(effects) do
		if effect.recipe then
			add_recipe_to_whitelist(item_whitelist, game.recipe_prototypes[effect.recipe])
			items_have_been_added = true
		end
	end
	return items_have_been_added
end

local function set_item_whitelist(force)
	global.fjei.item_whitelist[force.name] = {}
	local item_whitelist = global.fjei.item_whitelist[force.name]
	
	for key, recipe in pairs(force.recipes) do
		if recipe.enabled and not recipe.hidden then
			add_recipe_to_whitelist(item_whitelist, recipe)
		end
	end
	
	for key, technology in pairs(force.technologies) do
		if technology.researched then
			Public.add_research_to_whitelist(force, technology.effects)
		end
	end
end

local function set_item_whitelists_for_all_forces()
	global.fjei.item_whitelist = {}
	for _, force in pairs(game.forces) do
		if force.index ~= 2 and force.index ~= 3 then
			set_item_whitelist(force)
		end
	end
end

function Public.set_filtered_list(player)
	local player_data = global.fjei.player_data[player.index]
	player_data.filtered_list = {}
	player_data.active_page = 1
	local filtered_list = player_data.filtered_list
	local active_filter = player_data.active_filter
	local sorted_item_list = global.fjei.sorted_item_list
	local item_whitelist = global.fjei.item_whitelist[player.force.name]
		
	local i = 1
	for key, name in pairs(sorted_item_list) do
		if item_whitelist[name] then
			if active_filter then
				local a, b = string_find(name, active_filter, 1, true)
				if a then
					filtered_list[i] = key
					i = i + 1
				end
			else
				filtered_list[i] = key
				i = i + 1
			end
		end
	end
	player_data.size_of_filtered_list = #player_data.filtered_list
end

function Public.build_tables()
	global.fjei = {}
	global.fjei.player_data = {}
	set_item_list()										--creates list of all items as key and two tables for each key containing [1] product recipes and [2] ingredient recipes
	set_sorted_item_list()							--creates sorted list of all items in the game for faster searching
	set_crafting_machines()						--creates list of available crafting entities
	set_item_whitelists_for_all_forces()		--whitelist to only display researched items in the browser for the force
end

return Public