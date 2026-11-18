-- SPDX-License-Identifier: GPL-3.0-or-later
-- "Blasta Elegant" for RestedXP Guides' guide window (its V1 window), on top of
-- DaylightUI's RestedXP skin (DaylightUI_Skins, Packs/Addons/RXPGuides.lua):
--
--   no window     header, step list and footer have no box or background at
--                 all, like the current steps above them: a thin accent line
--                 under the header and a faint one over the footer part them,
--                 and every text has a shadow so it reads over the world
--   header        no RestedXP logo or class badge; the guide name centered, white
--   step list     no box per step: plain lines with a faint rule between them and
--                 an accent bar beside the steps in play
--   current steps no box at all, like DaylightUI's quest tracker: the "Step 9"
--                 title in the accent over a faint rule, shadowed text below
--
-- RestedXP sets its backdrops again on every guide load and hover, so each list
-- row gets its backdrop calls switched off once.
local ADDON, extras = ...
local DUI = DaylightUI
local skins = extras.Compatible("Skins")
local mod = DUI:GetModule("Skins")
if not (skins and mod and DUI.Skins and DUI.Skins.Register and DUI.Skins.Safe and DUI.Style) then return end

local Style = DUI.Style
local KEY = "addonSkins.rxpElegant"

local function on()
    local db = mod.db and mod.db.addonSkins
    return not (type(db) == "table" and db.rxpElegant == false)
end

if mod.defaults and type(mod.defaults.addonSkins) == "table" then mod.defaults.addonSkins.rxpElegant = true end
if extras.AddSetting then
    extras.AddSetting(mod, "addonSkins.rxp", {
        type = "toggle", key = KEY, label = "RestedXP: Blasta Elegant", reload = true,
        desc = "A lighter look for the RestedXP guide window: no boxes or background, just thin lines between header, steps and footer, an accent bar beside the current steps, and no logo.",
        disabled = function(get) return get("addonSkins.rxp") == false end,
        hidden = function()
            return not (C_AddOns and C_AddOns.DoesAddOnExist and C_AddOns.DoesAddOnExist("RXPGuides"))
        end,
    })
end

local function isTable(x) return type(x) == "table" end
local function nop() end

-- A DaylightUI border made invisible for good. A window's is a frame of its own;
-- a "lite" one (rows, tabs) is four edges and a background on the frame itself,
-- which DaylightUI recolors on hover and restyle, so the textures' own alpha is
-- what keeps them hidden.
local function vanish(s)
    if not isTable(s) then return end
    if s.lite then
        for _, e in ipairs(s.edges or {}) do e:SetAlpha(0) end
        if s.bg then s.bg:SetAlpha(0) end
    elseif s.SetAlpha then
        s:SetAlpha(0)
    end
end

local function unbox(Kit, frame)
    if not isTable(frame) then return end
    vanish(Kit.ShellOf and Kit.ShellOf(frame) or Style.GetShell(frame))
end


-- A 1 px line. White to start with: the accent is a gradient over it
-- (Style.PaintAccent), which shows nothing on an empty texture.
local function rule(parent, layer)
    local t = parent:CreateTexture(nil, layer or "ARTWORK")
    t:SetHeight(1)
    t:SetColorTexture(1, 1, 1, 1)
    return t
end

local function shadow(fs)
    if isTable(fs) and fs.SetShadowOffset then
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 1)
    end
end

local function v2On()
    local RXP = _G.RXP
    local v2 = RXP and RXP.v2
    return isTable(v2) and type(v2.IsGuideWindowEnabled) == "function" and v2:IsGuideWindowEnabled() == true
end

-- ---------------------------------------------------------------------
-- The window
-- ---------------------------------------------------------------------

local headRule, footRule, stepsRule

