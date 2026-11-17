local _, extras = ...

-- German fallbacks for DaylightUI and shared labels used by Blasta.
local translations = {
    ["DoT damage left"] = "Verbleibender DoT-Schaden",
    ["A small skull by the bar once your damage over time is enough to finish that enemy."] =
        "Zeigt einen kleinen Totenkopf neben der Leiste, wenn dein verbleibender Schaden über Zeit den Gegner voraussichtlich besiegt.",
    ["A small Alliance or Horde banner before each friend's character, and their faction in the tooltip."] = "Zeigt das Fraktionswappen vor dem Charakternamen und die Fraktion im Tooltip.",
    ["All, Same game and Online chips over the friends list, to show only the friends you can play with or the ones who are on."] = "Filtert die Freundesliste nach allen Freunden, Freunden im selben Spiel oder Freunden, die online sind.",
    ["Vertical stands the bar upright, filling from the bottom to the top. Its width is then how tall it stands, and its height how thick."] = "Senkrecht füllt sich die Leiste von unten nach oben. Die Breite bestimmt dann ihre Länge, die Höhe ihre Dicke.",
    ["Vertical stands the separate bar upright, filling from the bottom to the top. Its width is then how tall it stands, and its height how thick."] = "Senkrecht füllt sich die separate Leiste von unten nach oben. Die Breite bestimmt dann ihre Länge, die Höhe ihre Dicke.",
    ["While your interrupt is on cooldown, a thin line on an enemy's cast bar shows where it comes back. No line: it's ready now, or it won't be back before the cast ends."] = "Eine Linie auf der gegnerischen Zauberleiste zeigt, wann deine Unterbrechung wieder bereit ist. Sie erscheint, wenn die Abklingzeit vor Ende des Zaubers abläuft.",
    ["While your interrupt is on cooldown, a thin line on an enemy target's or focus's cast bar shows where it comes back. No line: it's ready now, or it won't be back before the cast ends."] = "Eine Linie auf der Zauberleiste des gegnerischen Ziels oder Fokus zeigt, wann deine Unterbrechung wieder bereit ist. Sie erscheint, wenn die Abklingzeit vor Ende des Zaubers abläuft.",
    ["Who an enemy's spell is aimed at, in their class color, on the right of its cast bar. Spells with no one target (an area spell, a self heal) show none."] = "Zeigt rechts auf der gegnerischen Zauberleiste das Zauberziel in seiner Klassenfarbe. Bei Flächenzaubern und Selbstheilung bleibt die Anzeige leer.",
    ["After you cast a spell that costs mana, a light crosses your mana bar for the 5 seconds until your Spirit regen is back. Shows on your player frame and personal display."] = "Nach einem Zauber mit Manakosten zeigt ein Lichtlauf die fünf Sekunden bis zur nächsten Manaregeneration durch Willenskraft. Er erscheint am Spielerrahmen und in der persönlichen Anzeige.",
    ["You get back %.0f mana every 5 seconds while casting."] = "Beim Zauberwirken regenerierst du alle 5 Sekunden %.0f Mana.",
    ["Your attacks ignore %.0f of the target's armor."] = "Deine Angriffe ignorieren %.0f Punkte der Rüstung des Ziels.",
    ["Your spells ignore %.0f of the target's resistances."] = "Deine Zauber ignorieren %.0f Punkte der Widerstände des Ziels.",
    ["Dragging spells to your bars works out of combat."] = "Außerhalb des Kampfes kannst du Zauber auf deine Aktionsleisten ziehen.",
    ["Bind keys opens after combat."] = "Die Tastenbelegung öffnet sich nach dem Kampf.",
    ["/dui bug - your version, addons and setup, ready to copy into the Discord bug form"] = "/dui bug - Version, Addons und Einstellungen für den Fehlerbericht auf Discord",
    ["Click a box and press Ctrl+C, then paste it into the Discord form."] = "Klicke in ein Feld, kopiere den Inhalt mit Strg+C und füge ihn in das Discord-Formular ein.",
    ["%d of %d"] = "%d von %d",
    ["%s and %s"] = "%s und %s",
    ["ABSORBS"] = "ABSORPTION",
    ["All characters of this faction"] = "Alle Charaktere dieser Fraktion",
    ["Alliance"] = "Allianz",
    ["Angled ends on"] = "Abgeschrägte Enden aktiv",
    ["Armor penetration"] = "Rüstungsdurchschlag",
    ["Arrow size"] = "Pfeilgröße",
    ["At a glance"] = "Auf einen Blick",
    ["Attackers"] = "Angreifer",
    ["Avoidable"] = "Vermeidbar",
    ["Battlegrounds"] = "Schlachtfelder",
    ["Beside the meter"] = "Neben der Anzeige",
    ["Bind"] = "Belegen",

    ["Blessing"] = "Segen",
    ["Browse profiles"] = "Profile durchsuchen",
    ["Buy a stack"] = "Stapel kaufen",
    ["Cast target"] = "Ziel des Zaubers",
    ["Casts on the cursor ring"] = "Zauberfortschritt am Mauszeiger",
    ["Change with forms and stances"] = "Bei Gestalt- und Haltungswechsel umschalten",
    ["Choose"] = "Auswählen",
    ["Choose reward"] = "Belohnung auswählen",
    ["Compare items"] = "Gegenstände vergleichen",
    ["Conversation height"] = "Höhe des Gesprächsfensters",
    ["Conversation opens"] = "Gesprächsfenster öffnen bei",
    ["Copy %s"] = "%s kopieren",
    ["Copy its setup"] = "Einstellungen kopieren",
    ["Ctrl + mouse wheel"] = "Strg + Mausrad",
    ["Cursor ring"] = "Ring am Mauszeiger",
    ["Cursor ring color"] = "Farbe des Mauszeigerrings",
    ["Cursor ring glow"] = "Leuchtsaum des Mauszeigerrings",
    ["Cursor ring motion"] = "Animation des Mauszeigerrings",
    ["Cursor ring opacity"] = "Deckkraft des Mauszeigerrings",
    ["Cursor ring size"] = "Größe des Mauszeigerrings",
    ["Cursor trail"] = "Mauszeigerspur",
    ["Custom cursor ring color"] = "Eigene Farbe des Mauszeigerrings",
    ["Custom overshield color"] = "Eigene Farbe für überschüssige Absorption",
    ["Daylight UI version"] = "DaylightUI-Version",
    ["Death"] = "Tod",
    ["Dim friends you can't play with"] = "Derzeit nicht verfügbare Freunde abdunkeln",
    ["Druid bars height"] = "Höhe der Druidenleisten",
    ["Druid bars numbers"] = "Zahlen auf Druidenleisten",
    ["Druid bars width"] = "Breite der Druidenleisten",
    ["Druid resource bars"] = "Ressourcenleisten für Druiden",
    ["Execute icon"] = "Symbol für Finisher",
    ["Experience bar orientation"] = "Ausrichtung der EP-Leiste",
    ["Faction"] = "Fraktion",
    ["Faction icons"] = "Fraktionssymbole",
    ["Fight summary"] = "Kampfzusammenfassung",
    ["Filter chips"] = "Filterschaltflächen",
    ["Flash when the global cooldown ends"] = "Am Ende der globalen Abklingzeit aufleuchten",
    ["Flying"] = "Fliegend",
    ["Form or stance"] = "Gestalt oder Haltung",
    ["Frames grow"] = "Anordnungsrichtung der Rahmen",
    ["Free slots"] = "Freie Plätze",
    ["Friend alerts"] = "Freundesbenachrichtigungen",
    ["From Stamina, gear and buffs."] = "Durch Ausdauer, Ausrüstung und Stärkungseffekte.",
    ["From your class, gear and buffs."] = "Durch Klasse, Ausrüstung und Stärkungseffekte.",
    ["From your gear, buffs and talents."] = "Durch Ausrüstung, Stärkungseffekte und Talente.",
    ["Fully rested"] = "Vollständig erholt",
    ["Global cooldown on the ring"] = "Globale Abklingzeit am Ring",
    ["Group focus"] = "Hauptziel der Gruppe",
    ["Group focus mark"] = "Markierung für das Hauptziel der Gruppe",
    ["Group mark"] = "Gruppenmarkierung",
    ["Heal indicator look"] = "Darstellung der Heilungsanzeige",
    ["Horde"] = "Horde",
    ["Keep the spellbook in a fight"] = "Zauberbuch im Kampf offen halten",
    ["Keybind"] = "Tastenbelegung",
    ["Killing blow"] = "Todesstoß",
    ["Levels beside names"] = "Stufen neben Namen anzeigen",
    ["Line round the middle"] = "Linie in der Ringmitte",
    ["Missing health opacity"] = "Deckkraft bei fehlender Gesundheit",
    ["Mouseover light"] = "Hervorhebung beim Darüberfahren",
    ["NPC names"] = "NSC-Namen",
    ["Nameplate report"] = "Bericht zu Namensplaketten",
    ["New window"] = "Neues Fenster",
    ["No death in this fight."] = "In diesem Kampf ist niemand gestorben.",
    ["No fights yet."] = "Noch keine Kämpfe aufgezeichnet.",
    ["Not now"] = "Jetzt nicht",
    ["Off-hand damage"] = "Schaden der Nebenhand",
    ["On land"] = "An Land",
    ["Other faction names"] = "Namen der gegnerischen Fraktion",
    ["Other faction's crest"] = "Wappen der gegnerischen Fraktion",
    ["Overkill %s"] = "Überschüssiger Schaden: %s",
    ["Overshield"] = "Überschüssige Absorption",
    ["Overshield color"] = "Farbe der überschüssigen Absorption",
    ["Overshield texture"] = "Textur der überschüssigen Absorption",
    ["Own arrow color"] = "Eigene Pfeilfarbe",
    ["Own window"] = "Eigenes Fenster",
    ["Page %d"] = "Seite %d",
    ["Pages"] = "Seiten",
    ["Pet happiness (hunters)"] = "Zufriedenheit des Begleiters (Jäger)",
    ["Pet info"] = "Begleiterinformationen",
    ["Place in bags"] = "In die Taschen legen",
    ["Plate size by threat"] = "Größe der Namensplakette nach Bedrohung",
    ["Player names"] = "Spielernamen",
    ["Portrait rings"] = "Porträtrahmen",
    ["Preview the sleeping bag timer"] = "Schlafsack-Timer in der Vorschau anzeigen",
    ["Quest mob color"] = "Farbe für Questgegner",
    ["Quest mobs in their own color"] = "Eigene Farbe für Questgegner",
    ["Report a bug"] = "Fehler melden",
    ["Reputation bar orientation"] = "Ausrichtung der Rufleiste",
    ["Ring around the cursor"] = "Ring um den Mauszeiger",
    ["Second panel text size"] = "Schriftgröße des zweiten Chatfensters",
    ["Settings"] = "Einstellungen",
    ["Shared by players"] = "Von Spielern geteilt",
    ["Show the cursor ring"] = "Ring am Mauszeiger anzeigen",
    ["Show when alone"] = "Auch ohne Gruppe anzeigen",
    ["Sleeping bag timer"] = "Schlafsack-Timer",
    ["Soul bag size"] = "Größe des Seelenbeutels",
    ["Soul bag slots"] = "Plätze im Seelenbeutel",
    ["Speed"] = "Geschwindigkeit",
    ["Spell penetration"] = "Zauberdurchschlag",
    ["Spells"] = "Zauber",
    ["Stacks and charges"] = "Stapel und Aufladungen",
    ["Swimming"] = "Schwimmend",
    ["Tab settings"] = "Reitereinstellungen",
    ["Talent sets"] = "Talentverteilungen",
    ["Target arrows"] = "Zielpfeile",
    ["Target icons"] = "Zielsymbole",
    ["Targets"] = "Ziele",
    ["Thunder Bluff"] = "Donnerfels",
    ["Trade District"] = "Handelsdistrikt",
    ["Tradeskills"] = "Berufe",
    ["Turn off"] = "Ausschalten",
    ["Turn on"] = "Einschalten",
    ["Undercity"] = "Unterstadt",
    ["Valley of Honor"] = "Tal der Ehre",
    ["Where weapon masters stand"] = "Standorte der Waffenmeister",
    ["You can take %.0f damage before you die."] = "Du kannst noch %.0f Schaden erleiden.",
    ["You cast %.1f%% faster."] = "Du wirkst Zauber %.1f%% schneller.",
    ["You shoot %.1f%% faster."] = "Du schießt %.1f%% schneller.",
    ["You swing %.1f%% faster."] = "Du führst Nahkampfangriffe %.1f%% schneller aus.",
    ["Deadly"] = "Tödlich",
    ["Earlier error"] = "Vorheriger Fehler",
    ["Later error"] = "Nächster Fehler",
    ["Every number, by player"] = "Alle Werte nach Spieler",
    ["Every setting"] = "Alle Einstellungen",
    ["Falls and durability"] = "Stürze und Haltbarkeit",
    ["Fight on: updates when it ends."] = "Kampf läuft. Die Anzeige wird danach aktualisiert.",
    ["Find your perfect setup"] = "Passendes Profil finden",
    ["Finish the setup guide first."] = "Schließe zuerst die Einrichtung ab.",
    ["For your class"] = "Für deine Klasse",
    ["Gold characters"] = "Charaktere in der Goldanzeige",
    ["Happiness left / right"] = "Begleiterzufriedenheit links / rechts",
    ["Happiness up / down"] = "Begleiterzufriedenheit hoch / runter",
    ["Happiness look"] = "Darstellung der Begleiterzufriedenheit",
    ["Happiness position"] = "Position der Begleiterzufriedenheit",
    ["Happiness size"] = "Größe der Zufriedenheitsanzeige",
    ["Import one here"] = "Hier importieren",
    ["Info Panel > Meters"] = "Infopanel > Kampfstatistiken",
    ["Monthly supporters"] = "Monatliche Unterstützer",
    ["Mouseover"] = "Beim Darüberfahren",
    ["Move anything"] = "Elemente verschieben",
    ["Nothing here for this player yet."] = "Für diesen Spieler liegen noch keine Daten vor.",
    ["Opening"] = "Wird geöffnet",
    ["Other UI addons (bars, plates, bags...)"] = "Andere Interface-Addons (Leisten, Namensplaketten, Taschen …)",
    ["Other bars"] = "Andere Leisten",
    ["Overshield from the other end"] = "Überschüssige Absorption vom anderen Ende",
    ["Own spot"] = "Eigene Position",
    ["Pets fill upward"] = "Begleiter von unten nach oben anordnen",
    ["Separate second panel text size"] = "Eigene Schriftgröße für das zweite Chatfenster",
    ["Show me around"] = "Rundgang starten",
    ["Skip tour"] = "Rundgang überspringen",
    ["Slides out from"] = "Fährt aus von",
    ["Take a tour?"] = "Rundgang starten?",
    ["Take the tour"] = "Rundgang starten",
    ["The tour waits until the fight is over."] = "Der Rundgang startet nach dem Kampf.",
    ["Target text left / right inside the frame"] = "Zieltext im Rahmen links / rechts",
    ["Target text up / down inside the frame"] = "Zieltext im Rahmen hoch / runter",
    ["Target: name size"] = "Schriftgröße des Zielnamens",
    ["Threat size: about to switch"] = "Größe bei drohendem Zielwechsel",
    ["Threat size: attacking you"] = "Größe, wenn der Gegner dich angreift",
    ["Threat size: not attacking you"] = "Größe, wenn der Gegner jemand anderen angreift",
    ["The most you can hold for your abilities."] = "Maximale Ressource für deine Fähigkeiten.",

    ["%d bar"] = "%d Leiste",
    ["%d bars"] = "%d Leisten",
    ["%d buff"] = "%d Stärkung",
    ["%d buffs"] = "%d Stärkungen",
    ["%d cooldown"] = "%d Abklingzeit",
    ["%d cooldowns"] = "%d Abklingzeiten",
    ["%d quests to turn in"] = "%d abgabebereite Quests",
    ["%d utility"] = "%d Hilfsfähigkeiten",
    ["%s (drag items here)"] = "%s (Gegenstände hierher ziehen)",
    ["%s, talent set %d"] = "%s, Talentverteilung %d",
    ["Addon skins"] = "Addon-Skins",
    ["Basics"] = "Grundlagen",
    ["Spirit"] = "Willenskraft",
    ["New ranks on your bars"] = "Neue Zauberränge automatisch einsetzen",
    ["When you learn a new rank of a spell, it takes the place of the rank before it on your bars. A lower rank you keep on purpose, like rank 1 to save mana, stays. Not macros."] = "Ein neu erlernter Zauberrang ersetzt seinen direkten Vorgänger auf den Aktionsleisten. Ältere Ränge und Makros bleiben erhalten.",
    ["Ring thickness"] = "Dicke des Porträtrahmens",
    ["Action bars, short"] = "Aktionsleisten, kurz",
    ["Add by ID"] = "Per ID hinzufügen",
    ["Also supporting"] = "Weitere Unterstützer",
    ["Ambience"] = "Umgebungsgeräusche",
    ["Anchor: %s"] = "Anker: %s",
    ["another frame adds it to this group, or takes it out"] = "Ein anderer Rahmen fügt ihn der Gruppe hinzu oder entfernt ihn daraus",
    ["AP"] = "AP",
    ["Arrow keys move it, Shift a grid step"] = "Mit den Pfeiltasten verschieben, mit Umschalt um einen Rasterschritt",
    ["Best in your bags"] = "Beste Gegenstände in deinen Taschen",
    ["Chat menu: emotes and languages (speaking %s)"] = "Chatmenü: Emotes und Sprachen (du sprichst %s)",
    ["Chat menu: emotes and languages"] = "Chatmenü: Emotes und Sprachen",
    ["Clear all"] = "Alles leeren",
    ["Click again: pinned ones stay"] = "Erneut klicken. Angeheftete Einträge bleiben erhalten.",
    ["Click: mute all sound"] = "Klick: Ton stummschalten",
    ["Click: sound back on"] = "Klick: Ton einschalten",
    ["Click: use (after combat)"] = "Klick: nach dem Kampf benutzen",
    ["Click: use"] = "Klick: benutzen",
    ["Combat text"] = "Kampftext",
    ["Community invites only open from the game's own chat: set Chat style to Classic, then click it."] = "Community-Einladungen lassen sich im Spielchat öffnen. Stelle den Chatstil auf Klassisch und klicke erneut.",
    ["Cooking"] = "Kochkunst",
    ["Cooldown layout report saved. Type /reload, then send your DaylightUI.lua file."] = "Der Bericht zum Abklingzeiten-Layout wurde gespeichert. Gib /reload ein und sende anschließend deine Datei DaylightUI.lua.",
    ["Crit"] = "Krit",
    ["Ctrl-click"] = "Strg-Klick",
    ["DaylightUI saved the crowd control alert's position. Reload to put it in place?"] = "DaylightUI hat die Position der Kontrollverlustanzeige gespeichert. Oberfläche neu laden, um sie zu übernehmen?",
    ["DaylightUI saved these positions. Reload to put them in place?"] = "DaylightUI hat diese Positionen gespeichert. Oberfläche neu laden, um sie zu übernehmen?",
    ["Effects"] = "Effekte",
    ["Enchanting"] = "Verzauberkunst",
    ["Equipped"] = "Angelegt",
    ["Flash Heal"] = "Blitzheilung",
    ["Group %d (%d)"] = "Gruppe %d (%d)",
    ["Import a Cooldown Manager layout"] = "Layout des Abklingzeitenmanagers importieren",
    ["Imported the Cooldown Manager profile %s, used by talent set %d."] = "Das Profil %s des Abklingzeitenmanagers wurde für Talentverteilung %d importiert.",
    ["Imported"] = "Importiert",
    ["In your bags"] = "In deinen Taschen",
    ["In your layout: click to move it here."] = "Bereits im Layout. Klicke, um es hierher zu verschieben.",
    ["it has no layouts in it"] = "enthält keine Layouts",
    ["it's damaged (was all of it copied?)"] = "ist beschädigt (wurde der ganze Text kopiert?)",
    ["it's from a newer game version"] = "stammt aus einer neueren Spielversion",
    ["it's made for a %s"] = "ist für die Klasse %s vorgesehen",
    ["Item ID:"] = "Gegenstands-ID:",
    ["Last fight"] = "Letzter Kampf",
    ["Last sold"] = "Zuletzt verkauft",
    ["Layout %s: %s."] = "Layout %s: %s.",
    ["Lock the chat's spot and size"] = "Position und Größe des Chats sperren",
    ["Master"] = "Gesamtlautstärke",
    ["Move to main panel"] = "In das Hauptfenster verschieben",
    ["Move to second panel"] = "In das zweite Fenster verschieben",
    ["Move together"] = "Gemeinsam verschieben",
    ["Muted"] = "Stummgeschaltet",
    ["No group"] = "Keine Gruppe",
    ["No Hearthstone in your bags."] = "Du hast keinen Ruhestein in deinen Taschen.",
    ["No item has that ID."] = "Es gibt keinen Gegenstand mit dieser ID.",
    ["No spell has that ID."] = "Es gibt keinen Zauber mit dieser ID.",
    ["no spells this character has"] = "enthält keine Zauber, die dieser Charakter beherrscht",
    ["none of its spells are in this game"] = "enthält keine Zauber aus dieser Spielversion",
    ["not in combat"] = "im Kampf nicht verfügbar",
    ["Now"] = "Jetzt",
    ["Numbers from before the fight."] = "Werte vor dem Kampf.",
    ["Overpower"] = "Überwältigen",
    ["Paste a layout string from the game's Cooldown Manager (its Export), a guide or another UI (Ctrl+V). It becomes a new profile, used by talent set %d."] = "Füge mit Strg+V einen Layout-Export aus dem Abklingzeitenmanager, einem Guide oder einer anderen Oberfläche ein. Daraus entsteht ein neues Profil für Talentverteilung %d.",
    ["Play it again"] = "Erneut abspielen",
    ["Play the quest's voice"] = "Questvertonung abspielen",
    ["Remove group from layout"] = "Gruppe aus dem Layout entfernen",
    ["Right-click: pick a channel"] = "Rechtsklick: Kanal auswählen",
    ["Right-click: pick a profession"] = "Rechtsklick: Beruf auswählen",
    ["Right-click: remove a character"] = "Rechtsklick: Charakter entfernen",
    ["Shards"] = "Splitter",
    ["Soul Shards"] = "Seelensplitter",
    ["SP"] = "ZM",
    ["Spell ID:"] = "Zauber-ID:",
    ["Stop the voice"] = "Vertonung stoppen",
    ["Tailoring"] = "Schneiderei",
    ["Takes every spell of this group out of the layout; they go back to the tray."] = "Alle Zauber dieser Gruppe werden aus dem Layout entfernt und kommen zurück in die Ablage.",
    ["that isn't a Cooldown Manager string"] = "ist kein Export des Abklingzeitenmanagers",
    ["That item has no use to time."] = "Dieser Gegenstand hat keinen benutzbaren Effekt mit Abklingzeit.",
    ["The crowd control alert's spot is kept by the game's Edit Mode, and you're on an Edit Mode layout of your own: move it there (Esc > Edit Mode)."] = "Dein eigenes Layout verwaltet die Position der Kontrollverlustanzeige. Verschiebe sie im Bearbeitungsmodus über das Spielmenü (Esc).",
    ["The layout: %s."] = "Das Layout: %s.",
    ["They come back if you log in on them."] = "Sie erscheinen wieder, sobald du dich mit ihnen einloggst.",
    ["this game client can't read it"] = "kann von diesem Spielclient nicht gelesen werden",
    ["Trade (Local)"] = "Handel (Lokal)",
    ["Trade (Services)"] = "Handel (Dienstleistungen)",
    ["try again in a moment"] = "versuche es gleich noch einmal",
    ["Type a number."] = "Gib eine Zahl ein.",
    ["Unlock the chat: drag the tab row to move it, a corner to size it"] = "Entsperre den Chat. Ziehe die Reiterleiste zum Verschieben oder eine Ecke zum Ändern der Größe.",
    ["Voice chat and channels"] = "Sprachchat und Kanäle",
    ["Volume"] = "Lautstärke",
    ["Wheel: louder or quieter"] = "Mausrad: lauter oder leiser",
    ["Active border and glow color"] = "Farbe für aktiven Rahmen und Leuchten",
    ["Apply opacity to every window"] = "Deckkraft auf alle Fenster anwenden",
    ["Bar background opacity"] = "Deckkraft des Leistenhintergrunds",
    ["Boss color"] = "Bossfarbe",
    ["Bosses in their own color"] = "Bosse in eigener Farbe",
    ["Brew"] = "Alchemie",
    ["Cast bar on the personal display"] = "Zauberleiste auf der persönlichen Anzeige",
    ["Caster color"] = "Farbe für Zauberwirker",
    ["Casters in their own color"] = "Zauberwirker in eigener Farbe",
    ["Chat input text size"] = "Schriftgröße der Chat-Eingabe",
    ["Chat menu button"] = "Chatmenü-Schaltfläche",
    ["Chat tab text size"] = "Schriftgröße der Chatreiter",
    ["Class-colored names and numbers"] = "Namen und Zahlen in Klassenfarbe",
    ["Clock color"] = "Farbe der Uhr",
    ["Coordinates color"] = "Koordinatenfarbe",
    ["Coordinates text size"] = "Schriftgröße der Koordinaten",
    ["Copy profile"] = "Profil kopieren",
    ["Custom active border and glow color"] = "Eigene Farbe für aktiven Rahmen und Leuchten",
    ["Custom guild color"] = "Eigene Gildenfarbe",
    ["Custom job color"] = "Eigene Farbe für NSC-Rollen",
    ["Custom level color"] = "Eigene Stufenfarbe",
    ["Custom threat % color"] = "Eigene Farbe für Bedrohung in Prozent",
    ["Damage meter side"] = "Seite der Schadensanzeige",
    ["Data bar accent line"] = "Akzentlinie der Datenleiste",
    ["Data bar angled ends"] = "Abgeschrägte Enden der Datenleiste",
    ["Data bar border opacity"] = "Deckkraft des Datenleistenrahmens",
    ["Data bar height"] = "Höhe der Datenleiste",
    ["Data bar icons"] = "Symbole in der Datenleiste",
    ["Data bar labels"] = "Beschriftungen der Datenleiste",
    ["Data bar text size"] = "Schriftgröße der Datenleiste",
    ["Data bar width"] = "Breite der Datenleiste",
    ["Data bar"] = "Datenleiste",
    ["Detach as group"] = "Als Gruppe lösen",
    ["Detached bars"] = "Gelöste Leisten",
    ["Experience bar fade"] = "Erfahrungsleiste ausblenden",
    ["Experience bar has its own fade"] = "Erfahrungsleiste separat ausblenden",
    ["Fishing water"] = "Angelwasser",
    ["Flip the loot feed left and right"] = "Beute-Feed horizontal spiegeln",
    ["Forge"] = "Schmiede",
    ["Framerate color"] = "Farbe der Bildrate",
    ["Glow on an active spell"] = "Aktiven Zauber hervorheben",
    ["Glow on chests"] = "Truhen hervorheben",
    ["Glow on everything else"] = "Andere Objekte hervorheben",
    ["Glow on ore and herbs"] = "Erz und Kräuter hervorheben",
    ["Glow on quest objects"] = "Questobjekte hervorheben",
    ["Glow on your fishing bobber"] = "Angelpose hervorheben",
    ["Group name color"] = "Farbe der Gruppennamen",
    ["Group names"] = "Gruppennamen",
    ["Guild size"] = "Gildengröße",
    ["Health text position"] = "Position der Lebensanzeige",
    ["Hide friendly plates in instances"] = "Verbündete Namensplaketten in Instanzen ausblenden",
    ["Import a layout"] = "Layout importieren",
    ["In instances"] = "In Instanzen",
    ["Job color"] = "Farbe der NSC-Rolle",
    ["Job size"] = "Schriftgröße der NSC-Rolle",
    ["Keep tracking on"] = "Aufspüren aktiv halten",
    ["Level size"] = "Schriftgröße der Stufe",
    ["Light the border on an active spell"] = "Rahmen eines aktiven Zaubers hervorheben",
    ["Loot window animations"] = "Animationen des Beutefensters",
    ["Loot window flash"] = "Aufblitzen im Beutefenster",
    ["Mana regen sweep"] = "Animation der Manaregeneration",
    ["Meter numbers"] = "Zahlenformat der Anzeige",
    ["Minimap box border"] = "Rahmen der Minikarte",
    ["Minimap box"] = "Minikartenfenster",
    ["Minimap tracking"] = "Aufspüren auf der Minikarte",
    ["New options"] = "Neue Optionen",
    ["Object glow color"] = "Farbe der Objekthervorhebung",
    ["Object glow height"] = "Höhe der Objekthervorhebung",
    ["Object glow in dungeons and raids"] = "Objekte in Dungeons und Schlachtzügen hervorheben",
    ["Object glow in fights"] = "Objekte im Kampf hervorheben",
    ["Object glow look"] = "Stil der Objekthervorhebung",
    ["Object glow"] = "Objekthervorhebung",
    ["Objects in the world"] = "Objekte in der Welt",
    ["Party cast bar text size"] = "Schriftgröße der Gruppen-Zauberleisten",
    ["Party cast bars"] = "Zauberleisten der Gruppe",
    ["Party members on a quest"] = "Gruppenmitglieder mit derselben Quest",
    ["Personal absorbs"] = "Absorption auf der persönlichen Anzeige",
    ["Personal display angle"] = "Winkel der persönlichen Anzeige",
    ["Personal health bar"] = "Lebensleiste auf der persönlichen Anzeige",
    ["Personal incoming heals"] = "Eingehende Heilung auf der persönlichen Anzeige",
    ["Power bar gap"] = "Abstand zur Ressourcenleiste",
    ["Power bar on"] = "Ressourcenleiste anzeigen bei",
    ["Preview the brew"] = "Alchemie-Vorschau",
    ["Preview the fishing water"] = "Angelwasser-Vorschau",
    ["Preview the forge"] = "Schmiede-Vorschau",
    ["Preview the object glow"] = "Objekthervorhebung ansehen",
    ["Preview the sewing"] = "Schneiderei-Vorschau",
    ["Preview the workshop"] = "Werkstatt-Vorschau",
    ["Rare color"] = "Farbe seltener Gegner",
    ["Rares in their own color"] = "Seltene Gegner in eigener Farbe",
    ["Roleplay names"] = "Rollenspielnamen",
    ["Second chat panel"] = "Zweites Chatfenster",
    ["Second panel background opacity"] = "Hintergrunddeckkraft des zweiten Chatfensters",
    ["Second panel height"] = "Höhe des zweiten Chatfensters",
    ["Second panel hides"] = "Zweites Chatfenster ausblenden",
    ["Second panel width"] = "Breite des zweiten Chatfensters",
    ["Second panel"] = "Zweites Fenster",
    ["Separate chat input text size"] = "Eigene Schriftgröße der Chat-Eingabe",
    ["Separate second panel background opacity"] = "Eigene Hintergrunddeckkraft für das zweite Chatfenster",
    ["Sewing"] = "Schneiderei",
    ["Show keybinds on icons"] = "Tastenbelegungen auf Symbolen anzeigen",
    ["Show leader tools"] = "Werkzeuge für Gruppenleiter anzeigen",
    ["Show NEW on options added since"] = "Neue Optionen markieren ab Version",
    ["Show party cast bars"] = "Zauberleisten der Gruppe anzeigen",
    ["Show quest tooltips"] = "Quest-Tooltips anzeigen",
    ["Show the data bar"] = "Datenleiste anzeigen",
    ["Show XP from finished quests"] = "EP aus abgeschlossenen Quests anzeigen",
    ["Special mobs"] = "Besondere Gegner",
    ["Spell icon side"] = "Seite des Zaubersymbols",
    ["Swing timers on the personal display"] = "Schlagtimer auf der persönlichen Anzeige",
    ["Threat % color"] = "Farbe der Bedrohung in Prozent",
    ["Threat % size"] = "Schriftgröße der Bedrohung in Prozent",
    ["Threat %"] = "Bedrohung in Prozent",
    ["Threat color style"] = "Farbstil für Bedrohung",
    ["Threat tag angled end"] = "Abgeschrägtes Ende der Bedrohungsanzeige",
    ["Threat tag box"] = "Rahmen der Bedrohungsanzeige",
    ["Threat tag color"] = "Farbe der Bedrohungsanzeige",
    ["Threat tag height"] = "Höhe der Bedrohungsanzeige",
    ["Threat tag left / right"] = "Bedrohungsanzeige links / rechts",
    ["Threat tag position"] = "Position der Bedrohungsanzeige",
    ["Threat tag text size"] = "Schriftgröße der Bedrohungsanzeige",
    ["Threat tag up / down"] = "Bedrohungsanzeige hoch / runter",
    ["Threat tag width"] = "Breite der Bedrohungsanzeige",
    ["Threat: attacking you"] = "Bedrohung: greift dich an",
    ["Threat: not attacking you"] = "Bedrohung: greift jemand anderen an",
    ["Tooltip on hover"] = "Tooltip beim Darüberfahren",
    ["Voice chat button"] = "Sprachchat-Schaltfläche",
    ["Words and phrases to hide"] = "Auszublendende Wörter und Ausdrücke",
    ["Workshop"] = "Werkstatt",
    ["Zone name text size"] = "Schriftgröße des Gebietsnamens",
    ["Cuts the right end of the flight timer at an angle. When off, the end is straight."] = "Schrägt das rechte Ende des Flugtimers ab. Ausgeschaltet bleibt das Ende gerade.",
    ["You're on talent set %d, which has no profile. New and Import make one for it."] = "Talentverteilung %d hat noch kein Profil. Erstelle eines mit Neu oder Importieren.",
    ["You're on talent set %d. The buttons below work on its profile, %s."] = "Du verwendest Talentverteilung %d. Mit den folgenden Schaltflächen bearbeitest du das Profil %s.",
    ["Your class's pick (%s)"] = "Empfehlung für deine Klasse (%s)",
    ["Name for the copy:"] = "Name der Kopie:",
    ["Name for the new profile:"] = "Name des neuen Profils:",
    ["No words yet."] = "Noch keine Wörter eingetragen.",
    ["No change"] = "Keine Änderung",
    ["Nothing, hide the tags"] = "Keine, Beschriftungen ausblenden",
    ["Rename %s"] = "%s umbenennen",
    ["Spare page %d"] = "Zusatzseite %d",
    ["A word or phrase"] = "Ein Wort oder Ausdruck",
    ["Action Bar 1 in %s"] = "Aktionsleiste 1 in %s",
}

