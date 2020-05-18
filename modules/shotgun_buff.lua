local function on_research_finished(event)
	local research = event.research
	if string.sub(research.name, 0, 26) ~= "physical-projectile-damage" then return end
	local multiplier = 4
	if global.shotgun_shell_damage_research_multiplier then multiplier = global.shotgun_shell_damage_research_multiplier end
	
	local modifier = game.forces[research.force.name].get_ammo_damage_modifier("shotgun-shell")
	
	modifier = modifier - research.effects[3].modifier
	modifier = modifier + research.effects[3].modifier * multiplier
	
	game.forces[research.force.name].set_ammo_damage_modifier("shotgun-shell", modifier)
end

local event = require 'utils.event'
event.add(defines.events.on_research_finished, on_research_finished)