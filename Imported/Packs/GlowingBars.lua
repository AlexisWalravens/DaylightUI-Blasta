-- Glowing Bars uses the same window builder for its options, looks and messages.
local _, ns = ...
if not ns.ok then return end

local KEY = "GlowingBars"
local WINDOWS = { "GlowingBarsOptions", "GlowingBarsLooks", "GlowingBarsMessage" }

local function dress(frame)
    if not ns.Usable(frame) then return end
    -- The window builder adds a separate brown fill inside its bronze backdrop.
    for _, region in ipairs({ frame:GetRegions() }) do
        if ns.Usable(region) and region:GetObjectType() == "Texture"
            and region:GetDrawLayer() == "BACKGROUND" and region:GetNumPoints() == 2 then
            local a, parentA, relA, xA, yA = region:GetPoint(1)
            local b, parentB, relB, xB, yB = region:GetPoint(2)
            if a == "TOPLEFT" and parentA == frame and relA == a and xA == 6 and yA == -6
                and b == "BOTTOMRIGHT" and parentB == frame and relB == b and xB == -6 and yB == 6 then
                ns.Kill(region)
                break
            end
        end
    end
    ns.PlainWindow(frame, { fonts = true }, KEY)
end

ns.Pack(KEY, "Glowing Bars", function()
    for _, name in ipairs(WINDOWS) do ns.Watch(KEY, name, dress) end
end, { window = true, controls = true, text = true, shadow = true, font = "daylight" })
