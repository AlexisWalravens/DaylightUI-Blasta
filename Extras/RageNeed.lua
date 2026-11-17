-- SPDX-License-Identifier: GPL-3.0-or-later
local ADDON, extras = ...
-- /blastarage is registered first so it answers even when the feature
-- below can't start on this client; inactive says why.
local inactive, diagnose = "the file stopped while loading (see BugSack for an error)"
SLASH_BLASTARAGENEED1 = "/blastarage"
SlashCmdList.BLASTARAGENEED = function()
    if diagnose then diagnose() return end
    DEFAULT_CHAT_FRAME:AddMessage("|cff4c92ffBlasta Rage|r inactive: " .. tostring(inactive))
end
local DUI = DaylightUI
local style, T = DUI.Style, extras.Translate
local bars = extras.Compatible("ActionBars")
local buttons = bars and bars.Buttons
local spellAPI = C_Spell or {}
-- Older and newer clients name these differently: fall back to the globals.
local getPowerCost = spellAPI.GetSpellPowerCost or GetSpellPowerCost
local getSpellID = function(spell)
    if spellAPI.GetSpellInfo then
        local info = spellAPI.GetSpellInfo(spell)
        if type(info) == "table" then return info.spellID end
    end
    if GetSpellInfo then return select(7, GetSpellInfo(spell)) end
end
if not getPowerCost then inactive = "this client has no GetSpellPowerCost" return end
if not GetActionInfo then inactive = "this client has no GetActionInfo" return end
if not (style and style.SetTextSize) then inactive = "DaylightUI has no Style.SetTextSize" return end

local defaults = { enabled = false, energy = false, surplus = true, size = 13, corner = "TOPLEFT", x = 0, y = 0 }
extras.RageNeedDefaults = defaults
local function get(key)
    local value = DUI:Get(ADDON, "rageNeed." .. key)
    if value == nil then return defaults[key] end
    return value
end

local german = {
    ["Resource costs on buttons"] = "Ressourcenkosten auf Aktionsbuttons",
    ["Show missing Rage"] = "Fehlende Wut anzeigen",
    ["Show missing Energy"] = "Fehlende Energie anzeigen",
    ["Show extra resources"] = "Überschuss anzeigen",
    ["Resource number size"] = "Schriftgröße der Ressourcenzahl",
    ["Resource number position"] = "Position der Ressourcenzahl",
    ["Resource number left / right"] = "Ressourcenzahl links / rechts",
    ["Resource number up / down"] = "Ressourcenzahl hoch / runter",
    ["Missing resource"] = "Fehlende Ressource",
    ["Resource surplus"] = "Überschuss",
    ["Exact cost"] = "Exakte Kosten",
    ["Shows how much Rage a Warrior still needs for the ability."] = "Zeigt Kriegern, wie viel Wut für die Fähigkeit noch fehlt.",
    ["Shows how much Energy the ability still needs on Rogues and Druids in Cat Form."] = "Zeigt Schurken und Druiden in Katzengestalt, wie viel Energie für die Fähigkeit noch fehlt.",
}
for en, de in pairs(german) do extras.German[en] = de end
local function control(key, kind, label, fields)
    local item = fields or {}
    local path = "rageNeed." .. key
    item.key, item.type, item.label = path, kind, label
    item.get = function() return get(key) end
    item.default = function() return defaults[key] end
    item.set = function(v) DUI:Set(ADDON, path, v) end
    return item
end
local corners = {
    TOPLEFT = { 4, -3, "Top left" }, TOPRIGHT = { -4, -3, "Top right" },
    BOTTOMLEFT = { 4, 3, "Bottom left" }, BOTTOMRIGHT = { -4, 3, "Bottom right" },
}
extras.RageNeedGroup = { label = "Resource costs on buttons", items = {
    control("enabled", "toggle", "Show missing Rage", { desc = "Shows how much Rage a Warrior still needs for the ability." }),
    control("energy", "toggle", "Show missing Energy", { desc = "Shows how much Energy the ability still needs on Rogues and Druids in Cat Form." }),
    control("surplus", "toggle", "Show extra resources"),
    control("size", "slider", "Resource number size", { min = 8, max = 22, step = 1 }),
    control("corner", "dropdown", "Resource number position", {
        values = { TOPLEFT = corners.TOPLEFT[3], TOPRIGHT = corners.TOPRIGHT[3],
            BOTTOMLEFT = corners.BOTTOMLEFT[3], BOTTOMRIGHT = corners.BOTTOMRIGHT[3] },
        order = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" },
    }),
    control("x", "slider", "Resource number left / right", { min = -20, max = 20, step = 1, unit = "px" }),
    control("y", "slider", "Resource number up / down", { min = -20, max = 20, step = 1, unit = "px" }),
} }

