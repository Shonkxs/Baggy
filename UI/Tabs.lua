local ADDON_NAME, ns = ...

local Theme = ns.Theme

local Tabs = {}
ns.Tabs = Tabs

local function createTabButton(parent, fontObject)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetBackdrop(Theme.insetBackdrop)
    button.text = button:CreateFontString(nil, "OVERLAY", fontObject or "GameFontNormalSmall")
    button.text:SetPoint("CENTER")
    button.text:SetWordWrap(false)
    button.text:SetJustifyH("CENTER")
    return button
end

function Tabs.Create(parent, definitions, options)
    options = options or {}

    local bar = CreateFrame("Frame", nil, parent)
    bar.buttons = {}
    bar.buttonsByID = {}
    bar.definitions = definitions or {}
    bar.spacing = options.spacing or 4
    bar.buttonHeight = options.height or 24
    bar.fontObject = options.fontObject or "GameFontNormalSmall"
    bar.onSelect = options.onSelect
    bar.activeID = options.defaultID
    bar.countByID = {}
    bar.enabledByID = {}

    function bar:SetCounts(countByID)
        self.countByID = countByID or {}

        for _, button in ipairs(self.buttons) do
            local count = self.countByID[button.tabID] or 0
            button.text:SetText(string.format("%s (%d)", button.baseLabel, count))
        end

        self:RefreshStyles()
    end

    function bar:SetEnabledMap(enabledByID)
        self.enabledByID = enabledByID or {}
        self:RefreshStyles()
    end

    function bar:SetActive(tabID)
        self.activeID = tabID
        self:RefreshStyles()
    end

    function bar:GetActive()
        return self.activeID
    end

    function bar:Layout()
        local buttonCount = #self.buttons
        if buttonCount == 0 then
            return
        end

        local availableWidth = self:GetWidth()
        local buttonWidth = math.floor((availableWidth - ((buttonCount - 1) * self.spacing)) / buttonCount)
        if buttonWidth < 44 then
            buttonWidth = 44
        end

        local previous
        for _, button in ipairs(self.buttons) do
            button:ClearAllPoints()
            button:SetSize(buttonWidth, self.buttonHeight)

            if previous then
                button:SetPoint("LEFT", previous, "RIGHT", self.spacing, 0)
            else
                button:SetPoint("LEFT", self, "LEFT", 0, 0)
            end

            previous = button
        end
    end

    function bar:RefreshStyles()
        for _, button in ipairs(self.buttons) do
            local isEnabled = self.enabledByID[button.tabID] ~= false
            local isActive = self.activeID == button.tabID
            Theme.StyleTabButton(button, isActive, isEnabled)
            button:SetEnabled(isEnabled)
        end
    end

    for _, definition in ipairs(bar.definitions) do
        local button = createTabButton(bar, bar.fontObject)
        button.tabID = definition.id
        button.baseLabel = definition.label
        button:SetScript("OnClick", function(selfButton)
            if bar.activeID ~= selfButton.tabID then
                bar:SetActive(selfButton.tabID)
                if bar.onSelect then
                    bar.onSelect(selfButton.tabID)
                end
            end
        end)

        bar.buttons[#bar.buttons + 1] = button
        bar.buttonsByID[button.tabID] = button
    end

    if not bar.activeID and bar.definitions[1] then
        bar.activeID = bar.definitions[1].id
    end

    bar:SetHeight(bar.buttonHeight)
    bar:SetScript("OnSizeChanged", function()
        bar:Layout()
    end)

    bar:Layout()
    bar:RefreshStyles()

    return bar
end
