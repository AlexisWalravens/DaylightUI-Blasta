if GetLocale() ~= "deDE" then return end

local DUI = DaylightUI
local module = DUI:GetModule("Skins")
local ns = module and module.ns
local pins = ns and ns.MapPins

local places = {
    ["Stormwind"] = "Sturmwind",
    ["Sentinel Hill"] = "Späherkuppe",
    ["Westfall"] = "Westfall",
    ["Lakeshire"] = "Seenhain",
    ["Redridge"] = "Rotkammgebirge",
    ["Ironforge"] = "Eisenschmiede",
    ["Menethil Harbor"] = "Hafen von Menethil",
    ["Wetlands"] = "Sumpfland",
    ["The Sepulcher"] = "Das Grabmal",
    ["Silverpine Forest"] = "Silberwald",
    ["Undercity"] = "Unterstadt",
    ["Darkshire"] = "Dunkelhain",
    ["Duskwood"] = "Dämmerwald",
    ["Tarren Mill"] = "Tarrens Mühle",
    ["Southshore"] = "Süderstade",
    ["Hillsbrad"] = "Vorgebirge des Hügellands",
    ["Refuge Pointe"] = "Die Zuflucht",
    ["Arathi"] = "Arathihochland",
    ["Booty Bay"] = "Beutebucht",
    ["Stranglethorn"] = "Schlingendorntal",
    ["Grom'gol Base Camp"] = "Basislager von Grom'gol",
    ["Badlands"] = "Ödland",
    ["Thunder Bluff"] = "Donnerfels",
    ["Crossroads"] = "Das Wegekreuz",
    ["The Barrens"] = "Brachland",
    ["Darkshore"] = "Dunkelküste",
    ["Rut'theran Village"] = "Rut'theran",
    ["Ashenvale"] = "Eschental",
    ["Sun Rock Retreat"] = "Sonnenfels",
    ["Stonetalon Mountains"] = "Steinkrallengebirge",
    ["Freewind Post"] = "Freiwindposten",
    ["Thousand Needles"] = "Tausend Nadeln",
    ["Dustwallow Marsh"] = "Düstermarschen",
    ["Stonetalon Peak"] = "Steinkrallengipfel",
    ["Nijel's Point"] = "Die Nijelspitze",
    ["Shadowprey Village"] = "Schattenflucht",
    ["Feathermoon"] = "Mondfeder",
    ["Feathermoon Stronghold"] = "Mondfederfeste",
    ["Camp Mojache"] = "Camp Mojache",
    ["Aerie Peak"] = "Nistgipfel",
    ["The Hinterlands"] = "Hinterland",
    ["Nethergarde Keep"] = "Burg Nethergarde",
    ["Blasted Lands"] = "Verwüstete Lande",
    ["Bloodvenom Post"] = "Blutgiftposten",
    ["Felwood"] = "Teufelswald",
    ["Moonglade"] = "Mondlichtung",
    ["Everlook"] = "Ewige Warte",
    ["Winterspring"] = "Winterquell",
    ["Brackenwall Village"] = "Morastwinkel",
    ["Swamp of Sorrows"] = "Sümpfe des Elends",
    ["Zoram'gar Outpost"] = "Außenposten von Zoram'gar",
    ["Alterac Valley"] = "Alteractal",
    ["Frostwolf Keep"] = "Burg Frostwolf",
    ["Splintertree Post"] = "Splitterholzposten",
    ["Nighthaven"] = "Nachthafen",
    ["Talrendis Point"] = "Talrendisspitze",
    ["Talonbranch Glade"] = "Krallenzweiglichtung",
    ["Chillwind Camp"] = "Zugwindlager",
    ["Western Plaguelands"] = "Westliche Pestländer",
    ["Light's Hope Chapel"] = "Kapelle des hoffnungsvollen Lichts",
    ["Eastern Plaguelands"] = "Östliche Pestländer",
    ["Flame Crest"] = "Flammenkamm",
    ["Burning Steppes"] = "Brennende Steppe",
    ["Morgan's Vigil"] = "Morgans Wacht",
    ["Cenarion Hold"] = "Burg Cenarius",
    ["Thorium Point"] = "Thoriumspitze",
    ["Searing Gorge"] = "Sengende Schlucht",
    ["Revantusk Village"] = "Dorf der Bruchhauer",
    ["Camp Taurajo"] = "Camp Taurajo",
    ["Marshal's Refuge"] = "Marschalls Zuflucht",
    ["Un'Goro Crater"] = "Krater von Un'Goro",
    ["Ratchet"] = "Ratschet",
    ["Plaguewood Tower"] = "Turm des Pestwaldes",
    ["Northpass Tower"] = "Nordpassturm",
    ["Eastwall Tower"] = "Ostwallturm",
    ["Crown Guard Tower"] = "Kronenwacht",
    ["Mount Hyjal"] = "Hyjal",
    ["Summit of Eternity"] = "Gipfel der Ewigkeit",
    ["Tainted Foothills"] = "Besudeltes Vorgebirge",
    ["Riverglades"] = "Flusslande",
    ["Farholde Keep"] = "Burg Farholde",
    ["Theramore Isle"] = "Insel Theramore",
    ["Stormwind Harbor"] = "Hafen von Sturmwind",
    ["The Forgotten Coast"] = "Die Vergessene Küste",
    ["Powderfuse Port"] = "Hafen von Powderfuse",
    ["Steamwheedle Port"] = "Dampfdruckpier",
}

