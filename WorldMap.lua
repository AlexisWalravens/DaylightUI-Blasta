local ADDON, extras = ...
local DUI = DaylightUI
local searchKit
local search
local hookedMap
local levelOverlay

local function placeSearch(map)
    if not searchKit or not map:IsShown() then return end
    local nav = map.NavBar
    if not nav or not searchKit.ShellOf(nav) then return end
    if not search then
        for _, child in ipairs({ map:GetChildren() }) do
            if child.EditBox and RSSearchMixin and child.OnShow == RSSearchMixin.OnShow then
                search = child
                searchKit.Strip(child.EditBox)
                child.EditBox:SetTextInsets(8, 8, 0, 0)
                searchKit.EditBox(child.EditBox, map)
                break
            end
        end
    end
    if not search then return end
    local left, right = nav:GetLeft(), nav:GetRight()
    if not left or not right then return end
    local occupied = left
    for _, button in ipairs(nav.navList or {}) do
        if button:IsShown() then occupied = math.max(occupied, button:GetRight() or left) end
    end
    if nav.homeButton and nav.homeButton:IsShown() then
        occupied = math.max(occupied, nav.homeButton:GetRight() or left)
    end
    local width = math.min(175, right - occupied - 22)
    if width < 82 then
        search:SetSize(140, 22)
        search.EditBox:SetSize(140, 22)
        search:ClearAllPoints()
        search:SetPoint("TOP", map:GetCanvasContainer(), "TOP", 0, -8)
        return
    end
    search:SetSize(width, 22)
    search.EditBox:SetSize(width, 22)
    search:ClearAllPoints()
    search:SetPoint("RIGHT", nav, "RIGHT", -8, 0)
end

local levelKey = "mapZoneLevels"
local function levelsEnabled() return DUI:Get(ADDON, levelKey) ~= false end
extras.MapLevelsGroup = { label = "World Map", items = {
    { type = "toggle", key = levelKey, label = "Show zone level ranges",
        desc = "Show the level range below the hovered zone name on the world map." },
} }

local zonesByMap = {}
local lastProbe
-- Bumped when cached level sources or the text style change.
local levelRevision = 0
local finderRanges
local nextFinderScan = 0
local foreverLevelCap = 60

local function positiveLevel(value)
    return type(value) == "number" and not (issecretvalue and issecretvalue(value))
        and value > 0 and value or nil
end

local function playableRange(low, high)
    if positiveLevel(low) and positiveLevel(high) and high >= low and low <= foreverLevelCap then
        return low, math.min(high, foreverLevelCap)
    end
end

local function zoneLabel(text)
    if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) then return end
    local plain = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return (plain:gsub("%s+%(%d[%d%s–%-]*%)$", ""))
end

local function scanFinderRanges()
    local finder = C_LFGList
    if not (finder and finder.GetAvailableCategories and finder.GetAvailableActivities
        and finder.GetActivityInfoTable) then return end
    local now = GetTime()
    if now < nextFinderScan then return end
    nextFinderScan = now + 2
    local ok, categories = pcall(finder.GetAvailableCategories)
    if not ok or type(categories) ~= "table" then return end

    local ranges = {}
    for _, category in ipairs(categories) do
        local listed, activities = pcall(finder.GetAvailableActivities, category)
        if listed and type(activities) == "table" then
            for _, id in ipairs(activities) do
                local read, info = pcall(finder.GetActivityInfoTable, id)
                if read and type(info) == "table" then
                    local low, high = playableRange(info.minLevelSuggestion, info.maxLevelSuggestion)
                    if not low then low, high = playableRange(info.minLevel, info.maxLevel) end
                    local name = zoneLabel(info.fullName)
                    if not name or name == "" then name = zoneLabel(info.shortName) end
                    if name and name ~= "" and low then
                        local previous = ranges[name]
                        if previous == nil then
                            ranges[name] = { low, high }
                        elseif previous and (previous[1] ~= low or previous[2] ~= high) then
                            ranges[name] = false
                        end
                    end
                end
            end
        end
    end
    if next(ranges) then finderRanges = ranges end
