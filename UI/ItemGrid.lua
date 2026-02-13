local ADDON_NAME, ns = ...

local Constants = ns.Constants
local Theme = ns.Theme
local ItemButton = ns.ItemButton

local ItemGrid = {}
ns.ItemGrid = ItemGrid

function ItemGrid.Create(parent)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Theme.ApplyInset(frame)

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
    scrollFrame:SetClipsChildren(true)
    scrollFrame:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    local grid = {
        frame = frame,
        scrollFrame = scrollFrame,
        content = content,
        buttons = {},
        items = {},
        scrollStep = (Constants.ITEM_BUTTON_SIZE + Constants.ITEM_BUTTON_SPACING) * 2,
    }

    local function ensureButtons(count)
        while #grid.buttons < count do
            grid.buttons[#grid.buttons + 1] = ItemButton.Create(grid.content)
        end
    end

    function grid:Refresh()
        local itemCount = #self.items
        ensureButtons(itemCount)

        local itemSize = Constants.ITEM_BUTTON_SIZE
        local spacing = Constants.ITEM_BUTTON_SPACING
        local rowHeight = itemSize + spacing

        local availableWidth = math.max(1, self.scrollFrame:GetWidth())
        local columns = math.floor((availableWidth + spacing) / rowHeight)
        if columns < 1 then
            columns = 1
        end

        local rows = math.ceil(itemCount / columns)
        local contentWidth = columns * rowHeight
        local contentHeight = rows * rowHeight
        if contentHeight < 1 then
            contentHeight = 1
        end

        self.content:SetSize(contentWidth, contentHeight)

        for index, itemRecord in ipairs(self.items) do
            local row = math.floor((index - 1) / columns)
            local column = (index - 1) % columns
            local button = self.buttons[index]
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", self.content, "TOPLEFT", column * rowHeight, -(row * rowHeight))
            button:SetItem(itemRecord)
        end

        for index = itemCount + 1, #self.buttons do
            self.buttons[index]:SetItem(nil)
        end

        local maxScroll = math.max(0, contentHeight - self.scrollFrame:GetHeight())
        self.scrollFrame.maxScroll = maxScroll
        if self.scrollFrame:GetVerticalScroll() > maxScroll then
            self.scrollFrame:SetVerticalScroll(maxScroll)
        end
    end

    function grid:SetItems(items)
        self.items = items or {}
        self.scrollFrame:SetVerticalScroll(0)
        self:Refresh()
    end

    function grid:GetItemCount()
        return #self.items
    end

    scrollFrame:SetScript("OnMouseWheel", function(selfFrame, delta)
        local maxScroll = selfFrame.maxScroll or 0
        if maxScroll <= 0 then
            return
        end

        local nextScroll = selfFrame:GetVerticalScroll() - (delta * grid.scrollStep)
        if nextScroll < 0 then
            nextScroll = 0
        elseif nextScroll > maxScroll then
            nextScroll = maxScroll
        end

        selfFrame:SetVerticalScroll(nextScroll)
    end)

    frame:SetScript("OnSizeChanged", function()
        grid:Refresh()
    end)

    return grid
end
