local ADDON_NAME, ns = ...

local Constants = ns.Constants
local Theme = ns.Theme

local ItemButton = {}
ns.ItemButton = ItemButton

local function getRecordLink(record)
    if record.link then
        return record.link
    end

    if record.itemID then
        return "item:" .. tostring(record.itemID)
    end

    return nil
end

local function openStackSplit(button)
    local record = button.record
    if not record or (record.stackCount or 0) <= 1 then
        return false
    end

    if _G.OpenStackSplitFrame then
        _G.OpenStackSplitFrame(record.stackCount, button, "BOTTOMRIGHT", "TOPRIGHT")
        return true
    end

    if _G.StackSplitFrame and _G.StackSplitFrame.OpenStackSplitFrame then
        _G.StackSplitFrame:OpenStackSplitFrame(record.stackCount, button, "BOTTOMRIGHT", "TOPRIGHT")
        return true
    end

    return false
end

local function onClick(selfButton, mouseButton)
    local record = selfButton.record
    if not record then
        return
    end

    if mouseButton == "LeftButton" and _G.IsModifiedClick and _G.IsModifiedClick("SPLITSTACK") then
        if openStackSplit(selfButton) then
            return
        end
    end

    local link = getRecordLink(record)
    if link and _G.HandleModifiedItemClick and _G.HandleModifiedItemClick(link) then
        return
    end

    if not (_G.C_Container and _G.C_Container.PickupContainerItem and _G.C_Container.UseContainerItem) then
        return
    end

    if mouseButton == "RightButton" then
        _G.C_Container.UseContainerItem(record.bagID, record.slotID)
    else
        _G.C_Container.PickupContainerItem(record.bagID, record.slotID)
    end
end

local function onDragStart(selfButton)
    local record = selfButton.record
    if not record then
        return
    end

    if _G.C_Container and _G.C_Container.PickupContainerItem then
        _G.C_Container.PickupContainerItem(record.bagID, record.slotID)
    end
end

local function onReceiveDrag(selfButton)
    local record = selfButton.record
    if not record then
        return
    end

    if _G.C_Container and _G.C_Container.PickupContainerItem then
        _G.C_Container.PickupContainerItem(record.bagID, record.slotID)
    end
end

local function onEnter(selfButton)
    local record = selfButton.record
    if not record then
        return
    end

    if _G.GameTooltip and _G.GameTooltip.SetBagItem then
        _G.GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        _G.GameTooltip:SetBagItem(record.bagID, record.slotID)
        _G.GameTooltip:Show()
    end
end

local function onLeave(selfButton)
    if _G.GameTooltip and _G.GameTooltip:GetOwner() == selfButton then
        _G.GameTooltip:Hide()
    end
end

function ItemButton.Create(parent)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(Constants.ITEM_BUTTON_SIZE, Constants.ITEM_BUTTON_SIZE)
    button:SetBackdrop(Theme.insetBackdrop)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnClick", onClick)
    button:SetScript("OnDragStart", onDragStart)
    button:SetScript("OnReceiveDrag", onReceiveDrag)
    button:SetScript("OnEnter", onEnter)
    button:SetScript("OnLeave", onLeave)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    button.countText = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.countText:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)

    button.lockOverlay = button:CreateTexture(nil, "OVERLAY")
    button.lockOverlay:SetAllPoints(button.icon)
    button.lockOverlay:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    button.lockOverlay:Hide()

    function button:SplitStack(splitAmount)
        local record = self.record
        if not record then
            return
        end

        if _G.C_Container and _G.C_Container.SplitContainerItem then
            _G.C_Container.SplitContainerItem(record.bagID, record.slotID, splitAmount)
        end
    end

    function button:GetBagID()
        if self.record then
            return self.record.bagID
        end
        return nil
    end

    function button:GetID()
        if self.record then
            return self.record.slotID
        end
        return nil
    end

    function button:SetItem(record)
        self.record = record
        if not record then
            self.icon:SetTexture(nil)
            self.countText:SetText("")
            self.lockOverlay:Hide()
            self:Hide()
            return
        end

        self.icon:SetTexture(record.icon or 134400)

        if (record.stackCount or 1) > 1 then
            self.countText:SetText(record.stackCount)
        else
            self.countText:SetText("")
        end

        if record.isLocked then
            self.lockOverlay:Show()
        else
            self.lockOverlay:Hide()
        end

        local quality = record.quality or 0
        local qualityColor = _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[quality]
        if qualityColor then
            self:SetBackdropBorderColor(qualityColor.r, qualityColor.g, qualityColor.b, 0.95)
        else
            self:SetBackdropBorderColor(unpack(Theme.palette.insetBorder))
        end

        self:Show()
    end

    return button
end