end

local function getZoneLevels(info)
    if not info or not info.mapID then return end
    if C_Map.GetMapLevels then
        local low, high = playableRange(C_Map.GetMapLevels(info.mapID))
        if low then return low, high, "C_Map" end
    end
    if info.mapType ~= (Enum and Enum.UIMapType and Enum.UIMapType.Zone) then return end
    if not finderRanges then scanFinderRanges() end
    local range = finderRanges and finderRanges[info.name]
    if range then return range[1], range[2], "C_LFGList" end
end

-- The level range of the zone you're in (its Zone map, above any city or
-- cave map), for the zone title: low, high or nil.
function extras.CurrentZoneLevels()
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetMapInfo) then return end
    local id = C_Map.GetBestMapForUnit("player")
    local zoneType = Enum and Enum.UIMapType and Enum.UIMapType.Zone
    for _ = 1, 6 do
        local info = type(id) == "number" and C_Map.GetMapInfo(id)
        if not info then return end
        local low, high = getZoneLevels(info)
        if low then return low, high end
        if info.mapType == zoneType then return end
        id = info.parentMapID
    end
end

local function zoneAtCursor(map, nativeText)
    local id = map:GetMapID()
    if not id then return end
    local x, y = map:GetNormalizedCursorPosition()
    if not x or not y or x < 0 or y < 0 or x > 1 or y > 1 then return end
    local info = C_Map.GetMapInfoAtPosition and C_Map.GetMapInfoAtPosition(id, x, y)
    if (not info or info.mapID == id) and type(nativeText) == "string" and nativeText ~= ""
        and C_Map.GetMapChildrenInfo and Enum and Enum.UIMapType then
        if not zonesByMap[id] then
            local zones = {}
            for _, zone in ipairs(C_Map.GetMapChildrenInfo(id, Enum.UIMapType.Zone, true) or {}) do
                zones[zone.name] = zone
            end
            zonesByMap[id] = zones
        end
        info = zonesByMap[id][zoneLabel(nativeText)] or info
    end
    return info or C_Map.GetMapInfo(id)
end

local function findAreaLabel(frame, depth)
    for _, child in ipairs({ frame:GetChildren() }) do
        if child.Name and child.GetHighestPriorityLabelInfo then return child end
        if depth > 0 then
            local label = findAreaLabel(child, depth - 1)
            if label then return label end
        end
    end
end

