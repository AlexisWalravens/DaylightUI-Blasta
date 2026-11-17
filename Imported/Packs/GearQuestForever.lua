local _, ns = ...
if not ns.ok then return end

local KEY = "GearQuestForever"
local Style = DaylightUI.Style
local windowArt = {
    "blackBg", "NineSlice", "gqOuterBorder", "gqHeaderBar", "gqHeaderLine", "gqLogScene", "gqLogSceneShade",
    "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
    "TopEdge", "BottomEdge", "LeftEdge", "RightEdge",
}
local panelFields = { "listInset", "detailBg", "simClassInset", "simDetail", "settingsList", "settingsDetail" }
local tabs = { "tabActive", "tabCompleted", "tabRemoved", "tabTracked", "tabLog", "tabLookup", "tabSimulator", "tabSettings" }
local edges = { "gqEdgeTop", "gqEdgeBottom", "gqEdgeLeft", "gqEdgeRight" }

local function removeWindowArt(frame)
    for _, field in ipairs(windowArt) do ns.Kill(frame[field]) end
end

local function paintTab(tab, selected)
    local shade = selected and 0.13 or 0.055
    if tab.GetBackdrop and tab:GetBackdrop() then
        tab:SetBackdropColor(shade, shade, shade + 0.01, 0.94)
        tab:SetBackdropBorderColor(0.55, 0.52, 0.47, selected and 0.65 or 0.25)
    end
    if tab.gqFill then tab.gqFill:SetColorTexture(shade, shade, shade + 0.01, 0.94) end
    for _, key in ipairs(edges) do
        if tab[key] then tab[key]:SetColorTexture(0.55, 0.52, 0.47, selected and 0.65 or 0.25) end
    end
    ns.Kill(tab.gqOpenCover)
    local label = tab:GetFontString()
    if label then Style.InkText(label, selected and "TITLE" or "LABEL") end
    if tab.gqIcon then tab.gqIcon:SetVertexColor(0.86, 0.84, 0.79, selected and 1 or 0.65) end
end

local function paintPanels(frame)
    removeWindowArt(frame)
    local title = frame.TitleText or (frame.TitleContainer and frame.TitleContainer.TitleText)
    if title and title.SetTextColor then Style.InkText(title, "TITLE") end
    for _, field in ipairs(panelFields) do
        local pane = frame[field]
        if pane then
            ns.Kill(pane.gqParchment)
            ns.Kill(pane.blackBg)
            if pane.GetBackdrop and pane:GetBackdrop() then ns.NoBackdrop(pane) end
            if ns.Once(pane) then ns.Shell(pane, { flat = true, noBevel = true, borderPx = 1 }, KEY) end
        end
    end
end

local function lightenText(frame)
    if not frame or not frame:IsVisible() then return end
    for _, region in ipairs({ frame:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            local r, g, b, a = region:GetTextColor()
            if r <= 0.42 and g <= 0.37 and b <= 0.26 then Style.InkText(region, "TEXT", a) end
        end
    end
    for _, child in ipairs({ frame:GetChildren() }) do lightenText(child) end
end

local function dressLog(frame)
    if not ns.Usable(frame) then return end
    ns.PlainWindow(frame, { fonts = true }, KEY)
    ns.HeaderLine(frame)
    paintPanels(frame)
end

ns.Pack(KEY, "GearQuest Forever", function()
    local gear = _G.GearQuest
    if not gear then return end
    local log, tracker = gear.Log, gear.Tracker
    if log and type(log.Init) == "function" and type(log.Show) == "function" then
        local function dress(self) dressLog(self.frame) end
        local queued
        local function paint(self)
            local frame = self.frame
            if queued or not frame or not frame:IsVisible() then return end
            queued = true
            C_Timer.After(0, function()
                queued = nil
                if not frame:IsVisible() then return end
                paintPanels(frame)
                local category = self.GetListTab and self:GetListTab()
                local page = self.GetPageTab and self:GetPageTab()
                local selection = {
                    tabActive = category == "active", tabCompleted = category == "completed",
                    tabRemoved = category == "removed", tabTracked = category == "tracked",
                    tabLog = page == "log", tabLookup = page == "lookup",
                    tabSimulator = page == "simulator", tabSettings = page == "settings",
                }
                for _, field in ipairs(tabs) do
                    if frame[field] then paintTab(frame[field], selection[field]) end
                end
                lightenText(frame.detailChild)
                lightenText(frame.settingsDetail)
                lightenText(frame.simDetail)
            end)
        end
        if type(log.LogSceneTexture) == "function" then log.LogSceneTexture = function() end end
        hooksecurefunc(log, "Init", dress)
        hooksecurefunc(log, "Show", function(self) dress(self); paint(self) end)
        for _, method in ipairs({ "Refresh", "ApplyPageTab", "UpdateTabVisuals", "UpdatePageTabVisuals",
            "RefreshSettings", "RefreshSimulator", "RefreshLookup", "ShowLookupDetail", "ApplyEntryDetail",
            "ClearDetail", "UpdateDetailReward", "UpdateLogScene" }) do
            if type(log[method]) == "function" then hooksecurefunc(log, method, paint) end
        end
        dress(log)
        paint(log)
    end
    if tracker and type(tracker.Init) == "function" then
        local function dress(self)
            local frame = self.frame
            if ns.Usable(frame) and ns.Once(frame) then
                ns.Shell(frame, { window = true }, KEY)
                ns.DressOnShow(frame, { fonts = true }, nil, KEY)
            end
        end
        hooksecurefunc(tracker, "Init", dress)
        dress(tracker)
    end
end, { window = true, controls = true, text = true, shadow = true, font = "daylight" })
