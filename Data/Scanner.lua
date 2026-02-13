local ADDON_NAME, ns = ...

local Scanner = {}
ns.Scanner = Scanner

local pendingItemData = {}
local pendingCount = 0

local function markItemPending(itemID)
    if type(itemID) ~= "number" then
        return
    end

    if pendingItemData[itemID] then
        return
    end

    pendingItemData[itemID] = true
    pendingCount = pendingCount + 1

    if _G.C_Item and _G.C_Item.RequestLoadItemDataByID then
        _G.C_Item.RequestLoadItemDataByID(itemID)
    end
end

local function clearPendingItem(itemID)
    if not pendingItemData[itemID] then
        return false
    end

    pendingItemData[itemID] = nil
    pendingCount = pendingCount - 1
    if pendingCount < 0 then
        pendingCount = 0
    end

    return true
end

local function resolveItemLevel(itemLink)
    if not itemLink then
        return 0
    end

    if _G.C_Item and _G.C_Item.GetDetailedItemLevelInfo then
        local level = _G.C_Item.GetDetailedItemLevelInfo(itemLink)
        if type(level) == "number" then
            return level
        end
    end

    if _G.GetDetailedItemLevelInfo then
        local level = _G.GetDetailedItemLevelInfo(itemLink)
        if type(level) == "number" then
            return level
        end
    end

    return 0
end

local function resolveItemInfo(itemID, itemLink, slotInfo)
    local name, linkFromInfo, quality, _, _, _, _, _, equipLoc, icon, _, classID, subClassID = _G.GetItemInfo(itemID)
    local _, instantClassID, instantSubClassID, instantEquipLoc, instantIcon = _G.GetItemInfoInstant(itemID)

    if not name then
        markItemPending(itemID)
    end

    return {
        name = name or ("Item " .. tostring(itemID)),
        link = itemLink or linkFromInfo,
        quality = quality or slotInfo.quality or 0,
        itemLevel = resolveItemLevel(itemLink or linkFromInfo),
        classID = classID or instantClassID,
        subClassID = subClassID or instantSubClassID,
        equipLoc = equipLoc or instantEquipLoc or "",
        icon = icon or slotInfo.iconFileID or instantIcon,
    }
end

local function isMountItem(itemID)
    if not (_G.C_MountJournal and _G.C_MountJournal.GetMountFromItem) then
        return false
    end

    local mountID = _G.C_MountJournal.GetMountFromItem(itemID)
    return mountID ~= nil
end

function Scanner.ScanContainers(containerIDs)
    local records = {}
    if type(containerIDs) ~= "table" then
        return records
    end

    if not (_G.C_Container and _G.C_Container.GetContainerNumSlots and _G.C_Container.GetContainerItemInfo) then
        return records
    end

    for _, bagID in ipairs(containerIDs) do
        local slotCount = _G.C_Container.GetContainerNumSlots(bagID) or 0
        for slotID = 1, slotCount do
            local slotInfo = _G.C_Container.GetContainerItemInfo(bagID, slotID)
            if slotInfo and slotInfo.itemID then
                local itemLink = slotInfo.hyperlink
                if not itemLink and _G.C_Container.GetContainerItemLink then
                    itemLink = _G.C_Container.GetContainerItemLink(bagID, slotID)
                end

                local itemInfo = resolveItemInfo(slotInfo.itemID, itemLink, slotInfo)

                records[#records + 1] = {
                    bagID = bagID,
                    slotID = slotID,
                    itemID = slotInfo.itemID,
                    link = itemInfo.link,
                    name = itemInfo.name,
                    quality = itemInfo.quality or 0,
                    itemLevel = itemInfo.itemLevel or 0,
                    icon = itemInfo.icon,
                    stackCount = slotInfo.stackCount or 1,
                    classID = itemInfo.classID,
                    subClassID = itemInfo.subClassID,
                    equipLoc = itemInfo.equipLoc or "",
                    isMountItem = isMountItem(slotInfo.itemID),
                    isLocked = slotInfo.isLocked or false,
                }
            end
        end
    end

    return records
end

function Scanner.HandleItemDataLoadResult(itemID)
    if type(itemID) ~= "number" then
        return false
    end

    return clearPendingItem(itemID)
end

function Scanner.GetPendingCount()
    return pendingCount
end
