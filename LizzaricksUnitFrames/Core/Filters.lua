-- LizzaricksUnitFrames / Core / Filters
--
-- Luna's filter lists: named lists of aura spell IDs, shared by all
-- characters and profiles (LizzaricksUFDB.filterLists[name] = { [id] = true }).
-- A unit's buffs or debuffs can show only the auras of a list, or hide them;
-- squares can take their spells from a list.
--
-- The client's aura container matches by spell ID only, and only for buffs
-- on friendly units and debuffs on hostile ones. "Hide listed" is safe
-- everywhere (auras it cannot check stay visible); "show only listed" drops
-- every aura it cannot check.
--
-- The search walks the spell IDs in the background (a slice per frame) and
-- compares names; the rank ("Rank 3") comes from the spell's subtext, which
-- the client may load a moment later (SPELL_TEXT_UPDATE).
local _, ns = ...

local FL = {}
ns.Filters = FL

FL.MAX_ID = 1600000        -- highest spell ID the search looks at
FL.MAX_RESULTS = 500
FL.EXPORT_PREFIX = "LUF1"

local function lists()
    LizzaricksUFDB.filterLists = LizzaricksUFDB.filterLists or {}
    return LizzaricksUFDB.filterLists
end

local function changed()
    ns:ApplyAll()
    if FL.onChange then FL.onChange() end
end

-- ------------------------------------------------------------ spells --

local function spellName(id)
    if not (C_Spell and C_Spell.GetSpellName) then return nil end
    local ok, name = pcall(C_Spell.GetSpellName, id)
    if ok and ns.CanRead(name) and type(name) == "string" and name ~= "" then return name end
end

local function spellRank(id)
    if not (C_Spell and C_Spell.GetSpellSubtext) then return nil end
    local ok, sub = pcall(C_Spell.GetSpellSubtext, id)
    if ok and ns.CanRead(sub) and type(sub) == "string" and sub ~= "" then return sub end
    -- not loaded yet: ask for it, SPELL_TEXT_UPDATE refreshes the page
    if C_Spell.RequestLoadSpellData then pcall(C_Spell.RequestLoadSpellData, id) end
end

local function spellIcon(id)
    if not (C_Spell and C_Spell.GetSpellTexture) then return nil end
    local ok, icon = pcall(C_Spell.GetSpellTexture, id)
    if ok and ns.CanRead(icon) then return icon end
end

-- "Demon Armor  Rank 5  ID: 11735" as a list row.
function FL.Describe(id)
    local name = spellName(id) or "Unknown spell"
    local rank = spellRank(id)
    local text = name
    if rank then text = text .. "  |cffffd100" .. rank .. "|r" end
    return text .. "  |cff888888ID: " .. id .. "|r", spellIcon(id), name
end

function FL.Item(id)
    local text, icon = FL.Describe(id)
    return { id = id, text = text, icon = icon or 134400 }   -- question mark
end

-- ------------------------------------------------------------ lists --

function FL.Names()
    local names = {}
    for n in pairs(lists()) do table.insert(names, n) end
    table.sort(names)
    return names
end

function FL.Get(name)
    return name and lists()[name]
end

-- IDs of a list, sorted, as items for the options page.
function FL.Items(name)
    local ids = {}
    for id in pairs(FL.Get(name) or {}) do table.insert(ids, id) end
    table.sort(ids)
    local items = {}
    for i, id in ipairs(ids) do items[i] = FL.Item(id) end
    return items
end

-- Fingerprint of a list's contents (aura containers rebuild on a change).
function FL.Signature(name)
    local ids = {}
    for id in pairs(FL.Get(name) or {}) do table.insert(ids, id) end
    table.sort(ids)
    return (name or "") .. "=" .. table.concat(ids, ",")
end

local function clean(name)
    return ((name or ""):gsub("[:\n]", ""):match("^%s*(.-)%s*$"))
end

function FL.Create(name)
    name = clean(name)
    if name == "" then return nil, "Enter a name." end
    if lists()[name] then return nil, "A list with that name exists." end
    lists()[name] = {}
    FL.selected = name
    if FL.onChange then FL.onChange() end
    return name
end

-- Calls fn(table, key) for every setting in every profile that names a list.
local function eachReference(fn)
    for _, profile in pairs(LizzaricksUFDB.profiles or {}) do
        for _, unit in pairs(profile.units or {}) do
            if unit.auras then
                fn(unit.auras, "buffList")
                fn(unit.auras, "debuffList")
            end
            for _, sq in pairs(unit.squares or {}) do fn(sq, "list") end
        end
    end
end

function FL.Rename(old, new)
    new = clean(new)
    if not lists()[old] then return nil, "No list selected." end
    if new == "" then return nil, "Enter a name." end
    if new == old then return new end
    if lists()[new] then return nil, "A list with that name exists." end
    lists()[new], lists()[old] = lists()[old], nil
    eachReference(function(t, k) if t[k] == old then t[k] = new end end)
    FL.selected = new
    changed()
    return new
