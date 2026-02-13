local ADDON_NAME, ns = ...

local Constants = ns.Constants
local Overrides = ns.Overrides

local Categorizer = {}
ns.Categorizer = Categorizer

local tradeSubclassSets = {
    CLOTH = {},
    LEATHER = {},
    HERBS = {},
    ORES = {},
}

local function clearSet(setTable)
    for key in pairs(setTable) do
        setTable[key] = nil
    end
end

local function clearTradeSubclassSets()
    clearSet(tradeSubclassSets.CLOTH)
    clearSet(tradeSubclassSets.LEATHER)
    clearSet(tradeSubclassSets.HERBS)
    clearSet(tradeSubclassSets.ORES)
end

function Categorizer.RebuildTradeSubclassSets()
    clearTradeSubclassSets()

    local enumTable = _G.Enum and _G.Enum.ItemTradeGoodsSubclass
    if type(enumTable) ~= "table" then
        return
    end

    for enumKey, enumValue in pairs(enumTable) do
        if type(enumKey) == "string" and type(enumValue) == "number" then
            local normalized = string.lower(enumKey)

            if string.find(normalized, "cloth", 1, true) then
                tradeSubclassSets.CLOTH[enumValue] = true
            end

            if string.find(normalized, "leather", 1, true) or string.find(normalized, "hide", 1, true) then
                tradeSubclassSets.LEATHER[enumValue] = true
            end

            if string.find(normalized, "herb", 1, true) then
                tradeSubclassSets.HERBS[enumValue] = true
            end

            if string.find(normalized, "ore", 1, true) or
                string.find(normalized, "metal", 1, true) or
                string.find(normalized, "stone", 1, true) then
                tradeSubclassSets.ORES[enumValue] = true
            end
        end
    end
end

local function isMountSubclass(itemRecord)
    local enumTable = _G.Enum
    if not (enumTable and enumTable.ItemClass and enumTable.ItemMiscellaneousSubclass) then
        return false
    end

    return itemRecord.classID == enumTable.ItemClass.Miscellaneous
        and itemRecord.subClassID == enumTable.ItemMiscellaneousSubclass.Mount
end

function Categorizer.Categorize(itemRecord)
    if type(itemRecord) ~= "table" then
        return Constants.TAB_IDS.MISC, nil
    end

    local override = Overrides.Get(itemRecord.itemID)
    if override then
        return override.mainTab or Constants.TAB_IDS.MISC, override.armorSubTab
    end

    local armorSubTab = Constants.ARMOR_EQUIP_LOC_TO_SUBTAB[itemRecord.equipLoc or ""]
    if armorSubTab then
        return Constants.TAB_IDS.ARMOR, armorSubTab
    end

    if itemRecord.isMountItem or isMountSubclass(itemRecord) then
        return Constants.TAB_IDS.MOUNTS, nil
    end

    local enumTable = _G.Enum
    if enumTable and enumTable.ItemClass then
        if itemRecord.classID == enumTable.ItemClass.Consumable
            or itemRecord.classID == enumTable.ItemClass.ItemEnhancement then
            return Constants.TAB_IDS.CONSUMABLES, nil
        end

        if itemRecord.classID == enumTable.ItemClass.Tradegoods then
            if tradeSubclassSets.CLOTH[itemRecord.subClassID] then
                return Constants.TAB_IDS.CLOTH, nil
            end

            if tradeSubclassSets.LEATHER[itemRecord.subClassID] then
                return Constants.TAB_IDS.LEATHER, nil
            end

            if tradeSubclassSets.HERBS[itemRecord.subClassID] then
                return Constants.TAB_IDS.HERBS, nil
            end

            if tradeSubclassSets.ORES[itemRecord.subClassID] then
                return Constants.TAB_IDS.ORES, nil
            end
        end
    end

    return Constants.TAB_IDS.MISC, nil
end

Categorizer.RebuildTradeSubclassSets()
