-- SPDX-License-Identifier: GPL-3.0-or-later
-- DaylightUI's DoT tracking (DUI.Dots: "DoT damage left" and the DoT skull on
-- the target frame and nameplates) reads a DoT's damage, school and duration
-- from the spell description, with English and French patterns only. German
-- descriptions name the duration first ("das 24 Sek. lang 323 Punkt(e)
-- Schattenschaden zufügt"), which a pattern can't reorder. So on a German
-- client:
--   * German patterns for what's read straight from the description (a
--     finisher, combo points awarded, a weapon poison, a heal), and
--   * each description rewritten into the English form before it's parsed
--     ("323 Shadow damage over 24 sec").
-- /blastadots <spell> shows what a spell's description turns into.
local DUI = DaylightUI
local Dots = DUI and DUI.Dots
if not (Dots and type(Dots.Parse) == "function" and Dots.LOCALES and Dots.UseLocale) or GetLocale() ~= "deDE" then
    return
end

-- Checked against the German text itself (Dots.lua reads these before parsing).
Dots.LOCALES.deDE = {
    finisher = "[Ff]inishing[ %-][Mm]ove%f[%A]", -- "Finishing-Move" or "Finishing move"
    weapon = "berzieht.-[Ww]affe",           -- poisons: "Überzieht eine Waffe ..."
    heal = "^Heilt",
    awards = "(%d+)%s+[CcKk]ombopunkt",     -- "Gewährt 1 Combopunkt."
}
Dots.UseLocale("deDE")

local SCHOOLS = {
    Schatten = "Shadow", Feuer = "Fire", Natur = "Nature", Frost = "Frost", Arkan = "Arcane", Heilig = "Holy",
    Frostfeuer = "Frostfire", Blutungs = "Physical",
}

local function number(text) return (text:gsub(",", ".")) end

-- Pieces of the German wording. A number may be followed by "Punkt(e)" or
-- "Punkte"; the school is the word before "schaden" (none: Physical).
local POINT_WORD = "Punkt%(?e?n?%)?"
local AMOUNT = "(%d+)%s+" .. POINT_WORD .. "%s+"
local NUM = "(%d+)%s+"
local SECS = "(%d+[,.]?%d*) Sek%.?"
local DAMAGE = "(%a*)[Ss]chaden"

-- Damage over time, duration first: "24 Sek. lang 323 Punkt(e) Schattenschaden",
-- "im Verlauf von 18 Sek. 30 Schattenschaden", "über 12 Sek. 186 Naturschaden".
local OVER_SECS_FIRST = {
    SECS .. "%s+lang%s+" .. AMOUNT .. DAMAGE,
    SECS .. "%s+lang%s+" .. NUM .. DAMAGE,
    "[Ii]m Verlauf von " .. SECS .. "%s+" .. AMOUNT .. DAMAGE,
    "[Ii]m Verlauf von " .. SECS .. "%s+" .. NUM .. DAMAGE,
    "über " .. SECS .. "%s+" .. AMOUNT .. DAMAGE,
    "über " .. SECS .. "%s+" .. NUM .. DAMAGE,
    SECS .. "%s+lang bluten und fügt damit%s+" .. AMOUNT .. DAMAGE,
    SECS .. "%s+lang bluten und fügt damit%s+" .. NUM .. DAMAGE,
}
-- Damage first: "20 Punkt(e) Feuerschaden im Verlauf von 15 Sek.", "20 Naturschaden über 15 Sek."
local OVER_DAMAGE_FIRST = {
    AMOUNT .. DAMAGE .. "%s+im Verlauf von " .. SECS,
    NUM .. DAMAGE .. "%s+im Verlauf von " .. SECS,
    AMOUNT .. DAMAGE .. "%s+über " .. SECS,
    NUM .. DAMAGE .. "%s+über " .. SECS,
}
-- A tick every few seconds: "alle 3 Sek. 15 Punkt(e) Schattenschaden",
-- "15 Punkt(e) Schattenschaden alle 3 Sek."
local EVERY_SECS_FIRST = {
    "alle " .. SECS .. "%s+" .. AMOUNT .. DAMAGE,
    "alle " .. SECS .. "%s+" .. NUM .. DAMAGE,
}
local EVERY_DAMAGE_FIRST = {
    AMOUNT .. DAMAGE .. "%s+alle " .. SECS,
    NUM .. DAMAGE .. "%s+alle " .. SECS,
}
-- Health drained every few seconds: "alle 3 Sek. 15 Gesundheit", "15 Gesundheit alle 3 Sek."
local DRAIN_SECS_FIRST = {
    "alle " .. SECS .. "%s+" .. NUM .. "[Gg]esundheit",
    "alle " .. SECS .. "%s+" .. AMOUNT .. "[Gg]esundheit",
    "alle " .. SECS .. "%s+" .. NUM .. "[Ll]ebenspunkt",
}
local DRAIN_AMOUNT_FIRST = {
    NUM .. "[Gg]esundheit.-alle " .. SECS,
    AMOUNT .. "[Gg]esundheit.-alle " .. SECS,
    NUM .. "[Ll]ebenspunkt.-alle " .. SECS,
}
-- How long it lasts: "Hält 30 Sek. lang an.", "Dauert 30 Sek.", "für 30 Sek."
local LASTS = { "[Hh]ält " .. SECS, "[Dd]auert " .. SECS, "für " .. SECS, SECS .. " lang an" }
-- Require a damage amount and duration on the same combo-point entry.
local POINTS = "(%d+)%s+Punkte?%s*:%s*"
local FINISHER_DAMAGE = "%a*[Ss]chaden%s+"
local PER_POINT = {
    POINTS .. AMOUNT .. FINISHER_DAMAGE .. "über " .. SECS,
    POINTS .. NUM .. FINISHER_DAMAGE .. "über " .. SECS,
    POINTS .. AMOUNT .. FINISHER_DAMAGE .. "im Verlauf von " .. SECS,
    POINTS .. NUM .. FINISHER_DAMAGE .. "im Verlauf von " .. SECS,
    POINTS .. NUM .. "über " .. SECS,
    POINTS .. NUM .. "im Verlauf von " .. SECS,
}

