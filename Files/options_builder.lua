---@diagnostic disable: inject-field, param-type-mismatch

--- Addon name, namespace
local addonName, addonTable = ...

--- AceAddon local variable
local aceAddon = addonTable.aceAddon

--- Locale local variable
local L = addonTable.L

--- Addon title
local ADDON_TITLE = addonTable.ADDON_TITLE

--- @enum Enum.ChatType
local ChatType = {
    Channel = 1,
    Say = 2,
    Yell = 3,
    Party = 4,
    Raid = 5,
    Battleground = 6,
    Guild = 7,
    Officer = 8,
}

--- Available languages
local Languages = {
    { value = "ruRU", key = "LANG_RU" },
    { value = "enUS", key = "LANG_EN" },
}

function addonTable:CreateInterfaceOptions()
    local panel = CreateFrame("Frame")
    panel.name = ADDON_TITLE

    --- The chat type picker lives in the main window, not here
    local title = self:CreateTitle(panel)
    local intervalFrame = self:CreateIntervalSlider(panel, title)
    local autoFocusBoxFrame = self:CreateAutoFocusCheckBox(panel, intervalFrame)
    local hideTooltipsFrame = self:CreateHideTooltipsCheckBox(panel, autoFocusBoxFrame)
    local hideMinimapButtonFrame = self:CreateHideMinimapButtonCheckBox(panel, hideTooltipsFrame)
    self:CreateLanguageDropdown(panel, hideMinimapButtonFrame)

    --- Modern client uses Settings, old client uses InterfaceOptions
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        self.settingsCategory = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    self.optionsPanel = panel
end

function addonTable:CreateTitle(panel)
    local title = panel:CreateFontString("WTSAutoFloodSettingsTitle", "ARTWORK")
    title:SetFontObject(addonTable.fontLarge)
    title:SetPoint("TOPLEFT", 16, -16)

    --- Compatible on both the modern and the old client
    local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local version = GetAddOnMetadata(addonName, "Version")
    if version then
        title:SetText(ADDON_TITLE .. " |cffffff99" .. version .. "|r")
    else
        title:SetText(ADDON_TITLE)
    end

    return title
end

--- Caller anchors the returned frame
--- @param parentFrame Frame
--- @param labelKey string? locale key for the caption
--- @param width number? dropdown width
function addonTable:CreateChatTypeDropdown(parentFrame, labelKey, width)
    local chatTypes = {}
    for key, value in pairs(ChatType) do
        chatTypes[value] = L["CHAT_" .. string.upper(key)]
    end

    local frame = CreateFrame("Frame", "WTSAutoFloodChatTypeDropdownFrame", parentFrame)

    local title = frame:CreateFontString("WTSAutoFloodChatTypeDropdownTitle", "ARTWORK")
    title:SetFontObject(addonTable.fontSmall)
    title:SetPoint("TOPLEFT", frame)
	title:SetText(tostring(L[labelKey or "CHAT_TYPE"]))
    title:SetJustifyH("LEFT")

    local dropDown = CreateFrame("Frame", "WTSAutoFloodChatTypeDropown", frame, "UIDropDownMenuTemplate")
    dropDown:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -18, -5)

    UIDropDownMenu_SetWidth(dropDown, width or 200)
    UIDropDownMenu_JustifyText(dropDown, "LEFT")
    _G[dropDown:GetName() .. "Text"]:SetFontObject(addonTable.fontSmall)

    --- Shows the selected chat type
    local function updateSelectedText(channels)
        local chatType = aceAddon.db.profile.chat_type
        if not chatType then
            UIDropDownMenu_SetText(dropDown, L["SET_CHAT_TYPE"])
            return
        end

        local channelName
        if chatType == ChatType.Channel then
            for _, channel in pairs(channels) do
                if channel.id == aceAddon.db.profile.channel_type then
                    channelName = channel.name
                    break
                end
            end
        end

        if channelName then
            UIDropDownMenu_SetText(dropDown, chatTypes[chatType] .. ": " .. channelName)
        else
            UIDropDownMenu_SetText(dropDown, chatTypes[chatType])
        end
    end

    UIDropDownMenu_Initialize(dropDown, function(_, level, menuList)
        local joinedChannels = addonTable:GetJoinedChannels()
        local info = UIDropDownMenu_CreateInfo()

        if (level or 1) == 1 then

            updateSelectedText(joinedChannels)

            for value, text in ipairs(chatTypes) do
                info.text = text
                info.value = value
                info.fontObject = addonTable.fontSmall
                info.func = function(self)
                    if self.value ~= ChatType.Channel then
                        aceAddon.db.profile.chat_type = self.value
                        aceAddon.db.profile.channel_type = nil
                        UIDropDownMenu_SetText(dropDown, self:GetText())
                    end
                end
                if value == ChatType.Channel then
                    info.menuList = "Channels"
                    info.hasArrow = true
                else
                    info.menuList = nil
                    info.hasArrow = false
                end
                info.checked = value == aceAddon.db.profile.chat_type
                UIDropDownMenu_AddButton(info, level)
            end

        elseif menuList == "Channels" then

            --- Channels inactive right here (Trade works only in cities) stay
            --- listed: the pick is saved and the message is sent later
            for _, channel in pairs(joinedChannels) do
                info.text = channel.name
                info.value = channel.id
                info.fontObject = addonTable.fontSmall
                info.func = function(self)
                    aceAddon.db.profile.chat_type = ChatType.Channel
                    aceAddon.db.profile.channel_type = self.value
                    UIDropDownMenu_SetText(dropDown, chatTypes[ChatType.Channel] .. ": " .. self:GetText())
                    CloseDropDownMenus()
                end
                info.checked = channel.id == aceAddon.db.profile.channel_type
                UIDropDownMenu_AddButton(info, level)
            end

        end
    end)

    --- Loads last selected chat type
    updateSelectedText(self:GetJoinedChannels())

    local width = max(dropDown:GetWidth(), title:GetWidth())
    local height = dropDown:GetHeight() + title:GetHeight()
    frame:SetSize(width, height)

    return frame
