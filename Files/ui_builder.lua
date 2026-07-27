---@diagnostic disable: return-type-mismatch, undefined-field, param-type-mismatch

--- Addon name, namespace
local addonName, addonTable = ...

--- AceAddon local variable
local aceAddon = addonTable.aceAddon

--- Locale local variable
local L = addonTable.L

--- Addon title
local ADDON_TITLE = addonTable.ADDON_TITLE

--- Bundled cyrillic font
local FONT_PATH = "Interface\\AddOns\\" .. addonName .. "\\Fonts\\FrizQuadrataCTT.ttf"

--- Settings table
local settings = {
    mainFrame = {
        size = {
            width = 470,
            height = 300,
        },
    },

    defaultButtons = {
        size = {
            width = 50,
            height = 25,
        },
    },
}

--- Creates the addon font objects
function addonTable:CreateFonts()
    local function createFont(name, size)
        local font = CreateFont(name)
        font:SetFont(FONT_PATH, size, "")
        font:SetTextColor(1, 0.82, 0)
        font:SetShadowColor(0, 0, 0, 1)
        font:SetShadowOffset(1, -1)
        return font
    end

    self.fontLarge = createFont("WTSAutoFloodFontLarge", 16)
    self.fontNormal = createFont("WTSAutoFloodFontNormal", 12)
    self.fontSmall = createFont("WTSAutoFloodFontSmall", 11)
end

--- @return Frame mainFrame, Frame mainFrameInset
function addonTable:CreateMainFrame()
    local mainFrame = CreateFrame("Frame", "WTSAutoFloodMainFrame", UIParent, "BackdropTemplate")

    local width = settings.mainFrame.size.width
    local height = settings.mainFrame.size.height

    mainFrame:SetSize(width, height)

    mainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 11, top = 11, bottom = 11 },
    })

    --- Setup title text
    local title = mainFrame:CreateFontString("WTSAutoFloodMainFrameTitle", "ARTWORK")
    title:SetFontObject(addonTable.fontLarge)
    title:SetPoint("TOP", mainFrame, "TOP", 0, -14)
    title:SetText("|cff66bbff" .. ADDON_TITLE .. "|r")

    --- Setup close button
    local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -4, -4)
    closeButton:SetScript("OnClick", function()
        addonTable:HideUI()
    end)

    --- Setup inset
    local mainFrameInset = CreateFrame("Frame", "WTSAutoFloodMainFrameInset", mainFrame, "BackdropTemplate")
    mainFrameInset:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 14, -70)
    mainFrameInset:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -25, 96)
    mainFrameInset:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    mainFrameInset:SetBackdropColor(0, 0, 0, 0.8)
    mainFrameInset:SetBackdropBorderColor(0, 0, 0, 1)
    mainFrameInset:EnableMouse(true)
    mainFrameInset:SetScript("OnMouseDown", function()
        addonTable:FocusEditBox()
    end)

    if aceAddon.db.profile.position.x and aceAddon.db.profile.position.y then
        mainFrame:SetPoint("CENTER", UIParent, "CENTER", aceAddon.db.profile.position.x, aceAddon.db.profile.position.y)
    else
        mainFrame:SetPoint("CENTER", UIParent)
    end

    mainFrame:SetToplevel(true)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:Hide()

    mainFrame:SetScript("OnMouseDown", function(this, button)
        if button == "LeftButton" then
            this:StartMoving()
        end
    end)

    mainFrame:SetScript("OnMouseUp", function(this, button)
        if button == "LeftButton" then
            this:StopMovingOrSizing()
            local x, y = this:GetCenter()
            local px, py = this:GetParent():GetCenter()
            local cx, cy = x-px, y-py
            aceAddon.db.profile.position.x = cx
            aceAddon.db.profile.position.y = cy
        end
    end)

    mainFrame:SetScript("OnShow", function(this)
        this:SetMovable(true)
    end)

    mainFrame:SetScript("OnHide", function(this)
        this:SetMovable(false)
    end)

    return mainFrame, mainFrameInset
