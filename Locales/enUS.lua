--- Addon name, namespace
local addonName, addonTable = ...

addonTable.locales = addonTable.locales or {}

--- Compatible on both the modern and the old client
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local title = GetAddOnMetadata(addonName, "Title") or addonName
local version = GetAddOnMetadata(addonName, "Version") or ""
local prefix = "|cff66bbff[" .. title .. "]|r "

addonTable.locales.enUS = {
    ADDON_LOADED = "|cff66bbff" .. title .. " " .. version .. "|r" .. " loaded.",

    MINIMAP_LEFT_CLICK = "|cff6699ffLeft-click|r to open the addon.",
    MINIMAP_RIGHT_CLICK = "|cff6699ffRight-click|r to show settings.",

    TURN_ON = "Turn |cff40c040ON|r",
    TURN_OFF = "Turn |cffbf2626OFF|r",

    MESSAGE_TURNED_ON = prefix .. "Your automatic message was turned |cff40c040ON|r",
    MESSAGE_TURNED_OFF = prefix .. "Your automatic message was turned |cffbf2626OFF|r",
    MESSAGE_WILL_BE_DISPLAYED = " and will be displayed in #INTERVAL# seconds",

    SET_CHAT_CHANNEL = prefix .. "|cffff2020Set the chat/channel in the addon's settings|r",
    MANUAL_CHAT_ONLY = prefix .. "|cffffd000This chat does not accept messages on a timer.|r The message goes out on your next key press. While you are away from the game, nothing is sent.",
    AUTO_STOPPED_BLOCKED = prefix .. "|cffff2020The game blocked the timed message, auto sending is off.|r Use the Advertise button.",
    BINDING_ADVERTISE = "Send the message",

    TEST_BUTTON = "Test",
    ADVERTISE_BUTTON = "Send",

    PRESET_LABEL = "Preset",
    PRESET_EMPTY = "no presets",
    PRESET_SAVE = "Save",
    PRESET_DELETE = "Delete",
    PRESET_NAME_PROMPT = "Preset name:",
    PRESET_SAVED = prefix .. "Preset |cff40c040#NAME#|r saved.",
    PRESET_DELETED = prefix .. "Preset |cffbf2626#NAME#|r deleted.",
    PRESET_SAVE_TIP = "Save the current text as a preset",
    PRESET_DELETE_TIP = "Delete the selected preset",

    SEND_TO = "Send to",
    KEY_LABEL = "Key",
    KEY_NONE = "not set",
    KEY_PRESS_NOW = "press a key",
    KEY_TIP = "Click, then press a key. Escape cancels, Delete clears the binding.",
    KEY_SET = prefix .. "Send key: |cff40c040#KEY#|r",
    KEY_CLEARED = prefix .. "Send key binding cleared.",
    KEY_NOT_IN_COMBAT = prefix .. "|cffff2020Bindings cannot be changed in combat.|r",
    YOUR_MESSAGE = prefix .. "Your message: ",
    SHOW_YOUR_MESSAGE = "Print your |cff6699ffmessage|r",
    SEND_YOUR_MESSAGE = "Send your |cff6699ffmessage|r in the chat",

    CHAT_TYPE = "Chat type",
    SET_CHAT_TYPE = "Set the chat type",
    INTERVAL = "Interval (seconds)",
    AUTO_FOCUS = "Auto-focus message window",
    HIDE_TOOLTIPS = "Hide tooltips",
    HIDE_MINIMAP_BUTTON = "Hide minimap button",

    LANGUAGE = "Language",
    LANG_RU = "Russian",
    LANG_EN = "English",
    LOCALE_RELOAD = "Type /reload to apply the language.",

    CHAT_CHANNEL = "Channel",
    CHAT_SAY = "Say",
    CHAT_YELL = "Yell",
    CHAT_PARTY = "Party",
    CHAT_RAID = "Raid",
    CHAT_BATTLEGROUND = "Battlefield",
    CHAT_GUILD = "Guild",
    CHAT_OFFICER = "Officer",
}
