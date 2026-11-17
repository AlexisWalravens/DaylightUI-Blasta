local _, extras = ...
if not extras.RegisterAddonSkin then return end

local DUI = DaylightUI
local description = "Styles the BugSack window and controls in the DaylightUI theme."
extras.German[description] = "Gestaltet das BugSack-Fenster und seine Bedienelemente im DaylightUI-Stil."

extras.RegisterAddonSkin("BugSack", "bugSack", "BugSack", description, function(kit, def)
    local sack = _G.BugSack
    if not sack then return false end
    local styled
    local dress = DUI.Skins.Safe(def, function()
        local frame, log = _G.BugSackFrame, _G.BugSackScrollText
        if styled or not (frame and log) then return end
        kit.Window(frame, { ownFade = true })
        frame:SetAlpha(1)
        kit.Hide(frame.PortraitContainer)
        kit.Hide(frame.NineSlice)
        kit.Font(log, nil, DUI.Style.INK.VALUE)
        local scroll = log:GetParent()
        kit.ScrollBar(scroll.ScrollBar or scroll.scrollBar)
        for _, suffix in ipairs({ "NextButton", "PrevButton", "SendButton", "WipeButton" }) do
            kit.Button(_G["BugSack" .. suffix])
        end
        for _, suffix in ipairs({ "All", "Session", "Last", "Options" }) do
            local tab = _G["BugSackTab" .. suffix]
            if tab then
                kit.Tab(tab)
                local label = tab.Text or tab:GetFontString()
                if label then
                    label:ClearAllPoints()
                    label:SetPoint("CENTER", tab)
                    label:SetWidth(0)
                    local function fit()
                        tab:SetWidth(math.ceil(label:GetStringWidth()) + 24)
                    end
                    fit()
                    tab:HookScript("OnShow", fit)
                    DUI.On("StyleChanged", fit)
                end
            end
        end
        styled = true
    end)
    local function onOpen()
        if not styled then DUI.AfterCombat(dress, "blasta:bugsack") end
    end
    hooksecurefunc(sack, "OpenSack", onOpen)
    hooksecurefunc(sack, "OpenConfig", onOpen)
    onOpen()
end)
