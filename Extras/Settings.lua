local ADDON, extras = ...
local DUI = DaylightUI

-- Capture Daylight's original rows before the feature modules add their controls.
-- Move the controls before Daylight builds its options, while keeping their
-- original profile keys and module callbacks.
local modules = { "Nameplates", "UnitFrames", "ActionBars", "Tooltip", "QoL", "Professions", "Quests", "Bags", "Skins" }
local original = {}
local nativeSwitches = {}
local function rememberRows(name)
    local mod = DUI:GetModule(name)
    local switches = {}
    nativeSwitches[name] = switches
    for _, page in ipairs(mod and mod.options and mod.options.pages or {}) do
        for _, group in ipairs(page.groups or {}) do
            for _, item in ipairs(group.items or {}) do
                original[item] = true
                if item.type == "toggle" and item.key and type(item.label) == "string" then
                    switches[item.key] = { label = item.label, invert = item.invert }
                end
            end
        end
    end
end
for _, name in ipairs(modules) do rememberRows(name) end
rememberRows("InfoPanel")
rememberRows("Buffs")

local function notice(label, hidden)
    local widgets = DUI.Widgets
    return {
        type = "custom", label = "DaylightUI", hidden = hidden,
        build = function(row)
            local text = widgets.Font(row, widgets.BODY, 12, nil, "LEFT")
            text:SetPoint("TOPLEFT", row, "TOPLEFT", widgets.PAD, -8)
            text:SetJustifyV("TOP")
            text:SetWordWrap(true)
            text:SetText(label())
            row.blastaNotice = text
        end,
        height = function(row)
            local text = row.blastaNotice
            text:SetWidth(math.max(1, row:GetWidth() - 2 * widgets.PAD))
            return math.max(14, math.ceil(text:GetStringHeight())) + 16
        end,
    }
end

local function moduleNotice(mod)
    return notice(function()
        return extras.Translate("Enable the DaylightUI module “%s”."):format(extras.Translate(mod.label or mod.name))
    end, function() return mod.enabled == true end)
end

local function switchOn(mod, key, switch)
    local value = DUI:Get(mod.name, key)
    if switch.invert then return value ~= true end
    return value == true
end

local function switchNotice(mod, key, switch)
    return notice(function()
        return extras.Translate("In DaylightUI, enable “%s”."):format(extras.Translate(switch.label))
    end, function() return not mod.enabled or switchOn(mod, key, switch) end)
end

