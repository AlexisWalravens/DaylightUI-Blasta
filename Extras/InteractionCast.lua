-- SPDX-License-Identifier: GPL-3.0-or-later
if GetLocale() ~= "deDE" then return end

local mod = DaylightUI:GetModule("UnitFrames")
local cast = mod and mod.ns and mod.ns.CastBar
if not (cast and cast.Refresh and UnitCastingInfo) then return end

local names = {
    Gathering = "Sammeln", Collecting = "Sammeln", Collect = "Sammeln",
    Opening = "Öffnen", Open = "Öffnen", Looting = "Aufheben",
}
local function translated(name)
    if (issecretvalue and issecretvalue(name)) or type(name) ~= "string" then return end
    return names[(name:gsub("[%.…]+$", ""))]
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
