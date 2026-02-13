local ADDON_NAME, ns = ...

local Overrides = {}
ns.Overrides = Overrides

local overrideByItemID = {
    -- [itemID] = { mainTab = "MISC", armorSubTab = "ALL" },
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
