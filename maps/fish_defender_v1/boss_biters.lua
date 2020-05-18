local boss_biter = {}
local math_random = math.random
local radius = 6
local targets = {}
local acid_splashes = {
	["big-biter"] = "acid-stream-worm-medium",
	["behemoth-biter"] = "acid-stream-worm-big"
}
local acid_lines = {
	["big-spitter"] = "acid-stream-spitter-medium",
	["behemoth-spitter"] = "acid-stream-spitter-big"
}
for x = radius * -1, radius, 1 do
	for y = radius * -1, radius, 1 do
		if math.sqrt(x^2 + y^2) <= radius then
			targets[#targets + 1] = {x = x, y = y}
		end
	end
end

local function acid_nova(event)
	for _ = 1, math.random(20, 40) do
		local i = math.random(1, #targets)		
		event.entity.surface.create_entity({	
			name = acid_splashes[event.entity.name],
			position = event.entity.position,
			force = event.entity.force.name,
			source = event.entity.position,
			target = {x = event.entity.position.x + targets[i].x, y = event.entity.position.y + targets[i].y},
			max_range = radius, 
			speed = 0.001
		})
	end	
end

boss_biter.died = function(event)
	if acid_splashes[event.entity.name] then acid_nova(event) end
	if global.acid_lines_delay[event.entity.unit_number] then global.acid_lines_delay[event.entity.unit_number] = nil end
	global.boss_biters[event.entity.unit_number] = nil
end

local function acid_line(surface, name, source, target)
	local distance = math.sqrt((source.x - target.x) ^ 2 + (source.y - target.y) ^ 2)
	local modifier = {(target.x - source.x) / distance, (target.y - source.y) / distance}
	
	local position = {source.x, source.y}
		
	for i = 1, distance * 1.5, 1 do
		if math_random(1,2) ~= 1 then
			surface.create_entity({	
				name = name,
				position = source,
				force = "enemy",
				source = source,
				target = position,
				max_range = 25, 
				speed = 1
			})
		end
		position = {position[1] + modifier[1], position[2] + modifier[2]}
	end
end

boss_biter.damaged_entity = function(event)
	if acid_lines[event.cause.name] then
		if not global.acid_lines_delay[event.cause.unit_number] then global.acid_lines_delay[event.cause.unit_number] = 0 end
		if global.acid_lines_delay[event.cause.unit_number] < game.tick then
			acid_line(event.cause.surface, acid_lines[event.cause.name], event.cause.position, event.entity.position)
			global.acid_lines_delay[event.cause.unit_number] = game.tick + 180
		end
	end
end

return boss_biter