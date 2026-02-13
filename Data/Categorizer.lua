local ADDON_NAME, ns = ...

local Constants = ns.Constants
local Overrides = ns.Overrides

local Categorizer = {}
ns.Categorizer = Categorizer

local legacyMaterialTabs = {
    CLOTH = true,
    LEATHER = true,
    HERBS = true,
    ORES = true,
}

function Categorizer.NormalizeMainTab(tabID)
    if type(tabID) ~= "string" then
        return Constants.TAB_IDS.MISC
    end

    if legacyMaterialTabs[tabID] then
        return Constants.TAB_IDS.MATERIALS
    end

    if Constants.MAIN_TAB_LOOKUP[tabID] then
        return tabID
    end

    return Constants.TAB_IDS.MISC
end

function Categorizer.RebuildTradeSubclassSets()
    -- Kept as a no-op for compatibility with existing init flow.
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
        return Categorizer.NormalizeMainTab(override.mainTab), override.armorSubTab
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
        if itemRecord.classID == enumTable.ItemClass.Gem then
            return Constants.TAB_IDS.GEMS, nil
        end

        if itemRecord.classID == enumTable.ItemClass.ItemEnhancement then
            return Constants.TAB_IDS.ENCHANTMENTS, nil
        end

        if itemRecord.classID == enumTable.ItemClass.Consumable then
            return Constants.TAB_IDS.CONSUMABLES, nil
        end

        local isTradegoods = itemRecord.classID == enumTable.ItemClass.Tradegoods
        local isReagent = enumTable.ItemClass.Reagent and itemRecord.classID == enumTable.ItemClass.Reagent
        if isTradegoods or isReagent then
            return Constants.TAB_IDS.MATERIALS, nil
        end
    end

    return Constants.TAB_IDS.MISC, nil
end

Categorizer.RebuildTradeSubclassSets()
