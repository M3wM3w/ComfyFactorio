-- DISABLE WATER IN INGAME MAP GEN SETTINGS FOR BEST LOOKS
--[[
>>>eNpjYBBi4GVgZACCBnsQycOXmJeemlOsm5ZZXFxalMrA4OAAk
XOwF4JK5SWWlBYl5uimJxYjS3NDpfOLUg1xiBvhEDfGIW6CQ9wUh
7gZsjhLcn5iDrIAZ3JRaUqqbn4miihXal5qbqVuUmIx0LMHgMIMY
CnWkqLU1GKIIihmPLlZi7mhRY4BhP/XMyj8/w/CQNYDoC4QZmBsA
JoBVAkUgwHW5JzMtDQGBgVHIHYCGcTIyFgtss79YdUUe0aIGj0HK
OMDVORAEkzEE8bwc8AppQJjmMAYF+wZjcHgMxIDYmkJ0AqoKg4HB
AMi2QKSZGTsfbt1wfdjF+wY/6z8eMk3KcGe0dBV5N0Ho3V2QEkBk
D+Z4MSsmSCwE+YVBpiZD+yhUjftGc+eAYE39oysIB0iIEJBBkgEu
AEJAT4gsaAHJgbRbQczRsSBMQ0MvsF88hjGuGyP7g9gQNiADJcDE
SdABNhCuMsYIUyHfgdGB3mYrCRCCVC/EQOyG1IQPjwJs/Ywkv1oD
sGMCGR/oImoOGCJBi6QhSlw4gUz3DXA8LzADuM5zHdgZAYxQKq+A
MUgPEjihRgFoQUcmBkQAJi8BPc6XQMAy367Og==<<<
]]


local get_noise = require "utils.get_noise"
local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs

local spawn_size = 160
local spawn_check = spawn_size + 96

local waters = {"deepwater", "water"}

local function is_water(position, noise, seed)
	if math_abs(position.y) <= spawn_check or math_abs(position.x) <= spawn_check then
		local border_noise = get_noise("cave_ponds", position, seed)
		if math_abs(position.x) + border_noise * 10 < spawn_size and math_abs(position.y) + border_noise * 10 < spawn_size then return false end
		if math_abs(position.x) + border_noise * 10 < spawn_size + 32 and math_abs(position.y) + border_noise * 10 < spawn_size + 32 then return true end
	end
	if math_abs(noise) < 0.15 then return end
	if math_abs(noise) > 0.80 then return end
	return true
end

local function on_chunk_generated(event)	
	local surface = event.surface
	local seed = surface.map_gen_settings.seed
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	local set_tiles = surface.set_tiles
	local get_tile = surface.get_tile
	local position
	local noise
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do			
			position = {x = left_top_x + x, y = left_top_y + y}				
			if not get_tile(position).collides_with("resource-layer") then 
				noise = get_noise("watery_world", position, seed)
				if is_water(position, noise, seed) then
					set_tiles({{name = waters[math_floor(noise * 10 % 2 + 1)], position = position}}, true)
					if math_random(1, 128) == 1 then 
						surface.create_entity({name = global.watery_world_fishes[math_random(1, #global.watery_world_fishes)], position = position})
					end
				end
			end				
		end
	end
end

local function on_init()
	global.watery_world_fishes = {}
	for _, prototype in pairs(game.entity_prototypes) do
		if prototype.type == "fish" then
			table.insert(global.watery_world_fishes, prototype.name)
		end
	end
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)