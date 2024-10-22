local NAMESPACE = "Flyga.PM"
local KEY_AMOUNT = "MarkerAmount"
local KEY_MARKER_PREFIX = "Marker"
local KEY_VERSION = "Version"
local STORAGE_VERSION = "1"

-- https://stackoverflow.com/a/7615129
local function split(input, seperator)
    if seperator == nil then
        seperator = "%s"
    end

    local result = {}
    for substring in string.gmatch(input, "([^"..seperator.."]+)") do
        table.insert(result, substring)
    end

    return result
end

---Serialzes a color to the format #ffffffff (rgba).
---@param color Color # The color that should be serialized.
---@return string # The serialized color.
local function serializeColor(color)
    return string.format("#%02x%02x%02x%02x", color.R, color.G, color.B, color.A)
end

---Deserializes a color in the format #ffffffff (rgba).
---@param serializedColor string # The serialized color.
---@return Color # The deserialized color. Will use a fallback color if the color can't be deserialized properly.
local function deserializeColor(serializedColor)
    local fallbackColor = I:Color(185, 0, 255)

    local prefix = string.sub(serializedColor, 1, 1)
    local rest = string.sub(serializedColor, 2, #serializedColor)

    if prefix ~= '#' then
        Debug:Warn("Unable to deserialize color, because prefix is unexpected. Given: "..prefix..". Expected: #")
        return fallbackColor
    end

    if #rest ~= 8 then
        Debug:Warn("Unable to deserialize color, because amount of characters does not match expected value. Given: "..#rest..". Expected: 8")
        return fallbackColor
    end

    local r = string.sub(rest,1,2)
    local g = string.sub(rest,3,4)
    local b = string.sub(rest,5,6)
    local a = string.sub(rest,7,8)

    return I:Color(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), tonumber(a, 16)) or fallbackColor
end

---Serialzes a vector3 to the format [x y z].
---@param position Vector3 # The vector3 that should be serialized.
---@return string # The serialized vector3.
local function serializePosition(position)
    -- can't use string.format here, because it does not convert floats with the invariant culture
    -- this would lead to problems when deserializing, because tonumber() expects the invariant culture
    return "["..position.X.." "..position.Y.." "..position.Z.."]"
end

---Deserializes a vector3 in the format [x y z].
---@param serializedPosition string # The serialized vector3.
---@return Vector3 # The deserialized vector3. Will use a fallback position if the position can't be deserialized properly.
local function deserializePosition(serializedPosition)
    local fallbackVector = I:Vector3(0, 0, 0)
    
    local prefix = string.sub(serializedPosition, 1, 1)
    local content = string.sub(serializedPosition, 2, #serializedPosition-1)
    local suffix = string.sub(serializedPosition, #serializedPosition, #serializedPosition)

    if prefix ~= '[' or suffix ~= ']' then
        Debug:Warn("Unable to deserialize position, because prefix and suffix are unexpected. Given: "..prefix..""..suffix..". Expected: []")
        return fallbackVector
    end

    local parts = split(content, " ")

    if #parts ~= 3 then
        Debug:Warn("Unable to deserialize position, because amount of parts does not match expected value. Given: "..#parts..". Expected: 3")
        return fallbackVector
    end

    return I:Vector3(tonumber(parts[1], 10), tonumber(parts[2], 10), tonumber(parts[3], 10)) or fallbackVector
end

---Serialzes a marker.
---@param marker Marker # The marker that should be serialized.
---@return string # The serialized marker.
local function serializeMarker(marker)
    return string.format("{MapId:%d/Position:%s/Tint:%s}", marker.MapId, serializePosition(marker.Position), serializeColor(marker.Tint))
end

---Deserializes a marker into marker info that can be used to create a marker.
---@param serializedMarker string # The serialized marker.
---@return PM_MarkerInfo # The deserialized marker information. Will use fallback info if the marker can't be deserialized properly.
local function deserializeMarker(serializedMarker)
    local resultMarkerInfo = PM_MarkerInfo:new()

    local prefix = string.sub(serializedMarker, 1, 1)
    local content = string.sub(serializedMarker, 2, #serializedMarker-1)
    local suffix = string.sub(serializedMarker, #serializedMarker, #serializedMarker)

    if prefix ~= '{' or suffix ~= '}' then
        Debug:Warn("Unable to deserialize marker, because prefix and suffix are unexpected. Given: "..prefix..""..suffix..". Expected: {}")
        return resultMarkerInfo
    end

    local parts = split(content, "/")

    if #parts ~= 3 then
        Debug:Warn("Unable to deserialize marker, because amount of parts does not match expected value. Given: "..#parts..". Expected: 3")
        return resultMarkerInfo
    end

    for key, value in pairs(parts) do
        local pair = split(value, ":")

        if #pair == 2 then
            if pair[1] == "MapId" then
                resultMarkerInfo.MapId = tonumber(pair[2], 10) or -1
            elseif pair[1] == "Position" then
                resultMarkerInfo.Position = deserializePosition(pair[2])
            elseif pair[1] == "Tint" then
                resultMarkerInfo.Tint = deserializeColor(pair[2])
            else
                Debug:Warn("Unexpected key: "..pair[1])
            end
        end
    end

    return resultMarkerInfo
end

---Stores the marker states.
---@param markers Marker[] # The marker states that should be stored.
function PM_StoreMarkerStates(markers)
    Storage:UpsertValue(NAMESPACE, KEY_AMOUNT, #markers)
    Storage:UpsertValue(NAMESPACE, KEY_VERSION, STORAGE_VERSION)

    for i = 1, #markers do
        Storage:UpsertValue(NAMESPACE, KEY_MARKER_PREFIX..i, serializeMarker(markers[i]))
    end
end

---Retrieves the stored marker states.
---@return PM_MarkerInfo[] # The states of the stored markers.
function PM_RetrieveMarkerStates()
    local result = {}

    local storageVersion = Storage:ReadValue(NAMESPACE, KEY_VERSION)

    if storageVersion ~= STORAGE_VERSION and storageVersion ~= nil then
        User:ShowInfo("Unable to retrieve stored marker states. Incompatible version ("..storageVersion.." != "..STORAGE_VERSION..").")
        Debug:Warn("Unable to retrieve previously stored marker states, because the stored version can't be handled by this version of the marker pack. Update your pack please.")
        return result
    end

    local amountString = Storage:ReadValue(NAMESPACE, KEY_AMOUNT)

    if amountString == nil or amountString == "" then
        Debug:Warn("Unable to retrieve previously stored marker states, because no proper marker amount was stored.")
        return result
    end

    local amount = tonumber(amountString, 10)

    if amount == nil then
        Debug:Warn("Unable to retrieve previously stored marker states, because no proper marker amount was stored.")
        return result
    end

    if amount < 1 then
        return result
    end

    for i = 1, amount do
        local serializedMarker = Storage:ReadValue(NAMESPACE, KEY_MARKER_PREFIX..i)

        if serializedMarker ~= nil then
            table.insert(result, deserializeMarker(serializedMarker))
        end
    end

    return result
end