local _, companion = ...
local register = companion.RegisterAddonSkin
if not register then return end

local DUI = DaylightUI
local description = "Styles the cheapest-items window in the DaylightUI theme."
companion.German[description] = "Gestaltet das Fenster mit den günstigsten Gegenständen im DaylightUI-Stil."

local function styleRows(kit, scroll, safe)
    local styled = {}
    local firstRow, secondRow = _G.DCI_Item1, _G.DCI_Item2
    local _, _, _, _, firstY = firstRow:GetPoint()
    local _, _, _, _, secondY = secondRow:GetPoint()
    local pitch = math.abs((secondY or -46) - (firstY or -5))
    if pitch < 1 then return end

    local function draw()
        local offset, height = scroll:GetVerticalScroll(), scroll:GetHeight()
        if type(offset) ~= "number" or type(height) ~= "number" then return end
        local first = math.max(1, math.floor(offset / pitch))
        local last = math.ceil((offset + height) / pitch) + 1
        for index = first, last do
            local row = _G["DCI_Item" .. index]
            if not row then break end
            if not styled[row] then
                local background = row.DCI_InfoBackground
                if background then background:SetColorTexture(0, 0, 0, 0.20) end
                local icon = _G["DCI_ItemIcon" .. index]
                if icon then kit.Outline(icon, 0, "outline", true) end
                local art = _G["DCI_ItemIconTexture" .. index]
                if art then DUI.Style.CropIcon(art) end
                for _, region in ipairs({ row:GetRegions() }) do
                    if kit.Kind(region) == "FontString" then kit.Refont(region) end
                end
                kit.Button(_G["DCI_DeleteButton" .. index])
                styled[row] = true
            end
        end
    end
    draw = safe(draw)
    scroll:HookScript("OnVerticalScroll", draw)
    scroll:HookScript("OnSizeChanged", draw)
    draw()
    return draw
end

register("DeleteCheapestItem", "deleteCheapestItem", "DeleteCheapestItem Reloaded", description, function(kit, def)
    local frame = _G.DCIFrame
    if not (frame and frame.HookScript) then return false end
    local function safe(fn) return DUI.Skins.Safe(def, fn) end
    local draw
    local function onShow()
        if draw then draw(); return end
        local scroll = _G.DCI_ScrollParent
        if not (scroll and _G.DCI_Item1 and _G.DCI_Item2) then return end

        kit.Window(frame, { ownFade = true })
        kit.Hide(frame.NineSlice)
        kit.Hide(frame.Bg)
        kit.Hide(frame.RegularTheme)
        local title = _G.DCI_TitleText
        if title then
            kit.Font(title, DUI.Style.SIZE.head, DUI.Style.INK.TITLE)
            title:ClearAllPoints()
            title:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -4)
            title:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -50, -24)
            title:SetJustifyH("LEFT")
        end
        kit.ArtButton(_G.DCI_TitleInfoButton)
        kit.Inset(_G.DCI_BottomSection_Inset)
        kit.ScrollBar(scroll.ScrollBar or _G.DCI_ScrollParentScrollBar)
        kit.Refont(_G.DCI_TopSection_Text1)
        kit.Refont(_G.DCI_TopSection_Text2)
        draw = styleRows(kit, scroll, safe)
    end
    onShow = safe(onShow)
    frame:HookScript("OnShow", onShow)
    if frame:IsShown() then onShow() end
end)