local function window(Kit)
    local f = _G.RXPFrame
    local head, foot = f.GuideName or _G.RXPFrameGuideName, f.Footer
    if not (isTable(head) and isTable(foot) and isTable(f.BottomFrame)) then return end
    if not headRule then
        headRule = rule(head, "OVERLAY")
        headRule:SetPoint("BOTTOMLEFT", head, "BOTTOMLEFT", 10, 0)
        headRule:SetPoint("BOTTOMRIGHT", head, "BOTTOMRIGHT", -10, 0)
        -- Under the current steps, between them and the guide.
        local cur = f.CurrentStepFrame
        if isTable(cur) and cur.CreateTexture then
            stepsRule = rule(cur, "ARTWORK")
            stepsRule:SetPoint("TOPLEFT", cur, "BOTTOMLEFT", 6, -4)
            stepsRule:SetPoint("TOPRIGHT", cur, "BOTTOMRIGHT", -6, -4)
        end
        footRule = rule(foot, "OVERLAY")
        footRule:SetPoint("TOPLEFT", foot, "TOPLEFT", 10, 0)
        footRule:SetPoint("TOPRIGHT", foot, "TOPRIGHT", -10, 0)
    end
    for _, part in ipairs({ f.BottomFrame, head, foot }) do
        unbox(Kit, part)
        if part.ClearBackdrop then part:ClearBackdrop() end
    end
    Style.PaintAccent(headRule, 0.8)
    local label = Style.INK.LABEL
    footRule:SetColorTexture(label[1], label[2], label[3], 0.25)
    if stepsRule then stepsRule:SetColorTexture(label[1], label[2], label[3], 0.35) end
    -- Header: no logo, no class badge, the name across the full width.
    Kit.Hide(head.icon)
    Kit.Hide(head.classIcon)
    Kit.Hide(head.bg)
    Kit.Hide(foot.bg)
    if head.text then
        head.text:ClearAllPoints()
        head.text:SetPoint("LEFT", head, "LEFT", 10, 0)
        head.text:SetPoint("RIGHT", head, "RIGHT", -10, 0)
        Kit.Font(head.text)
        Kit.Light(head.text, Style.INK.VALUE)
        shadow(head.text)
    end
    if foot.text then
        Kit.Font(foot.text)
        Kit.Light(foot.text, label)
        shadow(foot.text)
    end
end

-- ---------------------------------------------------------------------
-- Step list rows
-- ---------------------------------------------------------------------

local dressed = setmetatable({}, { __mode = "k" })

local function paintRow(row)
    local d = dressed[row]
    if not d then return end
    local step = row.step
    local current = isTable(step) and step.active == true
    d.bar:SetShown(current)
    if current then Style.PaintAccent(d.bar, 1) end
end

local function dressRow(Kit, row)
    if not isTable(row) or not row.CreateTexture then return end
    local d = dressed[row]
    if not d then
        -- RestedXP sets these again on every load and hover: off for good.
        if row.ClearBackdrop then row:ClearBackdrop() end
        row.SetBackdrop, row.SetBackdropColor, row.SetBackdropBorderColor, row.ClearBackdrop = nop, nop, nop, nop
        d = {}
        local label = Style.INK.LABEL
        d.rule = rule(row, "BACKGROUND")
        d.rule:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 4, -2)
        d.rule:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, -2)
        d.rule:SetColorTexture(label[1], label[2], label[3], 0.12)
        d.bar = row:CreateTexture(nil, "OVERLAY")
        d.bar:SetWidth(2)
        d.bar:SetColorTexture(1, 1, 1, 1)
        d.bar:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -3)
        d.bar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 1, 1)
        d.bar:Hide()
        dressed[row] = d
    end
    -- DaylightUI's row box; its hover wash stays.
    local r = Kit.RowOf and Kit.RowOf(row)
    if isTable(r) then vanish(r.shell) end
    -- Room for the bar: RestedXP puts the text at the row's very left on each load.
    local text = row.text
    if isTable(text) and text.GetPoint and isTable(row.number) then
        local point, _, _, x = text:GetPoint(1)
        if point ~= "TOPLEFT" or x ~= 8 then
            text:ClearAllPoints()
            text:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -5)
            text:SetPoint("RIGHT", row.number, "LEFT", 0, 0)
        end
    end
    if isTable(row.number) and isTable(row.number.text) then
        Kit.Font(row.number.text)
        Kit.Light(row.number.text, Style.INK.LABEL)
        shadow(row.number.text)
    end
    shadow(row.text)
    paintRow(row)
