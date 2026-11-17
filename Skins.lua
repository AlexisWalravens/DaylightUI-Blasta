local _, companion = ...
local DUI = DaylightUI
local target = "RareScanner"
local key = "rareScanner"
local label = "RareScanner"
local module = DUI:GetModule("Skins")
local engine = module and module.ns and module.ns.Engine
local pages = module and module.options and module.options.pages
local skinAPI = DUI.Skins
if not (engine and type(engine.AddonSwitch) == "function" and type(engine.Installed) == "function"
    and skinAPI and type(skinAPI.Register) == "function" and type(skinAPI.Safe) == "function") then return end

-- DaylightUI 1.6.7.1 builds these rows before companion addons load.
-- Its public skin API registers the skin but does not add the options row.
local items
for _, page in ipairs(pages or {}) do
    if page.id == "skins" then
        for _, section in ipairs(page.groups or {}) do
            if section.label == "Other addons" then
                items = section.items
                break
            end
        end
        break
    end
end
if type(items) ~= "table" then return end

function companion.RegisterAddonSkin(addon, switch, title, description, apply)
    for _, skin in ipairs(engine.skins or {}) do
        if skin.addon == addon then return end
    end
    local spec = { key = switch, label = title, addon = addon }
    engine.AddonSwitch(spec)
    items[#items + 1] = {
        type = "toggle", key = "addonSkins." .. switch, label = title, desc = description,
        reload = true, hidden = function() return not engine.Installed(spec) end,
    }
    skinAPI.Register({ key = switch, switch = switch, label = title, addon = addon, apply = apply })
end

local description = "Styles the RareScanner Explorer and alert in the DaylightUI theme."
companion.German[description] = "Gestaltet den Explorer und das Fundfenster von RareScanner im DaylightUI-Stil."

local function styleList(kit, list)
    kit.Hide(list.background)
    kit.Shell(list, "row")
    kit.ScrollBar(list.scrollBar)
end

local function styleExplorer(kit, explorer)
    kit.Window(explorer, { ownFade = true })
    kit.Hide(explorer.Border)

    local filters = explorer.Filters
    kit.Dropdown(filters.FilterDropDown)
    kit.Dropdown(filters.ContinentDropDown)
    kit.Check(filters.LockCurrentZoneCheckButton)
    kit.Button(filters.ToggleLootButton)
    kit.Button(filters.RestartScanningButton)
    kit.Button(explorer.ScanRequired.StartScanningButton)
    kit.Font(explorer.ScanRequired.ScanRequiredText, 19)
    kit.Font(explorer.ScanRequired.ScanProcessText, 13)

    styleList(kit, explorer.RareNPCList)
    styleList(kit, explorer.RareLoot)
    kit.EditBox(explorer.RareLoot.SearchBox)
    kit.Dropdown(explorer.RareLoot.FilterDropDown)
    kit.Check(explorer.RareLoot.FilterAllCheck)

    local detail = explorer.RareInfo
    kit.Hide(detail.Border)
    kit.Hide(detail.BaseFrameBackground)
    kit.Hide(detail.BoardDropShadow)
    kit.Shell(detail, "row")
    kit.Font(detail.Name, 19)

    local control = explorer.Control
    kit.Check(control.AutoFilterCheckButton)
    kit.Check(control.CreateProfilesBackupCheckButton)
    kit.Button(control.ApplyFiltersButton)
end

local function styleAlert(kit, alert)
    -- Replace the original backdrop as well as the parchment textures.
    alert:SetBackdrop(nil)
    kit.Strip(alert)
    local style = DUI.Style
    local neutral = style.NEUTRAL
    kit.Shell(alert, "control", {
        borderPx = 1,
        borderColor = { neutral[1], neutral[2], neutral[3], 0.65 },
        bgAlpha = style.WindowBack("Skins"),
    })

    local line = alert:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetHeight(DUI.Win and DUI.Win.LINE or 2)
    line:SetPoint("TOPLEFT", alert, "TOPLEFT", 6, -2)
    line:SetPoint("TOPRIGHT", alert, "TOPRIGHT", -6, -2)

    local title, hint = alert.Title, alert.Description_text
    title:ClearAllPoints()
    title:SetPoint("TOPLEFT", alert, "TOPLEFT", 11, -8)
    title:SetPoint("TOPRIGHT", alert, "TOPRIGHT", -26, -8)
    title:SetJustifyH("LEFT")
    title:SetMaxLines(1)

    hint:ClearAllPoints()
    hint:SetPoint("TOPLEFT", alert, "TOPLEFT", 11, -26)
    hint:SetPoint("TOPRIGHT", alert, "TOPRIGHT", -26, -26)
    hint:SetJustifyH("LEFT")
    hint:SetMaxLines(2)

    local close = alert.CloseButton
    close:ClearAllPoints()
    close:SetPoint("TOPRIGHT", alert, "TOPRIGHT", -6, -6)
    kit.Close(close)
    for _, filter in ipairs({ alert.FilterEntityButton, alert.UnFilterEntityButton }) do
        filter:ClearAllPoints()
        filter:SetPoint("BOTTOMRIGHT", alert, "BOTTOMRIGHT", -6, 5)
    end

    local function paint()
        style.PaintAccent(line, 0.7)
        kit.Font(title, style.SIZE.head, style.INK.TITLE)
        kit.Font(hint, style.SIZE.tiny, style.INK.LABEL)
    end
    paint()
    DUI.On("StyleChanged", paint)
end

companion.RegisterAddonSkin(target, key, label, description, function(kit)
    if companion.StyleRareScannerMap then companion.StyleRareScannerMap(kit) end
    local explorer = _G.RSExplorerFrame
    local alert = _G.RARESCANNER_BUTTON
    if not (explorer and alert) then return false end
    if not (explorer.Filters and explorer.RareNPCList and explorer.RareLoot
        and explorer.RareInfo and explorer.Control and explorer.ScanRequired
        and alert.SetBackdrop and alert.Title and alert.Description_text and alert.CloseButton) then return end
    styleExplorer(kit, explorer)
    styleAlert(kit, alert)
end)
