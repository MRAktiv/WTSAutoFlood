---@diagnostic disable: undefined-global, inject-field, duplicate-set-field, undefined-field, missing-fields, param-type-mismatch

--- Addon name, namespace
local addonName, addonTable = ...

--- Compatible on both the modern and the old client
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

--- The global is a deprecated wrapper and gets blocked outside a hardware event
local SendChatMessage = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage

--- Title from the .toc, used everywhere the player sees the addon
local ADDON_TITLE = GetAddOnMetadata(addonName, "Title") or addonName
addonTable.ADDON_TITLE = ADDON_TITLE

--- Section name for Bindings.xml, must exist before the key bindings UI is built
BINDING_HEADER_WTSAUTOFLOOD = ADDON_TITLE

--- AceAddon local variable
local aceAddon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceHook-3.0")
addonTable.aceAddon = aceAddon

--- Icon local variable
local icon = LibStub("LibDBIcon-1.0")

--- Chat type constants accepted by SendChatMessage
local CHAT_TYPES = {
    [1] = "CHANNEL",
    [2] = "SAY",
    [3] = "YELL",
    [4] = "PARTY",
    [5] = "RAID",
    [6] = "BATTLEGROUND",
    [7] = "GUILD",
    [8] = "OFFICER",
}

--- Group chats the client lets an addon post to on a timer. Broadcast chats
--- (CHANNEL, SAY, YELL) need a real key press or click, verified in game.
local TIMER_ALLOWED = {
    PARTY = true,
    RAID = true,
    BATTLEGROUND = true,
    GUILD = true,
    OFFICER = true,
}

--- Locale table, falls back to enUS for missing keys
local L = setmetatable({}, { __index = function(_, key)
    local locales = addonTable.locales
    local selected = aceAddon.db and locales[aceAddon.db.profile.locale]
    local lang = selected or locales.enUS
    return lang[key] or locales.enUS[key] or key
end })
addonTable.L = L

--- Local variables
local mainFrame
local editBox
local updateFrame

local isEditBoxOnFocus = false
local hasLoadedUI = false

--- Defaults for AceDB
local defaults = {
    profile = {
        position = {
            x = nil,
            y = nil,
        },
        minimap = {
            hide = false,
        },
        trade_text = "",
        is_on = false,
        interval = 30, -- Default time interval
        chat_type = nil, -- Default chat
        channel_type = nil, -- Default channel
        auto_focus_enabled = false, -- Default auto focus
        hide_tooltips = false, -- Default hide tooltips
        locale = "ruRU", -- Default language
        presets = {}, -- Saved advert texts, { name = , text = }
    },
}

--- Key binding the send button answers to
local BINDING_ACTION = "CLICK WTSAutoFloodAdvertiseButton:LeftButton"

----------------------------------------------------------------------------------------

function aceAddon:OnInitialize()
    --- Setup AceDB
    self.db = LibStub("AceDB-3.0"):New("WTSAutoFloodDB", defaults)

    --- Register slash commands
    self:RegisterChatCommand("wts", "SlashCommand")
    self:RegisterChatCommand("wtsautoflood", "SlashCommand")

    --- Setup fonts
    addonTable:CreateFonts()

    --- Setup invisible frame
    addonTable:SetupUpdateFrame()
end

--- Guards against a double insert when both shift-click routes fire
local lastLink, lastLinkAt = nil, 0

--- Takes a shift-clicked link into the addon field, true if taken
local function CaptureLink(link)
    if not link or not mainFrame or not mainFrame:IsShown() then
        return false
    end

    --- The player is typing in chat, leave the link to chat
    if ChatEdit_GetActiveWindow() and not isEditBoxOnFocus then
        return false
    end

    local now = GetTime()
    if link == lastLink and (now - lastLinkAt) < 0.2 then
        return true
    end
    lastLink, lastLinkAt = link, now

    editBox:Insert(link)
    editBox:SetFocus()
    return true
end

function aceAddon:OnEnable()
    --- UI entry point for every shift-click: bags, recipes, spellbook
    self:SecureHook("HandleModifiedItemClick", function(link)
        if IsModifiedClick("CHATLINK") then
            CaptureLink(link)
        end
    end)

    --- Used directly when a chat edit box is already active
    self:RawHook("ChatEdit_InsertLink", function(link)
        if CaptureLink(link) then
            return true
        end
        return self.hooks.ChatEdit_InsertLink(link)
    end, true)
end

function aceAddon:OnDisable()
    self:Unhook("HandleModifiedItemClick")
    self:Unhook("ChatEdit_InsertLink")
end

function aceAddon:SlashCommand()
    addonTable:ToggleUI()
end

----------------------------------------------------------------------------------------

