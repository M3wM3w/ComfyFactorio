local Global = require "utils.global"

local this = {
	-- map player <> force
	initialForce = {}
}

Global.register(this, function (t) this = t end)

local function is_spying(player)
	return this.initialForce[player.index] ~= nil
end

local function switch_force(player, force)
	this.initialForce[player.index] = player.force
	player.force = force
end

local function spy_production(player, force)
	if is_spying(player) then
		return
	end
	switch_force(player, force)
	player.opened = defines.gui_type.production
end

local function spy_tech_tree(player, force)
	if is_spying(player) then
		return
	end
	switch_force(player, force)
	player.open_technology_gui()
end

local function restore_force(player)
	if not is_spying(player) then
		return
	end
	player.force = this.initialForce[player.index]
	this.initialForce[player.index] = nil
end

-- When a player clicks on a spying prod LuaGuiElement
local function spy_prod_handler(event)
	if not event.element.valid then
		return
	end
	local elementToForce = {
		["spy-north-prod"] = "north",
		["spy-south-prod"] = "south"
	}
	local force = elementToForce[event.element.name]
	if force then
		local player = game.players[event.player_index]
		spy_production(player, force)
	end
end

-- When a player clicks on a spying tech LuaGuiElement
local function spy_tech_handler(event)
	if not event.element.valid then
		return
	end
	local elementToForce = {
		["spy-north-tech"] = "north",
		["spy-south-tech"] = "south"
	}
	local force = elementToForce[event.element.name]
	if force then
		local player = game.players[event.player_index]
		spy_tech_tree(player, force)
	end
end

-- When a player closes the prod view while spying
local function close_prod_handler(event)
	if event.gui_type ~= defines.gui_type.production then
		return
	end
	local player = game.players[event.player_index]
	-- If the player was spying
	if is_spying(player) then
		restore_force(player)
	end
end

-- When a player closes the tech view while spying
local function close_tech_handler(event)
	if event.gui_type ~= defines.gui_type.research then
		return
	end
	local player = game.players[event.player_index]
	-- If the player was spying
	if is_spying(player) then
		restore_force(player)
	end
end

local Event = require 'utils.event'
Event.add(defines.events.on_gui_click, spy_prod_handler)
Event.add(defines.events.on_gui_click, spy_tech_handler)
Event.add(defines.events.on_gui_closed, close_prod_handler)
Event.add(defines.events.on_gui_closed, close_tech_handler)