local function attachLevels(map)
    if levelOverlay or not (C_Map and C_Map.GetMapInfo
        and map.GetMapID and map.GetNormalizedCursorPosition) then return end
    local canvas = map:GetCanvasContainer()
    local overlay = CreateFrame("Frame", nil, canvas)
    levelOverlay = overlay
    overlay:SetAllPoints(canvas)
    overlay:SetFrameStrata("HIGH")
    overlay:EnableMouse(false)
    local name = DUI.Style.Text(overlay, 18, "CENTER")
    name:SetPoint("TOP", overlay, "TOP", 0, -12)
    local range = DUI.Style.Text(overlay, 13, "CENTER")
    range:SetShadowOffset(1, -1)
    local native = findAreaLabel(map, 2)
    local function hide()
        name:Hide()
        range:Hide()
    end
    local elapsed = 0
    -- The zone lookup allocates and repaints text. Skip it while the cursor,
    -- map, native label and player level are the same as on the last probe.
    local probe = {}
    lastProbe = probe
    local seenMap, seenX, seenY, seenText, seenLevel, seenRevision
    overlay:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed < 0.08 then return end
        elapsed = 0
        if not canvas:IsMouseOver() then
            seenMap = nil
            return hide()
        end
        local nativeText = native and native.Name:IsVisible() and native.Name:GetText()
        if issecretvalue and issecretvalue(nativeText) then nativeText = nil end
        local mapID = map:GetMapID()
        local x, y = map:GetNormalizedCursorPosition()
        local level = UnitLevel("player")
        if issecretvalue and (issecretvalue(x) or issecretvalue(y) or issecretvalue(level)) then
            x, y, level = nil, nil, nil
        end
        if seenMap ~= nil and mapID == seenMap and x == seenX and y == seenY and nativeText == seenText
            and level == seenLevel and seenRevision == levelRevision then return end
        seenMap, seenX, seenY, seenText, seenLevel, seenRevision = mapID or false, x, y, nativeText, level, levelRevision
        local info = zoneAtCursor(map, nativeText)
        probe.map, probe.name, probe.id = mapID, nativeText, info and info.mapID
        if not info or not info.mapID or not info.name then return hide() end
        local low, high = getZoneLevels(info)
        if not low then
            -- Finder ranges can arrive later. Look again on the next probe.
            seenMap = nil
            return hide()
        end
        if type(level) ~= "number" or level <= 0 then return hide() end
        local color = level < low and (low - level >= 5 and "BAD" or "WARN")
            or level <= high and "WARN" or level - high <= 5 and "GOOD" or "OFF"
        local nativeName = zoneLabel(nativeText) == info.name
        if nativeName then
            -- Move the native inline range into the separate line.
            if nativeText ~= info.name then native.Name:SetText(info.name) end
            name:Hide()
        elseif nativeText and nativeText ~= "" then
            return hide()
        else
            name:SetText(info.name)
            name:Show()
        end
        local anchor = nativeName and native.Name or name
        if range.anchor ~= anchor then
            range.anchor = anchor
            range:ClearAllPoints()
            range:SetPoint("TOP", anchor, "BOTTOM", 0, -2)
        end
        local text = low == high and tostring(low) or ("%d–%d"):format(low, high)
        range:SetText(DUI.L["Level %s"]:format(text))
        DUI.Style.InkText(range, color)
        range:Show()
    end)
    hide()
end

if DUI.RegisterCommand then
    DUI.RegisterCommand("blastamapcheck", function(arg)
        local id = tonumber(arg) or (lastProbe and lastProbe.id)
        local info = id and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(id)
        local low, high, source = getZoneLevels(info)
        DUI.Print(("Blasta map: enabled=%s, overlay=%s, map=%s, hover=%s, zoneID=%s, levels=%s–%s, source=%s"):format(
            tostring(levelsEnabled()), tostring(levelOverlay ~= nil), tostring(lastProbe and lastProbe.map),
            tostring(lastProbe and lastProbe.name), tostring(id), tostring(low), tostring(high), source or "none"))
    end, "/dui blastamapcheck [mapID]")
end

local function setup()
    local map = WorldMapFrame
    if not (map and map.GetCanvasContainer and map:GetCanvasContainer()) then return end
    if hookedMap ~= map then
        hookedMap = map
        map:HookScript("OnShow", function() C_Timer.After(0, setup) end)
        map:HookScript("OnSizeChanged", function() C_Timer.After(0, setup) end)
    end
    local enabled = levelsEnabled()
    if enabled then attachLevels(map) end
    if levelOverlay then levelOverlay:SetShown(enabled) end
    placeSearch(map)
end

if type(NavBar_AddButton) == "function" then
    hooksecurefunc("NavBar_AddButton", function(nav)
        if WorldMapFrame and nav == WorldMapFrame.NavBar then C_Timer.After(0, setup) end
    end)
end

function extras.StyleRareScannerMap(kit)
    searchKit = kit
    setup()
end

DUI.On("Login", setup)
DUI.RegisterEvent("LFG_LIST_AVAILABILITY_UPDATE", function()
    finderRanges = nil
    nextFinderScan = 0
    levelRevision = levelRevision + 1
end)
DUI.On("StyleChanged", function() levelRevision = levelRevision + 1 end)
DUI.RegisterEvent("ADDON_LOADED", function(_, name)
    if name == "Blizzard_WorldMap" or name == "RareScanner" then C_Timer.After(0, setup) end
end)
if EventRegistry then
    EventRegistry:RegisterCallback("MapCanvas.MapSet", function() C_Timer.After(0, setup) end, extras)
end

DUI.On("SettingChanged", function(scope, key)
    if scope == ADDON and key == levelKey then setup() end
end)