local secret = DUI.IsSecret or function(v) return issecretvalue ~= nil and issecretvalue(v) == true end
local function number(n) return type(n) == "number" and not secret(n) end
local powerTypes = Enum and Enum.PowerType
local RAGE, ENERGY = powerTypes and powerTypes.Rage or 1, powerTypes and powerTypes.Energy or 3
local resource, resourceToken
local labels = setmetatable({}, { __mode = "k" })
local tracked = {}
local size, x, y, point, surplus

local function readAppearance()
    local anchor = get("corner")
    local inset = corners[anchor] or corners.TOPLEFT
    point = corners[anchor] and anchor or "TOPLEFT"
    size = math.max(8, math.min(22, tonumber(get("size")) or defaults.size))
    x, y = inset[1] + (tonumber(get("x")) or 0), inset[2] + (tonumber(get("y")) or 0)
    surplus = get("surplus") == true
end

local function position(text, button)
    for _, fs in ipairs({ text, text.extra }) do
        style.SetTextSize(fs, size)
        fs:ClearAllPoints()
        fs:SetPoint(point, button, point, x, y)
    end
end

local function hideLabel(text)
    text:Hide()
    text.extra:Hide()
end

local function paint(text, delta)
    text.extra:Hide()
    if delta == 0 or (delta > 0 and not surplus) then text:Hide(); return end
    if delta > 0 then
        text:SetText("+" .. delta)
        text:SetTextColor(0.40, 1, 0.53)
    else
        text:SetText(tostring(-delta))
        text:SetTextColor(1, 0.49, 0.23)
    end
    text:Show()
end

-- Each label has a second text (extra) for the surplus while the power is
-- restricted: then the game fills both, and only one of them is ever non-empty.
local function makeLabel(button)
    local overlay = CreateFrame("Frame", nil, button)
    overlay:SetAllPoints(button)
    local level = button:GetFrameLevel() + 5
    local cooldown = button.cooldown or button.Cooldown
    if type(cooldown) == "table" and cooldown.GetFrameLevel then
        level = math.max(level, cooldown:GetFrameLevel() + 1)
    end
    overlay:SetFrameLevel(level)
    local font = bars and bars.MEDIA and bars.MEDIA.font
    local text = style.Text(overlay, size, "LEFT", font)
    text.extra = style.Text(overlay, size, "LEFT", font)
    text.extra:SetTextColor(0.40, 1, 0.53)
    text.extra:Hide()
    position(text, button)
    return text
end

-- UnitPower with an explicit type can return nothing on some clients:
-- then read the current power bar, if it is this resource.
local function currentPower()
    local value = UnitPower("player", resource)
    if number(value) then return value end
    local shown = UnitPowerType("player")
    if number(shown) and shown == resource then
        value = UnitPower("player")
        if number(value) then return value end
        if UnitMana then
            value = UnitMana("player")
            if number(value) then return value end
        end
    end
end

-- Restricted power (a secret value) can't be compared or subtracted here.
-- The game itself then turns it into text: UnitPowerPercent through a curve
-- that maps the power share to the missing (or surplus) amount, and
-- C_StringUtil formats it, empty when zero. The same way as Warrior Rage Need.
local curveAPI, strings = C_CurveUtil, C_StringUtil
local maxPower, curves = 100, {}
local function refreshMax()
    if not (UnitPowerMax and resource) then return end
    local ok, value = pcall(UnitPowerMax, "player", resource)
    if ok and number(value) and value > 0 and value ~= maxPower then
        maxPower = value
        wipe(curves)
    end