--- Creates the UI
function addonTable:SetupUI()
    mainFrame, editBox = self:CreateUI()
    self:CreateMinimapButton()
end

--- Creates interface options
function addonTable:SetupInterfaceOption()
    self:CreateInterfaceOptions()
end

--- Creates invisible frame for tracking time
function addonTable:SetupUpdateFrame()
    updateFrame = CreateFrame("Frame")
    updateFrame:SetSize(1, 1)
    updateFrame:SetFrameStrata("HIGH")
    updateFrame:SetToplevel(true)
    updateFrame:SetMovable(false)
    updateFrame:EnableMouse(false)

    --- Inject fields
    updateFrame.timeSinceLastUpdate = 0

    --- Register events
    updateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    updateFrame:RegisterEvent("ADDON_ACTION_BLOCKED")
    updateFrame:SetScript("OnEvent", UdateFrameOnEvent)

    --- Register updates
	updateFrame:SetScript("OnUpdate", UpdateFrameOnUpdate)
end

----------------------------------------------------------------------------------------

--- Callback function for onEvent used by updateFrame
function UdateFrameOnEvent(self, event, ...)
    if (not hasLoadedUI and event == "PLAYER_ENTERING_WORLD") then
        print(L["ADDON_LOADED"])
        hasLoadedUI = true
        updateFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
        addonTable:SetupUI()
        addonTable:SetupInterfaceOption()

        --- Localized label for the key binding, the locale is known only now
        _G["BINDING_NAME_CLICK WTSAutoFloodAdvertiseButton:LeftButton"] = L["BINDING_ADVERTISE"]
    elseif event == "ADDON_ACTION_BLOCKED" then
        --- Safety net: a chat we believed was timer friendly turned out not to be
        local blockedAddon = ...
        if blockedAddon == addonName and aceAddon.db.profile.is_on
           and addonTable:CanSendOnTimer() then
            aceAddon.db.profile.is_on = false
            addonTable:RefreshToggleButton()
            print(L["AUTO_STOPPED_BLOCKED"])
        end
    end
end

--- Callback function for onUpdate used by updateFrame
function UpdateFrameOnUpdate(self, elapsed)
	if not aceAddon.db.profile.is_on then
        return
    end

	self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
	if self.timeSinceLastUpdate >= aceAddon.db.profile.interval then
        --- Broadcast chats would only raise ADDON_ACTION_BLOCKED here
        if addonTable:CanSendOnTimer() then
            addonTable:SendMessage()
        end
		self.timeSinceLastUpdate = 0
	end
end

----------------------------------------------------------------------------------------

--- Gets all joined channels
function addonTable:GetJoinedChannels()
    local channels = { }
    local channelList = { GetChannelList() }
    for i = 1, #channelList, 3 do
        table.insert(channels, {
            id = channelList[i],
            name = channelList[i+1],
            isDisabled = channelList[i+2],
        })
    end
    return channels
end

--- Creates the minimap button
function addonTable:CreateMinimapButton()
    local autoFloodLDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
        type = "data source",
        text = ADDON_TITLE,
        icon = "Interface\\AddOns\\WTSAutoFlood\\Resources\\icon",
        OnClick = function(_, button)
            if button == "LeftButton" then
                self:ToggleUI()
            elseif button == "RightButton" then
                self:OpenOptions()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(ADDON_TITLE)
            tooltip:AddLine(L["MINIMAP_LEFT_CLICK"], 1, 1, 1)
            tooltip:AddLine(L["MINIMAP_RIGHT_CLICK"], 1, 1, 1)
        end,
    })

    icon:Register(addonName, autoFloodLDB, aceAddon.db.profile.minimap)
end

