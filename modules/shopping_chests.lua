local shop_list = {
	["coal"] = 1,
	["copper-ore"] = 1,
	["crude-oil-barrel"] = 7.5,
	["empty-barrel"] = 5,
	["iron-ore"] = 1,
	["landfill"] = 2,
	["raw-fish"] = 4.25,
	["stone"] = 1,
	["uranium-ore"] = 3,
	["wood"] = 0.75,
}

function create_shopping_chest(surface, position, destructible)
	local entity = surface.create_entity({name = "logistic-chest-requester", position = position, force = "shopping_chests"})
	entity.minable = false
	if not destructible then	entity.destructible = false end	
end

function create_dump_chest(surface, position, destructible)
	local entity = surface.create_entity({name = "logistic-chest-passive-provider", position = position, force = "shopping_chests"})
	entity.minable = false
	if not destructible then	entity.destructible = false end	
end

local function get_affordable_item_count(name, count)
	if global.credits >= count * shop_list[name] then
		return count
	end
	count = math.floor(global.credits / shop_list[name])
	return count
end

local function process_shopping_chest(k, chest)
	if not chest.valid then global.shopping_chests[k] = nil return end
	if global.credits <= 0 then return end
	local requested_item_stack = chest.get_request_slot(1)
	if not requested_item_stack then return end
	if not shop_list[requested_item_stack.name] then
		chest.surface.create_entity({name = "flying-text", position = {chest.position.x - 2, chest.position.y}, text = requested_item_stack.name .. " is not for sale", color = {r = 200, g = 160, b = 30}}) 
		return 
	end	
	local inventory = chest.get_inventory(defines.inventory.chest)
	--if not inventory.can_insert(requested_item_stack) then return end
	local current_count = inventory.get_item_count(requested_item_stack.name)
	if current_count >= requested_item_stack.count then return end	
	local count = requested_item_stack.count - current_count
	count = get_affordable_item_count(requested_item_stack.name, count)
	if count < 1 then return end
	local inserted_amount = inventory.insert({name = requested_item_stack.name, count = count})
	if inserted_amount == 0 then return end
	local spent_credits = inserted_amount * shop_list[requested_item_stack.name]
	global.credits = global.credits - spent_credits
	chest.surface.create_entity({name = "flying-text", position = chest.position, text = "-" .. spent_credits .. " ø", color = {r = 200, g = 160, b = 30}})
end

local function process_dump_chest(k, chest)
	if not chest.valid then global.dump_chests[k] = nil return end	
	local inventory = chest.get_inventory(defines.inventory.chest)	
	if inventory.is_empty() then return end
	for k, price in pairs(shop_list) do
		local removed = inventory.remove(k)
		if removed > 0 then
			local gain = removed * shop_list[k]
			global.credits = global.credits + gain
			chest.surface.create_entity({name = "flying-text", position = chest.position, text = "+" .. gain .. " ø", color = {r = 200, g = 160, b = 30}})
			return
		end
	end
end

local function gui()
	local tooltip = "Trade goods: "
	for k, v in pairs(shop_list) do
		tooltip = tooltip .. k
		tooltip = tooltip .. " "
		tooltip = tooltip .. v
		tooltip = tooltip .. " | "
	end
	
	for _, player in pairs(game.connected_players) do
		if player.gui.top.credits_button then player.gui.top.credits_button.destroy() end
		local frame = player.gui.top.add({type = "frame", name = "credits_button"})
		frame.style.maximal_height = 38
		frame.style.top_padding = 0
		frame.style.left_padding = 0
		local element = frame.add({type = "label", name = "credits", caption = global.credits .. " ø", tooltip = tooltip})
		local style = element.style
		style.minimal_height = 38
		style.maximal_height = 38
		style.minimal_width = 100
		style.horizontal_align = "right"
		style.top_padding = 2
		style.left_padding = 2
		style.right_padding = 2
		style.bottom_padding = 2
		style.font_color = {r = 255, g = 215, b = 0}
		style.font = "default-large-bold"
	end
end

local function on_gui_opened(event)
	if not event.entity then return end
	if event.entity.force.name ~= "shopping_chests" then return end
	
	local index = event.entity.position.x .. "_"
	index = index .. event.entity.position.y
	if global.registerd_shopping_chests[index] then return end
	
	if event.entity.name == "logistic-chest-passive-provider" then
		global.dump_chests[#global.dump_chests + 1] = event.entity
		global.registerd_shopping_chests[index] = true
		event.entity.surface.create_entity({name = "flying-text", position = event.entity.position, text = "Chest registered, shop active!", color = {r = 200, g = 160, b = 30}})
		return
	end
	if event.entity.name == "logistic-chest-requester" then
		global.shopping_chests[#global.shopping_chests + 1] = event.entity
		global.registerd_shopping_chests[index] = true
		event.entity.surface.create_entity({name = "flying-text", position = event.entity.position, text = "Chest registered, shop active!", color = {r = 200, g = 160, b = 30}})
		return
	end
end

local function tick()
	for k, chest in pairs(global.shopping_chests) do
		process_shopping_chest(k, chest)
	end
	for k, chest in pairs(global.dump_chests) do
		process_dump_chest(k, chest)
	end
	gui()
end

local function on_init()
	global.shopping_chests = {}
	global.dump_chests = {}
	global.registerd_shopping_chests = {}
	global.credits = 0
	game.create_force("shopping_chests")	
	game.forces.player.set_friend("shopping_chests", true)
	game.forces.shopping_chests.set_friend("player", true)
end

local event = require 'utils.event'
event.add(defines.events.on_gui_opened, on_gui_opened)
event.on_nth_tick(120, tick)
event.on_init(on_init)