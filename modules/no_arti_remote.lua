local function disable_recipe(event)
	local technology = event.research
	if technology.name == "artillery" then
		technology.force.recipes["artillery-targeting-remote"].enabled = false
	end
end

local function on_research_finished(event)
	disable_recipe(event)
end

local event = require 'utils.event'
event.add(defines.events.on_research_finished, on_research_finished)
