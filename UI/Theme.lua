local ADDON_NAME, ns = ...

local Theme = {}
ns.Theme = Theme

Theme.palette = {
    panelBg = { 0.07, 0.08, 0.10, 0.93 },
    panelBorder = { 0.35, 0.40, 0.50, 0.85 },
    insetBg = { 0.03, 0.04, 0.05, 0.90 },
    insetBorder = { 0.20, 0.24, 0.32, 0.80 },
    tabBg = { 0.13, 0.15, 0.19, 0.90 },
    tabBgDisabled = { 0.07, 0.08, 0.10, 0.85 },
    tabBgActive = { 0.18, 0.32, 0.50, 0.95 },
    tabBorder = { 0.28, 0.33, 0.43, 0.85 },
    tabBorderActive = { 0.42, 0.67, 1.00, 0.95 },
    textNormal = { 0.92, 0.94, 1.00, 1.00 },
    textMuted = { 0.55, 0.60, 0.68, 1.00 },
}

Theme.panelBackdrop = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

Theme.insetBackdrop = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local function applyBackdrop(frame, backdrop, bgColor, borderColor)
    if not frame.SetBackdrop then
        return
    end

    frame:SetBackdrop(backdrop)
    frame:SetBackdropColor(unpack(bgColor))
    frame:SetBackdropBorderColor(unpack(borderColor))
end

function Theme.ApplyPanel(frame)
    applyBackdrop(frame, Theme.panelBackdrop, Theme.palette.panelBg, Theme.palette.panelBorder)
end

function Theme.ApplyInset(frame)
    applyBackdrop(frame, Theme.insetBackdrop, Theme.palette.insetBg, Theme.palette.insetBorder)
end

function Theme.StyleTabButton(button, isActive, isEnabled)
    if isActive then
        button:SetBackdropColor(unpack(Theme.palette.tabBgActive))
        button:SetBackdropBorderColor(unpack(Theme.palette.tabBorderActive))
        button.text:SetTextColor(unpack(Theme.palette.textNormal))
        return
    end

    if isEnabled then
        button:SetBackdropColor(unpack(Theme.palette.tabBg))
        button:SetBackdropBorderColor(unpack(Theme.palette.tabBorder))
        button.text:SetTextColor(unpack(Theme.palette.textNormal))
    else
        button:SetBackdropColor(unpack(Theme.palette.tabBgDisabled))
        button:SetBackdropBorderColor(unpack(Theme.palette.tabBorder))
        button.text:SetTextColor(unpack(Theme.palette.textMuted))
    end
end

function Theme.StyleUtilityButton(button, isEnabled)
    if isEnabled then
        button:SetBackdropColor(0.10, 0.23, 0.36, 0.92)
        button:SetBackdropBorderColor(0.42, 0.67, 1.00, 0.95)
        button.text:SetTextColor(unpack(Theme.palette.textNormal))
    else
        button:SetBackdropColor(unpack(Theme.palette.tabBgDisabled))
        button:SetBackdropBorderColor(unpack(Theme.palette.tabBorder))
        button.text:SetTextColor(unpack(Theme.palette.textMuted))
    end
end

function Theme.StyleSearchBox(editBox)
    applyBackdrop(editBox, Theme.insetBackdrop, { 0.04, 0.05, 0.07, 0.95 }, Theme.palette.tabBorder)
    editBox:SetTextColor(unpack(Theme.palette.textNormal))
end
