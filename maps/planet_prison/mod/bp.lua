local public = {}
local _common = require(".common")

public.init = function()
   if global.this == nil then
      global.this = {}
   end

   global.this._bps = {}
end

--[[
push_blueprint - Pushes blueprint into a list.
@param name - Handle of a blueprint.
@param bp - Blueprint in JSON format.
--]]
public.push_blueprint = function(name, bp)
   local entry = {
      bp = game.json_to_table(bp).blueprint,
      hook = nil,
      refs = {}
   }
   global.this._bps[name] = entry
end

--[[
set_blueprint_hook - Set callback to a blueprint.
@param name - Handle of a blueprint
@param hook - Callback that will be called after blueprint is placed.
--]]
public.set_blueprint_hook = function(name, hook)
   if name == nil then
      log("bp.set_blueprint_hook: name is nil")
      return
   end

   if global.this._bps[name] == nil then
      log("bp.set_blueprint_hook: unrecognized blueprint")
      return
   end

   global.this._bps[name].hook = hook
end

--[[
get_references - Get all references of the blueprint on the map.
@param name - Blueprint handle.
--]]
public.get_references = function(name)
   if name == nil then
      log("bp.get_references: name is nil")
      return {}
   end

   local object = global.this._bps[name]
   if object == nil then
      log("bp.get_references: unrecognized blueprint")
      return {}
   end

   return object.refs
end

--[[
get_references - Gets opaque object representing bp references.
@param name - Blueprint handle.
--]]
public.get_references = function(name)
   if name == nil then
      log("bp.get_references: name is nil")
      return
   end

   local object = global.this._bps[name]
   if object == nil then
      log("bp.get_references: unrecognized blueprint")
      return
   end

   return object.refs
end

--[[
reference_get_bounding_box - Return bounding box from the reference.
@param reference - Valid reference object fetched from get_references.
--]]
public.reference_get_bounding_box = function(reference)
   return reference.bb
end

--[[
reference_get_entities - Return references to entities.
@param reference - Valid reference object fetched from get_references.
--]]
public.reference_get_entities = function(reference)
   return reference.entities
end

--[[
reference_get_timestamp - Return timestamp of a reference
@param reference - Valid reference object fetched from get_references.
--]]
public.reference_get_timestamp = function(reference)
   return reference.timestamp
end


--[[
unlink_references_filtered - Unlinks all references of blueprint on the map if they
meet the query rules.
@param name - Blueprint handle.
@param query - Additional parameter by which unlinking is guided
@param query.timestamp - If reference is older that submitted timestamp, it will be
unlinked.
@return An array of unlinked references.
--]]
public.unlink_references_filtered = function(name, query)
   if name == nil then
      log("bp.get_references: name is nil")
      return
   end

   local object = global.this._bps[name]
   if object == nil then
      log("bp.get_references: unrecognized blueprint")
      return
   end

   local refs = {}
   for i = #object.refs, 1, -1 do
      local ref = object.refs[i]
      if query and query.timestamp then
         if ref.timestamp > query.timestamp then
            goto continue
         end
      end

      table.insert(refs, ref)
      table.remove(object.refs, i)
      ::continue::
   end

   return refs
end

--[[
destroy_references_filtered - Destroys all references of blueprint on the map if they
meet the query rules.
@param surf - Surface on which blueprints are placed.
@param name - Blueprint handle.
@param query - Additional parameter by which removal is guided
@param query.timestamp - If reference is older that submitted timestamp, it will be
removed.
--]]
public.destroy_references_filtered = function(surf, name, query)
   if name == nil then
      log("bp.get_references: name is nil")
      return
   end

   local object = global.this._bps[name]
   if object == nil then
      log("bp.get_references: unrecognized blueprint")
      return
   end

   for i = 1, #object.refs do
      local ref = object.refs[i]
      if query and query.timestamp then
         if ref.timestamp > query.timestamp then
            goto continue
         end
      end

      for _, ent in pairs(ref.entities) do
         if ent.valid then
            ent.destroy()
         end
      end

      local tiles = {}
      for _, tile in pairs(ref.tiles) do
         tile.name = "concrete"
         table.insert(tiles, tile)
      end

      surf.set_tiles(tiles)

      table.remove(object.refs, i)
      ::continue::
   end
