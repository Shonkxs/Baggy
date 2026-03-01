local ADDON_NAME, ns = ...

local Constants = ns.Constants

local ItemButton = {}
ns.ItemButton = ItemButton

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

local function hideUnsupportedOverlays(button)
    local overlayKeys = {
        "NewItemTexture",
        "BattlepayItemTexture",
        "BagIndicator",
        "JunkIcon",
        "UpgradeIcon",
        "QuestBadge",
        "IconQuestTexture",
        "ExtendedSlot",
        "flash",
    }

    for _, key in ipairs(overlayKeys) do
        local region = button[key]
        if region and region.Hide then
            region:Hide()
        end
    end
end

function ItemButton.Create(parent)
    local button = CreateFrame("ItemButton", nil, parent, "ContainerFrameItemButtonTemplate")
    button:SetSize(Constants.ITEM_BUTTON_SIZE, Constants.ITEM_BUTTON_SIZE)

    button.icon = button.icon or button.IconTexture or button.Icon
    if button.icon then
        button.icon:ClearAllPoints()
        button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end

    button.lockOverlay = button:CreateTexture(nil, "OVERLAY")
    button.lockOverlay:SetAllPoints(button.icon or button)
    button.lockOverlay:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    button.lockOverlay:Hide()

    button.reagentQualityBadge = button:CreateTexture(nil, "OVERLAY", nil, 7)
    button.reagentQualityBadge:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    button.reagentQualityBadge:Hide()

    hideUnsupportedOverlays(button)

    function button:SetItem(record)
        self.record = record
        if not record then
            if self.SetBagID then self:SetBagID(nil) end
            self:SetID(0)
            if self.icon then self.icon:SetTexture(nil) end
            SetItemButtonCount(self, 0)
            self.lockOverlay:Hide()
            self.reagentQualityBadge:Hide()
            if self.IconBorder then self.IconBorder:Hide() end
            self:Hide()
            return
        end

        if self.SetBagID then self:SetBagID(record.bagID) end
        self:SetID(record.slotID or 0)

        if self.icon then
            self.icon:SetTexture(record.icon or 134400)
        end

        SetItemButtonCount(self, record.stackCount or 0)

        if record.isLocked then
            self.lockOverlay:Show()
        else
            self.lockOverlay:Hide()
        end

        if setReagentQualityBadge(self.reagentQualityBadge, record.reagentQuality) then
            self.reagentQualityBadge:Show()
        else
            self.reagentQualityBadge:Hide()
        end

        local quality = record.quality or 0
        local qualityColor = _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[quality]
        if qualityColor and self.IconBorder then
            self.IconBorder:SetVertexColor(qualityColor.r, qualityColor.g, qualityColor.b)
            self.IconBorder:Show()
        elseif self.IconBorder then
            self.IconBorder:Hide()
        end

        hideUnsupportedOverlays(self)
        self:Show()
    end

    return button
end
