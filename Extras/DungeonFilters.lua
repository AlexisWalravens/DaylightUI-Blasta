-- SPDX-License-Identifier: GPL-3.0-or-later
local ADDON, extras = ...
local DUI = DaylightUI
local lfg = DUI.Lfg
local browse, data = lfg and lfg.Browse, lfg and lfg.Data
local win, widgets, style = DUI.Win, DUI.Widgets, DUI.Style
if not (browse and browse.Render and browse.PaintChips and data and data.Places
    and data.Groups and data.ActivityName and data.PlaystyleWord and data.PLAYSTYLES
    and win and win.Header and win.Feel and win.Feel.Slide and win.Feel.Settle
    and widgets and widgets.Input and widgets.RoleText and widgets.OpenMenu and widgets.CloseMenu
    and style and style.Shell and DUI.Motion and DUI.Motion.AlphaTo) then return end

local T = extras.Translate
local setting = "dungeonFinder"
local function enabled()
    return DUI:Get(ADDON, setting) == true
end

extras.DungeonFinderGroup = { label = "Blasta Dungeon Finder", items = {
    { type = "toggle", key = setting, label = "Blasta Dungeon Finder", reload = true,
        desc = "Enable the docked dungeon filters in DaylightUI's group finder.",
        get = enabled, set = function(value) return DUI:Set(ADDON, setting, value) end,
        default = function() return false end },
} }

local nativePlaystyle = data.PlaystyleWord
function data.PlaystyleWord(id)
    local native = nativePlaystyle(id)
    if native and id == 4 and (GetLocale() == "deDE" or extras.Language == "deDE") then
        return "Ziehhilfe"
    end
    return native
end

local listing = lfg.Listing
if listing and listing.Build and listing.Render then
    local function watchWidth(page)
        local lastWidth
        local pending
        page:HookScript("OnSizeChanged", function(_, newWidth)
            if type(newWidth) ~= "number" or pending or not page:IsVisible() or newWidth == lastWidth then return end
            local goal = page.win and page.win.goalW
            if goal and math.abs(newWidth - goal) > 0.5 then return end
            pending = true
            C_Timer.After(0, function()
                pending = false
                if not page:IsVisible() or lastWidth == page:GetWidth() then return end
                lastWidth = page:GetWidth()
                listing.Render(page)
                if listing.FitNote then listing.FitNote() end
            end)
        end)
    end
    if listing.page then watchWidth(listing.page) end
    hooksecurefunc(listing, "Build", watchWidth)
end
local dungeonCategory = GROUP_FINDER_CATEGORY_ID_DUNGEONS or 2
local roles = { "TANK", "HEALER", "DAMAGER" }
local roleLabels = { TANK = "Tank", HEALER = "Healer", DAMAGER = "Damage" }
local selectedRoles = {}
local dungeon, playstyle, drawer, activityButton, clickActivity
local opened, menuOpen, slideOffset = false, false, 0
local width, gap, inset = 276, 8, 14

local function hasRoles()
    return next(selectedRoles) ~= nil
end

local function matches(result)
    if dungeon and not tContains(result.acts, dungeon) then return false end
    if playstyle and result.style ~= data.PlaystyleWord(playstyle) then return false end
    if hasRoles() then
        if result.solo or result.delisted then return false end
        local _, free = data.Places(result)
        for role in pairs(selectedRoles) do
            if (free[role] or 0) > 0 then return true end
        end
        return false
    end
    return true
end

local function filterCount()
    return (dungeon and 1 or 0) + (hasRoles() and 1 or 0) + (playstyle and 1 or 0)
end

local function refresh()
    browse.open = nil
    browse.Render()
end

local function closeMenu()
    if menuOpen then widgets.CloseMenu() end
    menuOpen = false
end

local function closeDrawer(immediate)
    if not drawer or not opened then return end
    opened = false
    closeMenu()
    drawer.search:ClearFocus()
    if immediate then
        DUI.Motion.AlphaTo(drawer, 0, 0, true)
        drawer:Hide()
        win.Feel.Settle(drawer)
    else
        win.Feel.Slide(drawer, slideOffset)
        DUI.Motion.AlphaTo(drawer, 0, DUI.Motion.NORMAL, true)
    end
    if activityButton then activityButton.SetActive(filterCount() > 0) end
