local Public = {}

-- one table to rule them all!
local Global = require 'utils.global'
local ffatable = {}
Global.register(
		ffatable,
		function(tbl)
			ffatable = tbl
		end
)

function Public.reset_table()
	for k, _ in pairs(ffatable) do
		ffatable[k] = nil
	end
end

function Public.get_table()
	return ffatable
end

local on_init = function ()
   Public.reset_table()
end

local Event = require 'utils.event'
Event.on_init(on_init)

return Public