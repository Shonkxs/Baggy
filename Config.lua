local ADDON_NAME, ns = ...

local Constants = ns.Constants

ns.Config = {}

ns.Config.defaults = {
    profile = {
        point = { "CENTER", "UIParent", "CENTER", 0, 0 },
        size = {
            width = Constants.DEFAULT_WIDTH,
            height = Constants.DEFAULT_HEIGHT,
        },
        scale = 1.0,
        locked = false,
        activeTab = Constants.TAB_IDS.CONSUMABLES,
        activeArmorSubTab = Constants.ARMOR_SUBTAB_IDS.ALL,
        activeMode = Constants.MODES.INVENTORY,
        trackedCurrencyIDs = {},
    },
}

function ns.Config.ClampScale(scaleValue)
    local value = tonumber(scaleValue) or 1.0
    if value < 0.75 then
        value = 0.75
    elseif value > 1.50 then
        value = 1.50
    end
    return value
end

function ns.Config.CopyPoint(point)
    if type(point) ~= "table" or #point < 5 then
        return { "CENTER", "UIParent", "CENTER", 0, 0 }
    end

    return {
        point[1] or "CENTER",
        "UIParent",
        point[3] or "CENTER",
        tonumber(point[4]) or 0,
        tonumber(point[5]) or 0,
    }
end

function ns.Config.CopySize(size)
    local width = Constants.DEFAULT_WIDTH
    local height = Constants.DEFAULT_HEIGHT

    if type(size) == "table" then
        width = tonumber(size.width) or width
        height = tonumber(size.height) or height
    end

    if width < Constants.MIN_WIDTH then
        width = Constants.MIN_WIDTH
    end

    if height < Constants.MIN_HEIGHT then
        height = Constants.MIN_HEIGHT
    end

    return {
        width = width,
        height = height,
    }
end

function ns.Config.CopyNumberList(list)
    local result = {}
    if type(list) ~= "table" then
        return result
    end

    for _, value in ipairs(list) do
        local numeric = tonumber(value)
        if numeric then
            result[#result + 1] = math.floor(numeric)
        end
    end

    return result
end
