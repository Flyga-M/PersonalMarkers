-- Meta class
---@class PM_MarkerInfo
---@field MapId integer
---@field Position Vector3
---@field Tint Color
PM_MarkerInfo = {MapId = -1, Position = I:Vector3(0,0,0), Tint = I:Color(0,0,0,255)}

---Creates a new PM_MarkerInfo with the provided mapId, position and tint.
---Will use default values if parameters are nil.
---@param o any
---@param mapId integer?
---@param position Vector3?
---@param tint Color?
---@return PM_MarkerInfo
function PM_MarkerInfo:new (o, mapId, position, tint)
   o = o or {}
   setmetatable(o, self)
   self.__index = self

   self.MapId = mapId or -1
   self.Position = position or I:Vector3(0,0,0)
   self.Tint = tint or I:Color(0,0,0,255)

   return o
end