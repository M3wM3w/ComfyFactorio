--extra difficulty mode with beyond 100% evolution modifiers

require "modules.biter_evasion_hp_increaser"

local event = require 'utils.event'
local simplex_noise = require 'utils.simplex_noise'.d2
local gui_refreshrate = 900

local evo_gains = {
	["unit-spawner"] = 0.0025,
	["unit"] = 0.000025,
	["turret"] = 0.001
}

local function draw_evolution_gui()
	local seed = game.surfaces[1].map_gen_settings.seed
	local color_r = math.abs(simplex_noise(global.color_counter * 0.015, 0, seed)) + 0.2
	if color_r > 1 then color_r = 1 end
	local color_g = math.abs(simplex_noise(global.color_counter * 0.015, 10000, seed)) + 0.2
	if color_g > 1 then color_g = 1 end
	local color_b = math.abs(simplex_noise(global.color_counter * 0.015, 20000, seed)) + 0.2
	if color_b > 1 then color_b = 1 end

	for _, player in pairs(game.connected_players) do
		if player.gui.top.evolution_gui then player.gui.top.evolution_gui.destroy() end
		local element = player.gui.top.add({type = "sprite-button", name = "evolution_gui", caption = "Evolution: " .. math.round(global.evolution_factor, 4) * 100 .. "%", tooltip = "Can go beyond 100%, increasing biter strength even further."})
		local style = element.style
		style.minimal_height = 38
		style.maximal_height = 38
		style.minimal_width = 176
		style.top_padding = 2
		style.left_padding = 4
		style.right_padding = 4
		style.bottom_padding = 2
		style.font_color = {r = color_r, g = color_g, b = color_b}
		style.font = "default-large-bold"
	end
end

local function set_endgame_stats()
	if global.evolution_factor < 1 then return end
	game.forces.enemy.set_ammo_damage_modifier("melee", (global.evolution_factor - 1) * 1.5)
	game.forces.enemy.set_ammo_damage_modifier("biological", (global.evolution_factor - 1) * 1.5)
	global.biter_evasion_health_increase_factor = global.evolution_factor * 3
end

local function add_evolution(amount)	
	global.evolution_factor = global.evolution_factor + amount
	local evo = global.evolution_factor
	if evo > 1 then	evo = 1 end
	game.forces.enemy.evolution_factor = evo		
end

local function on_entity_died(event)
	if not event.entity.valid then return end
	
	if event.entity.force.name == "enemy" then
		add_evolution(evo_gains[event.entity.type])
		draw_evolution_gui()
		global.color_counter = global.color_counter + 1
		return
	end
end

local function tick()
	add_evolution(global.tick_gain)
	set_endgame_stats()
	draw_evolution_gui()
	global.color_counter = global.color_counter + 1
end

local function on_init(event)
	global.evolution_factor = 0
	global.color_counter = 0
	
	local hours_to_max_evo = 24
	local ticks_to_max_evo = 12 * 60 * 60 * 60
	global.tick_gain = math.round((1 / ticks_to_max_evo) * gui_refreshrate, 8)
end

event.add(defines.events.on_entity_died, on_entity_died)
event.on_nth_tick(gui_refreshrate, tick)
event.on_init(on_init)