end

--- @param parentFrame Frame
--- @param boundingFrame Frame
--- @return ScrollFrame scrollFrame
function addonTable:CreateScrollFrame(parentFrame, boundingFrame)
    local scrollFrame = CreateFrame("ScrollFrame", "WTSAutoFloodScrollFrame", parentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", boundingFrame, 5, -5)
    scrollFrame:SetPoint("BOTTOMLEFT", boundingFrame, 5, 5)
    scrollFrame:SetPoint("RIGHT", parentFrame)

    local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -22, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -22, 16)
    scrollBar.Bg = scrollBar:CreateTexture("WTSAutoFloodScrollFrameBg", "BACKGROUND")
    scrollBar.Bg:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble")
    scrollBar.Bg:SetHorizTile(true)
    scrollBar.Bg:SetVertTile(true)
    scrollBar.Bg:SetAllPoints(scrollBar)

    return scrollFrame
end

--- @param scrollFrame ScrollFrame
--- @param boundingFrame Frame
--- @return EditBox editBox
function addonTable:CreateEditBox(scrollFrame, boundingFrame)
    local editBox = CreateFrame("EditBox", "WTSAutoFloodEditBox", scrollFrame)
    editBox:SetSize(boundingFrame:GetWidth(), boundingFrame:GetHeight())

    editBox:SetMultiLine(true)
    editBox:SetHyperlinksEnabled(true)
    editBox:SetFontObject(addonTable.fontNormal)
    editBox:SetTextColor(1, 1, 1, 1)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(255)
    editBox:SetAltArrowKeyMode(false)

    editBox:SetScript("OnTextChanged", function(this)
        aceAddon.db.profile.trade_text = this:GetText()
    end)

    editBox:SetScript("OnEditFocusGained", function()
        addonTable:OnFocusGained()
    end)

    editBox:SetScript("OnEditFocusLost", function()
        addonTable:OnFocusLost()
    end)

    editBox:SetScript("OnEscapePressed", function()
        addonTable:HideUI()
    end)

    editBox:SetScript("OnHyperlinkEnter", function(this, link)
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)

    editBox:SetScript("OnHyperlinkLeave", function()
        GameTooltip:Hide()
    end)

    editBox:SetScript("OnHyperlinkClick", function(_, link, text, button)
        SetItemRef(link, text, button)
    end)

    scrollFrame:SetScrollChild(editBox)

    return editBox
end

--- @param parentFrame Frame
--- @param boundingFrame Frame
--- @return Frame buttonsFrame
function addonTable:CreateButtons(parentFrame, boundingFrame)
    local hButtonsFrame = CreateFrame("Frame", "WTSAutoFloodHButtonsFrame", parentFrame)
    hButtonsFrame:SetPoint("BOTTOMLEFT", parentFrame, 14, 10)
    hButtonsFrame:SetPoint("BOTTOMRIGHT", parentFrame, -14, 10)
    hButtonsFrame:SetHeight(settings.defaultButtons.size.height)

    local testButton = self:CreateTestButton(hButtonsFrame)
    local advertiseButton = self:CreateAdvertiseButton(hButtonsFrame, testButton)
    local toggleButton = self:CreateToggleButton(hButtonsFrame, advertiseButton)
    self.toggleButton = toggleButton

    return hButtonsFrame
end

