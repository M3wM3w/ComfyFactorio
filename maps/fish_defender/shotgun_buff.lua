local event = require 'utils.event'
local gain_multiplier = 4

local function on_research_finished(event)
	local research = event.research
	local force_name = research.force.name
	
	if not global.shotgun_shell_damage_modifier_old[force_name] then global.shotgun_shell_damage_modifier_old[force_name] = game.forces[force_name].get_ammo_damage_modifier("shotgun-shell") - 0.1 end
	
	if string.sub(research.name, 0, 26) == "physical-projectile-damage" then
		local current_damage = game.forces[force_name].get_ammo_damage_modifier("shotgun-shell")
		local vanilla_gain = current_damage - global.shotgun_shell_damage_modifier_old[force_name]
		local additional_gain = vanilla_gain * (gain_multiplier - 1)				
		game.forces[force_name].set_ammo_damage_modifier("shotgun-shell", current_damage + additional_gain)
	end	
	
	global.shotgun_shell_damage_modifier_old[force_name] = game.forces[force_name].get_ammo_damage_modifier("shotgun-shell")
end

local function on_init()
	game.forces.player.set_ammo_damage_modifier("shotgun-shell", 1)	
	global.shotgun_shell_damage_modifier_old = {}
end

event.on_init(on_init)
event.add(defines.events.on_research_finished, on_research_finished)


