local customization = require("loader.customization")

local LanguageLoader = {
    setting = "Config.Language",
    objectName = "Locale",
    schema = require("loader.customization_schema").language,
    dateFormats = { ["Locale.Clock"] = true, ["Locale.Date"] = true },
    customDirectory = "customizable/languages",
    builtInDirectory = "lua/buildIn/languages",
    fallback = "en"
}

LanguageLoader.load = customization.load

return LanguageLoader