end

local function rows(Kit)
    local f = _G.RXPFrame
    local child = isTable(f) and f.ScrollChild
    for _, row in pairs(isTable(child) and child.framePool or {}) do dressRow(Kit, row) end
end

-- ---------------------------------------------------------------------
-- Current step boxes and the item / target boxes: their tab is accent text
-- ---------------------------------------------------------------------

local function tab(Kit, frame, fs)
    if not isTable(frame) then return end
    unbox(Kit, frame)
    if frame.ClearBackdrop then frame:ClearBackdrop() end
    if isTable(fs) and fs.GetObjectType and fs:GetObjectType() == "FontString" then
        Kit.Font(fs)
        Style.InkText(fs, "pop")
    end
end

local stepRules = setmetatable({}, { __mode = "k" })


local function steps(Kit)
    local f = _G.RXPFrame
    local cur = isTable(f) and f.CurrentStepFrame
    for _, stepframe in pairs(isTable(cur) and cur.framePool or {}) do
        if isTable(stepframe) then
            unbox(Kit, stepframe)
            if stepframe.ClearBackdrop then stepframe:ClearBackdrop() end
            if isTable(stepframe.number) then
                tab(Kit, stepframe.number, stepframe.number.text)
                shadow(stepframe.number.text)
                local line = stepRules[stepframe]
                if not line then
                    line = rule(stepframe, "ARTWORK")
                    line:SetPoint("LEFT", stepframe.number, "RIGHT", 4, 0)
                    line:SetPoint("RIGHT", stepframe, "RIGHT", -6, 0)
                    stepRules[stepframe] = line
                end
                local label = Style.INK.LABEL
                line:SetColorTexture(label[1], label[2], label[3], 0.3)
            end
            for _, el in pairs(stepframe.elements or {}) do
                if isTable(el) then shadow(el.text) end
            end
        end
    end
end

local function boxes(Kit)
    for _, name in ipairs({ "RXPItemFrame", "RXPTargetFrame" }) do
        local title = _G[name .. "_title"]
        if isTable(title) then
            local fs
            for _, r in ipairs({ title:GetRegions() }) do
                if r.GetObjectType and r:GetObjectType() == "FontString" then fs = r break end
            end
            tab(Kit, title, fs)
            shadow(fs)
        end
        unbox(Kit, _G[name])
    end
end

local function all(Kit)
    if v2On() then return end
    window(Kit)
    rows(Kit)
    steps(Kit)
    boxes(Kit)
end

DUI.Skins.Register({ key = "blastaRxpElegant", switch = "rxp", addon = "RXPGuides",
    label = "RestedXP Guides (Blasta Elegant)", thirdParty = true, apply = function(Kit, def)
        if not on() then return end
        local f = _G.RXPFrame
        if not isTable(f) or not isTable(f.CurrentStepFrame) then return false end
        local Safe = DUI.Skins.Safe
        -- After DaylightUI's own hooks (registered first), so its boxes are
        -- there to hide.
        local again = Safe(def, function() all(Kit) end)
        if type(f.UpdateVisuals) == "function" then hooksecurefunc(f, "UpdateVisuals", again) end
        if type(f.UpdateScrollBar) == "function" then hooksecurefunc(f, "UpdateScrollBar", again) end
        if type(f.CurrentStepFrame.UpdateText) == "function" then
            hooksecurefunc(f.CurrentStepFrame, "UpdateText", Safe(def, function() steps(Kit); rows(Kit) end))
        end
        if isTable(f.BottomFrame) and type(f.BottomFrame.UpdateFrame) == "function" then
            hooksecurefunc(f.BottomFrame, "UpdateFrame", Safe(def, function() rows(Kit) end))
        end
        f:HookScript("OnShow", again)
        DUI.On("StyleChanged", again)
        all(Kit)
    end })
