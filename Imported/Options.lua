local ADDON, ns = ...
if not ns.ok then return end

local DUI = DaylightUI
local FOLLOW = "followDaylight"

local function following(get) return get(FOLLOW) ~= false end

-- Fonts: DaylightUI's, the addon's own, and every font shared through LibSharedMedia. Fonts that
-- other addons share after this file has run are added at login, into the same table.
local fonts = { daylight = "DaylightUI font", addon = "The addon's own font" }
local function gatherFonts()
	local LSM = ns.LSM
	if not LSM then return end
	local ok, list = pcall(LSM.List, LSM, "font")
	if not ok or type(list) ~= "table" then return end
	for _, name in ipairs(list) do
		if type(name) == "string" and fonts[name] == nil then fonts[name] = name end
	end
end
gatherFonts()
local late = CreateFrame("Frame")
late:RegisterEvent("PLAYER_LOGIN")
late:SetScript("OnEvent", gatherFonts)

local OUTLINES = { keep = "As the addon has it", none = "None", thin = "Thin", thick = "Thick" }

-- The line at the top of an addon's page while its rows are set aside.
local function hint()
	return { type = "text",
		label = "Turn off shared Daylight settings in AddonSkins to edit this skin.",
		hidden = function(get) return not following(get) end }
end

local function textGroups(addon, caps, tab)
	local at = "look." .. addon .. "."
	local items = {
		hint(),
		{ type = "dropdown", key = at .. "font", label = "Font", values = fonts,
		  desc = "The font of this addon's text.", disabled = following },
		{ type = "dropdown", key = at .. "outline", label = "Text outline", values = OUTLINES,
		  desc = "The outline round this addon's text.", disabled = following },
	}
	if caps.shadow then
		items[#items + 1] = { type = "toggle", key = at .. "shadow", label = "Text shadow",
			desc = "A soft shadow under this addon's text.", disabled = following }
	end
	items[#items + 1] = { type = "slider", key = at .. "size", label = "Text size", min = 0.8, max = 1.4, step = 0.05, unit = "%",
		desc = "How big this addon's text is, next to the size the addon gave it.", disabled = following }
	local groups = { { label = "Font", tab = tab, items = items } }
	if caps.colors then
		groups[#groups + 1] = { label = "Text colors", tab = tab, items = {
			{ type = "toggle", key = at .. "daylightColors", label = "Use DaylightUI's text colors",
			  desc = "Off: the addon keeps its own text colors.", disabled = following },
		} }
		groups[#groups + 1] = { label = "Accent", tab = tab, items = {
			{ type = "toggle", key = at .. "daylightAccent", label = "Use DaylightUI's accent",
			  desc = "Off: pick an accent for this addon alone.", disabled = following },
			{ type = "color", key = at .. "accent", label = "Accent color",
			  desc = "This addon's accent: its highlights, marks and arrow.",
			  disabled = function(get) return following(get) or get(at .. "daylightAccent") ~= false end },
		} }
	end
	return groups
end

