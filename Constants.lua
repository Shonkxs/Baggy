local ADDON_NAME, ns = ...

local Constants = {}
ns.Constants = Constants

Constants.MODES = {
    INVENTORY = "INVENTORY",
    BANK = "BANK",
}

Constants.TAB_IDS = {
    CONSUMABLES = "CONSUMABLES",
    ARMOR = "ARMOR",
    MATERIALS = "MATERIALS",
    MOUNTS = "MOUNTS",
    MISC = "MISC",
}

Constants.MAIN_TABS = {
    { id = Constants.TAB_IDS.CONSUMABLES, label = "Consumables" },
    { id = Constants.TAB_IDS.ARMOR, label = "Armor" },
    { id = Constants.TAB_IDS.MATERIALS, label = "Materials" },
    { id = Constants.TAB_IDS.MOUNTS, label = "Mounts" },
    { id = Constants.TAB_IDS.MISC, label = "Misc" },
}

Constants.ARMOR_SUBTAB_IDS = {
    ALL = "ALL",
    WEAPONS = "WEAPONS",
    HEAD = "HEAD",
    NECK = "NECK",
    SHOULDER = "SHOULDER",
    BACK = "BACK",
    CHEST = "CHEST",
    WRIST = "WRIST",
    HANDS = "HANDS",
    WAIST = "WAIST",
    LEGS = "LEGS",
    FEET = "FEET",
    FINGER = "FINGER",
    TRINKET = "TRINKET",
}

Constants.ARMOR_SUB_TABS = {
    { id = Constants.ARMOR_SUBTAB_IDS.ALL, label = "All" },
    { id = Constants.ARMOR_SUBTAB_IDS.WEAPONS, label = "Weapons" },
    { id = Constants.ARMOR_SUBTAB_IDS.HEAD, label = "Head" },
    { id = Constants.ARMOR_SUBTAB_IDS.NECK, label = "Neck" },
    { id = Constants.ARMOR_SUBTAB_IDS.SHOULDER, label = "Shoulder" },
    { id = Constants.ARMOR_SUBTAB_IDS.BACK, label = "Back" },
    { id = Constants.ARMOR_SUBTAB_IDS.CHEST, label = "Chest" },
    { id = Constants.ARMOR_SUBTAB_IDS.WRIST, label = "Wrist" },
    { id = Constants.ARMOR_SUBTAB_IDS.HANDS, label = "Hands" },
    { id = Constants.ARMOR_SUBTAB_IDS.WAIST, label = "Waist" },
    { id = Constants.ARMOR_SUBTAB_IDS.LEGS, label = "Legs" },
    { id = Constants.ARMOR_SUBTAB_IDS.FEET, label = "Feet" },
    { id = Constants.ARMOR_SUBTAB_IDS.FINGER, label = "Finger" },
    { id = Constants.ARMOR_SUBTAB_IDS.TRINKET, label = "Trinket" },
}

Constants.ARMOR_EQUIP_LOC_TO_SUBTAB = {
    INVTYPE_WEAPON = Constants.ARMOR_SUBTAB_IDS.WEAPONS,
    INVTYPE_2HWEAPON = Constants.ARMOR_SUBTAB_IDS.WEAPONS,
    INVTYPE_WEAPONMAINHAND = Constants.ARMOR_SUBTAB_IDS.WEAPONS,
    INVTYPE_WEAPONOFFHAND = Constants.ARMOR_SUBTAB_IDS.WEAPONS,
    INVTYPE_RANGED = Constants.ARMOR_SUBTAB_IDS.WEAPONS,
    INVTYPE_RANGEDRIGHT = Constants.ARMOR_SUBTAB_IDS.WEAPONS,
    INVTYPE_THROWN = Constants.ARMOR_SUBTAB_IDS.WEAPONS,
    INVTYPE_HOLDABLE = Constants.ARMOR_SUBTAB_IDS.WEAPONS,
    INVTYPE_SHIELD = Constants.ARMOR_SUBTAB_IDS.WEAPONS,

    INVTYPE_HEAD = Constants.ARMOR_SUBTAB_IDS.HEAD,
    INVTYPE_NECK = Constants.ARMOR_SUBTAB_IDS.NECK,
    INVTYPE_SHOULDER = Constants.ARMOR_SUBTAB_IDS.SHOULDER,
    INVTYPE_CLOAK = Constants.ARMOR_SUBTAB_IDS.BACK,
    INVTYPE_CHEST = Constants.ARMOR_SUBTAB_IDS.CHEST,
    INVTYPE_ROBE = Constants.ARMOR_SUBTAB_IDS.CHEST,
    INVTYPE_WRIST = Constants.ARMOR_SUBTAB_IDS.WRIST,
    INVTYPE_HAND = Constants.ARMOR_SUBTAB_IDS.HANDS,
    INVTYPE_WAIST = Constants.ARMOR_SUBTAB_IDS.WAIST,
    INVTYPE_LEGS = Constants.ARMOR_SUBTAB_IDS.LEGS,
    INVTYPE_FEET = Constants.ARMOR_SUBTAB_IDS.FEET,
    INVTYPE_FINGER = Constants.ARMOR_SUBTAB_IDS.FINGER,
    INVTYPE_TRINKET = Constants.ARMOR_SUBTAB_IDS.TRINKET,
}

Constants.MIN_WIDTH = 720
Constants.MIN_HEIGHT = 480
Constants.DEFAULT_WIDTH = 980
Constants.DEFAULT_HEIGHT = 640
Constants.ITEM_BUTTON_SIZE = 40
Constants.ITEM_BUTTON_SPACING = 6

Constants.MAIN_TAB_LOOKUP = {}
for _, tab in ipairs(Constants.MAIN_TABS) do
    Constants.MAIN_TAB_LOOKUP[tab.id] = true
end

Constants.ARMOR_SUB_TAB_LOOKUP = {}
for _, tab in ipairs(Constants.ARMOR_SUB_TABS) do
    Constants.ARMOR_SUB_TAB_LOOKUP[tab.id] = true
end

function Constants.NewMainCountMap()
    local result = {}
    for _, tab in ipairs(Constants.MAIN_TABS) do
        result[tab.id] = 0
    end
    return result
end

function Constants.NewArmorCountMap()
    local result = {}
    for _, tab in ipairs(Constants.ARMOR_SUB_TABS) do
        result[tab.id] = 0
    end
    return result
end
