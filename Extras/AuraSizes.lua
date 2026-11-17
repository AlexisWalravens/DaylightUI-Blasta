local _, extras = ...
local DUI = DaylightUI

-- Independent aura icon heights. Every native icon size slider stays the
-- width. Beside it Blasta stores, under the same path:
--   blasta<Stem>KeepAspect  (default on) the height follows the width,
--   blasta<Stem>Ratio       the height-to-width ratio locked by the player,
--   blasta<Stem>Height      the height while the ratio is unlocked.
-- Without a locked ratio the height uses the native proportion.
local Sizes = {}
extras.AuraSizes = Sizes

local FIELDS = { "Height", "KeepAspect", "Ratio" }

-- "targetAuras.buffSize" -> "targetAuras.", { Height = "blastaBuffHeight", ... }
-- "party.auras.debuffs.size" -> "party.auras.debuffs.", { Height = "blastaHeight", ... }
function Sizes.Names(sizeKey)
    local path, last = sizeKey:match("^(.-)([^.]+)$")
    local stem = last == "size" and "" or last:match("^(.-)Size$")
    if not stem then return end
    if stem ~= "" then stem = stem:sub(1, 1):upper() .. stem:sub(2) end
    local names = {}
    for _, field in ipairs(FIELDS) do names[field] = "blasta" .. stem .. field end
    return path, names
end

local function round(value) return math.floor(value + .5) end

-- The height for a width. read(field) returns the stored Height, KeepAspect
-- or Ratio. base is the ratio used when none is locked.
function Sizes.Height(read, width, base)
    width = tonumber(width) or 0
    if width <= 0 then return 0 end
    -- A reader may return nothing at all; keep each value in a local so
    -- tonumber always gets an argument.
    local keep, stored, locked = read("KeepAspect"), read("Height"), read("Ratio")
    if keep == false then
        local height = tonumber(stored)
        if height and height > 0 then return height end
        return math.max(1, round(width * base))
    end
    local ratio = tonumber(locked)
    if not ratio or ratio <= 0 then ratio = base end
    return math.max(1, round(width * ratio))
end

-- Reads the fields from a settings table that holds the size key.
function Sizes.TableReader(cfg, names)
    return function(field)
        if type(cfg) ~= "table" then return nil end
        return cfg[names[field]]
    end
end

-- Crops the icon art so it is never squashed, at any width and height.
function Sizes.IconCoords(w, h, inset)
    inset = 2 * (inset or 0)
    w, h = w and w - inset, h and h - inset
    if not (w and h and w > 0 and h > 0) then return .08, .92, .08, .92 end
    if w >= h then
        local span = .84 * h / w
        return .08, .92, .5 - span / 2, .5 + span / 2
    end
    local span = .84 * w / h
    return .5 - span / 2, .5 + span / 2, .08, .92
end

-- The two option rows that follow a native size slider: the height and the
-- aspect lock. opts:
--   scope       module name for DUI:Get/Set
--   base        function returning the ratio used without a locked one
--   mapKey      optional function mapping a page key to its profile key
--   locked      optional function(key, row) from the page
--   since, anchor, minHeight, maxHeight, onChange
function Sizes.Rows(sizeRow, opts)
    local path, names = Sizes.Names(sizeRow.key)
    if not path then return end
    local scope = opts.scope
    local function map(key) return opts.mapKey and opts.mapKey(key) or key end
    local function read(key) return DUI:Get(scope, map(key)) end
    local function write(key, value)
        local ok = DUI:Set(scope, map(key), value)
        if opts.onChange then opts.onChange(key, value) end
        return ok
    end
    local heightKey, keepKey, ratioKey = path .. names.Height, path .. names.KeepAspect, path .. names.Ratio
    local minWidth, maxWidth = sizeRow.min or 1, sizeRow.max or 64
    local function width()
        local value = read(sizeRow.key)
        return tonumber(value) or minWidth
    end
    local function field(name)
        if name == "Height" then return read(heightKey) end
        if name == "KeepAspect" then return read(keepKey) end
        return read(ratioKey)
    end
    local function height() return Sizes.Height(field, width(), opts.base()) end
    local function hidden(get)
        if not sizeRow.hidden then return false end
        if opts.mapKey then return sizeRow.hidden(function(key) return read(key) end) end
        return sizeRow.hidden(get)
    end
    local function disabled(get, row)
        if opts.locked and opts.locked(sizeRow.key, row) then return true end
        if not sizeRow.disabled then return false end
        if opts.mapKey then return sizeRow.disabled(function(key) return read(key) end) == true end
        return sizeRow.disabled(get) == true
    end
    local heightRow = {
        type = "slider", key = heightKey, label = "Height", unit = "px", step = 1,
        min = opts.minHeight or 6, max = opts.maxHeight or math.max(48, maxWidth * 2),
        desc = "How tall each icon is.",
        blastaSince = opts.since, blastaJumpAnchor = opts.anchor or sizeRow.key,
        get = height,
        set = function(value)
            value = round(tonumber(value) or 0)
            if value <= 0 then return end
            if read(keepKey) ~= false then return false end
            return write(heightKey, value)
        end,
        default = function()
            local w = tonumber(DUI.DB.GetPath(opts.defaults or {}, sizeRow.key)) or width()
            return round(w * opts.base())
        end,
    }
    local keepRow = {
        type = "toggle", key = keepKey, label = "Keep aspect ratio",
        desc = "Keeps the icon's proportions while resizing. Turn off to set width and height separately.",
        blastaSince = opts.since, blastaJumpAnchor = opts.anchor or sizeRow.key,
        get = function() return read(keepKey) ~= false end,
        set = function(value)
            local current = height()
            if value then
                write(ratioKey, current / math.max(1, width()))
            else
                write(heightKey, current)
            end
            return write(keepKey, value == true)
        end,
        default = function() return true end,
    }
    heightRow.blastaWidthLabel = function() return read(keepKey) == false and "Width" or "Size" end
    heightRow.hidden = function(get) return read(keepKey) ~= false or hidden(get) end
    keepRow.hidden = hidden
    heightRow.disabled = function(get) return disabled(get, heightRow) end
    keepRow.disabled = function(get) return disabled(get, keepRow) end
    return heightRow, keepRow
end
