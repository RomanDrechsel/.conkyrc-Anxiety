local customization = require("loader.customization")

local ThemeLoader = {
    setting = "Config.Theme",
    objectName = "Theme",
    schema = require("loader.customization_schema").theme,
    optional = { ["Theme.BackgroundImage"] = true },
    customDirectory = "customizable/themes",
    builtInDirectory = "lua/buildIn/themes",
    fallback = "theme_nebula"
}

ThemeLoader.load = customization.load

-- Keep graph data settings while applying only fields declared by the theme schema.
local function applyFields(target, style, schema, keepExisting)
    for key, field in pairs(schema) do
        if type(field) == "table" then
            local values = type(target[key]) == "table" and target[key] or {}
            target[key] = values
            applyFields(values, style[key], field, keepExisting)
        elseif not keepExisting or target[key] == nil then
            target[key] = style[key]
        end
    end
end

function ThemeLoader:apply(config, theme)
    -- Older configurations without Config.Theme can still supply their own styles.
    applyFields(config, theme, self.schema, config.Theme == nil)
end

return ThemeLoader
