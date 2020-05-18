local function draw_map_tag(surface, force, position)
	force.add_chart_tag(surface, {icon = {type = 'item', name = 'heavy-armor'}, position = position, text = "   "})
end

local function is_tag_valid(tag)
	if not tag.icon then return end
	if tag.icon.type ~= "item" then return end
	if tag.icon.name ~= "heavy-armor" then return end
	if tag.text ~= "   " then return end
	return true
end

local function get_corpse_force(corpse)
	if corpse.character_corpse_player_index then 
		if game.players[corpse.character_corpse_player_index] then
			return game.players[corpse.character_corpse_player_index].force
		end
	end
	return game.forces.neutral
end

local function destroy_all_tags()
	for _, force in pairs(game.forces) do
		for _, surface in pairs(game.surfaces) do
			for _, tag in pairs(force.find_chart_tags(surface)) do
				if is_tag_valid(tag) then tag.destroy() end
			end
		end
	end
end

local function redraw_all_tags()
	for _, surface in pairs(game.surfaces) do
		for _, corpse in pairs(surface.find_entities_filtered({name = "character-corpse"})) do
			draw_map_tag(corpse.surface, get_corpse_force(corpse), corpse.position)
		end
	end
end

local function find_and_destroy_tag(corpse)
	local force = get_corpse_force(corpse)
	for _, tag in pairs(force.find_chart_tags(corpse.surface, {{corpse.position.x - 0.1, corpse.position.y - 0.1}, {corpse.position.x + 0.1, corpse.position.y + 0.1}})) do		
		if is_tag_valid(tag) then
			tag.destroy()
			return true
		end		
	end
	return false
end

local function on_player_died(event)
	local player = game.players[event.player_index]
	draw_map_tag(player.surface, player.force, player.position)
end

local function on_character_corpse_expired(event)
	if find_and_destroy_tag(event.corpse) then return end
	destroy_all_tags()
	redraw_all_tags()
end

local function on_pre_player_mined_item(event)
	if event.entity.name ~= "character-corpse" then return end	
	if find_and_destroy_tag(event.entity) then return end
	destroy_all_tags()
	redraw_all_tags()
end

local event = require 'utils.event'
event.add(defines.events.on_player_died, on_player_died)
event.add(defines.events.on_character_corpse_expired, on_character_corpse_expired)
event.add(defines.events.on_pre_player_mined_item, on_pre_player_mined_item)