local L = DaylightUI.L
local germanClient = GetLocale() == "deDE"
if germanClient and rawget(L, "Space") == nil then L["Space"] = _G.KEY_SPACE or "Leertaste" end
local castLabels = {
    [" cast bar text"] = "Zauberleistentext",
    [" spell name"] = "Zaubername",
    [" cast time"] = "Wirkzeit",
    [" cast time format"] = "Wirkzeitformat",
    [" text size inside the frame"] = "Schriftgröße im Rahmen",
}
for _, field in ipairs({ { " spell name", "Zaubername" }, { " cast time", "Wirkzeit" } }) do
    castLabels[field[1] .. " text size"] = field[2] .. " – Schriftgröße"
    castLabels[field[1] .. " position"] = field[2] .. " – Position"
    castLabels[field[1] .. " left / right"] = field[2] .. " – links / rechts"
    castLabels[field[1] .. " up / down"] = field[2] .. " – hoch / runter"
    castLabels[field[1] .. " color"] = field[2] .. " – Farbe"
end
for unit, name in pairs({ Player = "Spieler", Target = "Ziel", Focus = "Fokus", Party = "Gruppe" }) do
    for suffix, label in pairs(castLabels) do translations[unit .. suffix] = name .. " · " .. label end
end
for key, value in pairs(translations) do
    if not extras.German[key] then rawset(extras.German, key, value) end
    if germanClient and rawget(L, key) == nil then L[key] = value end