end

local function placeDrawer(page)
    local host = page.win or page:GetParent()
    local rootScale, scale = UIParent:GetEffectiveScale(), host:GetEffectiveScale()
    local ratio = scale / rootScale
    local left = (host:GetLeft() or 0) * ratio
    local right = UIParent:GetWidth() - (host:GetRight() or 0) * ratio
    local needed = (width + gap) * ratio
    local dockRight = right >= needed or right >= left
    slideOffset = dockRight and -36 or 36
    drawer:ClearAllPoints()
    if right < needed and left < needed then
        local side = dockRight and "TOPRIGHT" or "TOPLEFT"
        drawer:SetPoint(side, host, side, dockRight and -gap or gap, 0)
    elseif dockRight then
        drawer:SetPoint("TOPLEFT", host, "TOPRIGHT", gap, 0)
    else
        drawer:SetPoint("TOPRIGHT", host, "TOPLEFT", -gap, 0)
    end
end

local function dungeonMenu(owner)
    local query = drawer.search:GetText():lower()
    local ids, labels = { 0 }, { [0] = T("All dungeons") }
    for _, group in ipairs(data.Groups(dungeonCategory)) do
        for _, activity in ipairs(group.acts) do
            if activity.name:lower():find(query, 1, true) and not labels[activity.id] then
                ids[#ids + 1] = activity.id
                labels[activity.id] = activity.name
            end
        end
    end
    if #ids == 1 and query ~= "" then
        drawer.dungeon.text:SetText(T("No dungeons found"))
        return
    end
    drawer.search:ClearFocus()
    menuOpen = true
    widgets.OpenMenu(owner, ids, labels, dungeon or 0, function(id)
        menuOpen = false
        dungeon = id ~= 0 and id or nil
        drawer.search:SetText("")
        refresh()
    end, width - 2 * inset)
end

local function fullWidth(region, parent, y)
    region:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -y)
    region:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -inset, -y)
end

local function heading(parent, text, y)
    local label = style.Text(parent, style.SIZE.body, "LEFT")
    fullWidth(label, parent, y)
    label:SetText(T(text))
    style.InkText(label, "VALUE")
end

local function buildDrawer(page)
    local panel = CreateFrame("Frame", nil, page)
    panel:SetSize(width, 350)
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:Hide()
    style.Shell(panel, { window = "GroupFinder" })
    win.Header(panel, { compact = true, onClose = function() closeDrawer() end })
    panel.title:SetText(T("Dungeon filters"))

    heading(panel, "Dungeon", 44)
    panel.search = widgets.Input(panel, { search = true, hint = T("Search dungeons"), onChange = function()
        closeMenu()
        if panel.dungeon then panel.dungeon.text:SetText(dungeon and data.ActivityName(dungeon) or T("All dungeons")) end
        if panel.reset then panel.reset.SetOff(filterCount() == 0 and panel.search:GetText() == "") end
    end })
    fullWidth(panel.search, panel, 64)
    panel.dungeon = widgets.Button(panel, "", 24)
    fullWidth(panel.dungeon, panel, 95)
    panel.dungeon:SetScript("OnClick", dungeonMenu)
    panel.search:HookScript("OnEnterPressed", function() dungeonMenu(panel.dungeon) end)

    heading(panel, "Open roles", 132)
    panel.roles = {}
    local roleWidth = (width - 2 * inset - 8) / #roles
    for index, role in ipairs(roles) do
        local label = widgets.RoleText(role, 12) .. " " .. T(roleLabels[role])
        local button = widgets.Button(panel, label, 24)
        button:SetWidth(roleWidth)
        button:SetPoint("TOPLEFT", panel, "TOPLEFT", inset + (index - 1) * (roleWidth + 4), -152)
        button:SetScript("OnClick", function()
            selectedRoles[role] = not selectedRoles[role] or nil
            refresh()
        end)
        panel.roles[role] = button
    end

    heading(panel, "Playstyle", 189)
    panel.styles = {}
    local styleWidth = (width - 2 * inset - 4) / 2
    for index, id in ipairs(data.PLAYSTYLES) do
        local label = data.PlaystyleWord(id)
        local button = widgets.Button(panel, label, 24)
        button:SetWidth(styleWidth)
        button:SetPoint("TOPLEFT", panel, "TOPLEFT", inset + ((index - 1) % 2) * (styleWidth + 4),
            -209 - math.floor((index - 1) / 2) * 28)
        button:SetScript("OnClick", function()
            playstyle = playstyle ~= id and id or nil
            refresh()
        end)
        panel.styles[id] = button
    end
    local reset = widgets.Button(panel, T("Reset filters"), 24)
    fullWidth(reset, panel, 277)
    reset:SetScript("OnClick", function()
        dungeon, playstyle = nil, nil
        wipe(selectedRoles)
        panel.search:SetText("")
        refresh()
    end)
    panel.reset = reset
    panel.count = style.Text(panel, style.SIZE.body, "CENTER")
    fullWidth(panel.count, panel, 321)
    style.InkText(panel.count, "LABEL")
    page:HookScript("OnHide", function() closeDrawer(true) end)
    return panel
