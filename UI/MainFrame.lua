local ADDON_NAME, ns = ...

local Constants = ns.Constants
local Config = ns.Config
local Theme = ns.Theme
local Tabs = ns.Tabs
local ItemGrid = ns.ItemGrid
local BankToggle = ns.BankToggle

local MainFrame = {}
ns.MainFrame = MainFrame

local function createResizeHandle(frame, callbacks)
    local resizeHandle = CreateFrame("Button", nil, frame)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeHandle:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then
            return
        end

        if frame.locked then
            return
        end

        frame:StartSizing("BOTTOMRIGHT")
        frame.isSizing = true
    end)

    resizeHandle:SetScript("OnMouseUp", function()
        if not frame.isSizing then
            return
        end

        frame:StopMovingOrSizing()
        frame.isSizing = false

        if callbacks.onGeometryChanged then
            callbacks.onGeometryChanged()
        end
    end)

    return resizeHandle
end

local function createDragHandle(frame, callbacks)
    local dragHandle = CreateFrame("Frame", nil, frame)
    dragHandle:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
    dragHandle:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -320, -8)
    dragHandle:SetHeight(26)
    dragHandle:EnableMouse(true)
    dragHandle:RegisterForDrag("LeftButton")

    dragHandle:SetScript("OnDragStart", function()
        if frame.locked then
            return
        end

        frame:StartMoving()
        frame.isMoving = true
    end)

    dragHandle:SetScript("OnDragStop", function()
        if not frame.isMoving then
            return
        end

        frame:StopMovingOrSizing()
        frame.isMoving = false

        if callbacks.onGeometryChanged then
            callbacks.onGeometryChanged()
        end
    end)

    return dragHandle
end