end

--[[
destroy_references - Destroys all references of blueprint on the map
@param surf - Surface on which blueprints are placed.
@param name - Blueprint handle.
--]]
public.destroy_references = function(surf, name)
   public.destroy_references_filtered(surf, name, {})
end

global._bp_destroy_reference = function(surf, ref)
   for _, ent in pairs(ref.entities) do
      if ent.valid then
         ent.destroy()
      end
   end

   local tiles = {}
   for _, tile in pairs(ref.tiles) do
      if tile.valid then
         goto continue
      end

      tile.name = "concrete"
      table.insert(tiles, tile)
      ::continue::
   end

   surf.set_tiles(tiles)
end

--[[
destroy_reference - Destroys reference of a blueprint at given surface.
@param surf - Surface on which blueprints are placed.
@param reference - Any valid reference.
--]]
public.destroy_reference = function(surf, reference)
   for _, meta in pairs(global.this._bps) do
      for i = 1, #meta.refs do
         local ref = meta.refs[i]
         if reference.id == ref.id then
            global._bp_destroy_reference(surf, ref)
            table.remove(meta.refs, i)
            return
         end
      end
   end
end

local function _build_tiles(surf, point, tiles)
   local _tiles = {}

   local get_axis = _common.get_axis
   for _, tile in pairs(tiles) do
      local _tile = {
         name = tile.name,
         position = {
            x = get_axis(tile.position, "x") + get_axis(point, "x"),
            y = get_axis(tile.position, "y") + get_axis(point, "y")
         }
      }
      table.insert(_tiles, _tile)
   end

   surf.set_tiles(_tiles)
   return _tiles
end


local function _build_entities(surf, point, entities, hook, args)
   local _entities = {}

   local get_axis = _common.get_axis
   for _, ent in pairs(entities) do
      local ent_info = {
         position = {
            x = get_axis(ent.position, "x") + get_axis(point, "x"),
            y = get_axis(ent.position, "y") + get_axis(point, "y")
         },
         name = ent.name,
      }
      local e = surf.create_entity(ent_info)
      if not e or not e.valid then
         goto continue
      end

      if hook then
         hook(e, args)
      end

      table.insert(_entities, e)
      ::continue::
   end

   return _entities
end

--[[
build - Place blueprint at given point.
@param surf - LuaSurface on which action will be taken.
@param name - Blueprint handle.
@param point - Position at which place blueprint.
@param args - If hook was set, this will be argument passed.
--]]
public.build = function(surf, name, point, args)
   if surf == nil then
      log("bp.build: surf is nil")
      return
   end

   if name == nil then
      log("bp.build: name is nil")
      return
   end

   local object = global.this._bps[name]
   if object == nil then
      log("bp.set_blueprint_hook: unrecognized blueprint")
      return
   end

   local instance = {
      entities = {},
      tiles = {},
      bb = nil,
      timestamp = game.tick,
   }
   local bbs = {}
   local tiles = object.bp.tiles
   if tiles and #tiles > 0 then
      instance.tiles = _build_tiles(surf, point, tiles)
      local bb = _common.create_bounding_box_by_points(instance.tiles)
      table.insert(bbs, bb)

      local query = {
         name = "character",
         area = bb,
         invert = true,
      }
      for _, ent in pairs(surf.find_entities_filtered(query)) do
         if ent.valid then
            ent.destroy()
         end
      end
   end

   local entities = object.bp.entities
   if entities and #entities > 0 then
      instance.entities = _build_entities(surf, point, entities, object.hook, args)
      local bb = _common.create_bounding_box_by_points(instance.entities)
      table.insert(bbs, bb)

      local query = {
         name = "character",
         area = bb,
         invert = true,
      }
      for _, ent_found in pairs(surf.find_entities_filtered(query)) do
         if not ent_found.valid then
            goto continue
         end

         for _, ent_spawned in pairs(instance.entities) do
            if ent_found == ent_spawned then
               goto continue
            end
         end

         ent_found.die()
         ::continue::
      end
   end

   instance.bb = _common.merge_bounding_boxes(bbs)
   instance.id = game.tick
   table.insert(object.refs, instance)

   return instance
end

return public