end

local function curveFor(cost, extra)
    if not (curveAPI and curveAPI.CreateCurve) or not cost or cost <= 0 then return end
    local key = cost .. ":" .. maxPower .. (extra and ":+" or "")
    if curves[key] ~= nil then return curves[key] or nil end
    local at = math.max(0, math.min(1, cost / maxPower))
    local ok, curve = pcall(curveAPI.CreateCurve)
    local built = ok and curve ~= nil and curve.AddPoint ~= nil and pcall(function()
        if curve.SetType and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Linear then
            curve:SetType(Enum.LuaCurveType.Linear)
        end
        -- The tiny extra keeps whole numbers from interpolating to x.99999.
        if extra then
            curve:AddPoint(0, 0)
            curve:AddPoint(at, 0)
            if at < 1 then curve:AddPoint(1, maxPower - cost + 0.000001) end
        else
            curve:AddPoint(0, cost + 0.000001)
            curve:AddPoint(at, math.max(0, cost - maxPower) + 0.000001)
            if at < 1 then curve:AddPoint(1, 0.000001) end
        end
    end)
    curves[key] = built and curve or false
    return built and curve or nil
end

local function present(v) return secret(v) or v ~= nil end

-- Second result: why there's no text, for /blastarage.
local function nativeText(curve, plus)
    if not curve then return nil, "no curve" end
    if not (UnitPowerPercent and strings and strings.TruncateWhenZero) then return nil, "no native API" end
    local ok, value = pcall(UnitPowerPercent, "player", resource, false, curve)
    if not ok then return nil, "UnitPowerPercent: " .. tostring(value) end
    if not present(value) then return nil, "UnitPowerPercent gave nothing" end
    local okText, text = pcall(strings.TruncateWhenZero, value)
    if not okText then return nil, "TruncateWhenZero: " .. tostring(text) end
    if not present(text) then return nil, "TruncateWhenZero gave nothing" end
    if plus then
        if not strings.WrapString then return nil, "no WrapString" end
        local okWrap, wrapped = pcall(strings.WrapString, text, "+", nil)
        if not okWrap then return nil, "WrapString: " .. tostring(wrapped) end
        if not present(wrapped) then return nil, "WrapString gave nothing" end
        text = wrapped
    end
    return text
end

local lastValue
local function render()
    if not next(tracked) then return end
    local value = currentPower()
    if number(value) then
        if value == lastValue then return end
        lastValue = value
        for button, cost in pairs(tracked) do
            local text = labels[button]
            local delta = value >= cost and math.floor(value - cost) or -math.ceil(cost - value)
            if not text and (delta < 0 or (delta > 0 and surplus)) then
                text = makeLabel(button)
                labels[button] = text
            end
            if text then paint(text, delta) end
        end
        return
    end
    lastValue = nil
    local byCost = {}
    for button, cost in pairs(tracked) do
        local entry = byCost[cost]
        if not entry then
            entry = { missing = nativeText(curveFor(cost)),
                extra = surplus and nativeText(curveFor(cost, true), true) or nil }
            byCost[cost] = entry
        end
        local text = labels[button]
        if not text then
            text = makeLabel(button)
            labels[button] = text
        end
        if present(entry.missing) then
            text:SetText(entry.missing)
            text:SetTextColor(1, 0.49, 0.23)
            text:Show()
        else
            text:Hide()
        end
        if present(entry.extra) then
            text.extra:SetText(entry.extra)
            text.extra:Show()
        else
            text.extra:Hide()
        end
    end
end

