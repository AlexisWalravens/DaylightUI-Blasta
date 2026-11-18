local ADDON, ns = ...
if not ns.ok then return end

local DUI = DaylightUI

-- Blasta no longer skins other addons (AddonSkins by Glowey_ does that); the call
-- still moves Blasta's rows onto DaylightUI's own pages.
ns.MoveSettings()
local pages = {}

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

-- Blasta's own: consumable bars, language and profiles.
if ns.ConsumableBarsGroup then
    pages[#pages + 1] = { id = "consumables", label = "Consumable bars", groups = { ns.ConsumableBarsGroup() } }
end
pages[#pages + 1] = ns.GeneralPage()
if ns.ProfileTransferPage then pages[#pages + 1] = ns.ProfileTransferPage() end

-- Pages in the order of the areas they belong to: general, units and auras,
-- the interface, content, then profiles.
local PAGE_ORDER = { "language", "consumables", "blastaProfiles" }
local rank = {}
for i, id in ipairs(PAGE_ORDER) do rank[id] = i end
for i, page in ipairs(pages) do page.blastaOrder = (rank[page.id] or #PAGE_ORDER + 1) * 1000 + i end
table.sort(pages, function(a, b) return a.blastaOrder < b.blastaOrder end)
for _, page in ipairs(pages) do page.blastaOrder = nil end

ns.LocalizePages(pages)
ns.RegisterSettings(pages)