end

function addonTable:CreateIntervalSlider(parentFrame, referenceFrame)
    local frame = CreateFrame("Frame", "WTSAutoFloodIntervalSliderFrame", parentFrame)
    frame:SetPoint("TOPLEFT", referenceFrame, "BOTTOMLEFT", 0, -16)

    local title = frame:CreateFontString("WTSAutoFloodIntervalSliderTitle", "ARTWORK")
    title:SetFontObject(addonTable.fontSmall)
    title:SetPoint("TOPLEFT", frame)
	title:SetText(tostring(L["INTERVAL"]))
	title:SetJustifyH("LEFT")
	title:SetWidth(200)

    local sliderValueText = frame:CreateFontString("WTSAutoFloodIntervalSliderText", "ARTWORK")
    sliderValueText:SetFontObject(addonTable.fontSmall)

    local slider = CreateFrame("Slider", "WTSAutoFloodIntervalSlider" , frame, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    slider:SetWidth(200)
	slider:SetMinMaxValues(10, 120)
	slider:SetValueStep(1)
	slider:SetObeyStepOnDrag(true)
	slider:SetOrientation("HORIZONTAL")
	slider:SetValue(aceAddon.db.profile.interval)

    _G[slider:GetName() .. "Low"]:SetText("10s")
	_G[slider:GetName() .. "High"]:SetText("120s")

	slider:SetScript("OnValueChanged", function(_, value)
        aceAddon.db.profile.interval = value
        sliderValueText:SetText(value .. "s")
	end)

    sliderValueText:SetPoint("CENTER", slider, 0, -10)
	sliderValueText:SetText(aceAddon.db.profile.interval .. "s")
	sliderValueText:SetJustifyH("CENTER")
	sliderValueText:SetWidth(100)

    local width = max(slider:GetWidth(), title:GetWidth())
    local height = slider:GetHeight() + title:GetHeight() + sliderValueText:GetHeight()
    frame:SetSize(width, height)

    return frame
end

function addonTable:CreateAutoFocusCheckBox(parentFrame, referenceFrame)
    local frame = CreateFrame("Frame", "WTSAutoFloodAutoFocusFrame", parentFrame)
    frame:SetPoint("TOPLEFT", referenceFrame, "BOTTOMLEFT", 0, -24)

    local checkBox = CreateFrame("CheckButton", "WTSAutoFloodAutoFocusCheckBox", frame, "UICheckButtonTemplate")
    checkBox:SetPoint("TOPLEFT", frame, -5, 5)
    checkBox:SetChecked(aceAddon.db.profile.auto_focus_enabled)
    checkBox:SetScript("OnClick", function()
        aceAddon.db.profile.auto_focus_enabled = not aceAddon.db.profile.auto_focus_enabled
    end)

    local text = frame:CreateFontString("WTSAutoFloodAutoFocusCheckboxText", "ARTWORK")
    text:SetFontObject(addonTable.fontSmall)
    text:SetPoint("LEFT", checkBox, "RIGHT")
	text:SetText(tostring(L["AUTO_FOCUS"]))
    text:SetTextColor(1, 1, 1, 1)
	text:SetJustifyH("LEFT")
	text:SetWidth(200)

    local width = max(checkBox:GetWidth(), text:GetWidth())
    local height = checkBox:GetHeight() - 11
    frame:SetSize(width, height)

    return frame
end

function addonTable:CreateHideTooltipsCheckBox(parentFrame, referenceFrame)
    local frame = CreateFrame("Frame", "WTSAutoFloodHideTooltipsFrame", parentFrame)
    frame:SetPoint("TOPLEFT", referenceFrame, "BOTTOMLEFT", 0, -16)

    local checkBox = CreateFrame("CheckButton", "WTSAutoFloodHideTooltipsCheckBox", frame, "UICheckButtonTemplate")
    checkBox:SetPoint("TOPLEFT", frame, -5, 5)
    checkBox:SetChecked(aceAddon.db.profile.hide_tooltips)
    checkBox:SetScript("OnClick", function()
        aceAddon.db.profile.hide_tooltips = not aceAddon.db.profile.hide_tooltips
    end)

    local text = frame:CreateFontString("WTSAutoFloodHideTooltipsCheckboxText", "ARTWORK")
    text:SetFontObject(addonTable.fontSmall)
    text:SetPoint("LEFT", checkBox, "RIGHT")
	text:SetText(tostring(L["HIDE_TOOLTIPS"]))
    text:SetTextColor(1, 1, 1, 1)
	text:SetJustifyH("LEFT")
	text:SetWidth(200)

    local width = max(checkBox:GetWidth(), text:GetWidth())
    local height = checkBox:GetHeight() - 11
    frame:SetSize(width, height)

    return frame
end

function addonTable:CreateHideMinimapButtonCheckBox(parentFrame, referenceFrame)
    local frame = CreateFrame("Frame", "WTSAutoFloodHideMinimapButtonFrame", parentFrame)
    frame:SetPoint("TOPLEFT", referenceFrame, "BOTTOMLEFT", 0, -16)

    local checkBox = CreateFrame("CheckButton", "WTSAutoFloodHideMinimapButtonCheckBox", frame, "UICheckButtonTemplate")
    checkBox:SetPoint("TOPLEFT", frame, -5, 5)
    checkBox:SetChecked(aceAddon.db.profile.minimap.hide)
    checkBox:SetScript("OnClick", function()
        aceAddon.db.profile.minimap.hide = checkBox:GetChecked() and true or false
        addonTable:ToggleMinimapButton()
    end)

    local text = frame:CreateFontString("WTSAutoFloodHideMinimapButtonCheckboxText", "ARTWORK")
    text:SetFontObject(addonTable.fontSmall)
    text:SetPoint("LEFT", checkBox, "RIGHT")
	text:SetText(tostring(L["HIDE_MINIMAP_BUTTON"]))
    text:SetTextColor(1, 1, 1, 1)
	text:SetJustifyH("LEFT")
	text:SetWidth(200)

    local width = max(checkBox:GetWidth(), text:GetWidth())
    local height = checkBox:GetHeight() - 11
    frame:SetSize(width, height)

    return frame
end

function addonTable:CreateLanguageDropdown(parentFrame, referenceFrame)
    local frame = CreateFrame("Frame", "WTSAutoFloodLanguageDropdownFrame", parentFrame)
    frame:SetPoint("TOPLEFT", referenceFrame, "BOTTOMLEFT", 0, -24)

    local title = frame:CreateFontString("WTSAutoFloodLanguageDropdownTitle", "ARTWORK")
    title:SetFontObject(addonTable.fontSmall)
    title:SetPoint("TOPLEFT", frame)
    title:SetText(tostring(L["LANGUAGE"]))
    title:SetJustifyH("LEFT")

    local dropDown = CreateFrame("Frame", "WTSAutoFloodLanguageDropdown", frame, "UIDropDownMenuTemplate")
    dropDown:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -18, -5)

    UIDropDownMenu_SetWidth(dropDown, 200)
    UIDropDownMenu_JustifyText(dropDown, "LEFT")
    _G[dropDown:GetName() .. "Text"]:SetFontObject(addonTable.fontSmall)

    UIDropDownMenu_Initialize(dropDown, function(_, level)
        local info = UIDropDownMenu_CreateInfo()

        for _, language in ipairs(Languages) do
            info.text = L[language.key]
            info.value = language.value
            info.fontObject = addonTable.fontSmall
            info.func = function(self)
                aceAddon.db.profile.locale = self.value
                UIDropDownMenu_SetText(dropDown, self:GetText())
                CloseDropDownMenus()
            end
            info.checked = language.value == aceAddon.db.profile.locale
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    for _, language in ipairs(Languages) do
        if language.value == aceAddon.db.profile.locale then
            UIDropDownMenu_SetText(dropDown, L[language.key])
        end
    end

    local hint = frame:CreateFontString("WTSAutoFloodLanguageReloadHint", "ARTWORK")
    hint:SetFontObject(addonTable.fontSmall)
    hint:SetPoint("TOPLEFT", dropDown, "BOTTOMLEFT", 18, 0)
    hint:SetText(tostring(L["LOCALE_RELOAD"]))
    hint:SetTextColor(1, 1, 1, 1)
    hint:SetJustifyH("LEFT")
    hint:SetWidth(300)

    local width = max(dropDown:GetWidth(), title:GetWidth())
    local height = dropDown:GetHeight() + title:GetHeight() + hint:GetHeight()
    frame:SetSize(width, height)

    return frame
end
