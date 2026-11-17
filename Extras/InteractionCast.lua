-- SPDX-License-Identifier: GPL-3.0-or-later
if GetLocale() ~= "deDE" then return end

local mod = DaylightUI:GetModule("UnitFrames")
local cast = mod and mod.ns and mod.ns.CastBar
if not (cast and cast.Refresh and UnitCastingInfo) then return end

local names = {
    gathering = "Sammeln", collecting = "Sammeln", collect = "Sammeln",
    opening = "Öffnen", open = "Öffnen", looting = "Aufheben",
}
-- The client's own names for these, untranslated even on German clients,
-- some with a tag after a dash ("Opening - No Text" when picking up a
-- quest item). Case and trailing dots don't matter.
local function translated(name)
    if (issecretvalue and issecretvalue(name)) or type(name) ~= "string" then return end
    local key = name:gsub("[%.…]+$", ""):gsub("%s*[%-–]%s*[Nn]o [Tt]ext$", "")
    return names[key:lower()]
end

hooksecurefunc(cast, "Refresh", function(bar)
    if bar.unit ~= "player" or bar.test or not bar.enabled or not bar:IsShown()
        or not bar.duration or bar.channel or not bar.text
        or (bar.spellCfg and bar.spellCfg.show == false) then return end
    local current = bar.text:GetText()
    if issecretvalue and issecretvalue(current) then return end
    local replacement = translated(current)
    if current == nil or current == "" then
        local raw, display = UnitCastingInfo("player")
        replacement = translated(display) or translated(raw)
        if not replacement and not (issecretvalue and issecretvalue(raw)) and type(raw) == "string" and raw ~= "" then
            replacement = raw
        end
    end
    if replacement then bar.text:SetText(replacement) end
end)