local function trimText(text)
    if type(text) ~= "string" then
        return ""
    end
    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function formatFallbackCoins(copperAmount)
    local copper = tonumber(copperAmount) or 0
    if copper < 0 then
        copper = 0
    end

    copper = math.floor(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copperRemainder = copper % 100

    return string.format("%dg %ds %dc", gold, silver, copperRemainder)
end

function MainFrame.Create(callbacks)
    callbacks = callbacks or {}

    local frame = CreateFrame("Frame", "BaggyMainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(Constants.DEFAULT_WIDTH, Constants.DEFAULT_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(Constants.MIN_WIDTH, Constants.MIN_HEIGHT)
    elseif frame.SetMinResize then
        frame:SetMinResize(Constants.MIN_WIDTH, Constants.MIN_HEIGHT)
    end
    frame:SetClampedToScreen(true)
    frame.locked = false
    Theme.ApplyPanel(frame)
    frame:Hide()

    frame:SetScript("OnHide", function(selfFrame)
        if selfFrame.isMoving or selfFrame.isSizing then
            selfFrame:StopMovingOrSizing()
            selfFrame.isMoving = false
            selfFrame.isSizing = false
        end
    end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
    frame.title:SetText("Baggy")

    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)

    frame.bankToggle = BankToggle.Create(frame, function(mode)
        if callbacks.onModeChanged then
            callbacks.onModeChanged(mode)
        end
    end)
    frame.bankToggle:SetPoint("TOPRIGHT", frame.closeButton, "TOPLEFT", -6, -2)

    frame.moneyValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.moneyValue:SetPoint("RIGHT", frame.bankToggle, "LEFT", -10, 0)
    frame.moneyValue:SetJustifyH("RIGHT")

    frame.moneyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.moneyLabel:SetPoint("RIGHT", frame.moneyValue, "LEFT", -6, 0)
    frame.moneyLabel:SetText("Gold")
    if Theme.palette and Theme.palette.textMuted then
        frame.moneyLabel:SetTextColor(unpack(Theme.palette.textMuted))
    end

    frame.searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.searchLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -44)
    frame.searchLabel:SetText("Search")

    frame.searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate,BackdropTemplate")
    frame.searchBox:SetAutoFocus(false)
    frame.searchBox:SetSize(260, 24)
    frame.searchBox:SetPoint("LEFT", frame.searchLabel, "RIGHT", 10, 0)
    frame.searchBox:SetScript("OnEscapePressed", function(selfEditBox)
        selfEditBox:ClearFocus()
    end)
    Theme.StyleSearchBox(frame.searchBox)
    frame.searchBox:SetScript("OnTextChanged", function(selfEditBox)
        if frame.suppressSearchEvents then
            return
        end
        if callbacks.onSearchChanged then
            callbacks.onSearchChanged(trimText(selfEditBox:GetText()))
        end
    end)

    frame.mainTabBar = Tabs.Create(frame, Constants.MAIN_TABS, {
        height = 26,
        spacing = 4,
        fontObject = "GameFontNormalSmall",
        onSelect = function(tabID)
            if callbacks.onMainTabChanged then
                callbacks.onMainTabChanged(tabID)
            end
        end,
    })
    frame.mainTabBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -76)
    frame.mainTabBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -76)

    frame.armorTabBar = Tabs.Create(frame, Constants.ARMOR_SUB_TABS, {
        height = 22,
        spacing = 3,
        fontObject = "GameFontNormalSmall",
        onSelect = function(subTabID)
            if callbacks.onArmorSubTabChanged then
                callbacks.onArmorSubTabChanged(subTabID)
            end
        end,
    })
    frame.armorTabBar:SetPoint("TOPLEFT", frame.mainTabBar, "BOTTOMLEFT", 0, -8)
    frame.armorTabBar:SetPoint("TOPRIGHT", frame.mainTabBar, "BOTTOMRIGHT", 0, -8)

    frame.itemGrid = ItemGrid.Create(frame)
    frame.itemGrid.frame:SetPoint("TOPLEFT", frame.armorTabBar, "BOTTOMLEFT", 0, -8)
    frame.itemGrid.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 16)

    frame.emptyText = frame.itemGrid.frame:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
    frame.emptyText:SetPoint("CENTER", frame.itemGrid.frame, "CENTER")
    frame.emptyText:SetText("No items in this category.")
    frame.emptyText:Hide()

    frame.resizeHandle = createResizeHandle(frame, callbacks)
    frame.dragHandle = createDragHandle(frame, callbacks)

    function frame:SetLocked(isLocked)
        self.locked = isLocked and true or false
        self.resizeHandle:SetShown(not self.locked)
    end

    function frame:SetMode(mode, bankAvailable)
        self.bankToggle:SetState(mode, bankAvailable)
    end

    function frame:SetSearchText(text)
        self.suppressSearchEvents = true
        self.searchBox:SetText(text or "")
        self.suppressSearchEvents = false
    end

    function frame:SetMoney(copperAmount)
        local copper = tonumber(copperAmount) or 0
        if copper < 0 then
            copper = 0
        end

        copper = math.floor(copper)

        if _G.GetCoinTextureString then
            self.moneyValue:SetText(_G.GetCoinTextureString(copper))
        else
            self.moneyValue:SetText(formatFallbackCoins(copper))
        end
    end

    function frame:SetArmorSubTabsVisible(isVisible)
        if isVisible then
            self.armorTabBar:Show()
            self.itemGrid.frame:ClearAllPoints()
            self.itemGrid.frame:SetPoint("TOPLEFT", self.armorTabBar, "BOTTOMLEFT", 0, -8)
            self.itemGrid.frame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -16, 16)
        else
            self.armorTabBar:Hide()
            self.itemGrid.frame:ClearAllPoints()
            self.itemGrid.frame:SetPoint("TOPLEFT", self.mainTabBar, "BOTTOMLEFT", 0, -8)
            self.itemGrid.frame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -16, 16)
        end
    end

    function frame:UpdateTabs(activeMainTab, activeArmorSubTab, mainCounts, armorCounts)
        local mainEnabled = {}
        for _, tab in ipairs(Constants.MAIN_TABS) do
            mainEnabled[tab.id] = (mainCounts[tab.id] or 0) > 0
        end

        self.mainTabBar:SetCounts(mainCounts)
        self.mainTabBar:SetEnabledMap(mainEnabled)
        self.mainTabBar:SetActive(activeMainTab)

        local showArmorTabs = activeMainTab == Constants.TAB_IDS.ARMOR
        self:SetArmorSubTabsVisible(showArmorTabs)

        if showArmorTabs then
            local armorEnabled = {}
            for _, tab in ipairs(Constants.ARMOR_SUB_TABS) do
                armorEnabled[tab.id] = (armorCounts[tab.id] or 0) > 0
            end

            self.armorTabBar:SetCounts(armorCounts)
            self.armorTabBar:SetEnabledMap(armorEnabled)
            self.armorTabBar:SetActive(activeArmorSubTab)
        end
    end

    function frame:SetItems(items)
        self.itemGrid:SetItems(items)
        if self.itemGrid:GetItemCount() == 0 then
            self.emptyText:Show()
        else
            self.emptyText:Hide()
        end
    end

    function frame:CaptureGeometry()
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint(1)
        return {
            point or "CENTER",
            "UIParent",
            relativePoint or "CENTER",
            xOfs or 0,
            yOfs or 0,
        }, {
            width = self:GetWidth(),
            height = self:GetHeight(),
        }
    end

    function frame:ApplyProfile(profile)
        profile = profile or {}
        local point = Config.CopyPoint(profile.point)
        local size = Config.CopySize(profile.size)
        local scale = Config.ClampScale(profile.scale)

        self:SetScale(scale)
        self:SetSize(size.width, size.height)
        self:ClearAllPoints()
        self:SetPoint(point[1], UIParent, point[3], point[4], point[5])
    end

    frame:SetMoney(0)

    return frame
end