--- @param parentFrame Frame
--- @return Button testButton
function addonTable:CreateTestButton(parentFrame)
    local testButton = CreateFrame("Button", "WTSAutoFloodTestButton", parentFrame, "UIPanelButtonTemplate")
    testButton:SetNormalFontObject(addonTable.fontNormal)
    testButton:SetText(tostring(L["TEST_BUTTON"]))
    testButton:SetSize(settings.defaultButtons.size.width, settings.defaultButtons.size.height)
    testButton:SetPoint("RIGHT", parentFrame, -5, 0)
    testButton:SetPoint("CENTER", parentFrame)

    testButton:SetScript("OnClick", function()
        addonTable:PrintMessage()
    end)

    testButton:SetScript("OnEnter", function(this)
        if not aceAddon.db.profile.hide_tooltips then
            GameTooltip:SetOwner(this or UIParent, "ANCHOR_BOTTOM")
            GameTooltip:SetText(L["SHOW_YOUR_MESSAGE"], 1, 1, 1, 1)
            GameTooltip:Show()
        end
    end)

    testButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return testButton
end

--- @param parentFrame Frame
--- @param relativeFrame Frame
--- @return Button advertiseButton
function addonTable:CreateAdvertiseButton(parentFrame, relativeFrame)
    local advertiseButton = CreateFrame("Button", "WTSAutoFloodAdvertiseButton", parentFrame, "UIPanelButtonTemplate")
    advertiseButton:SetNormalFontObject(addonTable.fontNormal)
    advertiseButton:SetText(tostring(L["ADVERTISE_BUTTON"]))
    advertiseButton:SetSize(settings.defaultButtons.size.width + 35, settings.defaultButtons.size.height)
    advertiseButton:SetPoint("TOPRIGHT", relativeFrame, "TOPLEFT", -5, 0)

    advertiseButton:SetScript("OnEnter", function(this)
        if not aceAddon.db.profile.hide_tooltips then
            GameTooltip:SetOwner(this or UIParent, "ANCHOR_BOTTOM")
            GameTooltip:SetText(tostring(L["SEND_YOUR_MESSAGE"]), 1, 1, 1, 1)
            GameTooltip:Show()
        end
    end)

    advertiseButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    advertiseButton:SetScript("OnClick", function(this)
        addonTable:SendMessage()
    end)

    return advertiseButton
end

--- @param parentFrame Frame
--- @param relativeFrame Frame
--- @return Button toggleButton
function addonTable:CreateToggleButton(parentFrame, relativeFrame)
    local toggleButton = CreateFrame("Button", "WTSAutoFloodToggleButton", parentFrame, "UIPanelButtonTemplate")
    local toggleText = aceAddon.db.profile.is_on and L["TURN_OFF"] or L["TURN_ON"]
    toggleButton:SetNormalFontObject(addonTable.fontNormal)
    toggleButton:SetText(tostring(toggleText))
    toggleButton:SetSize(settings.defaultButtons.size.width + 25, settings.defaultButtons.size.height)
    toggleButton:SetPoint("TOPRIGHT", relativeFrame, "TOPLEFT", -5, 0)

    toggleButton:SetScript("OnClick", function(this)
        addonTable:ToggleMessage(this)
    end)

    return toggleButton
end