local function spellFor(slot)
    if not number(slot) or slot <= 0 then return end
    -- The game resolves spells and macros for the slot itself, where it can.
    if C_ActionBar and C_ActionBar.GetSpell then
        local ok, id = pcall(C_ActionBar.GetSpell, slot)
        if ok and number(id) and id > 0 then return id end
    end
    local kind, id, subType = GetActionInfo(slot)
    if secret(kind) or secret(subType) or not number(id) then return end
    if kind == "spell" then return id end
    if kind ~= "macro" then return end
    -- Newer clients hand a macro's current spell ID straight to the action
    -- ("macro", spellID, "spell"); id is then no macro index.
    if subType == "spell" then return id end
    if not GetMacroSpell then return end
    local function fromMacro(index)
        if not number(index) or index <= 0 then return end
        local spell, _, legacy = GetMacroSpell(index)
        if number(legacy) and legacy > 0 then return legacy end
        if number(spell) and spell > 0 then return spell end
        if type(spell) == "string" and not secret(spell) then
            local found = getSpellID(spell)
            if number(found) and found > 0 then return found end
        end
    end
    local found = fromMacro(id)
    if found then return found end
    -- The action's text is the macro's name: find its index from there.
    local name = GetActionText and GetActionText(slot)
    if type(name) == "string" and not secret(name) and GetMacroIndexByName then
        return fromMacro(GetMacroIndexByName(name))
    end
end

local function resourceCost(spell)
    local ok, costs = pcall(getPowerCost, spell)
    if not ok or type(costs) ~= "table" or secret(costs) then return end
    -- Costs bound to an aura count only while it's up; if every cost of
    -- this resource needs an aura that isn't up, the plain lowest is used.
    local minimum, fallback
    for _, cost in ipairs(costs) do
        local kind = type(cost) == "table" and not secret(cost) and cost.type
        local name = kind ~= false and cost.name
        if (number(kind) and kind == resource)
            or (type(name) == "string" and not secret(name) and name == resourceToken) then
            local value = cost.cost
            if number(value) and value > 0 and number(cost.minCost) and cost.minCost > 0 then
                value = math.min(value, cost.minCost)
            end
            if number(value) and value >= 0 then
                fallback = math.min(fallback or value, value)
                local aura = cost.requiredAuraID
                local auraActive = not secret(cost.hasRequiredAura) and cost.hasRequiredAura == true
                if not secret(aura) and (not number(aura) or aura == 0 or auraActive) then
                    minimum = math.min(minimum or value, value)
                end
            end
        end
    end
    return minimum or fallback
end

local stock = { "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
    "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button" }
local function playerResource()
    local _, class = UnitClass("player")
    if secret(class) then return end
    if class == "WARRIOR" and get("enabled") == true then return RAGE, "RAGE" end
    if (class == "ROGUE" or class == "DRUID") and get("energy") == true then
        local powerType = UnitPowerType("player")
        if number(powerType) and powerType == ENERGY then return ENERGY, "ENERGY" end
    end
end

-- Every button showing a resource spell (spellOf), even ones that cost
-- nothing right now, so an aura that changes a cost can be picked up
-- without walking all action slots again. usesMacros: a tracked slot is a
-- macro, whose spell can follow modifiers or the target.
local spellOf, usesMacros = {}, false

local function scan()
    wipe(tracked)
    wipe(spellOf)
    usesMacros = false
    lastValue = nil
    for _, text in pairs(labels) do hideLabel(text) end
    resource, resourceToken = playerResource()
    if not resource then return end
    refreshMax()
    readAppearance()
    local costs = {}
    local function track(button, slot)
        local id = spellFor(slot)
        if not id then return end
        if not usesMacros and GetActionInfo(slot) == "macro" then usesMacros = true end
        spellOf[button] = id
        if costs[id] == nil then costs[id] = resourceCost(id) or false end
        if not costs[id] or costs[id] <= 0 then return end
        tracked[button] = costs[id]
        if labels[button] then position(labels[button], button) end
    end
    if buttons and buttons.All and buttons.SlotOf then
        for _, button in ipairs(buttons.All()) do track(button, buttons.SlotOf(button)) end
    end
    local standalone = resource == ENERGY and "RogueEnergyNeed" or "WarriorRageNeed"
    if not (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(standalone)) then
        for _, prefix in ipairs(stock) do
            for i = 1, 12 do
                local button = _G[prefix .. i]
                if button then
                    local slot = button.action
                    if not number(slot) and button.GetAttribute then slot = button:GetAttribute("action") end
                    track(button, slot)
                end
            end
        end
    end
    render()
end

