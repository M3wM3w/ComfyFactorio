local event = require 'utils.event' 

local function get_empty_hotbar_slot(player)
	for i = 1, 20, 1 do
		local item = player.get_quick_bar_slot(i)
		if not item then return i end
	end
	return false
end

local function is_item_already_present_in_hotbar(player, item)
	for i = 1, 20, 1 do
		local prototype = player.get_quick_bar_slot(i)
		if prototype then
			if item == prototype.name then return true end
		end
	end
	return false
end

local function set_hotbar(player, item)
	if not game.entity_prototypes[item] then return end
	if not game.recipe_prototypes[item] then return end
	local slot_index = get_empty_hotbar_slot(player)
	if not slot_index then return end
	if is_item_already_present_in_hotbar(player, item) then return end
	player.set_quick_bar_slot(slot_index, item)
end

local function on_player_fast_transferred(event)
	if not global.auto_hotbar_enabled[event.player_index] then return end
	local player = game.players[event.player_index]
	for name, count in pairs(player.get_main_inventory().get_contents()) do
		set_hotbar(player, name)
	end
end

local function on_player_crafted_item(event)
	if not global.auto_hotbar_enabled[event.player_index] then return end
	set_hotbar(game.players[event.player_index], event.item_stack.name)		
end

local function on_picked_up_item(event)
	if not global.auto_hotbar_enabled[event.player_index] then return end
	set_hotbar(game.players[event.player_index], event.item_stack.name)		
end

local function on_player_mined_entity(event)
	if not global.auto_hotbar_enabled[event.player_index] then return end
	set_hotbar(game.players[event.player_index], event.entity.name)		
end

local function on_init()
	global.auto_hotbar_enabled = {}
end

event.on_init(on_init)
event.add(defines.events.on_player_fast_transferred, on_player_fast_transferred)
event.add(defines.events.on_player_crafted_item, on_player_crafted_item)
event.add(defines.events.on_picked_up_item, on_picked_up_item)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)