--- Row of saved advert texts: picker plus save and delete
--- @param parentFrame Frame
function addonTable:CreatePresetBar(parentFrame)
    local frame = CreateFrame("Frame", "WTSAutoFloodPresetFrame", parentFrame)
    frame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 14, -36)
    frame:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -14, -36)
    frame:SetHeight(28)

    local label = frame:CreateFontString("WTSAutoFloodPresetLabel", "ARTWORK")
    label:SetFontObject(addonTable.fontSmall)
    label:SetPoint("LEFT", frame, 2, 0)
    label:SetText(tostring(L["PRESET_LABEL"]))

    local deleteButton = CreateFrame("Button", "WTSAutoFloodPresetDeleteButton", frame, "UIPanelButtonTemplate")
    deleteButton:SetNormalFontObject(addonTable.fontSmall)
    deleteButton:SetText(tostring(L["PRESET_DELETE"]))
    deleteButton:SetSize(70, 22)
    deleteButton:SetPoint("RIGHT", frame, 0, 0)

    local saveButton = CreateFrame("Button", "WTSAutoFloodPresetSaveButton", frame, "UIPanelButtonTemplate")
    saveButton:SetNormalFontObject(addonTable.fontSmall)
    saveButton:SetText(tostring(L["PRESET_SAVE"]))
    saveButton:SetSize(80, 22)
    saveButton:SetPoint("RIGHT", deleteButton, "LEFT", -4, 0)

    local dropDown = CreateFrame("Frame", "WTSAutoFloodPresetDropdown", frame, "UIDropDownMenuTemplate")
    dropDown:SetPoint("LEFT", label, "RIGHT", -10, -2)
    UIDropDownMenu_SetWidth(dropDown, 180)
    UIDropDownMenu_JustifyText(dropDown, "LEFT")
    _G[dropDown:GetName() .. "Text"]:SetFontObject(addonTable.fontSmall)

    self.presetDropdown = dropDown

    UIDropDownMenu_Initialize(dropDown, function(_, level)
        local presets = addonTable:GetPresets()
        local info = UIDropDownMenu_CreateInfo()

        if #presets == 0 then
            info.text = L["PRESET_EMPTY"]
            info.disabled = true
            info.notCheckable = true
            info.fontObject = addonTable.fontSmall
            UIDropDownMenu_AddButton(info, level)
            return
        end

        for i = 1, #presets do
            info.text = presets[i].name
            info.value = presets[i].name
            info.disabled = nil
            info.notCheckable = nil
            info.fontObject = addonTable.fontSmall
            info.func = function(self)
                addonTable:ApplyPreset(self.value)
                UIDropDownMenu_SetText(dropDown, self.value)
                CloseDropDownMenus()
            end
            info.checked = false
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetText(dropDown, L["PRESET_EMPTY"])

    saveButton:SetScript("OnClick", function()
        addonTable:PromptSavePreset()
    end)

    saveButton:SetScript("OnEnter", function(this)
        if not aceAddon.db.profile.hide_tooltips then
            GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
            GameTooltip:SetText(tostring(L["PRESET_SAVE_TIP"]), 1, 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    saveButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    deleteButton:SetScript("OnClick", function()
        local name = UIDropDownMenu_GetText(dropDown)
        if name and addonTable:DeletePreset(name) then
            local text = tostring(L["PRESET_DELETED"])
            print(string.gsub(text, "#NAME#", name))
            UIDropDownMenu_SetText(dropDown, L["PRESET_EMPTY"])
        end
    end)

    deleteButton:SetScript("OnEnter", function(this)
        if not aceAddon.db.profile.hide_tooltips then
            GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
            GameTooltip:SetText(tostring(L["PRESET_DELETE_TIP"]), 1, 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    deleteButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return frame
end

--- Asks for a preset name, then stores the current text under it
function addonTable:PromptSavePreset()
    local text = aceAddon.db.profile.trade_text
    if not text or text == "" then
        return
    end

    StaticPopupDialogs["WTSAUTOFLOOD_SAVE_PRESET"] = {
        text = tostring(L["PRESET_NAME_PROMPT"]),
        button1 = ACCEPT or "OK",
        button2 = CANCEL or "Cancel",
        hasEditBox = true,
        maxLetters = 32,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        OnAccept = function(popup)
            local editBoxWidget = popup.editBox or _G[popup:GetName() .. "EditBox"]
            local name = editBoxWidget and editBoxWidget:GetText()
            if addonTable:SavePreset(name, aceAddon.db.profile.trade_text) then
                local message = tostring(L["PRESET_SAVED"])
                print(string.gsub(message, "#NAME#", name))
                if addonTable.presetDropdown then
                    UIDropDownMenu_SetText(addonTable.presetDropdown, name)
                end
            end
        end,
    }

    StaticPopup_Show("WTSAUTOFLOOD_SAVE_PRESET")
end

--- Chat picker plus the send key, sits right above the buttons
--- @param parentFrame Frame
--- @param relativeFrame Frame
function addonTable:CreateSendControls(parentFrame, relativeFrame)
    local chatFrame = self:CreateChatTypeDropdown(parentFrame, "SEND_TO", 170)
    chatFrame:SetPoint("BOTTOMLEFT", relativeFrame, "TOPLEFT", 2, 6)

    local keyFrame = CreateFrame("Frame", "WTSAutoFloodKeyFrame", parentFrame)
    keyFrame:SetPoint("BOTTOMRIGHT", relativeFrame, "TOPRIGHT", 0, 6)
    keyFrame:SetSize(150, 44)

    local label = keyFrame:CreateFontString("WTSAutoFloodKeyLabel", "ARTWORK")
    label:SetFontObject(addonTable.fontSmall)
    label:SetPoint("TOPLEFT", keyFrame)
    label:SetText(tostring(L["KEY_LABEL"]))
    label:SetJustifyH("LEFT")

    local keyButton = CreateFrame("Button", "WTSAutoFloodKeyButton", keyFrame, "UIPanelButtonTemplate")
    keyButton:SetNormalFontObject(addonTable.fontSmall)
    keyButton:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
    keyButton:SetSize(150, 22)

    self.keyButton = keyButton
    keyButton.isListening = false

    keyButton:EnableKeyboard(false)
    keyButton:SetScript("OnKeyDown", function(this, key)
        addonTable:HandleKeyCapture(this, key)
    end)

    keyButton:SetScript("OnClick", function(this)
        --- Otherwise the key press would be typed into the message instead
        local messageBox = _G["WTSAutoFloodEditBox"]
        if messageBox then
            messageBox:ClearFocus()
        end

        this.isListening = true
        this:EnableKeyboard(true)
        this:SetPropagateKeyboardInput(false)
        this:SetText(tostring(L["KEY_PRESS_NOW"]))
    end)

    keyButton:SetScript("OnEnter", function(this)
        if not aceAddon.db.profile.hide_tooltips then
            GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
            GameTooltip:SetText(tostring(L["KEY_TIP"]), 1, 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    keyButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self:RefreshKeyButton()

    return chatFrame, keyFrame
end

--- Turns a raw key press into a binding
function addonTable:HandleKeyCapture(button, key)
    if not button.isListening then
        return
    end

    --- Modifiers alone are not a binding
    if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL"
       or key == "LALT" or key == "RALT" or key == "UNKNOWN" then
        return
    end

    button.isListening = false
    button:EnableKeyboard(false)
    button:SetPropagateKeyboardInput(true)

    if key == "ESCAPE" then
        self:RefreshKeyButton()
        return
    end

    if key == "DELETE" or key == "BACKSPACE" then
        self:ClearSendKey()
        print(L["KEY_CLEARED"])
        self:RefreshKeyButton()
        return
    end

    local combo = key
    if IsShiftKeyDown() then combo = "SHIFT-" .. combo end
    if IsControlKeyDown() then combo = "CTRL-" .. combo end
    if IsAltKeyDown() then combo = "ALT-" .. combo end

    if self:SetSendKey(combo) then
        local message = tostring(L["KEY_SET"])
        print(string.gsub(message, "#KEY#", combo))
    end
    self:RefreshKeyButton()
end

--- Shows the currently bound key on the button
function addonTable:RefreshKeyButton()
    if not self.keyButton then
        return
    end
    self.keyButton:SetText(self:GetSendKey() or tostring(L["KEY_NONE"]))
end

--- @return Frame mainFrame, EditBox editBox
function addonTable:CreateUI()
    local mainFrame, mainFrameInset = self:CreateMainFrame()
    local scrollFrame = self:CreateScrollFrame(mainFrame, mainFrameInset)
    local editBox = self:CreateEditBox(scrollFrame, mainFrameInset)
    local buttonsFrame = self:CreateButtons(mainFrame, mainFrameInset)

    self:CreatePresetBar(mainFrame)
    self:CreateSendControls(mainFrame, buttonsFrame)

    return mainFrame, editBox
end