end

-- Forever uses different German names for ranks of Smite in the same book.
-- Blizzard's Forever class overview calls the spell "Heilige Pein".
local book = germanClient and DaylightUI.Book
local smiteRanks = { [585] = true, [591] = true, [598] = true, [984] = true,
    [1004] = true, [6060] = true, [10933] = true, [10934] = true }
local function spellTerms(text)
    if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) then return text end
    return (text:gsub("Göttliche Pein", "Heilige Pein"):gsub("göttliche Pein", "heilige Pein"))
end

local spellData = book and book.SpellData
if spellData and spellData.Read and spellData.RankOf then
    local readSpells = spellData.Read
    function spellData.Read(showLow, ...)
        local data = readSpells(showLow, ...)
        for _, section in ipairs(data.sections) do
            local spells, family, highest = {}, {}, nil
            local function collect(entry)
                entry.name = "Heilige Pein"
                family[#family + 1] = entry
                if not highest or spellData.RankOf(entry) > spellData.RankOf(highest) then highest = entry end
            end
            for _, entry in ipairs(section.spells) do
                if smiteRanks[entry.spellID] then
                    collect(entry)
                    for _, low in ipairs(entry.lows or {}) do collect(low) end
                else
                    spells[#spells + 1] = entry
                end
            end
            if highest then
                highest.lows, highest.low = {}, nil
                if #family > 1 then data.anyLow = true end
                if showLow then
                    table.sort(family, function(a, b) return spellData.RankOf(a) > spellData.RankOf(b) end)
                    for _, entry in ipairs(family) do
                        if entry ~= highest then
                            entry.low, entry.lows = true, {}
                            highest.lows[#highest.lows + 1] = entry
                        end
                    end
                end
                -- Keep the original book ordering relative to other spells.
                local index = 1
                while spells[index] and (spells[index].slot or math.huge) < (highest.slot or math.huge) do
                    index = index + 1
                end
                table.insert(spells, index, highest)
                section.spells = spells
            end
        end
        return data
    end
end

local spells = book and book.Spells
if spells and spells.Enter then
    hooksecurefunc(spells, "Enter", function(button)
        local entry, tooltip = button.cell, GameTooltip
        if not (entry and smiteRanks[entry.spellID] and tooltip and tooltip:IsOwned(button)) then return end
        local title = _G[tooltip:GetName() .. "TextLeft1"]
        if title and title:GetText() == "Göttliche Pein" then title:SetText("Heilige Pein") end
    end)
end

local training = book and book.Training
if training and training.Read then
    local readTraining = training.Read
    function training.Read(...)
        local list = readTraining(...)
        for i, entry in ipairs(list or {}) do
            if entry.name == "Göttliche Pein" then
                local display = {}
                for field, value in pairs(entry) do display[field] = value end
                display.name = "Heilige Pein"
                list[i] = display
            end
        end
        return list
    end
end

-- Normalize presentation data only. The underlying talent and spell IDs stay intact.
local talents = book and book.TalentData
if talents and talents.Read and talents.EntryLines and talents.Description then
    local originalNames = setmetatable({}, { __mode = "k" })
    local read, entryLines, describe = talents.Read, talents.EntryLines, talents.Description

    local function statText(text, talent)
        if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) then return text end
        text = spellTerms(text)
        if text == "Seele" or text == "Geist" then return "Willenskraft" end
        for _, wrong in ipairs({ "Geist", "Seele" }) do
            text = text:gsub("(%d[%d.,]*%%?%s+)" .. wrong .. "%f[%A]", "%1Willenskraft")
            text = text:gsub("([Ee]ure%s+)" .. wrong .. "%f[%A](%s+um%s+%d)", "%1Willenskraft%2")
            text = text:gsub("([Dd]eine%s+)" .. wrong .. "%f[%A](%s+um%s+%d)", "%1Willenskraft%2")
            text = text:gsub("([Ee]urer%s+)" .. wrong .. "%f[%A](%s+um%s+%d)", "%1Willenskraft%2")
        end
        if talent == "Dunkle Inspiration" then
            text = text:gsub("[Ee]uer Geist%f[%A]%s+und der ", "Eure Willenskraft und die ")
            text = text:gsub("[Ee]uer Geist%f[%A]", "Eure Willenskraft")
        end
        return text
    end

    function talents.Read(...)
        local data = read(...)
        for _, node in pairs(data and data.byID or {}) do
            local name = node.name == "Seele" and "Willenskraft" or spellTerms(node.name)
            if node.name == "Geist" then name = "Willenskraft" end
            if name ~= node.name then
                originalNames[node] = node.name
                node.name = name
            end
        end
        return data
    end

    function talents.EntryLines(node, rank)
        local name = node and originalNames[node]
        local source = name and setmetatable({ name = name }, { __index = node }) or node
        local lines = entryLines(source, rank)
        for _, line in ipairs(lines or {}) do
            if line then
                local talent = node and node.name
                line.left, line.right = statText(line.left, talent), statText(line.right, talent)
            end
        end
        return lines
    end

    function talents.Description(node, ...)
        local text, loading = describe(node, ...)
        return statText(text, node and node.name), loading
    end
end
