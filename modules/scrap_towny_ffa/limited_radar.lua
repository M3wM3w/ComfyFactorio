local Public = {}

function Public.reset()
	for index = 1, table.size(game.forces), 1 do
		local force = game.forces[index]
		if force ~= nil then
			force.clear_chart("nauvis")
		end
	end
end

--local Event = require 'utils.event'
--Event.add(defines.events.on_chunk_charted, on_chunk_charted)

return Public