-- Auras (Clearcasting, stances, buffs) only change what a spell costs, not
-- which spell sits on a button: re-read the costs of the known spells.
local function recost()
    if not resource or not next(spellOf) then return end
    local costs, changed = {}, false
    for button, id in pairs(spellOf) do
        if costs[id] == nil then costs[id] = resourceCost(id) or false end
        local cost = costs[id]
        if not cost or cost <= 0 then cost = nil end
        if tracked[button] ~= cost then
            tracked[button] = cost
            changed = true
            if not cost and labels[button] then hideLabel(labels[button]) end
        end
    end
    if changed then
        lastValue = nil
        render()
    end
end

-- Work is batched to the next frame. A full scan covers a cost refresh.
local pending
local function flush()
    local work = pending
    pending = nil
    if work == "scan" then scan() elseif work == "recost" then recost() end
end
local function request(work)
    if pending == "scan" or pending == work then return end
    local first = pending == nil
    pending = work
    if first then C_Timer.After(0, flush) end
end
local function schedule() request("scan") end

for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "ACTIONBAR_SLOT_CHANGED", "ACTIONBAR_PAGE_CHANGED",
    "UPDATE_BONUS_ACTIONBAR", "UPDATE_OVERRIDE_ACTIONBAR", "UPDATE_SHAPESHIFT_FORM", "UPDATE_MACROS",
    "SPELLS_CHANGED", "PLAYER_EQUIPMENT_CHANGED" }) do
    DUI.RegisterEvent(event, schedule)
end
-- Modifier keys and target changes only matter for macro conditions.
local function macroCheck()
    if resource and usesMacros then schedule() end
end
DUI.RegisterEvent("MODIFIER_STATE_CHANGED", macroCheck)
DUI.RegisterEvent("PLAYER_TARGET_CHANGED", macroCheck)
-- UNIT_AURA fires constantly in combat, so it only re-reads costs.
DUI.RegisterUnitEvent("UNIT_AURA", function()
    if resource then request("recost") end
end, "player")
DUI.RegisterUnitEvent("UNIT_DISPLAYPOWER", schedule, "player")
local function powerChanged(_, _, power)
    if resourceToken and not secret(power) and power == resourceToken then render() end
end
DUI.RegisterUnitEvent("UNIT_POWER_FREQUENT", powerChanged, "player")
DUI.RegisterUnitEvent("UNIT_POWER_UPDATE", powerChanged, "player")
DUI.RegisterUnitEvent("UNIT_MAXPOWER", function(_, _, power)
    if resourceToken and not secret(power) and power == resourceToken then
        refreshMax()
        lastValue = nil
        render()
    end
end, "player")
DUI.RegisterEvent("ADDON_LOADED", function(_, name)
    if name == "WarriorRageNeed" or name == "RogueEnergyNeed" then schedule() end
end)
for _, event in ipairs({ "Login", "ActionBarsBuilt", "ActionButtonMade", "ActionBarLaidOut", "ProfileKept" }) do
    DUI.On(event, schedule)
end
if buttons and buttons.SlotsChanged then hooksecurefunc(buttons, "SlotsChanged", schedule) end

-- The preview on DaylightUI's Action Bars page (Daylight has none of its
-- own there): three sample buttons, shown while the Text tab is open.
local refreshPreview
local function textTabOpen()
    local panel = DUI.OptionsPanel
    local page = panel and panel.PageFrame and panel.PageFrame()
    return not page or page.tab == nil or page.tab == "Text"