end

function FL.Delete(name)
    if not lists()[name] then return end
    lists()[name] = nil
    eachReference(function(t, k) if t[k] == name then t[k] = "" end end)
    FL.selected = FL.Names()[1]
    changed()
end

function FL.Add(name, id)
    local list = FL.Get(name)
    if not list or not id then return end
    list[id] = true
    changed()
end

function FL.Remove(name, id)
    local list = FL.Get(name)
    if not list then return end
    list[id] = nil
    changed()
end

-- "LUF1:Name:706,11735"
function FL.Export(name)
    local list = FL.Get(name)
    if not list then return "" end
    local ids = {}
    for id in pairs(list) do table.insert(ids, id) end
    table.sort(ids)
    return FL.EXPORT_PREFIX .. ":" .. name .. ":" .. table.concat(ids, ",")
end

function FL.Import(text)
    local name, body = (text or ""):match("^%s*" .. FL.EXPORT_PREFIX .. ":([^:]*):([%d,%s]*)%s*$")
    if not name then return nil, "Not a filter list string." end
    name = clean(name)
    if name == "" then name = "Imported" end
    local base, n = name, 2
    while lists()[name] do
        name = base .. " (" .. n .. ")"
        n = n + 1
    end
    local list = {}
    for id in body:gmatch("%d+") do list[tonumber(id)] = true end
    lists()[name] = list
    FL.selected = name
    changed()
    return name
end

-- candidateFilters for an aura group or slot, or nil.
function FL.CandidateFilters(name, mode)
    local list = FL.Get(name)
    if not list then return nil end
    local ids = {}
    for id in pairs(list) do ids[id] = true end
    if mode == "include" then return { includeSpellIDs = ids } end
    return { excludeSpellIDs = ids }
end

-- ------------------------------------------------------------ search --

-- FL.search = { query, results = { id, ... }, pos, done }
local scanner = CreateFrame("Frame")
scanner:Hide()

local function progress()
    if FL.onChange then FL.onChange() end
end

local sinceRefresh = 0
scanner:SetScript("OnUpdate", function(self, elapsed)
    local s = FL.search
    if not s or s.done then self:Hide() return end
    local clock = debugprofilestop
    local start = clock and clock()
    local id, last = s.pos, FL.MAX_ID
    local q = s.query
    while id <= last do
        local name = spellName(id)
        if name and name:lower():find(q, 1, true) then
            table.insert(s.results, id)
            if #s.results >= FL.MAX_RESULTS then id = last break end
        end
        id = id + 1
        -- about 6 ms of work per frame (without a clock: fixed slices)
        if id % 500 == 0 then
            if clock then
                if clock() - start > 6 then break end
            elseif id - s.pos >= 20000 then
                break
            end
        end
    end
    s.pos = id
    if id > last then
        s.done = true
        -- exact names first, then by ID (lower ranks first)
        table.sort(s.results, function(a, b)
            local ea, eb = (spellName(a) or ""):lower() == q, (spellName(b) or ""):lower() == q
            if ea ~= eb then return ea end
            return a < b
        end)
        self:Hide()
        progress()
        return
    end
    sinceRefresh = sinceRefresh + (elapsed or 0)
    if sinceRefresh > 0.25 then
        sinceRefresh = 0
        progress()
    end
end)

-- A number looks up that ID; anything else searches names (any part,
-- any case).
function FL.Search(query)
    query = (query or ""):match("^%s*(.-)%s*$")
    if query == "" then
        FL.search = nil
        scanner:Hide()
        progress()
        return
    end
    local id = tonumber(query)
    if id then
        FL.search = { query = query, results = spellName(id) and { id } or {}, pos = 0, done = true }
        scanner:Hide()
    else
        FL.search = { query = query:lower(), results = {}, pos = 1, done = false }
        sinceRefresh = 0
        scanner:Show()
    end
    progress()
end

function FL.SearchStatus()
    local s = FL.search
    if not s then return "Type a spell name or ID and press Enter." end
    if not s.done then
        return string.format("Searching ... %d%%  (%d found)", math.floor(s.pos / FL.MAX_ID * 100), #s.results)
    end
    if #s.results == 0 then return "Nothing found." end
    local more = #s.results >= FL.MAX_RESULTS and " (first " .. FL.MAX_RESULTS .. ")" or ""
    return #s.results .. " found" .. more .. ". Click Add to put an aura into the list."
end

function FL.SearchItems()
    local items = {}
    for i, id in ipairs(FL.search and FL.search.results or {}) do items[i] = FL.Item(id) end
    return items
end

-- Ranks arrive late; redraw the page when they do.
ns:RegisterEvent("SPELL_TEXT_UPDATE", progress)
