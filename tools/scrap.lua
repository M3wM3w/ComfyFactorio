local Public = {}
local math_random = math.random

local scrap_list = {
		"crash-site-spaceship-wreck-small-1",
		"crash-site-spaceship-wreck-small-2",
		"crash-site-spaceship-wreck-small-3",
		"crash-site-spaceship-wreck-small-4",
		"crash-site-spaceship-wreck-small-5",
		"crash-site-spaceship-wreck-small-6"
}

function Public.create_scrap(surface, position)
	local scraps = {
	  "crash-site-spaceship-wreck-small-1",
	  "crash-site-spaceship-wreck-small-1",
	  "crash-site-spaceship-wreck-small-2",
	  "crash-site-spaceship-wreck-small-2",
	  "crash-site-spaceship-wreck-small-3",
	  "crash-site-spaceship-wreck-small-3",
	  "crash-site-spaceship-wreck-small-4",
	  "crash-site-spaceship-wreck-small-4",
	  "crash-site-spaceship-wreck-small-5",
	  "crash-site-spaceship-wreck-small-5",
	  "crash-site-spaceship-wreck-small-6"
	}
	surface.create_entity({name = scraps[math_random(1, #scraps)], position = position, force = "neutral"})
end



function Public.get_scrap_name(index)
	if index > #scrap_list then return scrap_list[1] end
	if index < 1 then return scrap_list[1] end
	return scrap_list[index]
end

function Public.get_scraps()
	return scrap_list
end

function Public.get_scrap_true_array()
	local true_array = {}
	for _, e in pairs (scrap_list) do
		true_array[e] = true
	end
	return true_array
end

return Public
