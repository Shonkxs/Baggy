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
    dragHandle:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -520, -8)
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

local function formatCompactCount(value)
    local numeric = tonumber(value) or 0
    if numeric < 0 then
        numeric = 0
    end

    numeric = math.floor(numeric)

    if _G.AbbreviateLargeNumbers then
        return _G.AbbreviateLargeNumbers(numeric)
    end

    if _G.BreakUpLargeNumbers then
        return _G.BreakUpLargeNumbers(numeric)
    end

    return tostring(numeric)
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

        if selfFrame.currencyPicker then
            selfFrame.currencyPicker:Hide()
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

    frame.currencyStrip = CreateFrame("Frame", nil, frame)
    frame.currencyStrip:SetSize(470, 22)
    frame.currencyStrip:SetClipsChildren(true)
    frame.currencyBadgeButtons = {}
    frame.trackedCurrencyEntries = {}

    frame.currencyAddButton = CreateFrame("Button", nil, frame, "BackdropTemplate")
    frame.currencyAddButton:SetSize(22, 22)
    frame.currencyAddButton:SetBackdrop(Theme.insetBackdrop)
    frame.currencyAddButton.text = frame.currencyAddButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.currencyAddButton.text:SetPoint("CENTER", 0, -1)
    frame.currencyAddButton.text:SetText("+")
    Theme.StyleUtilityButton(frame.currencyAddButton, true)
    frame.currencyAddButton:SetPoint("RIGHT", frame.moneyLabel, "LEFT", -8, 0)
    frame.currencyStrip:SetPoint("RIGHT", frame.currencyAddButton, "LEFT", -6, 0)

    frame.currencyPicker = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.currencyPicker:SetSize(360, 320)
    frame.currencyPicker:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -34)
    Theme.ApplyInset(frame.currencyPicker)
    frame.currencyPicker:SetFrameStrata("DIALOG")
    frame.currencyPicker:SetFrameLevel(frame:GetFrameLevel() + 40)
    if frame.currencyPicker.SetToplevel then
        frame.currencyPicker:SetToplevel(true)
    end
    frame.currencyPicker:Hide()
    frame.currencyPicker.rows = {}
    frame.currencyPicker.entries = {}
    frame.currencyPicker.rowHeight = 24
    frame.currencyPicker.rowSpacing = 2

    frame.currencyPicker.title = frame.currencyPicker:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.currencyPicker.title:SetPoint("TOPLEFT", frame.currencyPicker, "TOPLEFT", 12, -10)
    frame.currencyPicker.title:SetText("Add Currency")

    frame.currencyPicker.closeButton = CreateFrame("Button", nil, frame.currencyPicker, "UIPanelCloseButton")
    frame.currencyPicker.closeButton:SetPoint("TOPRIGHT", frame.currencyPicker, "TOPRIGHT", 2, 2)

    frame.currencyPicker.searchLabel = frame.currencyPicker:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.currencyPicker.searchLabel:SetPoint("TOPLEFT", frame.currencyPicker, "TOPLEFT", 12, -34)
    frame.currencyPicker.searchLabel:SetText("Search")

    frame.currencyPicker.searchBox = CreateFrame("EditBox", nil, frame.currencyPicker, "InputBoxTemplate,BackdropTemplate")
    frame.currencyPicker.searchBox:SetAutoFocus(false)
    frame.currencyPicker.searchBox:SetSize(220, 22)
    frame.currencyPicker.searchBox:SetPoint("LEFT", frame.currencyPicker.searchLabel, "RIGHT", 8, 0)
    Theme.StyleSearchBox(frame.currencyPicker.searchBox)

    frame.currencyPicker.scrollFrame = CreateFrame("ScrollFrame", nil, frame.currencyPicker, "UIPanelScrollFrameTemplate")
    frame.currencyPicker.scrollFrame:SetPoint("TOPLEFT", frame.currencyPicker, "TOPLEFT", 12, -56)
    frame.currencyPicker.scrollFrame:SetPoint("BOTTOMRIGHT", frame.currencyPicker, "BOTTOMRIGHT", -28, 12)

    frame.currencyPicker.content = CreateFrame("Frame", nil, frame.currencyPicker.scrollFrame)
    frame.currencyPicker.content:SetPoint("TOPLEFT")
    frame.currencyPicker.content:SetSize(1, 1)
    frame.currencyPicker.scrollFrame:SetScrollChild(frame.currencyPicker.content)

    frame.currencyPicker.emptyText = frame.currencyPicker.content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    frame.currencyPicker.emptyText:SetPoint("TOP", frame.currencyPicker.content, "TOP", 0, -8)
    frame.currencyPicker.emptyText:SetText("No currencies found.")
    frame.currencyPicker.emptyText:Hide()

    local function syncCurrencyPickerContentWidth()
        local picker = frame.currencyPicker
        if not (picker and picker.scrollFrame and picker.content) then
            return
        end

        local width = math.floor((picker.scrollFrame:GetWidth() or 0) - 4)
        if width < 1 then
            width = 1
        end

        local height = math.floor(picker.content:GetHeight() or 1)
        if height < 1 then
            height = 1
        end

        picker.content:SetSize(width, height)
    end

    frame.currencyPicker.scrollFrame:SetScript("OnSizeChanged", function()
        syncCurrencyPickerContentWidth()
    end)
    syncCurrencyPickerContentWidth()

    local function acquireCurrencyBadgeButton(index)
        local button = frame.currencyBadgeButtons[index]
        if button then
            return button
        end

        button = CreateFrame("Button", nil, frame.currencyStrip, "BackdropTemplate")
        button:SetBackdrop(Theme.insetBackdrop)
        button:SetBackdropColor(unpack(Theme.palette.insetBg))
        button:SetBackdropBorderColor(unpack(Theme.palette.insetBorder))
        button:SetHeight(20)
        button:RegisterForClicks("RightButtonUp")

        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetSize(14, 14)
        button.icon:SetPoint("LEFT", button, "LEFT", 3, 0)

        button.countText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        button.countText:SetPoint("LEFT", button.icon, "RIGHT", 3, 0)
        button.countText:SetJustifyH("LEFT")

        button:SetScript("OnClick", function(selfButton, mouseButton)
            if mouseButton ~= "RightButton" then
                return
            end

            if callbacks.onCurrencyRemove and selfButton.currencyID then
                callbacks.onCurrencyRemove(selfButton.currencyID)
            end
        end)

        button:SetScript("OnEnter", function(selfButton)
            if not _G.GameTooltip then
                return
            end

            _G.GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
            _G.GameTooltip:AddLine(selfButton.currencyName or "Currency")
            _G.GameTooltip:AddLine(string.format("Amount: %s", formatCompactCount(selfButton.quantity or 0)), 1, 1, 1)
            _G.GameTooltip:AddLine("Right-click to remove", 0.6, 0.6, 0.6)
            _G.GameTooltip:Show()
        end)

        button:SetScript("OnLeave", function()
            if _G.GameTooltip then
                _G.GameTooltip:Hide()
            end
        end)

        button:Hide()
        frame.currencyBadgeButtons[index] = button
        return button
    end

    local function acquireCurrencyPickerRow(index)
        local row = frame.currencyPicker.rows[index]
        if row then
            return row
        end

        row = CreateFrame("Button", nil, frame.currencyPicker.content, "BackdropTemplate")
        row:SetBackdrop(Theme.insetBackdrop)
        row:SetBackdropColor(unpack(Theme.palette.insetBg))
        row:SetBackdropBorderColor(unpack(Theme.palette.insetBorder))
        row:SetHeight(frame.currencyPicker.rowHeight)
        row:RegisterForClicks("LeftButtonUp")

        if index == 1 then
            row:SetPoint("TOPLEFT", frame.currencyPicker.content, "TOPLEFT", 0, 0)
            row:SetPoint("TOPRIGHT", frame.currencyPicker.content, "TOPRIGHT", 0, 0)
        else
            row:SetPoint("TOPLEFT", frame.currencyPicker.rows[index - 1], "BOTTOMLEFT", 0, -frame.currencyPicker.rowSpacing)
            row:SetPoint("TOPRIGHT", frame.currencyPicker.rows[index - 1], "BOTTOMRIGHT", 0, -frame.currencyPicker.rowSpacing)
        end

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        row.icon:SetPoint("LEFT", row, "LEFT", 6, 0)

        row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.nameText:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.nameText:SetJustifyH("LEFT")
        row.nameText:SetWordWrap(false)

        row.countText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.countText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        row.countText:SetJustifyH("RIGHT")

        row.nameText:ClearAllPoints()
        row.nameText:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.nameText:SetPoint("RIGHT", row.countText, "LEFT", -8, 0)

        row.statusText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.statusText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        row.statusText:SetText("Added")
        row.statusText:Hide()

        row:SetScript("OnClick", function(selfRow)
            if not selfRow.entry or selfRow.entry.isDisabled then
                return
            end

            if callbacks.onCurrencyAdd and callbacks.onCurrencyAdd(selfRow.entry.currencyID) then
                frame.currencyPicker.suppressSearchEvents = true
                frame.currencyPicker.searchBox:SetText("")
                frame.currencyPicker.suppressSearchEvents = false
                frame:SetCurrencyPickerVisible(false)
            end
        end)

        row:SetScript("OnEnter", function(selfRow)
            local entry = selfRow.entry
            if not entry or not _G.GameTooltip then
                return
            end

            _G.GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
            _G.GameTooltip:AddLine(entry.name or "Currency")
            _G.GameTooltip:AddLine(string.format("Amount: %s", formatCompactCount(entry.quantity or 0)), 1, 1, 1)
            _G.GameTooltip:Show()
        end)

        row:SetScript("OnLeave", function()
            if _G.GameTooltip then
                _G.GameTooltip:Hide()
            end
        end)

        frame.currencyPicker.rows[index] = row
        return row
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

    frame.currencyAddButton:SetScript("OnClick", function()
        frame:SetCurrencyPickerVisible(not frame.currencyPicker:IsShown())
    end)

    frame.currencyPicker.closeButton:SetScript("OnClick", function()
        frame:SetCurrencyPickerVisible(false)
    end)

    frame.currencyPicker.searchBox:SetScript("OnEscapePressed", function(selfEditBox)
        selfEditBox:ClearFocus()
        frame:SetCurrencyPickerVisible(false)
    end)

    frame.currencyPicker.searchBox:SetScript("OnTextChanged", function(selfEditBox)
        if frame.currencyPicker.suppressSearchEvents then
            return
        end

        frame:RefreshCurrencyPicker(trimText(selfEditBox:GetText()))
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

    function frame:SetTrackedCurrencies(entries)
        self.trackedCurrencyEntries = entries or {}

        local rightAnchor
        local shown = 0
        local maxTracked = 8

        for _, entry in ipairs(self.trackedCurrencyEntries) do
            if shown >= maxTracked then
                break
            end

            shown = shown + 1
            local button = acquireCurrencyBadgeButton(shown)
            local quantity = tonumber(entry.quantity) or 0
            if quantity < 0 then
                quantity = 0
            end

            button.currencyID = entry.currencyID
            button.currencyName = entry.name or string.format("Currency %s", tostring(entry.currencyID or "?"))
            button.quantity = math.floor(quantity)
            button.icon:SetTexture(entry.iconFileID or 134400)
            button.countText:SetText(formatCompactCount(button.quantity))

            local width = math.floor((button.countText:GetStringWidth() or 0) + 24)
            if width < 28 then
                width = 28
            elseif width > 56 then
                width = 56
            end

            button:SetWidth(width)
            button:ClearAllPoints()
            if rightAnchor then
                button:SetPoint("RIGHT", rightAnchor, "LEFT", -4, 0)
            else
                button:SetPoint("RIGHT", self.currencyStrip, "RIGHT", 0, 0)
            end

            rightAnchor = button
            button:Show()
        end

        for index = shown + 1, #self.currencyBadgeButtons do
            self.currencyBadgeButtons[index]:Hide()
        end
    end

    function frame:RefreshCurrencyPicker(searchText)
        if not self.currencyPicker then
            return
        end

        local picker = self.currencyPicker
        syncCurrencyPickerContentWidth()
        local query = searchText
        if query == nil then
            query = picker.searchBox:GetText() or ""
        end
        query = trimText(query)
        self.currencyPickerSearchText = query

        if (picker.searchBox:GetText() or "") ~= query then
            picker.suppressSearchEvents = true
            picker.searchBox:SetText(query)
            picker.suppressSearchEvents = false
        end

        local entries = {}
        if callbacks.getCurrencyPickerOptions then
            entries = callbacks.getCurrencyPickerOptions(query) or {}
        end
        picker.entries = entries

        local shown = 0
        for _, entry in ipairs(entries) do
            shown = shown + 1
            local row = acquireCurrencyPickerRow(shown)
            row.entry = entry
            row.icon:SetTexture(entry.iconFileID or 134400)
            row.nameText:SetText(entry.name or string.format("Currency %s", tostring(entry.currencyID or "?")))
            row.countText:SetText(formatCompactCount(entry.quantity or 0))

            if entry.isSelected then
                row.nameText:SetTextColor(unpack(Theme.palette.textMuted))
                row.countText:SetText("")
                row.statusText:SetText("Added")
                row.statusText:Show()
                row:SetEnabled(false)
                row:SetBackdropColor(unpack(Theme.palette.tabBgDisabled))
                row:SetBackdropBorderColor(unpack(Theme.palette.tabBorder))
            elseif entry.isDisabled then
                row.nameText:SetTextColor(unpack(Theme.palette.textMuted))
                row.countText:SetText("")
                row.statusText:SetText("Max 8")
                row.statusText:Show()
                row:SetEnabled(false)
                row:SetBackdropColor(unpack(Theme.palette.tabBgDisabled))
                row:SetBackdropBorderColor(unpack(Theme.palette.tabBorder))
            else
                row.nameText:SetTextColor(unpack(Theme.palette.textNormal))
                row.countText:SetTextColor(unpack(Theme.palette.textMuted))
                row.statusText:Hide()
                row:SetEnabled(true)
                row:SetBackdropColor(unpack(Theme.palette.insetBg))
                row:SetBackdropBorderColor(unpack(Theme.palette.insetBorder))
            end

            row:Show()
        end

        for index = shown + 1, #picker.rows do
            picker.rows[index]:Hide()
        end

        picker.emptyText:SetShown(shown == 0)

        local rowExtent = picker.rowHeight + picker.rowSpacing
        local contentHeight = shown > 0 and ((shown * rowExtent) - picker.rowSpacing) or 1
        picker.content:SetHeight(contentHeight)
        syncCurrencyPickerContentWidth()
    end

    function frame:SetCurrencyPickerVisible(isVisible)
        if not self.currencyPicker then
            return
        end

        if isVisible then
            self.currencyPicker:Show()
            self.currencyPicker:SetFrameLevel(self:GetFrameLevel() + 40)
            self.currencyPicker:Raise()
            syncCurrencyPickerContentWidth()

            if callbacks.onCurrencyPickerOpened then
                callbacks.onCurrencyPickerOpened()
            end

            self.currencyPicker.suppressSearchEvents = true
            self.currencyPicker.searchBox:SetText("")
            self.currencyPicker.suppressSearchEvents = false
            self:RefreshCurrencyPicker("")
            self.currencyPicker.searchBox:SetFocus()
        else
            self.currencyPicker:Hide()
            self.currencyPicker.searchBox:ClearFocus()
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

    frame.currencyPickerSearchText = ""
    frame:SetMoney(0)
    frame:SetTrackedCurrencies({})

    return frame
end
