local ADDON_NAME, ns = ...

local Constants = ns.Constants

local ContainerIndex = {}
ns.ContainerIndex = ContainerIndex

local function getBagIndexEnum()
    return (_G.Enum and _G.Enum.BagIndex) or {}
end

local function getInventoryConstants()
    return (_G.Constants and _G.Constants.InventoryConstants) or {}
end

local function getContainerSlots(bagID)
    if not (_G.C_Container and _G.C_Container.GetContainerNumSlots) then
        return 0
    end

    local slots = _G.C_Container.GetContainerNumSlots(bagID)
    if type(slots) ~= "number" then
        return 0
    end

    return slots
end

local function appendContainer(out, seen, bagID)
    if bagID == nil or seen[bagID] then
        return
    end

    if getContainerSlots(bagID) <= 0 then
        return
    end

    seen[bagID] = true
    out[#out + 1] = bagID
end

local function appendRange(out, seen, startID, count)
    if startID == nil or type(count) ~= "number" or count <= 0 then
        return
    end

    for index = 0, count - 1 do
        appendContainer(out, seen, startID + index)
    end
end

function ContainerIndex.GetInventoryContainers()
    local bagIndex = getBagIndexEnum()
    local inventoryConstants = getInventoryConstants()
    local containers = {}
    local seen = {}

    appendContainer(containers, seen, bagIndex.Backpack)

    appendRange(
        containers,
        seen,
        bagIndex.Bag_1,
        inventoryConstants.NumBagSlots or 0
    )

    appendRange(
        containers,
        seen,
        bagIndex.ReagentBag,
        inventoryConstants.NumReagentBagSlots or 0
    )

    return containers
end

function ContainerIndex.GetBankContainers()
    local bagIndex = getBagIndexEnum()
    local inventoryConstants = getInventoryConstants()
    local containers = {}
    local seen = {}

    for _, bagID in ipairs(ContainerIndex.GetInventoryContainers()) do
        appendContainer(containers, seen, bagID)
    end

    appendContainer(containers, seen, bagIndex.Bank)
    appendContainer(containers, seen, bagIndex.Reagentbank)

    appendRange(
        containers,
        seen,
        bagIndex.CharacterBankTab_1 or bagIndex.BankBag_1,
        inventoryConstants.MAX_TRANSACTION_BANK_TABS or inventoryConstants.NumBankBagSlots or 0
    )

    appendRange(
        containers,
        seen,
        bagIndex.AccountBankTab_1,
        inventoryConstants.NumAccountBankSlots or 0
    )

    return containers
end

function ContainerIndex.GetContainers(mode, bankOpen)
    if mode == Constants.MODES.BANK and bankOpen then
        return ContainerIndex.GetBankContainers()
    end

    return ContainerIndex.GetInventoryContainers()
end