end
function extras.RageNeedSample(parent)
    local host, samples = CreateFrame("Frame", nil, parent), {}
    readAppearance()
    for i, case in ipairs({ { "Missing resource", -8 }, { "Resource surplus", 15 }, { "Exact cost", 0 } }) do
        local button = CreateFrame("Frame", nil, host)
        button:SetSize(42, 42)
        button:SetPoint("TOP", host, "TOP", (i - 2) * 105, -5)
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(button)
        icon:SetTexture("Interface\\Icons\\Spell_Nature_ThunderClap")
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        local note = style.Text(host, 12, "CENTER")
        note:SetPoint("TOP", button, "BOTTOM", 0, -6)
        note:SetText(T(case[1]))
        samples[i] = { button = button, label = makeLabel(button), delta = case[2] }
    end
    local function refresh()
        readAppearance()
        for _, sample in ipairs(samples) do
            position(sample.label, sample.button)
            paint(sample.label, sample.delta)
        end
    end
    refreshPreview = refresh
    return { frame = host, Parts = function() return {} end, Refresh = function(width)
        if not textTabOpen() then
            host:Hide()
            host:SetSize(width, 1)
            return 0
        end
        host:Show()
        host:SetSize(width, 72)
        refresh()
        return 72
    end }
end

DUI.On("SettingChanged", function(scope, path)
    if scope == ADDON and type(path) == "string" and path:find("^rageNeed%.") then
        if refreshPreview then refreshPreview() end
        schedule()
    end
end)

-- /blastarage: prints why numbers do or don't show, for bug reports.
diagnose = function()
    local function show(v) if secret(v) then return "secret" end return tostring(v) end
    local out = function(text) DEFAULT_CHAT_FRAME:AddMessage("|cff4c92ffBlasta Rage|r " .. text) end
    local _, class = UnitClass("player")
    out(("Class %s, Rage option %s, Energy option %s, surplus %s"):format(tostring(class),
        tostring(get("enabled")), tostring(get("energy")), tostring(get("surplus"))))
    if not resource then
        out("Off: no resource for this character. Turn on 'Show missing Rage' under Action Bars.")
        return
    end
    local all = buttons and buttons.All and buttons.All() or {}
    local seen, costed, shown = 0, 0, 0
    for _ in pairs(spellOf) do seen = seen + 1 end
    for button in pairs(tracked) do
        costed = costed + 1
        if labels[button] and labels[button]:IsShown() then shown = shown + 1 end
    end
    local typed, plain, shownType = UnitPower("player", resource), UnitPower("player"), UnitPowerType("player")
    local read = currentPower()
    out(("Power read %s (typed %s, bar %s, bar type %s)"):format(show(read),
        show(typed), show(plain), show(shownType)))
    out(("Native path: curves %s, UnitPowerPercent %s, formatter %s, max %s"):format(
        tostring(curveAPI ~= nil and curveAPI.CreateCurve ~= nil), tostring(UnitPowerPercent ~= nil),
        tostring(strings ~= nil and strings.TruncateWhenZero ~= nil), tostring(maxPower)))
    out(("Daylight buttons %d, with spell %d, with cost %d, numbers shown %d"):format(
        #all, seen, costed, shown))
    local listed = 0
    for _, button in ipairs(all) do
        local slot = buttons.SlotOf and buttons.SlotOf(button)
        if number(slot) and HasAction(slot) and listed < 8 then
            listed = listed + 1
            local id = spellOf[button]
            if not id then
                local kind, action, subType = GetActionInfo(slot)
                local name = GetActionText(slot)
                out(("  slot %d: %s %s %s (%s) - no spell"):format(slot, show(kind), show(action),
                    show(subType), show(name)))
            else
                local cost = tracked[button]
                local line = ("  slot %d: spell %s, cost %s"):format(slot, show(id), show(cost))
                if cost then
                    local text, why = nativeText(curveFor(cost))
                    local label = labels[button]
                    line = line .. (", native %s, label %s"):format(present(text) and "ok" or show(why),
                        label and (label:IsShown() and "shown" or "hidden") or "none")
                else
                    local ok, rows = pcall(getPowerCost, id)
                    if not ok then
                        line = line .. ", cost lookup failed: " .. show(rows)
                    elseif type(rows) ~= "table" or secret(rows) then
                        line = line .. ", cost rows " .. show(rows)
                    else
                        line = line .. ", rows " .. #rows
                        local row = rows[1]
                        if type(row) == "table" then
                            line = line .. (" (type %s, name %s, cost %s, min %s, aura %s)"):format(show(row.type),
                                show(row.name), show(row.cost), show(row.minCost), show(row.requiredAuraID))
                        end
                    end
                end
                out(line)
            end
        end
    end
end
