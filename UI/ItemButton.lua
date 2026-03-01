local ADDON_NAME, ns = ...

local Constants = ns.Constants

local ItemButton = {}
ns.ItemButton = ItemButton

ItemButton._count = 0

local function setReagentQualityBadge(texture, reagentQuality)
    if not texture or type(reagentQuality) ~= "number" then
        return false
    end

    local tier = math.floor(reagentQuality)
    if tier <= 0 then
        return false
    end

    if not texture.SetAtlas then
        return false
    end

    local atlasName = string.format("Professions-Icon-Quality-Tier%d-Inv", tier)
    if _G.C_Texture and _G.C_Texture.GetAtlasInfo and not _G.C_Texture.GetAtlasInfo(atlasName) then
        return false
    end

    local useAtlasSize = true
    if _G.TextureKitConstants and _G.TextureKitConstants.UseAtlasSize ~= nil then
        useAtlasSize = _G.TextureKitConstants.UseAtlasSize
    end

    texture:SetAtlas(atlasName, useAtlasSize)
    return true
end

local function onClick(self, mouseButton)
    local record = self.record
    if not record then return end

    if mouseButton == "LeftButton" and _G.IsModifiedClick and _G.IsModifiedClick("SPLITSTACK") then
        local stackCount = record.stackCount or 0
        if stackCount > 1 then
            if _G.OpenStackSplitFrame then
                _G.OpenStackSplitFrame(stackCount, self, "BOTTOMRIGHT", "TOPRIGHT")
                return
            elseif _G.StackSplitFrame and _G.StackSplitFrame.OpenStackSplitFrame then
                _G.StackSplitFrame:OpenStackSplitFrame(stackCount, self, "BOTTOMRIGHT", "TOPRIGHT")
                return
            end
        end
    end

    local link = record.link or (record.itemID and "item:" .. tostring(record.itemID))
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

local function onDragStart(self)
    local record = self.record
    if not record then return end
    if _G.C_Container and _G.C_Container.PickupContainerItem then
        _G.C_Container.PickupContainerItem(record.bagID, record.slotID)
    end
end

local function onReceiveDrag(self)
    local record = self.record
    if not record then return end
    if _G.C_Container and _G.C_Container.PickupContainerItem then
        _G.C_Container.PickupContainerItem(record.bagID, record.slotID)
    end
end

local function onEnter(self)
    local record = self.record
    if not record then return end
    if _G.GameTooltip and _G.GameTooltip.SetBagItem then
        _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        _G.GameTooltip:SetBagItem(record.bagID, record.slotID)
        _G.GameTooltip:Show()
    end
end

local function onLeave(self)
    if _G.GameTooltip and _G.GameTooltip:GetOwner() == self then
        _G.GameTooltip:Hide()
    end
end

function ItemButton.Create(parent)
    ItemButton._count = ItemButton._count + 1
    local button = CreateFrame(
        "ItemButton",
        "BaggyItemButton" .. tostring(ItemButton._count),
        parent
    )
    button:SetSize(Constants.ITEM_BUTTON_SIZE, Constants.ITEM_BUTTON_SIZE)

    if not button.IconBorder then
        button.IconBorder = button:CreateTexture(nil, "OVERLAY")
        button.IconBorder:SetAllPoints(button)
        button.IconBorder:SetTexture("Interface/Common/WhiteIconFrame")
        button.IconBorder:Hide()
    end

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnClick", onClick)
    button:SetScript("OnDragStart", onDragStart)
    button:SetScript("OnReceiveDrag", onReceiveDrag)
    button:SetScript("OnEnter", onEnter)
    button:SetScript("OnLeave", onLeave)

    -- Reagent quality badge is not part of the standard template
    button.reagentQualityBadge = button:CreateTexture(nil, "OVERLAY", nil, 7)
    button.reagentQualityBadge:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    button.reagentQualityBadge:Hide()

    function button:SplitStack(splitAmount)
        local record = self.record
        if not record then return end
        if _G.C_Container and _G.C_Container.SplitContainerItem then
            _G.C_Container.SplitContainerItem(record.bagID, record.slotID, splitAmount)
        end
    end

    function button:GetBagID()
        return self.record and self.record.bagID
    end

    function button:SetItem(record)
        self.record = record
        if not record then
            self.bagID = nil
            self:SetID(0)
            SetItemButtonTexture(self, nil)
            SetItemButtonCount(self, 0)
            if self.IconBorder then self.IconBorder:Hide() end
            self.reagentQualityBadge:Hide()
            self:Hide()
            return
        end

        self.bagID = record.bagID
        self:SetID(record.slotID)

        SetItemButtonTexture(self, record.icon or 134400)
        SetItemButtonCount(self, record.stackCount or 0)
        SetItemButtonDesaturated(self, record.isLocked)

        local quality = record.quality or 0
        local qualityColor = _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[quality]
        if qualityColor and self.IconBorder then
            self.IconBorder:SetVertexColor(qualityColor.r, qualityColor.g, qualityColor.b)
            self.IconBorder:Show()
        elseif self.IconBorder then
            self.IconBorder:Hide()
        end

        if setReagentQualityBadge(self.reagentQualityBadge, record.reagentQuality) then
            self.reagentQualityBadge:Show()
        else
            self.reagentQualityBadge:Hide()
        end

        self:Show()
    end

    return button
end
