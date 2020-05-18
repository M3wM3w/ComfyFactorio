local blacklist = {
	 ["cliff"] = true, 
	 ["item-entity"] = true, 
}

local function on_marked_for_deconstruction(event)
	local entity = event.entity
	if not entity.valid then return end
	if not event.player_index then return end
	if entity.force.name ~= "neutral" then return end
	if blacklist[entity.type] then return end
	entity.cancel_deconstruction(game.players[event.player_index].force.name)
end

local Event = require 'utils.event' 
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
