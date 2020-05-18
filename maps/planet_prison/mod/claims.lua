local public = {}
local common = require(".common")

--[[
init - Initialize claim system.
@param names - Table of entity names that should be used as a marker.
@param max_distance - Maximal distance allowed between markers
--]]
public.init = function(names, max_distance)
   if global.this == nil then
      global.this = {}
   end

   if type(names) ~= "table" then
      names = { names }
   end

   global.this._claims_info = {}
   global.this._claims_visible_to = {}
   global.this._claim_markers = names
   global.this._claim_max_dist = max_distance
end

global.this._claim_new_claim = function(ent, deps)
   local comm = deps.common
   local point = {
      {
         x = comm.get_axis(ent.position, "x"),
         y = comm.get_axis(ent.position, "y"),
      }
   }

   local claims = global.this._claims_info
   if claims[ent.force.name] == nil then
      claims[ent.force.name] = {}
      claims[ent.force.name].polygons = {}
      claims[ent.force.name].claims = {}
      claims[ent.force.name].collections = {}
   end

   table.insert(claims[ent.force.name].collections, point)
end

global.this._claim_on_build_entity = function(ent, deps)
   local max_dist = global.this._claim_max_dist
   local force = ent.force.name
   local comm = deps.common
   local data = global.this._claims_info[force]

   if data == nil then
      global.this._claim_new_claim(ent, deps)
      return
   end

   local in_range = false
   local collections = data.collections
   for i = 1, #collections do
      local points = collections[i]

      for _, point in pairs(points) do
         point = point
         local dist = comm.get_distance(point, ent.position)
         if max_dist < dist then
            goto continue
         end

         in_range = true
         point = {
            x = comm.get_axis(ent.position, "x"),
            y = comm.get_axis(ent.position, "y"),
         }
         table.insert(points, point)
         data.claims[i] = comm.get_convex_hull(points)

         break
         ::continue::
      end
   end

   if not in_range then
      global.this._claim_new_claim(ent, deps)
   end
end

global.this._claims_in_markers = function(name)
   for _, marker in pairs(global.this._claim_markers) do
      if name == marker then
         return true
      end
   end

   return false
end

--[[
on_build_entity - Event processing function.
@param ent - Entity
--]]
public.on_built_entity = function(ent)
   if not global.this._claims_in_markers(ent.name) then
      return
   end

   local deps = {
      common = common,
   }
   global.this._claim_on_build_entity(ent, deps)
end

global.this._claim_on_entity_died = function(ent, deps)
   local comm = deps.common
   local force = ent.force.name
   local data = global.this._claims_info[force]
   if data == nil then
      return
   end

   for i = 1, #data.collections do
      local points = data.collections[i]

      for j = 1, #points do
         local point = points[j]
         if comm.positions_equal(point, ent.position) then
            table.remove(points, j)

            data.claims[i] = comm.get_convex_hull(points)
            break
         end
      end

      if #points == 0 then
         table.remove(data.claims, i)
         table.remove(data.collections, i)
         break
      end
   end

   if #data.claims == 0 then
      global.this._claims_info[force] = nil
   end
end

--[[
on_entity_died - Event processing function.
@param ent - Entity
--]]
public.on_entity_died = function(ent)
   if not global.this._claims_in_markers(ent.name) then
      return
   end

   local deps = {
      common = common,
   }
   global.this._claim_on_entity_died(ent, deps)
end

--[[
on_player_mined_entity - Event processing function.
@param ent - Entity
--]]
public.on_player_mined_entity = function(ent)
   public.on_entity_died(ent)
end

--[[
on_player_died - Event processing function
@param player - Player
--]]
public.on_player_died = function(player)
   global.this._claims_info[player.name] = nil
end

--[[
get_claims - Get all claims data points for given force.
@param f_name - Force name.
--]]
public.get_claims = function(f_name)
   if global.this._claims_info[f_name] == nil then
      return {}
   end

   return global.this._claims_info[f_name].claims
end

global.this._claims_update_visiblity = function()
   if #global.this._claims_visible_to == 0 then
      for _, info in pairs(global.this._claims_info) do
         for _, id in pairs(info.polygons) do
            if rendering.is_valid(id) then
               rendering.set_visible(id, false)
            end
         end
      end
      return
   end

   for _, info in pairs(global.this._claims_info) do
      for _, id in pairs(info.polygons) do
         if rendering.is_valid(id) then
            rendering.set_visible(id, true)
            rendering.set_players(id, global.this._claims_visible_to)
         end
      end
   end
end

--[[
set_visibility_to - Specifies who can see the claims and redraws.
@param name - Name of a player.
--]]
public.set_visibility_to = function(name)
   for _, p in pairs(global.this._claims_visible_to) do
      if p == name then
         return
      end
   end

   table.insert(global.this._claims_visible_to, name)
   global.this._claims_update_visiblity()
end

--[[
remove_visibility_from - Remove the claim visibility from the player.
@param name - Name of a player.
--]]
public.remove_visibility_from = function(name)
   for i = 1, #global.this._claims_visible_to do
      local p = global.this._claims_visible_to[i]
      if p == name then
         table.remove(global.this._claims_visible_to, i)
         global.this._claims_update_visiblity()
         break
      end
   end
end

return public
