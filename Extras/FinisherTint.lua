-- SPDX-License-Identifier: GPL-3.0-or-later
local _, extras = ...
local DUI = DaylightUI
local dots = DUI.Dots
local unitFrames = DUI:GetModule("UnitFrames")
if not (unitFrames and unitFrames.defaults and unitFrames.defaults.colors
    and extras.FindSetting(unitFrames, "colors.dotTint")
    and dots and dots.Paint and dots.LayoutVeil and dots.NewVeil and dots.TintVeil
    and type(dots.LeftByType) == "function") then return end

local toggleKey, colorKey = "colors.blastaFinisherTintEnabled", "colors.blastaFinisherTint"
local defaultColor = { 0.85, 0.26, 0.12, 0.75 }
local label, colorLabel = "Separate finisher damage color", "Finisher damage color"
local desc = "Gives the remaining damage from combo-point finishers a separate color on the target and enemy nameplates."
unitFrames.defaults.colors.blastaFinisherTintEnabled = false
unitFrames.defaults.colors.blastaFinisherTint = defaultColor
extras.German[label] = "Eigene Farbe für Finisher-Schaden"
extras.German[colorLabel] = "Farbe für Finisher-Schaden"
extras.German[desc] = "Färbt den verbleibenden Schaden von Combopunkt-Finishern am Zielrahmen und auf gegnerischen Namensplaketten separat ein."
local destination = { page = "Auras", tab = "General", label = "Finisher damage" }
extras.German[destination.label] = "Finisher-Schaden"
extras.AddSetting(unitFrames, "colors.dotTint", {
    type = "toggle", key = toggleKey, label = label, desc = desc, blastaDestination = destination,
})
extras.AddSetting(unitFrames, toggleKey, {
    type = "color", key = colorKey, label = colorLabel, alpha = true, blastaDestination = destination,
    disabled = function(get) return get(toggleKey) ~= true end,
})

local function enabled()
    return DUI:Get("UnitFrames", toggleKey) == true
end

local states = setmetatable({}, { __mode = "k" })
local layout, paint = dots.LayoutVeil, dots.Paint
function dots.LayoutVeil(veil, health, growLeft)
    layout(veil, health, growLeft)
    local state = states[veil]
    if not state then
        state = {}
        states[veil] = state
    end
    state.health, state.growLeft, state.linked = health, growLeft, false
    if state.extra then layout(state.extra, health, growLeft) end
end

-- The finisher segment of a veil, for the nameplate shape's clipping.
function extras.FinisherVeil(veil)
    local state = veil and states[veil]
    return state and state.extra
end

local function restore(veil, state)
    if not (state and state.extra) then return end
    state.extra:Hide()
    if state.linked then layout(veil, state.health, state.growLeft) end
    veil.bar:Show()
    state.linked = false
end

function dots.Paint(unit, veil, skull)
    local state = veil and states[veil]
    local total, finisher
    if state and unit and enabled() then total, finisher = dots.LeftByType(unit) end
    if not total or not finisher or finisher <= 0 then
        restore(veil, state)
        return paint(unit, veil, skull)
    end
    if not paint(unit, nil, skull) then
        restore(veil, state)
        veil:Hide()
        return false
    end

    local normal = total - finisher
    local extra = state.extra
    if not extra then
        extra = dots.NewVeil(state.health, 1)
        extra:SetParent(veil)
        extra:SetFrameLevel(veil:GetFrameLevel() + 1)
        state.extra = extra
        layout(extra, state.health, state.growLeft)
    end
    if extras.ClipPlateVeil then extras.ClipPlateVeil(state.health, extra) end
    local max = UnitHealthMax(unit)
    dots.TintVeil(extra, DUI:Get("UnitFrames", colorKey) or defaultColor)
    extra.bar:SetMinMaxValues(0, max)
    extra.bar:SetValue(finisher)
    extra.edge:SetShown(normal <= 0)
    extra:Show()
    if normal > 0 then
        if not state.linked then
            local lead = state.growLeft and "LEFT" or "RIGHT"
            local inner = state.growLeft and "RIGHT" or "LEFT"
            local fill = extra.bar:GetStatusBarTexture()
            veil.bar:ClearAllPoints()
            veil.bar:SetPoint("TOP" .. lead, fill, "TOP" .. inner)
            veil.bar:SetPoint("BOTTOM" .. lead, fill, "BOTTOM" .. inner)
            state.linked = true
        end
        veil.bar:SetMinMaxValues(0, max)
        veil.bar:SetValue(normal)
    end
    veil.bar:SetShown(normal > 0)
    veil:Show()
    return true
end

DUI.On("SettingChanged", function(scope, key)
    if scope == "UnitFrames" and (key == toggleKey or key == colorKey) then DUI.Fire("DotsChanged") end
end)
