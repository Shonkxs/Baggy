local ADDON_NAME, ns = ...

local AceAddon = LibStub("AceAddon-3.0")
local AceDB = LibStub("AceDB-3.0")

local Baggy = AceAddon:NewAddon(ADDON_NAME, "AceEvent-3.0", "AceConsole-3.0")
ns.Baggy = Baggy

local Constants = ns.Constants
local Config = ns.Config
local ContainerIndex = ns.ContainerIndex
local Categorizer = ns.Categorizer
local Scanner = ns.Scanner
local MainFrame = ns.MainFrame

local function normalizeMainTab(tabID)
    return Categorizer.NormalizeMainTab(tabID)
end

local function lowerOrEmpty(value)
    if type(value) ~= "string" then
        return ""
    end
    return string.lower(value)
end

local function itemSort(a, b)
    local aQuality = a.quality or 0
    local bQuality = b.quality or 0
    if aQuality ~= bQuality then
        return aQuality > bQuality
    end

    local aName = lowerOrEmpty(a.name)
    local bName = lowerOrEmpty(b.name)
    if aName ~= bName then
        return aName < bName
    end

    local aLevel = a.itemLevel or 0
    local bLevel = b.itemLevel or 0
    if aLevel ~= bLevel then
        return aLevel > bLevel
    end

    if a.bagID ~= b.bagID then
        return a.bagID < b.bagID
    end

    return (a.slotID or 0) < (b.slotID or 0)
end

local function cloneDefaults()
    local defaults = Config.defaults.profile
    return {
        point = Config.CopyPoint(defaults.point),
        size = Config.CopySize(defaults.size),
        scale = defaults.scale,
        locked = defaults.locked,
        activeTab = defaults.activeTab,
        activeArmorSubTab = defaults.activeArmorSubTab,
        activeMode = defaults.activeMode,
    }
end

function Baggy:OnInitialize()
    self.db = AceDB:New("BaggyDB", Config.defaults, true)
    self.profile = self.db.profile

    self.profile.activeTab = normalizeMainTab(self.profile.activeTab)
    if not Constants.MAIN_TAB_LOOKUP[self.profile.activeTab] then
        self.profile.activeTab = Constants.TAB_IDS.CONSUMABLES
    end

    if not Constants.ARMOR_SUB_TAB_LOOKUP[self.profile.activeArmorSubTab] then
        self.profile.activeArmorSubTab = Constants.ARMOR_SUBTAB_IDS.ALL
    end

    if self.profile.activeMode ~= Constants.MODES.BANK then
        self.profile.activeMode = Constants.MODES.INVENTORY
    end

    self.activeTab = self.profile.activeTab
    self.activeArmorSubTab = self.profile.activeArmorSubTab
    self.activeMode = self.profile.activeMode
    self.searchText = ""
    self.bankOpen = false

    self.mainBuckets = nil
    self.armorBuckets = nil
    self.mainCounts = Constants.NewMainCountMap()
    self.armorCounts = Constants.NewArmorCountMap()
    self.debugClassificationEnabled = false
    self.playerMoney = 0

    self:RegisterChatCommand("baggy", "HandleSlashCommand")
end

function Baggy:OnEnable()
    self:RegisterEvent("PLAYER_LOGIN")
    if _G.IsLoggedIn and _G.IsLoggedIn() then
        self:PLAYER_LOGIN()
    end
end

function Baggy:PLAYER_LOGIN()
    if self.started then
        return
    end

    self.started = true

    self.mainFrame = MainFrame.Create({
        onMainTabChanged = function(tabID) self:HandleMainTabChanged(tabID) end,
        onArmorSubTabChanged = function(subTabID) self:HandleArmorSubTabChanged(subTabID) end,
        onSearchChanged = function(text) self:HandleSearchChanged(text) end,
        onModeChanged = function(mode) self:SetMode(mode) end,
        onGeometryChanged = function() self:SaveGeometry() end,
    })

    self.mainFrame:ApplyProfile(self.profile)
    self.mainFrame:SetLocked(self.profile.locked)
    self.mainFrame:SetSearchText(self.searchText)
    self.mainFrame:SetMode(self:GetEffectiveMode(), self.bankOpen)

    self:RegisterEvent("BAG_UPDATE_DELAYED", "RequestRescan")
    self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", "RequestRescan")
    self:RegisterEvent("BANKFRAME_OPENED")
    self:RegisterEvent("BANKFRAME_CLOSED")
    self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
    self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
    self:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    self:RegisterEvent("PLAYER_MONEY")

    if _G.C_EventUtils and _G.C_EventUtils.IsEventValid and _G.C_EventUtils.IsEventValid("PLAYERREAGENTBANKSLOTS_CHANGED") then
        self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED", "RequestRescan")
    end

    self:InstallBagHooks()
    self:InstallContainerFrameVisibilityHooks()
    self:AddToSpecialFrames()
    self:RefreshMoney()
    Categorizer.RebuildTradeSubclassSets()
    self:RebuildData()
    self:ApplyView()

    _G.C_Timer.After(2, function()
        self:InstallContainerFrameVisibilityHooks()
    end)
