PersonalMarkers = {
    Version = "0.1.0"
}
Debug:Print("Loading PersonalMarkers Version: " .. PersonalMarkers.Version)

Pack:Require("Data/PersonalMarkers/Scripts/Types/markerInfo.lua")

-- requires markerInfo
Pack:Require("Data/PersonalMarkers/Scripts/storage.lua")

-- requires storage
Pack:Require("Data/PersonalMarkers/Scripts/marker.lua")
-- requires marker
Pack:Require("Data/PersonalMarkers/Scripts/menu.lua")

-- TODO
-- - proper menu naming for markers

-- Wishlist
-- - proper color palettes