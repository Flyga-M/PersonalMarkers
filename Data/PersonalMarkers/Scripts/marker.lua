-- mostly taken from: https://gw2pathing.com/docs/lua-scripting/lua-tutorials/creating-a-script-menu

math.randomseed(os.time())

PersonalMarkers.Marker = {
    activeMarkers = {},
    category = World.RootCategory:GetOrAddCategoryFromNamespace("personalMarkers.marker")
}

--- Sets the position of the marker to the current player position.
--- @param marker Marker # The marker whose position should be set.
local function setMarkerPositionToCurrent(marker)
    local playerPosition = Mumble.PlayerCharacter.Position
    -- Z and Y don't need to be swapped, because they are already swapped by SetPos
    marker:SetPos(playerPosition.X, playerPosition.Y, playerPosition.Z)
end

---Applies a random tint color to the marker.
---@param marker Marker # The marker whose tint color should be randomly set.
local function applyRandomTint(marker)
    local r = math.random(0, 255)
    local g = math.random(0, 255)
    local b = math.random(0, 255)

    marker.Tint = I:Color(r, g, b, 255)
end

---Makes the marker visible, if the mapId of the marker is the same as the current mapId.
---@param marker Marker
local function setVisibilityBasedOnMapId(marker)
    local visible = (marker.MapId == Mumble.CurrentMap.Id)

    marker.MapVisibility = visible
    marker.InGameVisibility = visible
    marker.MiniMapVisibility = visible
end

---Creates a marker with the provided mapId, position and tint.
---@param mapId integer
---@param position Vector3
---@param tint Color
---@return Marker
local function createMarker(mapId, position, tint)
    local new_marker_attr = {
        type = "personalMarkers.marker",
        Category = PersonalMarkers.Marker.category,
        xpos = position.X,
        ypos = position.Z, -- TODO: check if this needs to be flipped
        zpos = position.Y,
        MapId = mapId,
        ScaleOnMapWithZoom = false,
        mapDisplaySize = 32
    }

    local newMarker = Pack:CreateMarker(new_marker_attr)
    newMarker:SetTexture(1234928)
    newMarker.Tint = tint
    setVisibilityBasedOnMapId(newMarker)
    table.insert(PersonalMarkers.Marker.activeMarkers, newMarker)

    return newMarker
end

---Creates a marker at the current player position with a random tint.
---@return Marker
local function createMarkerAtCurrentPosition()
    local marker = createMarker(Mumble.CurrentMap.Id, Mumble.PlayerCharacter.Position, I:Color(255, 255, 255, 255))
    applyRandomTint(marker)
    return marker
end

---Updates the marker corresponding to the index or adds a new marker, if none with the
---index exists.
---@param index integer # 1-indexed
local function addOrUpdateMarker(index)
    --- @type Marker?
    local existingMarker = PersonalMarkers.Marker.activeMarkers[index]

    if existingMarker then
        setMarkerPositionToCurrent(existingMarker)
        setVisibilityBasedOnMapId(existingMarker)
    else
        createMarkerAtCurrentPosition()
    end

    PM_StoreMarkerStates(PersonalMarkers.Marker.activeMarkers)
end

---Removes the marker corresponding to the index.
---@param index integer # 1-indexed
---@return Marker? # The removed marker or nil if none with the index exists.
local function removeMarker(index)
    --- @type Marker?
    local existingMarker = PersonalMarkers.Marker.activeMarkers[index]

    if existingMarker then
        table.remove(PersonalMarkers.Marker.activeMarkers, index)
        existingMarker:Remove()
    end

    return existingMarker
end

---Updates the storage with the current marker states.
local function updateStorage()
    PM_StoreMarkerStates(PersonalMarkers.Marker.activeMarkers)
end

---Creates a marker from the given markerInfo.
---@param markerInfo PM_MarkerInfo
---@return Marker
local function createMarkerFromMarkerInfo(markerInfo)
    return createMarker(markerInfo.MapId, markerInfo.Position, markerInfo.Tint)
end

---Creates markers from the given array of markerInfo.
---@param markerInfo PM_MarkerInfo[]
---@return Marker[]
local function createMarkersFromMarkerInfo(markerInfo)
    local markers = {}
    for i = 1, #markerInfo do
        table.insert(markers, createMarkerFromMarkerInfo(markerInfo[i]))
    end
    return markers
end

---Updates the marker with the given index or creates a new one if none exists.
---@param index integer # 1-indexed
function PM_AddOrUpdateMarker(index)
    addOrUpdateMarker(index)
    updateStorage()
end

---Adds a new marker.
function PM_AddMarker()
    createMarkerAtCurrentPosition()
    updateStorage()
end

---Removes the marker with the corresponding index.
---@param index integer # 1-indexed
---@return Marker? # The removed marker or nil if none with the given index exists.
function PM_RemoveMarker(index)
    local removedMarker = removeMarker(index)
    updateStorage()
    return removedMarker
end

---Creates the markers from storage.
---@return Marker[]
function PM_InitializeMarkerFromStorage()
    local storedInfo = PM_RetrieveMarkerStates()

    return createMarkersFromMarkerInfo(storedInfo)
end