local unpackAll = table.unpack or unpack

-- Every match of each pattern, with where it starts: calls found(start, captures...).
local function scan(desc, patterns, found)
    for _, pattern in ipairs(patterns) do
        local from = 1
        while true do
            local result = { desc:find(pattern, from) }
            if not result[1] then break end
            found(unpackAll(result))
            from = result[2] + 1
        end
    end
end

-- The description in the English form DaylightUI parses, or unchanged when
-- there's nothing to translate.
local function english(desc)
    if desc:find(Dots.PATTERNS.weapon) or desc:find(Dots.PATTERNS.heal) then return desc end
    desc = desc:gsub("\194\160", " "):gsub("\226\128\175", " ")
    desc = desc:gsub("(%d)%s+Sekunden?%f[%A]", "%1 Sek.")
    -- Tooltips can group large damage numbers with a German thousands dot.
    local changes
    repeat
        desc, changes = desc:gsub("(%d)%.(%d%d%d)%f[%D]", "%1%2")
    until changes == 0
    -- Direct hits and their periodic component are often joined by
    -- “zusätzlichen Arkanschaden” (Moonfire) or “zusätzlichen Schaden” (Rake).
    desc = desc:gsub("%s+zusätzlich%a*%s+", " "):gsub("%s+insgesamt%s+", " "):gsub("%s+weitere%a*%s+", " ")
    local parts, seen = {}, {}
    local function add(at, text)
        if seen[at] then return end
        seen[at] = true
        parts[#parts + 1] = { at, text }
    end
    local function over(amount, word, secs)
        return amount .. " " .. (SCHOOLS[word] or "") .. " damage over " .. number(secs) .. " sec"
    end
    local function every(amount, word, secs)
        return amount .. " " .. (SCHOOLS[word] or "") .. " damage every " .. number(secs) .. " sec"
    end
    scan(desc, OVER_SECS_FIRST, function(s, _, secs, amount, word) add(s, over(amount, word, secs)) end)
    scan(desc, OVER_DAMAGE_FIRST, function(s, _, amount, word, secs) add(s, over(amount, word, secs)) end)
    scan(desc, EVERY_SECS_FIRST, function(s, _, secs, amount, word) add(s, every(amount, word, secs)) end)
    scan(desc, EVERY_DAMAGE_FIRST, function(s, _, amount, word, secs) add(s, every(amount, word, secs)) end)
    scan(desc, DRAIN_SECS_FIRST, function(s, _, secs, amount)
        add(s, amount .. " health every " .. number(secs) .. " sec")
    end)
    scan(desc, DRAIN_AMOUNT_FIRST, function(s, _, amount, secs)
        add(s, amount .. " health every " .. number(secs) .. " sec")
    end)
    local finisher = desc:find(Dots.PATTERNS.finisher) ~= nil
    if finisher then
        scan(desc, PER_POINT, function(s, _, points, amount, secs)
            -- The generic pattern may already have found the same damage line,
            -- but the combo-point parser specifically needs the points prefix.
            parts[#parts + 1] = { s, points .. " points: " .. amount .. " damage over " .. number(secs) .. " sec" }
        end)
    end
    if #parts == 0 then return desc end
    -- Lasts only matters next to ticks; keep it at the end.
    local lasts = desc:match(SECS .. "%s+lang%s+alle " .. SECS)
    scan(desc, LASTS, function(_, _, secs) lasts = lasts or secs end)
    -- The description's order: the parser takes the last periodic part
    -- (Immolate's burn, not its hit).
    table.sort(parts, function(x, y) return x[1] < y[1] end)
    local out = {}
    if finisher then out[1] = "Finishing move" end
    for _, entry in ipairs(parts) do out[#out + 1] = entry[2] end
    if lasts then out[#out + 1] = "Lasts " .. number(lasts) .. " sec" end
    return table.concat(out, ". ") .. "."
end

local parse = Dots.Parse
function Dots.Parse(desc, combo)
    if type(desc) == "string" and not (issecretvalue and issecretvalue(desc)) then
        local ok, rewritten = pcall(english, desc)
        if ok and rewritten then desc = rewritten end
    end
    return parse(desc, combo)
end

-- /blastadots <spell name>: the spell's description, what Blasta turns it into
-- and what DaylightUI reads from it, plus your DoT damage left on the target.
local spellAliases = {
    zerfetzen = { 1079, 9492, 9493, 9752, 9894, 9896 },
    blutung = { 1943, 8639, 8640, 11273, 11274, 11275 },
}

local function diagnosticSpell(query)
    local id = tonumber(query)
    local ok, info = pcall(C_Spell.GetSpellInfo, id or query)
    if ok and type(info) == "table" and info.spellID then return info.spellID, info.name end
    if id then return id end
    local ranks = spellAliases[query:lower()]
    if not ranks then return end
    local known = IsPlayerSpell or IsSpellKnown
    if known then
        for i = #ranks, 1, -1 do
            if known(ranks[i]) then return ranks[i] end
        end
    end
    return ranks[1]
end

SLASH_BLASTADOTS1 = "/blastadots"
SlashCmdList.BLASTADOTS = function(msg)
    local function say(...) print("|cff7fd0ffBlasta DoTs:|r", ...) end
    msg = strtrim(msg or "")
    local okLeft, left = pcall(Dots.Left, "target")
    say("DoT damage left on target:", okLeft and tostring(left) or "error")
    if msg == "" then return say("Aufruf: /blastadots <Zaubername oder ID> [#Combopunkte], z. B. /blastadots Zerfetzen #5") end
    local spell, points = msg:match("^(.-)%s+#([1-5])$")
    msg = spell or msg
    local id, name = diagnosticSpell(msg)
    if not id then return say("Spell not found:", msg) end
    local okDesc, desc = pcall(C_Spell.GetSpellDescription, id)
    if not okDesc or type(desc) ~= "string" or (issecretvalue and issecretvalue(desc)) then
        return say("Description not readable for", msg, id)
    end
    say(name or msg, id, "description:", desc)
    local okE, rewritten = pcall(english, desc)
    say("Blasta reads it as:", okE and rewritten or "error")
    local okP, total, school, duration, every = pcall(Dots.Parse, desc, tonumber(points))
    if desc:find(Dots.PATTERNS.finisher) then
        say("Finisher:", total and "damage over time" or "direct damage or control (no DoT)")
    end
    say("DaylightUI:", okP and (total and (total .. " damage, school " .. tostring(school) .. ", " .. tostring(duration)
        .. " sec" .. (every and (", every " .. every) or "")) or "not a DoT") or "error")
end