local function lookGroups(addon, caps, tab, lead)
	local at = "look." .. addon .. "."
	local groups = {}
	if caps.window then
		local items = {}
		if lead then items[#items + 1] = hint() end
		lead = false
		items[#items + 1] = { type = "toggle", key = at .. "ownOpacity", label = "Use my own background opacity",
			desc = "Off: these windows follow DaylightUI's window background opacity.", disabled = following }
		items[#items + 1] = { type = "slider", key = at .. "opacity", label = "Background opacity", min = 0, max = 1, step = 0.05, unit = "%",
			desc = "How solid the background of this addon's windows is.",
			disabled = function(get) return following(get) or get(at .. "ownOpacity") ~= true end }
		groups[#groups + 1] = { label = "Window background", tab = tab, items = items }
		groups[#groups + 1] = { label = "Window border", tab = tab, items = {
			{ type = "toggle", key = at .. "border", label = "Border",
			  desc = "The border round this addon's windows.", disabled = following },
			{ type = "toggle", key = at .. "ownBorder", label = "Use my own border size",
			  desc = "Off: the border is the size set in DaylightUI.",
			  disabled = function(get) return following(get) or get(at .. "border") == false end },
			{ type = "slider", key = at .. "borderPx", label = "Border size", min = 1, max = 16, step = 1, unit = "px",
			  desc = "How thick the border is.",
			  disabled = function(get) return following(get) or get(at .. "border") == false or get(at .. "ownBorder") ~= true end },
			{ type = "toggle", key = at .. "bevel", label = "Bevel",
			  desc = "The soft light along the top of this addon's windows.", disabled = following },
		} }
	end
	if caps.controls then
		local items = {}
		if lead then items[#items + 1] = hint() end
		items[#items + 1] = { type = "toggle", key = at .. "controls", label = "Dress buttons, boxes and scroll bars",
			desc = "Off: only the windows are dressed and their controls stay as the addon drew them. Takes hold after a reload.",
			disabled = following }
		groups[#groups + 1] = { label = "Controls", tab = tab, items = items }
	end
	return groups
end

local function skinPage(skinSwitches)
	local selected
	local function selectSkin(addon)
		selected = addon
		DUI.OptionsPanel.Refresh()
	end
	local function hideInDetail(row)
		local hidden = row.hidden
		row.hidden = function(get) return selected ~= nil or (hidden and hidden(get) == true) end
		return row
	end
	local function settingsGear(open)
		return function(row)
			local dock = CreateFrame("Frame", nil, row)
			dock:SetSize(44, 20)
			local gear = DUI.Widgets.IconButton(dock, "gear-small.png", ns.Translate("Skin settings"), open)
			gear:SetPoint("LEFT")
			dock.Refresh = function() end
			return dock
		end
	end
	local groups = {
		{ label = "DaylightUI's look", items = {
			hideInDetail({ type = "toggle", key = FOLLOW, label = "Use DaylightUI's settings for all windows" }),
		} },
	}
	local switches, skinLabels, detailOrder = {}, {}, {}
	for _, addon in ipairs(ns.order) do
		local caps, label = ns.caps[addon], ns.targets[addon]
		local row = hideInDetail({ type = "toggle", key = addon, label = label })
		switches[#switches + 1] = row
		if caps.text or caps.window or caps.controls then
			skinLabels[addon] = label
			detailOrder[#detailOrder + 1] = addon
			row.beside = settingsGear(function() selectSkin(addon) end)
		end
	end
	for _, row in ipairs(skinSwitches) do
		switches[#switches + 1] = hideInDetail(row)
	end
	switches[#switches + 1] = hideInDetail({ type = "button", label = "Reload interface", func = ReloadUI })
	groups[#groups + 1] = { label = "Addon windows", items = switches }
	groups[#groups + 1] = { label = "Skin settings", items = {
		{ type = "dropdown", label = "Addon", values = skinLabels, order = detailOrder,
			get = function() return selected end, set = selectSkin,
			hidden = function() return selected == nil end, noSearch = true },
		{ type = "button", label = "Skin overview", text = "Back", func = function() selectSkin(nil) end,
			hidden = function() return selected == nil end, noSearch = true },
		hint(),
	} }
	local detailHeader = groups[#groups]
	detailHeader.items[3].hidden = function(get) return selected == nil or not following(get) end

	-- A single set of widgets edits the selected skin's existing profile keys.
	local prefix = "look.__skin."
	local required = {
		Font = "text", ["Text colors"] = "colors", Accent = "colors",
		["Window background"] = "window", ["Window border"] = "window", Controls = "controls",
	}
	local detail = textGroups("__skin", { shadow = true, colors = true })
	for _, group in ipairs(lookGroups("__skin", { window = true, controls = true })) do
		detail[#detail + 1] = group
	end
	for _, group in ipairs(detail) do
		for i = #group.items, 1, -1 do
			if not group.items[i].key then table.remove(group.items, i) end
		end
		for _, row in ipairs(group.items) do
			local field = row.key:sub(#prefix + 1)
			local cap = field == "shadow" and "shadow" or required[group.label]
			local disabled = row.disabled
			local function path()
				local caps = selected and ns.caps[selected]
				if caps and caps[cap] then return "look." .. selected .. "." .. field end
			end
			row.get = function()
				local key = path()
				if key then return DUI:Get(ADDON, key) end
			end
			row.set = function(v)
				local key = path()
				return key ~= nil and DUI:Set(ADDON, key, v)
			end
			row.default = function()
				if path() then return ns.LookDefault(selected, field) end
			end
			row.hidden = function() return path() == nil end
			row.disabled = function(get)
				if not path() then return false end
				return disabled and disabled(function(key)
					if key:sub(1, #prefix) == prefix then
						key = "look." .. selected .. "." .. key:sub(#prefix + 1)
					end
					return get(key)
				end)
			end
			row.noSearch = true
		end
		groups[#groups + 1] = group
	end
	return { id = "addons", label = "AddonSkins", groups = groups, onShow = function() selected = nil end,
		desc = "Open each skin's settings here. Reload the interface after turning skins on or off." }
end

local skinSwitches = ns.MoveSettings()
local pages = { skinPage(skinSwitches) }

-- Settings that extend a DaylightUI feature sit on that feature's DaylightUI
-- page (Daylight's plugin API marks the card "From Blasta"); what DaylightUI
-- has nothing like keeps a page here.
local function pageOf(source) return source and source.groups or {} end
local function toDaylight(pageId, groups, after)
    for _, group in ipairs(groups or {}) do
        group.tab = nil
        ns.AddToDaylight(pageId, group, after)
    end
end

if ns.ExperiencePage then toDaylight("InfoPanel.panel", pageOf(ns.ExperiencePage()), "Experience bar") end
if ns.InfoPanelSpacingPage then toDaylight("InfoPanel.panel", pageOf(ns.InfoPanelSpacingPage())) end
if ns.DataTextColorPage then toDaylight("InfoPanel.data", pageOf(ns.DataTextColorPage())) end
if ns.PlayerAuraLayoutPage then toDaylight("Buffs.buffs", pageOf(ns.PlayerAuraLayoutPage())) end
if ns.AuraReminderPage then toDaylight("Buffs.buffs", pageOf(ns.AuraReminderPage())) end
local unitFrames = DUI:GetModule("UnitFrames")
local barCard = unitFrames and ns.AuraBarCard and ns.AuraBarCard()
if barCard then
    toDaylight("UnitFrames.player", pageOf(ns.ShowDaylightRequirements({ groups = { barCard } }, unitFrames)))
end
if ns.BarEffectsPage then toDaylight("UnitFrames.colors", pageOf(ns.BarEffectsPage())) end
if ns.LootFeedPage then toDaylight("QoL.loot", pageOf(ns.LootFeedPage())) end
if ns.ZoneTitleExtrasGroup then toDaylight("QoL.qol", { ns.ZoneTitleExtrasGroup() }, "Level up, zone and reputation") end
if ns.DungeonFinderGroup then toDaylight("windows", { ns.DungeonFinderGroup }, "Group Finder") end
if ns.SpellbookGroup then toDaylight("windows", { ns.SpellbookGroup }, "Spellbook") end
if ns.MapLevelsGroup then toDaylight("Skins.skins", { ns.MapLevelsGroup }, "World map") end
if ns.CharacterPanelGroup then toDaylight("Character.window", { ns.CharacterPanelGroup }) end

-- Blasta's own: consumable bars, language, profiles and add-on skins.
if ns.ConsumableBarsGroup then
    pages[#pages + 1] = { id = "consumables", label = "Consumable bars", groups = { ns.ConsumableBarsGroup() } }
end
pages[#pages + 1] = ns.GeneralPage()
if ns.ProfileTransferPage then pages[#pages + 1] = ns.ProfileTransferPage() end

-- Pages in the order of the areas they belong to: general, units and auras,
-- the interface, content, then add-on skins and profiles.
local PAGE_ORDER = { "language", "consumables", "addons", "blastaProfiles" }
local rank = {}
for i, id in ipairs(PAGE_ORDER) do rank[id] = i end
for i, page in ipairs(pages) do page.blastaOrder = (rank[page.id] or #PAGE_ORDER + 1) * 1000 + i end
table.sort(pages, function(a, b) return a.blastaOrder < b.blastaOrder end)
for _, page in ipairs(pages) do page.blastaOrder = nil end

ns.LocalizePages(pages)
ns.RegisterSettings(pages)