local function addNotices(mod, items, requiredKey)
    local switches = nativeSwitches[mod.name] or {}
    local seen = {}
    local notices = { moduleNotice(mod) }
    local function add(key)
        if key and switches[key] and not seen[key] then
            notices[#notices + 1] = switchNotice(mod, key, switches[key])
            seen[key] = true
        end
    end
    add(requiredKey)
    for _, item in ipairs(items) do
        local requirements = {}
        local parent = item.key and item.key:match("^(.*)%.[^.]+$")
        while parent do
            local key = parent .. ".enabled"
            if switches[key] then requirements[#requirements + 1] = key end
            parent = parent:match("^(.*)%.[^.]+$")
        end
        if switches[item.blastaRequires] then requirements[#requirements + 1] = item.blastaRequires end
        if #requirements > 0 then
            for _, key in ipairs(requirements) do add(key) end
            local hidden = item.hidden
            item.hidden = function(get)
                if hidden and hidden(get) == true then return true end
                for _, key in ipairs(requirements) do
                    if not switchOn(mod, key, switches[key]) then return true end
                end
                return false
            end
        end
    end
    for i = #notices, 1, -1 do table.insert(items, 1, notices[i]) end
end

function extras.ShowDaylightRequirements(page, mod, requiredKey)
    page.hidden = nil
    local requiredSwitch = nativeSwitches[mod.name] and nativeSwitches[mod.name][requiredKey]
    for _, group in ipairs(page.groups) do
        for _, row in ipairs(group.items) do
            local hidden = row.hidden
            row.hidden = function(get)
                return not mod.enabled or (requiredSwitch and not switchOn(mod, requiredKey, requiredSwitch))
                    or (hidden and hidden(get) == true)
            end
        end
    end
    local first = page.groups[1]
    if first then addNotices(mod, first.items, requiredKey) end
    return page
end

local function copy(row)
    local result = {}
    for k, v in pairs(row) do result[k] = v end
    return result
end

local function bridge(mod, row)
    local function get(key) return DUI:Get(mod.name, key) end
    if row.key and not row.get then
        local key = row.key
        row.get = function() return get(key) end
        row.set = function(value) return DUI:Set(mod.name, key, value) end
        row.default = function() return DUI.DB.GetPath(mod.defaults, key) end
    end
    local hidden, disabled = row.hidden, row.disabled
    row.hidden = function() return not mod.enabled or (hidden and hidden(get) == true) end
    if disabled then row.disabled = function() return disabled(get) end end
    return row
end

local previewRoutes = setmetatable({}, { __mode = "k" })
local portraitOffsets = {
    ["Leader crown"] = { "showLeader", "leader", "blastaLeader" },
    ["PvP flag"] = { "showPvP", "pvp", "blastaPvP" },
    Resting = { "showResting", "rest", "blastaRest" },
    Level = { "showLevel", "level", "level" },
}

local function offsetsFor(mod, source, part, wanted)
    local spec = mod.name == "UnitFrames" and portraitOffsets[part.label]
    if not spec then return end
    local function mapped(path) return source.mapKey and source.mapKey(path) or path end
    for _, key in ipairs(part.keys or {}) do
        local prefix = key:match("^(.*%.)" .. spec[1] .. "$")
        if prefix then
            local result = {}
            for _, axis in ipairs({ "X", "Y" }) do
                local native, blasta = prefix .. spec[2] .. axis, prefix .. spec[3] .. axis
                if extras.FindSetting(mod, native) and not DUI.Options.Locked(source, { key = native }) then
                    result[axis], wanted[native] = native, true
                elseif DUI.DB.GetPath(mod.defaults, mapped(blasta)) ~= nil and blasta ~= native then
                    result[axis], wanted[blasta] = blasta, true
                end
            end
            if result.X and result.Y then return result end
        end
    end
end

local function portraitMove(mod, source, part, wanted)
    local keys = offsetsFor(mod, source, part, wanted)
    if part.move and part.move.xKey and part.move.yKey then return part.move end
    if not keys then return part.move end
    local region = part.region
    local owner = part.move and part.move.owner or region:GetParent()
    if not owner then return part.move end
    -- Resolve the home position now: the native drag moves the region itself.
    local cx, cy = region:GetCenter()
    if not (cx and cy and owner:GetLeft() and owner:GetTop()) then return part.move end
    local scale = region:GetEffectiveScale() / owner:GetEffectiveScale()
    local dx = DUI:Get(mod.name, DUI.Options.Key(source, keys.X)) or 0
    local dy = DUI:Get(mod.name, DUI.Options.Key(source, keys.Y)) or 0
    local dots = { { spot = "home", x = cx * scale - owner:GetLeft() - dx, y = owner:GetTop() - cy * scale + dy } }
    return { xKey = keys.X, yKey = keys.Y, owner = owner, dots = dots,
        offsetLimit = 50,
        drop = function(x, y) return DUI.Spots.Drop(dots, x, y) end }
end

local previewHosts = setmetatable({}, { __mode = "k" })
function extras.IsUnitFramePreview(frame)
    local parent = frame:GetParent()
    while parent and not previewHosts[parent] do parent = parent:GetParent() end
    return parent ~= nil
end


local function removeAddedRows(groups, index, destination, stays, stayed)
    local group = groups[index]
    local kept = 0
    for i = 1, #group.items do
        local item = group.items[i]
        if original[item] or (stays and stays(item)) then
            kept = kept + 1
            group.items[kept] = item
            if not original[item] and stayed then stayed[#stayed + 1] = item end
        elseif destination then
            destination[#destination + 1] = item
        end
    end
    for i = #group.items, kept + 1, -1 do group.items[i] = nil end
    return kept == 0
end

-- Unit frame tabs. Every frame used to get its own tab, more than fit a
-- narrow window. The main frames keep theirs; raid sizes share one and the
-- smaller frames share "More frames", their cards named after the frame.

-- Blasta rows that stay on DaylightUI's own pages hide with the native switch
-- they extend (a "….enabled" parent), as Daylight's own rows do.
local function followParents(mod, item)
    local switches = nativeSwitches[mod.name] or {}
    local requirements = {}
    local parent = item.key and item.key:match("^(.*)%.[^.]+$")
    while parent do
        local key = parent .. ".enabled"
        if switches[key] then requirements[#requirements + 1] = key end
        parent = parent:match("^(.*)%.[^.]+$")
    end
    if switches[item.blastaRequires] then requirements[#requirements + 1] = item.blastaRequires end
    if #requirements == 0 then return end
    local hidden = item.hidden
    item.hidden = function(get)
        if hidden and hidden(get) == true then return true end
        for _, key in ipairs(requirements) do
            local switch = switches[key]
            local on
            if get then
                local value = get(key)
                if switch.invert then on = value ~= true else on = value == true end
            else
                on = switchOn(mod, key, switch)
            end
            if not on then return true end
        end
        return false
    end
end

-- Rows that extend a DaylightUI feature stay beside it in Daylight's menu,
-- marked with the Blasta badge. Only what Daylight has no place for moves
-- to Blasta's own pages.
-- Daylight checks every row of its pages when it registers them, so a row
-- only stays if it passes the same check; anything else moves as before.
local function staysInDaylight(mod)
    local validate = DUI.Options and DUI.Options.Validate
    return function(item)
        if item.blastaDestination ~= nil then return false end
        if not validate then return true end
        local ok, errors = pcall(validate, { item }, mod.defaults or {}, {}, "Blasta")
        return ok and type(errors) == "table" and #errors == 0
    end
end

local function markStayed(mod, rows)
    for _, item in ipairs(rows) do
        item.blastaBadge = true
        followParents(mod, item)
    end
end

local function nativePage(name, id)
    local mod = DUI:GetModule(name)
    for _, page in ipairs(mod and mod.options and mod.options.pages or {}) do
        if page.id == id then return page, mod end
    end
end

-- Daylight's own previews show Blasta's additions: the unit frame previews
-- count as previews for Blasta's drawing (extras.IsUnitFramePreview), and
-- the portrait icons and aura bars Blasta adds can be dragged in Daylight's
-- Design mode like its own parts.
local function wrapSample(mod, page)
    local factory = page.sample
    if type(factory) ~= "function" or page.blastaSample then return end
    page.blastaSample = true
    page.sample = function(parent, ...)
        local preview = factory(parent, ...)
        if type(preview) ~= "table" then return preview end
        if preview.frame then previewHosts[preview.frame] = true end
        local refresh = preview.Refresh
        if refresh and mod.name == "UnitFrames" then
            preview.Refresh = function(...)
                local used = refresh(...)
                if extras.PaintDispelPreview then pcall(extras.PaintDispelPreview, preview) end
                return used
            end
        end
        local readParts = preview.Parts
        if readParts and mod.name == "UnitFrames" then
            preview.Parts = function(...)
                local parts = readParts(...) or {}
                local wanted = {}
                for _, part in ipairs(parts) do
                    local ok, move = pcall(portraitMove, mod, page, part, wanted)
                    if ok then part.move = move end
                end
                if extras.AppendAuraBarPreviewParts then
                    pcall(extras.AppendAuraBarPreviewParts, parts, preview, page)
                end
                if page.id == "party" then
                    if extras.AddPartyPortraitMove then pcall(extras.AddPartyPortraitMove, preview, parts) end
                    if extras.AddPartyPowerMove then pcall(extras.AddPartyPowerMove, preview, parts) end
                end
                return parts
            end
        end
        return preview
    end
end

-- Per-bar rows on Daylight's "Bars" card show only for the bar picked
-- under "Settings for", like Daylight's own rows on that card.
local function followPick(group, item)
    local picker
    for _, row in ipairs(group.items) do
        if row.type == "dropdown" and row.get and not row.key then picker = row; break end
    end
    local id = item.key and item.key:match("^bars%.([^.]+)%.")
    if not (picker and id) then return end
    local own = item.hidden
    item.baseHidden = own
    item.hidden = function(get) return picker.get() ~= id or (own ~= nil and own(get) == true) end
end

-- Resource costs on buttons: Daylight's Action Bars page, Text tab.
local function placeRageNeed(stayed)
    local group = extras.RageNeedGroup
    local page = group and nativePage("ActionBars", "bars")
    if not page then return false end
    for _, other in ipairs(page.groups or {}) do
        if other.tab == "Text" then group.blastaTab = "Text"; break end
    end
    for _, item in ipairs(group.items) do stayed[#stayed + 1] = item end
    -- Daylight's Action Bars page has no preview of its own: the resource
    -- cost buttons fill that spot.
    if page.sample == nil and extras.RageNeedSample then
        page.sample = function(parent) return extras.RageNeedSample(parent) end
    end
    page.groups = page.groups or {}
    page.groups[#page.groups + 1] = group
    return true
end

function extras.MoveSettings()
    local skinSwitches = {}
    local stayed = {}
    -- Blasta's tooltip cards join DaylightUI's Tooltips page before the rows
    -- there are sorted, so they get the badge like every other Blasta row.
    local tooltipCards = extras.PlaceTooltipCards and extras.PlaceTooltipCards()
    if extras.PlaceBarFxCombat then pcall(extras.PlaceBarFxCombat) end
    for _, name in ipairs(modules) do
        local mod = DUI:GetModule(name)
        local valid = mod and staysInDaylight(mod)
        for _, source in ipairs(mod and mod.options and mod.options.pages or {}) do
            wrapSample(mod, source)
            for _, group in ipairs(source.groups or {}) do
                local picker = name == "ActionBars" and group.Picked ~= nil
                if picker then
                    -- Pixel-exact bars: half-pixel button sizes and gaps down
                    -- to -10 on Daylight's own size and gap sliders.
                    for _, row in ipairs(group.items) do
                        local field = row.key and row.key:match("^bars%.[^.]+%.([^.]+)$")
                        if field == "pad" and type(row.min) == "number" then row.min = math.min(row.min, -10)
                        elseif field == "size" then row.step = math.min(row.step or 1, 0.5) end
                    end
                end
                local i = 1
                while i <= #group.items do
                    local item = group.items[i]
                    if original[item] then
                        i = i + 1
                    else
                        item.blastaDestination, item.blastaCompanion = nil, nil
                        if picker then followPick(group, item) end
                        -- A row Daylight's check would refuse reads and writes
                        -- through its own get/set instead.
                        if not valid(item) then group.items[i] = bridge(mod, item); item = group.items[i] end
                        followParents(mod, item)
                        stayed[#stayed + 1] = item
                        i = i + 1
                    end
                end
            end
        end
    end
    local rageInDaylight = placeRageNeed(stayed)
    -- Translate the badged rows the same way as Blasta's own pages.
    if extras.LocalizePages and #stayed > 0 then
        local groups = { { items = stayed } }
        if rageInDaylight then groups[2] = { label = extras.RageNeedGroup.label, items = {} } end
        extras.LocalizePages({ { groups = groups } })
        if rageInDaylight then extras.RageNeedGroup.label = groups[2].label end
    end
    if tooltipCards and extras.LocalizePages then
        -- Only the cards' own title and text: their rows went through above.
        local shells = {}
        for i, card in ipairs(tooltipCards) do shells[i] = { label = card.label, desc = card.desc, items = {} } end
        extras.LocalizePages({ { groups = shells } })
        for i, card in ipairs(tooltipCards) do card.label, card.desc = shells[i].label, shells[i].desc end
    end
    for _, item in ipairs(stayed) do item.blastaBadge = true end
    if rageInDaylight then
        extras.RageNeedGroup.tab, extras.RageNeedGroup.blastaTab = extras.RageNeedGroup.blastaTab, nil
    end
    return skinSwitches
end

-- Blasta's own settings that extend a Daylight feature go on that feature's
-- Daylight page through Daylight's plugin API (AddOptionsGroup). Daylight
-- adds "From Blasta" to the card; each row also carries the Blasta badge.
local function defaultOf(key)
    return function()
        local own = DUI:GetModule(ADDON)
        return own and own.defaults and DUI.DB.GetPath(own.defaults, key)
    end
end

function extras.AddToDaylight(pageId, group, after)
    -- Named "Blasta" so the card reads "From Blasta"; the rows still save in
    -- Blasta's own settings (group.scope).
    local api = DUI.API and DUI.API.For and DUI.API.For("Blasta")
    if not (api and api.AddOptionsGroup and group and group.items) then return false end
    extras.LocalizePages({ { groups = { group } } })
    -- Daylight joins the card name with "From Blasta" itself, so the name has
    -- to be the finished text, not a translation key.
    if type(group.label) == "string" then group.label = rawget(DUI.L, group.label) or group.label end
    group.scope = ADDON
    for _, item in ipairs(group.items) do
        item.blastaBadge = true
        if item.key and item.default == nil and not item.get then item.default = defaultOf(item.key) end
    end
    return api.AddOptionsGroup(pageId, group, after)
end
