--- Addon name, namespace
local addonName, addonTable = ...

addonTable.locales = addonTable.locales or {}

--- Compatible on both the modern and the old client
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local title = GetAddOnMetadata(addonName, "Title") or addonName
local version = GetAddOnMetadata(addonName, "Version") or ""
local prefix = "|cff66bbff[" .. title .. "]|r "

addonTable.locales.ruRU = {
    ADDON_LOADED = "|cff66bbff" .. title .. " " .. version .. "|r" .. " загружен.",

    MINIMAP_LEFT_CLICK = "|cff6699ffЛКМ|r открывает окно аддона.",
    MINIMAP_RIGHT_CLICK = "|cff6699ffПКМ|r открывает настройки.",

    TURN_ON = "|cff40c040Включить|r",
    TURN_OFF = "|cffbf2626Выключить|r",

    MESSAGE_TURNED_ON = prefix .. "Автоматическое сообщение |cff40c040включено|r",
    MESSAGE_TURNED_OFF = prefix .. "Автоматическое сообщение |cffbf2626выключено|r",
    MESSAGE_WILL_BE_DISPLAYED = " и будет отправляться каждые #INTERVAL# сек.",

    SET_CHAT_CHANNEL = prefix .. "|cffff2020Выберите чат или канал в настройках аддона|r",
    MANUAL_CHAT_ONLY = prefix .. "|cffffd000Этот чат не принимает сообщения по таймеру.|r Сообщение будет отправлено при следующем нажатии любой клавиши. Пока вы не за игрой — отправки не будет.",
    AUTO_STOPPED_BLOCKED = prefix .. "|cffff2020Игра заблокировала отправку по таймеру, автоотправка выключена.|r Пользуйтесь кнопкой «Реклама».",
    BINDING_ADVERTISE = "Отправить сообщение",

    TEST_BUTTON = "Тест",
    ADVERTISE_BUTTON = "Отправить",

    PRESET_LABEL = "Заготовка",
    PRESET_EMPTY = "нет заготовок",
    PRESET_SAVE = "Сохранить",
    PRESET_DELETE = "Удалить",
    PRESET_NAME_PROMPT = "Название заготовки:",
    PRESET_SAVED = prefix .. "Заготовка |cff40c040#NAME#|r сохранена.",
    PRESET_DELETED = prefix .. "Заготовка |cffbf2626#NAME#|r удалена.",
    PRESET_SAVE_TIP = "Сохранить текущий текст как заготовку",
    PRESET_DELETE_TIP = "Удалить выбранную заготовку",

    SEND_TO = "Куда отправлять",
    KEY_LABEL = "Клавиша",
    KEY_NONE = "не задана",
    KEY_PRESS_NOW = "жмите клавишу",
    KEY_TIP = "Щёлкните и нажмите клавишу. Escape — отмена, Delete — снять привязку.",
    KEY_SET = prefix .. "Клавиша отправки: |cff40c040#KEY#|r",
    KEY_CLEARED = prefix .. "Привязка клавиши снята.",
    KEY_NOT_IN_COMBAT = prefix .. "|cffff2020В бою менять привязку нельзя.|r",
    YOUR_MESSAGE = prefix .. "Ваше сообщение: ",
    SHOW_YOUR_MESSAGE = "Показать своё |cff6699ffсообщение|r",
    SEND_YOUR_MESSAGE = "Отправить своё |cff6699ffсообщение|r в чат",

    CHAT_TYPE = "Тип чата",
    SET_CHAT_TYPE = "Выберите тип чата",
    INTERVAL = "Интервал (сек.)",
    AUTO_FOCUS = "Автофокус поля ввода",
    HIDE_TOOLTIPS = "Скрыть подсказки",
    HIDE_MINIMAP_BUTTON = "Скрыть кнопку миникарты",

    LANGUAGE = "Язык",
    LANG_RU = "Русский",
    LANG_EN = "English",
    LOCALE_RELOAD = "Введите /reload, чтобы применить язык.",

    CHAT_CHANNEL = "Канал",
    CHAT_SAY = "Сказать",
    CHAT_YELL = "Крик",
    CHAT_PARTY = "Группа",
    CHAT_RAID = "Рейд",
    CHAT_BATTLEGROUND = "Поле боя",
    CHAT_GUILD = "Гильдия",
    CHAT_OFFICER = "Офицерский",
}
