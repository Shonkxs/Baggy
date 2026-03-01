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

function ItemButton.Create(parent)
    ItemButton._count = ItemButton._count + 1
    local button = CreateFrame(
        "ItemButton",
        "BaggyItemButton" .. tostring(ItemButton._count),
        parent,
        "ContainerFrameItemButtonTemplate"
    )
    button:SetSize(Constants.ITEM_BUTTON_SIZE, Constants.ITEM_BUTTON_SIZE)

    -- Reagent quality badge is not part of the standard template
    button.reagentQualityBadge = button:CreateTexture(nil, "OVERLAY", nil, 7)
    button.reagentQualityBadge:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    button.reagentQualityBadge:Hide()

    function button:SplitStack(splitAmount)
        if not self.bagID then return end
        local slotID = self:GetID()
        if not slotID or slotID == 0 then return end
        if _G.C_Container and _G.C_Container.SplitContainerItem then
            _G.C_Container.SplitContainerItem(self.bagID, slotID, splitAmount)
        end
    end

    function button:GetBagID()
        return self.bagID
    end

    function button:SetItem(record)
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