--- Opens the settings panel
function addonTable:OpenOptions()
    if not self.optionsPanel then
        return
    end

    if self.settingsCategory and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(self.settingsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        --- Called twice, the first call opens the wrong category
        InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
    end
end

----------------------------------------------------------------------------------------

--- Saved advert texts

--- @return table presets
function addonTable:GetPresets()
    return aceAddon.db.profile.presets
end

--- Stores the current text under a name, overwriting a preset of the same name
--- @param name string
--- @param text string
function addonTable:SavePreset(name, text)
    if not name or name == "" or not text or text == "" then
        return false
    end

    local presets = self:GetPresets()
    for i = 1, #presets do
        if presets[i].name == name then
            presets[i].text = text
            return true
        end
    end

    table.insert(presets, { name = name, text = text })
    return true
end

--- @param name string
function addonTable:DeletePreset(name)
    local presets = self:GetPresets()
    for i = #presets, 1, -1 do
        if presets[i].name == name then
            table.remove(presets, i)
            return true
        end
    end
    return false
end

--- @param name string
--- @return string? text
function addonTable:GetPresetText(name)
    local presets = self:GetPresets()
    for i = 1, #presets do
        if presets[i].name == name then
            return presets[i].text
        end
    end
    return nil
end

--- Puts a saved text into the edit box
--- @param name string
function addonTable:ApplyPreset(name)
    local text = self:GetPresetText(name)
    if not text then
        return false
    end

    aceAddon.db.profile.trade_text = text
    if editBox then
        editBox:SetText(text)
        editBox:SetCursorPosition(text:len())
    end
    return true
end

----------------------------------------------------------------------------------------

--- Key binding handled from inside the addon window

--- @return string? key
function addonTable:GetSendKey()
    return (GetBindingKey(BINDING_ACTION))
end

--- Binds a key to the send button and saves it
--- @param key string
function addonTable:SetSendKey(key)
    if InCombatLockdown and InCombatLockdown() then
        print(L["KEY_NOT_IN_COMBAT"])
        return false
    end

    self:ClearSendKey()
    if not SetBinding(key, BINDING_ACTION) then
        return false
    end

    SaveBindings(GetCurrentBindingSet())
    return true
end

--- Frees whatever key is bound to the send button
function addonTable:ClearSendKey()
    local existing = self:GetSendKey()
    while existing do
        SetBinding(existing, nil)
        existing = self:GetSendKey()
    end

    if not (InCombatLockdown and InCombatLockdown()) then
        SaveBindings(GetCurrentBindingSet())
    end
end

--- Keeps the toggle button label in sync when the state changes on its own
function addonTable:RefreshToggleButton()
    if self.toggleButton then
        self.toggleButton:SetText(aceAddon.db.profile.is_on and L["TURN_OFF"] or L["TURN_ON"])
    end
end

--- True when the selected chat accepts a message sent by the timer
function addonTable:CanSendOnTimer()
    local chatType = CHAT_TYPES[aceAddon.db.profile.chat_type]
    return chatType ~= nil and TIMER_ALLOWED[chatType] == true
end

--- Sends the message
function addonTable:SendMessage()
    local chatType = CHAT_TYPES[aceAddon.db.profile.chat_type]
    local target = aceAddon.db.profile.channel_type

    if chatType and (chatType ~= "CHANNEL" or target) then
        local message = aceAddon.db.profile.trade_text
        if message ~= "" then
            SendChatMessage(message, chatType, nil, target)
        end
    else
        print(L["SET_CHAT_CHANNEL"])
    end
end

--- Prints the message
function addonTable:PrintMessage()
    print(L["YOUR_MESSAGE"] .. editBox:GetText())
end

--- Toggles auto message
function addonTable:ToggleMessage(toggleButton)
    if CHAT_TYPES[aceAddon.db.profile.chat_type] then
        aceAddon.db.profile.is_on = not aceAddon.db.profile.is_on

        local toggleText = aceAddon.db.profile.is_on and L["TURN_OFF"]or L["TURN_ON"]
        toggleButton:SetText(toggleText)

        local message = aceAddon.db.profile.is_on and L["MESSAGE_TURNED_ON"] or L["MESSAGE_TURNED_OFF"]
        if aceAddon.db.profile.is_on then
            local localizedMessage = tostring(L["MESSAGE_WILL_BE_DISPLAYED"])
            message = message .. string.gsub(localizedMessage, "#INTERVAL#", aceAddon.db.profile.interval)
        end
        print(message)

        if aceAddon.db.profile.is_on and not self:CanSendOnTimer() then
            print(L["MANUAL_CHAT_ONLY"])
        end
    else
        print(L["SET_CHAT_CHANNEL"])
    end
end

--- Toggles the minimap button
function addonTable:ToggleMinimapButton()
    if aceAddon.db.profile.minimap.hide then
        icon:Hide(addonName)
    else
        icon:Show(addonName)
    end
end

--- Toggles the UI
function addonTable:ToggleUI()
    if mainFrame:IsShown() then
        self:HideUI()
    else
        self:ShowUI()
    end
end

--- Hides the UI
function addonTable:ShowUI()
    local text = aceAddon.db.profile.trade_text
    if text ~= "" and editBox:GetText() == "" then
        editBox:SetText(text)
        editBox:SetCursorPosition(editBox:GetText():len())
    end
    mainFrame:Show()
    if aceAddon.db.profile.auto_focus_enabled then
        editBox:SetFocus()
    end
end

--- Shows the UI
function addonTable:HideUI()
    mainFrame:Hide()
end

--- Focus edit box
function addonTable:FocusEditBox()
    editBox:SetFocus()
end

--- Trigered when EditBox gains focus
function addonTable:OnFocusGained()
    isEditBoxOnFocus = true
end

--- Trigered when EditBox loses focus
function addonTable:OnFocusLost()
    isEditBoxOnFocus = false
end