end

function Baggy:AddToSpecialFrames()
    if type(_G.UISpecialFrames) ~= "table" then
        return
    end

    for _, frameName in ipairs(_G.UISpecialFrames) do
        if frameName == "BaggyMainFrame" then
            return
        end
    end

    _G.UISpecialFrames[#_G.UISpecialFrames + 1] = "BaggyMainFrame"
end

function Baggy:InstallBagHooks()
    if self.hooksInstalled then
        return
    end
    self.hooksInstalled = true

    local function hookIfExists(globalFunctionName, callback)
        if type(_G[globalFunctionName]) == "function" then
            hooksecurefunc(globalFunctionName, callback)
        end
    end

    hookIfExists("OpenAllBags", function()
        self:HandleBagOpenRequest()
    end)

    hookIfExists("OpenBackpack", function()
        self:HandleBagOpenRequest()
    end)

    hookIfExists("CloseAllBags", function()
        self:HandleBagCloseRequest()
    end)

    hookIfExists("CloseBackpack", function()
        self:HandleBagCloseRequest()
    end)

    hookIfExists("ToggleAllBags", function()
        local token = self.bagActionToken or 0
        _G.C_Timer.After(0, function()
            if (self.bagActionToken or 0) ~= token then
                return
            end
            self:HandleBagToggleFallback()
        end)
    end)

    hookIfExists("ToggleBackpack", function()
        local token = self.bagActionToken or 0
        _G.C_Timer.After(0, function()
            if (self.bagActionToken or 0) ~= token then
                return
            end
            self:HandleBagToggleFallback()
        end)
    end)

    hookIfExists("OpenBag", function()
        self:HandleBagOpenRequest()
    end)

    hookIfExists("CloseBag", function()
        self:HandleBagCloseRequest()
    end)

    hookIfExists("ToggleBag", function()
        local token = self.bagActionToken or 0
        _G.C_Timer.After(0, function()
            if (self.bagActionToken or 0) ~= token then
                return
            end
            self:HandleBagToggleFallback()
        end)
    end)
end

function Baggy:InstallContainerFrameVisibilityHooks()
    self.containerShowHooks = self.containerShowHooks or {}

    local function hookFrame(frame)
        if not frame or self.containerShowHooks[frame] then
            return
        end

        self.containerShowHooks[frame] = true
        frame:HookScript("OnShow", function()
            if not self.mainFrame then
                return
            end

            self:HandleBagOpenRequest()
        end)
    end

    hookFrame(_G.ContainerFrameCombinedBags)

    if _G.ContainerFrameContainer and _G.ContainerFrameContainer.ContainerFrames then
        for _, frame in ipairs(_G.ContainerFrameContainer.ContainerFrames) do
            hookFrame(frame)
        end
    end

    for index = 1, 20 do
        hookFrame(_G["ContainerFrame" .. tostring(index)])
    end
end

function Baggy:MarkBagAction()
    self.bagActionToken = (self.bagActionToken or 0) + 1
end

function Baggy:SuppressBagCloseFor(seconds)
    local now = (_G.GetTime and _G.GetTime()) or 0
    local duration = tonumber(seconds) or 0.35
    local untilTime = now + duration

    if (self.suppressBagCloseUntil or 0) < untilTime then
        self.suppressBagCloseUntil = untilTime
    end
end

function Baggy:IsBagCloseSuppressed()
    local now = (_G.GetTime and _G.GetTime()) or 0
    return (self.suppressBagCloseUntil or 0) > now
end

function Baggy:RefreshMoney()
    local money = 0
    if _G.GetMoney then
        money = tonumber(_G.GetMoney()) or 0
    end

    if money < 0 then
        money = 0
    end

    self.playerMoney = math.floor(money)

    if self.mainFrame and self.mainFrame.SetMoney then
        self.mainFrame:SetMoney(self.playerMoney)
    end
end

function Baggy:HandleBagOpenRequest()
    if not self.mainFrame then
        return
    end

    self:MarkBagAction()
    self:SuppressBagCloseFor(0.40)
    self:RefreshMoney()

    self.mainFrame:Show()
    self:RequestRescan()
    self:HideBlizzardBagFrames()
end

function Baggy:HandleBagCloseRequest()
    if not self.mainFrame then
        return
    end

    if self:IsBagCloseSuppressed() then
        return
    end

    if self.activeMode == Constants.MODES.BANK and self.bankOpen then
        return
    end

    self:MarkBagAction()
    self.mainFrame:Hide()
end

function Baggy:HandleBagToggleFallback()
    if not self.mainFrame then
        return
    end

    if self.mainFrame:IsShown() and self:GetEffectiveMode() == Constants.MODES.INVENTORY then
        self:HandleBagCloseRequest()
        return
    end

    self:HandleBagOpenRequest()
end

function Baggy:HideBlizzardBagFrames()
    self:SuppressBagCloseFor(0.40)
    self:InstallContainerFrameVisibilityHooks()

    if _G.ContainerFrameCombinedBags and _G.ContainerFrameCombinedBags:IsShown() then
        _G.ContainerFrameCombinedBags:Hide()
    end

    if _G.ContainerFrameContainer and _G.ContainerFrameContainer.ContainerFrames then
        for _, containerFrame in ipairs(_G.ContainerFrameContainer.ContainerFrames) do
            if containerFrame and containerFrame:IsShown() then
                containerFrame:Hide()
            end
        end
    end

    for index = 1, 13 do
        local frame = _G["ContainerFrame" .. tostring(index)]
        if frame and frame:IsShown() then
            frame:Hide()
        end
    end

    _G.C_Timer.After(0, function()
        if self.mainFrame and self.mainFrame:IsShown() then
            self:SuppressBagCloseFor(0.40)
            if _G.ContainerFrameCombinedBags and _G.ContainerFrameCombinedBags:IsShown() then
                _G.ContainerFrameCombinedBags:Hide()
            end

            if _G.ContainerFrameContainer and _G.ContainerFrameContainer.ContainerFrames then
                for _, containerFrame in ipairs(_G.ContainerFrameContainer.ContainerFrames) do
                    if containerFrame and containerFrame:IsShown() then
                        containerFrame:Hide()
                    end
                end
            end
        end
    end)
end

function Baggy:GetEffectiveMode()
    if self.activeMode == Constants.MODES.BANK and self.bankOpen then
        return Constants.MODES.BANK
    end

    return Constants.MODES.INVENTORY
end

function Baggy:SetMode(mode)
    if mode == Constants.MODES.BANK and not self.bankOpen then
        mode = Constants.MODES.INVENTORY
    end

    if mode ~= Constants.MODES.BANK then
        mode = Constants.MODES.INVENTORY
    end

    self.activeMode = mode
    self.profile.activeMode = mode
    self:RequestRescan()
end

function Baggy:RebuildData()
    local mode = self:GetEffectiveMode()
    local containerIDs = ContainerIndex.GetContainers(mode, self.bankOpen)
    local records = Scanner.ScanContainers(containerIDs)
    local debugLines = {}
    local debugLineLimit = 25

    local mainBuckets = {}
    local armorBuckets = {}
    local mainCounts = Constants.NewMainCountMap()
    local armorCounts = Constants.NewArmorCountMap()

    for _, tab in ipairs(Constants.MAIN_TABS) do
        mainBuckets[tab.id] = {}
    end

    for _, subTab in ipairs(Constants.ARMOR_SUB_TABS) do
        armorBuckets[subTab.id] = {}
    end

    for _, itemRecord in ipairs(records) do
        local mainTab, armorSubTab = Categorizer.Categorize(itemRecord)
        if not mainBuckets[mainTab] then
            mainTab = Constants.TAB_IDS.MISC
        end

        if self.debugClassificationEnabled and #debugLines < debugLineLimit then
            local debugName = tostring(itemRecord.name or "?")
            debugLines[#debugLines + 1] = string.format(
                "#%d id=%s name=%s class=%s sub=%s -> %s",
                #debugLines + 1,
                tostring(itemRecord.itemID),
                debugName,
                tostring(itemRecord.classID),
                tostring(itemRecord.subClassID),
                tostring(mainTab)
            )
        end

        mainBuckets[mainTab][#mainBuckets[mainTab] + 1] = itemRecord
        mainCounts[mainTab] = (mainCounts[mainTab] or 0) + 1

        if mainTab == Constants.TAB_IDS.ARMOR then
            armorBuckets[Constants.ARMOR_SUBTAB_IDS.ALL][#armorBuckets[Constants.ARMOR_SUBTAB_IDS.ALL] + 1] = itemRecord
            armorCounts[Constants.ARMOR_SUBTAB_IDS.ALL] = armorCounts[Constants.ARMOR_SUBTAB_IDS.ALL] + 1

            if armorSubTab and armorBuckets[armorSubTab] then
                armorBuckets[armorSubTab][#armorBuckets[armorSubTab] + 1] = itemRecord
                armorCounts[armorSubTab] = armorCounts[armorSubTab] + 1
            end
        end
    end

    for _, tab in ipairs(Constants.MAIN_TABS) do
        table.sort(mainBuckets[tab.id], itemSort)
    end

    for _, subTab in ipairs(Constants.ARMOR_SUB_TABS) do
        table.sort(armorBuckets[subTab.id], itemSort)
    end

    self.mainBuckets = mainBuckets
    self.armorBuckets = armorBuckets
    self.mainCounts = mainCounts
    self.armorCounts = armorCounts

    if self.debugClassificationEnabled then
        self:Print(string.format(
            "Debug classify: showing %d of %d scanned item(s).",
            #debugLines,
            #records
        ))
        for _, line in ipairs(debugLines) do
            self:Print(line)
        end
    end
end

function Baggy:GetVisibleItems()
    if not self.mainBuckets then
        return {}
    end

    local sourceItems
    if self.activeTab == Constants.TAB_IDS.ARMOR then
        sourceItems = self.armorBuckets[self.activeArmorSubTab] or self.armorBuckets[Constants.ARMOR_SUBTAB_IDS.ALL] or {}
    else
        sourceItems = self.mainBuckets[self.activeTab] or {}
    end

    local query = lowerOrEmpty(self.searchText)
    query = query:gsub("^%s+", ""):gsub("%s+$", "")
    if query == "" then
        return sourceItems
    end

    local filtered = {}
    for _, itemRecord in ipairs(sourceItems) do
        if string.find(lowerOrEmpty(itemRecord.name), query, 1, true) then
            filtered[#filtered + 1] = itemRecord
        end
    end

    return filtered
end

function Baggy:ApplyView()
    if not self.mainFrame then
        return
    end

    if not self.mainBuckets then
        self:RebuildData()
    end

    if not Constants.MAIN_TAB_LOOKUP[self.activeTab] then
        self.activeTab = Constants.TAB_IDS.CONSUMABLES
    end

    if not Constants.ARMOR_SUB_TAB_LOOKUP[self.activeArmorSubTab] then
        self.activeArmorSubTab = Constants.ARMOR_SUBTAB_IDS.ALL
    end

    self.profile.activeTab = self.activeTab
    self.profile.activeArmorSubTab = self.activeArmorSubTab

    local visibleItems = self:GetVisibleItems()
    local effectiveMode = self:GetEffectiveMode()

    self.mainFrame:SetMode(effectiveMode, self.bankOpen)
    self.mainFrame:UpdateTabs(self.activeTab, self.activeArmorSubTab, self.mainCounts, self.armorCounts)
    self.mainFrame:SetItems(visibleItems)

    if self.mainFrame:IsShown() then
        self:HideBlizzardBagFrames()
    end
end

function Baggy:RequestRescan()
    if not self.started then
        return
    end

    if self.rescanQueued then
        return
    end

    self.rescanQueued = true
    _G.C_Timer.After(0, function()
        self.rescanQueued = false
        self:RebuildData()
        self:ApplyView()
    end)
end

function Baggy:HandleMainTabChanged(tabID)
    if not Constants.MAIN_TAB_LOOKUP[tabID] then
        return
    end

    self.activeTab = tabID
    self.profile.activeTab = tabID
    self:ApplyView()
end

function Baggy:HandleArmorSubTabChanged(subTabID)
    if not Constants.ARMOR_SUB_TAB_LOOKUP[subTabID] then
        return
    end

    self.activeArmorSubTab = subTabID
    self.profile.activeArmorSubTab = subTabID
    self:ApplyView()
end

function Baggy:HandleSearchChanged(searchText)
    self.searchText = searchText or ""
    self:ApplyView()
end

function Baggy:SaveGeometry()
    if not self.mainFrame then
        return
    end

    local point, size = self.mainFrame:CaptureGeometry()
    self.profile.point = point
    self.profile.size = size
end

function Baggy:ResetProfileLayout()
    local defaults = cloneDefaults()
    self.profile.point = defaults.point
    self.profile.size = defaults.size
    self.profile.scale = defaults.scale
    self.profile.locked = defaults.locked
    self.profile.activeTab = defaults.activeTab
    self.profile.activeArmorSubTab = defaults.activeArmorSubTab
    self.profile.activeMode = defaults.activeMode

    self.activeTab = self.profile.activeTab
    self.activeArmorSubTab = self.profile.activeArmorSubTab
    self.activeMode = self.profile.activeMode
    self.searchText = ""

    if self.mainFrame then
        self.mainFrame:ApplyProfile(self.profile)
        self.mainFrame:SetLocked(self.profile.locked)
        self.mainFrame:SetSearchText("")
    end

    self:RequestRescan()
end

function Baggy:ToggleMainFrame()
    if not self.mainFrame then
        return
    end

    if self.mainFrame:IsShown() then
        self.mainFrame:Hide()
    else
        self.mainFrame:Show()
        self:RequestRescan()
        self:HideBlizzardBagFrames()
    end
end

function Baggy:HandleSlashCommand(input)
    local command, args = string.match(input or "", "^(%S+)%s*(.-)$")
    command = command and string.lower(command) or ""

    if command == "" then
        self:ToggleMainFrame()
        return
    end

    if command == "help" then
        self:Print("Baggy commands:")
        self:Print("/baggy - Toggle Baggy")
        self:Print("/baggy help - Show this help")
        self:Print("/baggy reset - Reset layout and settings")
        self:Print("/baggy lock - Toggle frame lock")
        self:Print("/baggy scale <0.75-1.50> - Set frame scale")
        self:Print("/baggy debug classify - Toggle classification debug output")
        return
    end

    if command == "debug" then
        local debugAction = string.match(args or "", "^(%S+)") or ""
        debugAction = string.lower(debugAction)

        if debugAction == "classify" then
            self.debugClassificationEnabled = not self.debugClassificationEnabled
            self:Print(self.debugClassificationEnabled and
                "Classification debug enabled (max 25 lines per rescan)." or
                "Classification debug disabled.")

            if self.debugClassificationEnabled then
                self:RequestRescan()
            end
            return
        end

        self:Print("Usage: /baggy debug classify")
        return
    end

    if command == "reset" then
        self:ResetProfileLayout()
        self:Print("Baggy layout and settings reset.")
        return
    end

    if command == "lock" then
        self.profile.locked = not self.profile.locked
        if self.mainFrame then
            self.mainFrame:SetLocked(self.profile.locked)
        end
        self:Print(self.profile.locked and "Baggy frame locked." or "Baggy frame unlocked.")
        return
    end

    if command == "scale" then
        local requestedScale = tonumber(args)
        if not requestedScale then
            self:Print("Usage: /baggy scale <0.75-1.50>")
            return
        end

        local clampedScale = Config.ClampScale(requestedScale)
        self.profile.scale = clampedScale
        if self.mainFrame then
            self.mainFrame:SetScale(clampedScale)
            self:SaveGeometry()
        end
        self:Print(string.format("Baggy scale set to %.2f", clampedScale))
        return
    end

    self:Print("Unknown command. Use /baggy help")
end

function Baggy:BANKFRAME_OPENED()
    self.bankOpen = true
    self:RequestRescan()
end

function Baggy:BANKFRAME_CLOSED()
    self.bankOpen = false
    if self.activeMode == Constants.MODES.BANK then
        self.activeMode = Constants.MODES.INVENTORY
        self.profile.activeMode = Constants.MODES.INVENTORY
    end
    self:RequestRescan()
end

function Baggy:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(_, interactionType)
    local types = _G.Enum and _G.Enum.PlayerInteractionType
    if not types then
        return
    end

    if interactionType == types.Banker
        or interactionType == types.CharacterBanker
        or interactionType == types.AccountBanker then
        self.bankOpen = true
        self:RequestRescan()
    end
end

function Baggy:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(_, interactionType)
    local types = _G.Enum and _G.Enum.PlayerInteractionType
    if not types then
        return
    end

    if interactionType == types.Banker
        or interactionType == types.CharacterBanker
        or interactionType == types.AccountBanker then
        self.bankOpen = false
        if self.activeMode == Constants.MODES.BANK then
            self.activeMode = Constants.MODES.INVENTORY
            self.profile.activeMode = Constants.MODES.INVENTORY
        end
        self:RequestRescan()
    end
end

function Baggy:ITEM_DATA_LOAD_RESULT(_, itemID)
    if Scanner.HandleItemDataLoadResult(itemID) then
        self:RequestRescan()
    end
end

function Baggy:PLAYER_MONEY()
    self:RefreshMoney()
end