end

local function paintDrawer()
    if not drawer then return end
    drawer.dungeon.text:SetText(dungeon and data.ActivityName(dungeon) or T("All dungeons"))
    for role, button in pairs(drawer.roles) do button.SetActive(selectedRoles[role] == true) end
    for id, button in pairs(drawer.styles) do button.SetActive(playstyle == id) end
    drawer.reset.SetOff(filterCount() == 0 and drawer.search:GetText() == "")
end

local function toggleDrawer(page)
    if opened then return closeDrawer() end
    drawer = drawer or buildDrawer(page)
    win.Feel.Settle(drawer)
    drawer:Hide()
    placeDrawer(page)
    win.Feel.Slide(drawer, slideOffset)
    drawer:SetAlpha(0)
    drawer:Show()
    opened = true
    win.Feel.Slide(drawer, 0)
    DUI.Motion.AlphaTo(drawer, 1, DUI.Motion.NORMAL)
    browse.Render(page, true)
end

hooksecurefunc(browse, "PaintChips", function(page)
    if not enabled() then return closeDrawer(true) end
    page = page or browse.page
    if not page or not page.act then return end
    if activityButton ~= page.act then
        activityButton = page.act
        clickActivity = activityButton:GetScript("OnClick")
        activityButton:SetScript("OnClick", function(self, ...)
            if enabled() and browse.cat == dungeonCategory then toggleDrawer(page)
            elseif clickActivity then clickActivity(self, ...) end
        end)
    end
    if browse.cat ~= dungeonCategory then return closeDrawer(true) end
    local count = filterCount()
    activityButton.text:SetText(count == 0 and T("Filters") or T("Filters") .. " (" .. count .. ")")
    activityButton.FitWidth(86)
    activityButton.SetActive(opened or count > 0)
    paintDrawer()
end)

local render = browse.Render
function browse.Render(page, ...)
    if not enabled() or browse.cat ~= dungeonCategory then return render(page, ...) end
    page = page or browse.page
    if not page then return render(page, ...) end
    local active = filterCount() > 0
    if not active and not opened then return render(page, ...) end
    local original = browse.results
    local filtered, groups = {}, 0
    if not browse.searching then
        for _, result in ipairs(original or {}) do
            if not active or matches(result) then
                if active then filtered[#filtered + 1] = result end
                if not result.mine and not result.solo then groups = groups + 1 end
            end
        end
    end
    if active then browse.results = filtered end
    local ok, err = pcall(render, page, ...)
    if active and browse.results == filtered then browse.results = original end
    if not ok then error(err, 0) end
    if drawer then
        drawer.count:SetText(browse.searching and DUI.L["Searching..."] or T("%d groups found"):format(groups))
    end
    if active and #filtered == 0 and not browse.searching and not browse.failed and browse.searched then
        page.note:SetText(T("No groups match these filters"))
        page.note:Show()
    end
end
