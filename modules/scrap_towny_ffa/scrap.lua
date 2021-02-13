local Public = {}

local scrapable = {
	-- simple entity
	"small-ship-wreck",
	"medium-ship-wreck",
	-- simple entity with owner
	"crash-site-spaceship-wreck-small-1",
	"crash-site-spaceship-wreck-small-2",
	"crash-site-spaceship-wreck-small-3",
	"crash-site-spaceship-wreck-small-4",
	"crash-site-spaceship-wreck-small-5",
	"crash-site-spaceship-wreck-small-6",
	"big-ship-wreck-1",
	"big-ship-wreck-2",
	"big-ship-wreck-3",
	"crash-site-chest-1",
	"crash-site-chest-2",
	"crash-site-spaceship-wreck-medium-1",
	"crash-site-spaceship-wreck-medium-2",
	"crash-site-spaceship-wreck-medium-3",
	"crash-site-spaceship-wreck-big-1",
	"crash-site-spaceship-wreck-big-2",
	"crash-site-spaceship"
}

function Public.is_scrap(entity)
	if not entity.valid then return false end
	local f = false
	for i = 1, #scrapable, 1 do
		if entity.name == scrapable[i] then f = true end
	end
	return f
end

return Public