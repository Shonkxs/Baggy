local ADDON_NAME, ns = ...

local Constants = ns.Constants
local Theme = ns.Theme

local BankToggle = {}
ns.BankToggle = BankToggle

function BankToggle.Create(parent, onClick)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(128, 24)
    button:SetBackdrop(Theme.insetBackdrop)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.text:SetPoint("CENTER")
    button.mode = Constants.MODES.INVENTORY
    button.bankAvailable = false

    button:SetScript("OnClick", function(selfButton)
        if not selfButton.bankAvailable then
            return
        end

        if onClick then
            local nextMode = Constants.MODES.BANK
            if selfButton.mode == Constants.MODES.BANK then
                nextMode = Constants.MODES.INVENTORY
            end
            onClick(nextMode)
        end
    end)

    function button:SetState(mode, bankAvailable)
        self.mode = mode
        self.bankAvailable = bankAvailable and true or false

        if not self.bankAvailable then
            self:Disable()
            self.text:SetText("Bank Closed")
        elseif self.mode == Constants.MODES.BANK then
            self:Enable()
            self.text:SetText("Inventory Mode")
        else
            self:Enable()
            self.text:SetText("Bank Mode")
        end

        Theme.StyleUtilityButton(self, self:IsEnabled())
    end

    button:SetState(Constants.MODES.INVENTORY, false)
    return button
end
