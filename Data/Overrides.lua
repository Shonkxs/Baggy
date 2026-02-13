local ADDON_NAME, ns = ...

local Overrides = {}
ns.Overrides = Overrides

local overrideByItemID = {
    -- Use this table for API outliers that should always map to a fixed Baggy category.
    -- Example:
    -- [12345] = { mainTab = "MATERIALS" },
    -- [67890] = { mainTab = "MATERIALS" },
    -- [24680] = { mainTab = "GEMS" },
    -- [13579] = { mainTab = "ENCHANTMENTS" },
    -- [11111] = { mainTab = "ARMOR", armorSubTab = "WEAPONS" },
}

function Overrides.Get(itemID)
    if type(itemID) ~= "number" then
        return nil
    end

    return overrideByItemID[itemID]
end

function Overrides.Set(itemID, categoryResult)
    if type(itemID) ~= "number" or type(categoryResult) ~= "table" then
        return
    end

    overrideByItemID[itemID] = categoryResult
end

function Overrides.Clear(itemID)
    if type(itemID) ~= "number" then
        return
    end

    overrideByItemID[itemID] = nil
end

function Overrides.SetMany(entries)
    if type(entries) ~= "table" then
        return
    end

    for itemID, categoryResult in pairs(entries) do
        Overrides.Set(itemID, categoryResult)
    end
end
