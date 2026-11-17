local _, ns = ...
if not ns.ok then return end

local KEY = "Books_on_map_Forever"
local W, Style = DaylightUI.Widgets, DaylightUI.Style

local function muteBox(frame)
    if frame.bg then frame.bg:SetColorTexture(0.035, 0.035, 0.043, 0.72) end
    for _, edge in ipairs(frame.borders or {}) do edge:SetAlpha(0.24); edge:SetDesaturated(true) end
end

local function cleanBox(frame)
    ns.Kill(frame.bg)
    for _, edge in ipairs(frame.borders or {}) do ns.Kill(edge) end
end

local function dressControl(frame)
    local kind = frame:GetObjectType()
    if kind == "CheckButton" and frame.mark and frame.borders and ns.Once(frame) then
        cleanBox(frame)
        ns.Kill(frame.mark)
        for _, region in ipairs({ frame:GetRegions() }) do
            if region:GetObjectType() == "Texture" then ns.Kill(region) end
        end
        local look = W.SwitchLook(frame, {}, frame:GetWidth())
        local function refresh()
            local checked = frame:GetChecked() and true or false
            if look.on ~= checked then look.SetOn(checked) end
        end
        hooksecurefunc(frame, "SetChecked", refresh)
        frame:HookScript("PostClick", refresh)
        refresh()
    elseif kind == "Button" and frame.fitWidth and frame.text and frame.borders and ns.Once(frame) then
        cleanBox(frame)
        for _, region in ipairs({ frame:GetRegions() }) do
            if region:GetObjectType() == "Texture" and region:GetDrawLayer() == "ARTWORK" then ns.Kill(region) end
        end
        Style.InkText(frame.text, "TEXT")
        ns.Kit.Button(frame)
    elseif kind == "Slider" and ns.Once(frame) then
        local thumb = frame:GetThumbTexture()
        if thumb then
            thumb:SetColorTexture(0.73, 0.71, 0.68, 1)
            thumb:SetSize(frame.label and 7 or thumb:GetWidth(), thumb:GetHeight())
        end
        for _, region in ipairs({ frame:GetRegions() }) do
            if region ~= thumb and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "ARTWORK" then
                region:SetColorTexture(0.55, 0.53, 0.49, 0.8)
            end
        end
        if frame.value then Style.InkText(frame.value, "VALUE") end
    elseif kind == "Frame" then
        if frame.bg and frame.borders and ns.Once(frame) then muteBox(frame) end
        if frame.label and (frame.right or frame.set) then
            Style.InkText(frame.label, "TEXT")
            for _, region in ipairs({ frame:GetRegions() }) do
                if region:GetObjectType() == "Texture" then
                    local layer = region:GetDrawLayer()
                    if layer == "BACKGROUND" then region:SetColorTexture(1, 1, 1, 0.045)
                    elseif layer == "BORDER" then region:SetColorTexture(1, 1, 1, 0.1)
                    elseif layer == "ARTWORK" then region:SetColorTexture(0.65, 0.61, 0.54, 0.8) end
                end
            end
        end
    end
end

local function dressTree(frame, depth)
    if depth > 8 then return end
    for _, child in ipairs({ frame:GetChildren() }) do
        if not (child.titleBar and child.borders) then
            dressControl(child)
            if child.GetChildren then dressTree(child, depth + 1) end
        end
    end
end

local function stripShell(frame)
    ns.Kill(frame.shadow)
    for _, edge in ipairs(frame.borders) do ns.Kill(edge) end
    for _, region in ipairs({ frame:GetRegions() }) do
        if region:GetObjectType() == "Texture" then
            local layer, sublevel = region:GetDrawLayer()
            if layer == "BACKGROUND" and (sublevel == -7 or sublevel == -5) then
                ns.Kill(region)
            end
        end
    end
end

local function dress(frame)
    -- Rounded window art uses dedicated sublayers.
    if not ns.Usable(frame) or type(frame.borders) ~= "table" or not ns.Once(frame) then return end
    stripShell(frame)
    ns.Shell(frame, { window = true }, KEY)
    if frame.titleBar then ns.HeaderLine(frame) end
    if frame.title then Style.InkText(frame.title, "TITLE") end
    if ns.Controls(KEY) then dressTree(frame, 0) end
    ns.DressOnShow(frame, { fonts = true, checks = false }, nil, KEY)
end

local function paintToast(frame)
    Style.InkText(frame.kicker, "pop")
    Style.InkText(frame.title, "TITLE")
    Style.InkText(frame.sub, "LABEL")
    Style.InkText(frame.count, "LABEL")
    frame.timer:SetTexture("Interface\\Buttons\\WHITE8X8")
    Style.PaintAccent(frame.timer, 0.75)
    if frame.iconBox.SetBorderColor then frame.iconBox:SetBorderColor(Style.Accent()) end
end

local function dressToast(frame)
    if not ns.Usable(frame) or type(frame.borders) ~= "table" or not frame.kicker or not frame.title
        or not frame.sub or not frame.count or not frame.timer or not frame.iconBox
        or not Style.PaintAccent or not ns.Once(frame) then return end
    stripShell(frame)
    ns.Kill(frame.wash)
    ns.Kill(frame.stripe)
    ns.Kill(frame.halo)
    ns.Kill(frame.shine)
    ns.Shell(frame, { window = true }, KEY)
    ns.HeaderLine(frame)
    ns.DressOnShow(frame, { fonts = true, checks = false }, paintToast, KEY)
    DaylightUI.On("StyleChanged", function()
        if frame:IsShown() then paintToast(frame) end
    end)
end

ns.Pack(KEY, "Books on Map Forever", function()
    ns.Watch(KEY, "BooksOnMapForeverOptions", function(frame)
        dress(frame)
        for _, child in ipairs({ frame:GetChildren() }) do
            if child.titleBar and child.borders then dress(child) end
        end
    end)
    ns.Watch(KEY, "BooksOnMapForeverRoute", dress)
    ns.Watch(KEY, "BooksOnMapForeverWelcome", dress)
    ns.Watch(KEY, "BooksOnMapForeverToast", dressToast)
end, { window = true, controls = true, text = true, shadow = true, font = "daylight" })