local instances = {
    ["Shadowfang Keep"] = "Burg Schattenfang",
    ["Stormwind Stockade"] = "Das Verlies von Sturmwind",
    ["Deadmines"] = "Die Todesminen",
    ["Wailing Caverns"] = "Die Höhlen des Wehklagens",
    ["Razorfen Kraul"] = "Der Kral von Razorfen",
    ["Blackfathom Deeps"] = "Tiefschwarze Grotte",
    ["Sunken Temple"] = "Versunkener Tempel",
    ["Razorfen Downs"] = "Die Hügel von Razorfen",
    ["Scarlet Monastery"] = "Das Scharlachrote Kloster",
    ["Blackrock Spire"] = "Blackrockspitze",
    ["Blackrock Depths"] = "Blackrocktiefen",
    ["Onyxia's Lair"] = "Onyxias Hort",
    ["Ragefire Chasm"] = "Der Flammenschlund",
    ["Molten Core"] = "Geschmolzener Kern",
    ["Dire Maul"] = "Düsterbruch",
    ["Blackwing Lair"] = "Pechschwingenhort",
    ["Ruins of Ahn'Qiraj"] = "Ruinen von Ahn'Qiraj",
    ["Ahn'Qiraj Temple"] = "Tempel von Ahn'Qiraj",
    ["Excavation Site: Wetlands"] = "Ausgrabungsstätte im Sumpfland",
    ["Ruins of Lordaeron"] = "Ruinen von Lordaeron",
    ["The Hall of Thanes"] = "Halle der Thanen",
    ["City of Dalaran"] = "Stadt Dalaran",
}

local qol = DUI:GetModule("QoL")
local flight = qol and qol.ns and qol.ns.Flight
if flight and type(flight.ShortName) == "function" then
    local shortName = flight.ShortName
    local lastName, lastLabel = nil, ""
    function flight.ShortName(name)
        if name ~= lastName then
            local short = shortName(name)
            lastName, lastLabel = name, places[short] or short
        end
        return lastLabel
    end
end

if not (pins and type(pins.For) == "function") then return end

-- MapPins looks up the full flight label in DaylightUI's locale table.
for _, entry in ipairs(ns.MapPinsData and ns.MapPinsData.flights or {}) do
    local name = entry[6]
    if type(name) == "string" and rawget(DUI.L, name) == nil then
        local translated = name:gsub("[^,]+", function(part)
            local space, place = part:match("^(%s*)(.+)$")
            return space .. (places[place] or place)
        end)
        if translated ~= name then DUI.L[name] = translated end
    end
end

-- Dungeon and travel labels normally come from the game in German.
-- Translate the English fallback labels if the client returns no German name.
local fallback = {}
for name, translated in pairs(instances) do fallback[name] = translated end
for _, entry in ipairs(pins.TRAVEL or {}) do
    local name = entry[6]
    if places[name] then
        local formatString = DUI.L[entry[1] == "boat" and "Boat to %s" or "Zeppelin to %s"]
        fallback[formatString:format(name)] = formatString:format(places[name])
    end
end

local getPins = pins.For
local translatedLists = setmetatable({}, { __mode = "k" })
function pins.For(mapID)
    local list = getPins(mapID)
    if type(list) == "table" and not translatedLists[list] then
        for _, pin in ipairs(list) do
            if pin.family ~= "flight" then
                for _, line in ipairs(pin.lines or {}) do
                    line[1] = fallback[line[1]] or line[1]
                end
            end
        end
        translatedLists[list] = true
    end
    return list
end
