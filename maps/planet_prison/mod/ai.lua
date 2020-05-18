local public = {}
local _common = require(".common")

public.command = {
   --[[
      @param args nil
   --]]
   noop = 0,

   --[[
      @param args nil
   --]]
   seek_and_destroy_player = 1,

   --[[
      @param args = {
          agents, // All movable agents
          positions, // Table of positions to attack
      }
   --]]
   attack_objects = 2
}

--[[
init - Initialize the module.
--]]
public.init = function()
   if global.this == nil then
      global.this = {}
   end
end

local function _get_direction(src, dest)
   local src_x = _common.get_axis(src, "x")
   local src_y = _common.get_axis(src, "y")
   local dest_x = _common.get_axis(dest, "x")
   local dest_y = _common.get_axis(dest, "y")

   local step = {
      x = nil,
      y = nil
   }

   local precision = _common.rand_range(1, 10)
   if dest_x - precision > src_x then
      step.x = 1
   elseif dest_x < src_x - precision then
      step.x = -1
   else
      step.x = 0
   end

   if dest_y - precision > src_y then
      step.y = 1
   elseif dest_y < src_y - precision then
      step.y = -1
   else
      step.y = 0
   end

   return _common.direction_lookup[step.x][step.y]
end

local function _move_to(ent, trgt, min_distance)
   local state = {
      walking = false,
   }

   local distance = _common.get_distance(trgt.position, ent.position)
   if min_distance < distance then
      local dir = _get_direction(ent.position, trgt.position)
      if dir then
         state = {
            walking = true,
            direction = dir
         }
      end
   end

   ent.walking_state = state
   return state.walking
end

local function _shoot_at(ent, trgt)
   ent.shooting_state = {
      state = defines.shooting.shooting_enemies,
      position = trgt.position
   }
end

local function _shoot_stop(ent)
   ent.shooting_state = {
      state = defines.shooting.not_shooting,
      position = {0, 0}
   }
end

local function _do_job_seek_and_destroy_player(surf)
   for _, player in pairs(game.players) do
      if player.character == nil then
         goto continue
      end

      local search_info = {
         name = "character",
         position = player.character.position,
         radius = 20,
         force = "enemy",
      }

      local ents = surf.find_entities_filtered(search_info)
      if not ents or #ents == 0 then
         goto continue
      end

      for _, e in pairs(ents) do
         if not _move_to(e, player.character, _common.rand_range(5, 10)) then
            _shoot_at(e, player.character)
         else
            _shoot_stop(e)
         end
      end

      ::continue::
   end
end

local function _do_job_attack_objects(surf, args)
   local agents = args.agents
   if #agents == 0 then
      return
   end

   local objects = args.objects
   local target, closest, agent, query
   for i = #agents, 1, -1 do
       agent = agents[i]
      if not agent.valid then
         table.remove(agents, i)
         goto continue
      end

      if game.tick % i ~= 0 then
         goto continue
      end

      query = {
         position = agent.position,
         radius = 15,
         type = {
            "projectile",
            "beam"
         },
         force = {
            "enemy",
            "player",
            "neutral",
         },
         invert = true
      }
      closest = surf.find_entities_filtered(query)
      if #closest ~= 0 then
         target = _common.get_closest_neighbour(agent.position, closest)
      else
         if #objects == 0 then
            _shoot_stop(agent)
            goto continue
         end

         target = _common.get_closest_neighbour(agent.position, objects)
      end

      if target == nil or not target.valid then
         goto continue
      end

      if not _move_to(agent, target, _common.rand_range(5, 15)) then
         _shoot_at(agent, target)
      else
         _shoot_stop(agent)
      end

      ::continue::
   end
end

--[[
do_job - Perform non-stateful operation on all enemy "character" entities.
@param surf - LuaSurface, on which everything is happening.
@param command - Command to perform on all non-player controllable characters.
--]]
public.do_job = function(surf, command, args)
   if args == nil then
      args = {}
   end

   if command == public.command.seek_and_destroy_player then
      _do_job_seek_and_destroy_player(surf)
   elseif command == public.command.attack_objects then
      _do_job_attack_objects(surf, args)
   end
end

return public
