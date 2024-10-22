PersonalMarkers.Menu = {
    rootMenu = nil,
    markerMenues = {},
    addMenu = nil,
    menuParents = {},
    menuChildren = {}
}

---Clears the parent of the given menu.
---Will also clear the child of the parent if clearChild is true.
---@param menu Menu # The menu whose parent should be cleared.
---@param clearChild boolean? # Whether the child entry of the parent should also be cleared. Default: true
local function clearMenuParent(menu, clearChild) end;

---Sets the menu <-> parent relationship.
---Does nothing if either menu or parent are nil.
---@param menu Menu
---@param parent Menu
local function setMenuParent(menu, parent)
    if menu ~= nil and parent ~= nil then
        clearMenuParent(menu)

        PersonalMarkers.Menu.menuParents[menu] = parent

        PersonalMarkers.Menu.menuChildren[parent] = PersonalMarkers.Menu.menuChildren[parent] or {}
        PersonalMarkers.Menu.menuChildren[parent][menu] = menu
    end
end

---Clears the child for the given parent menu.
---Will also clear the parent of the child if clearParent is true.
---@param parent Menu # The parent whose child should be cleared.
---@param child Menu # The child that should be cleared.
---@param clearParent boolean? # Whether the parent entry of the child should also be cleared. Default: true
local function clearMenuChild(parent, child, clearParent) end;

---Clears the parent of the given menu.
---Will also clear the child of the parent if clearChild is true.
---@param menu Menu # The menu whose parent should be cleared.
---@param clearChild boolean? # Whether the child entry of the parent should also be cleared. Default: true
clearMenuParent = function(menu, clearChild)
    clearChild = clearChild or true
    if menu == nil then
        return
    end

    local parent = PersonalMarkers.Menu.menuParents[menu]

    if parent == nil then
        return
    end
    PersonalMarkers.Menu.menuParents[menu] = nil
    
    if parent ~= nil and clearChild then
        clearMenuChild(parent, menu, false)
    end
end

---Returns the parent of the given menu or nil if none is set.
---@param menu Menu # The menu whose parent should be returned.
---@return Menu? # The parent of the given menu or nil if none is set.
local function getMenuParent(menu)
    if menu ~= nil then
        return PersonalMarkers.Menu.menuParents[menu]
    end
end

---Clears the child for the given parent menu.
---Will also clear the parent of the child if clearParent is true.
---@param parent Menu # The parent whose child should be cleared.
---@param child Menu # The child that should be cleared.
---@param clearParent boolean? # Whether the parent entry of the child should also be cleared. Default: true
clearMenuChild = function(parent, child, clearParent)
    clearParent = clearParent or true
    if parent ~= nil and child ~= nil then
        local children = PersonalMarkers.Menu.menuChildren[parent]
        if children then
            children[child] = nil
        end

        if clearParent then
            clearMenuParent(child, false)
        end
    end
end

---Clears all children for the given parent.
---Will also clear the parent of each child.
---@param parent Menu
local function clearMenuChildren(parent)
    if parent ~= nil then
        local children = PersonalMarkers.Menu.menuChildren[parent]
        if (children == nil) then
            return
        end

        PersonalMarkers.Menu.menuChildren[parent] = nil

        for key, child in pairs(children) do
            clearMenuParent(child, false)
        end
    end
end

---Returns the index of the given menu or nil if it's not indexed.
---@param menu Menu # The menu whose index should be returned.
---@return integer? # The index of the given menu or nil if it's not indexed.
local function getMenuIndex(menu)
    if menu == nil then
        Debug:Error("Unable to get menu index, because index is nil.")
        return nil
    end

    for index, element in ipairs(PersonalMarkers.Menu.markerMenues) do
        if element == menu then
            return index
        end
    end
    return nil
end

---Removes the menu.
---Does not remove the associated marker!
---@param menu Menu # The menu that should be removed.
local function removeMarkerMenu(menu)
    local menuIndex = getMenuIndex(menu)
    PersonalMarkers.Menu.rootMenu:Remove(menu)

    if menuIndex then
        table.remove(PersonalMarkers.Menu.markerMenues, menuIndex)
    end

    clearMenuParent(menu)
    clearMenuChildren(menu)
end

---Removes the marker and menu associated with the removeMenu.
---@param removeMenu Menu # The submenu (child) of the menu that should be removed.
local function removeMarker(removeMenu)
    local markerMenu = getMenuParent(removeMenu)
    if markerMenu == nil then
        Debug:Error("Unable to remove marker, because menu parent could not be determined")
        return
    end

    local menuIndex = getMenuIndex(markerMenu)

    if menuIndex then
        PM_RemoveMarker(menuIndex)
    end

    removeMarkerMenu(markerMenu)
end

---Returns the name for a marker menu based on the mapId and position.
---@param mapId integer? # The mapId. Will use the current mapId if nil.
---@param position Vector3? # The position. Will use the current position if nil.
---@return string # The name for a marker menu based on the current map and position.
local function getMarkerMenuName(mapId, position)
    if mapId == nil then
        mapId = Mumble.CurrentMap.Id
    end

    if position == nil then
        position = Mumble.PlayerCharacter.Position
    end
    
    local currentPositionString = position.X .. ", " .. position.Z .. ", " .. position.Y

    return mapId .. "@" .. currentPositionString
end

---Updates the marker and menu associated with the updateMenu to the current map and position.
---@param updateMenu Menu
local function updateMarker(updateMenu)
    local markerMenu = getMenuParent(updateMenu)
    if markerMenu == nil then
        Debug:Error("Unable to update marker, because menu parent could not be determined")
        return
    end

    local menuIndex = getMenuIndex(markerMenu)

    if menuIndex then
        PM_AddOrUpdateMarker(menuIndex)
        markerMenu.Name = getMarkerMenuName()
    end
end


---Adds a new marker menu with the given name.
---Does not add a marker!
---@param name string? # The name for the menu. Will generate a name based on the mapId and position if nil.
local function addMarkerMenu(name)
    if name == nil then
        name = getMarkerMenuName()
    end

    local markerMenu = PersonalMarkers.Menu.rootMenu:Add(name, nil)
    table.insert(PersonalMarkers.Menu.markerMenues, markerMenu)

    local updateSubmenu = markerMenu:Add("Update marker", updateMarker)
    local removeSubmenu = markerMenu:Add("Remove marker", removeMarker)

    setMenuParent(updateSubmenu, markerMenu)
    setMenuParent(removeSubmenu, markerMenu)
end

---Adds a marker and an associated menu.
---@param menu any # will be ignored.
local function addMarker(menu)
    PM_AddMarker()
    addMarkerMenu()
end

function PM_InitializeMenuAndMarkerFromStorage()
    local marker = PM_InitializeMarkerFromStorage()
    for i = 1, #marker do
        local currentMarker = marker[i]
        -- TODO: marker position already has y and z swapped, but getMarkerMenuName will swap them again
        addMarkerMenu(getMarkerMenuName(currentMarker.MapId, currentMarker.Position))
    end
    Debug:Print("Loaded "..#marker.." personal markers from storage.")
end

local rootMenu = Menu:Add("Personal Markers", nil)
PersonalMarkers.Menu.rootMenu = rootMenu

local addMenu = rootMenu:Add("Add Marker", addMarker, false, false, "This will spawn a personal marker on the player position.")
PersonalMarkers.Menu.addMenu = addMenu

PM_InitializeMenuAndMarkerFromStorage()