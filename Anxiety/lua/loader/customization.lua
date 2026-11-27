local Customization = {}

local function validate(value, schema, path, optional, dateFormats)
    local expected = type(schema) == "table" and "table" or schema
    if value == nil and optional[path] then
        return true
    end

    local actual = type(value)
    if actual ~= expected and not (expected == "color" and actual == "string") then
        return nil, ("%s: expected %s, got %s"):format(path, expected, actual)
    end

    if expected == "color" then
        local hex = value:gsub("^#", "")
        if (#hex ~= 6 and #hex ~= 8) or not hex:match("^%x+$") then
            return nil, path .. ": expected RRGGBB or RRGGBBAA (optionally prefixed with #)"
        end
    elseif expected == "number" and (value ~= value or math.abs(value) == math.huge) then
        return nil, path .. ": expected a finite number"
    elseif expected == "table" then
        for key, field in pairs(schema) do
            local ok, err = validate(rawget(value, key), field, path .. "." .. key, optional, dateFormats)
            if not ok then
                return nil, err
            end
        end
    end

    if dateFormats and dateFormats[path] then
        local ok, formatted = pcall(os.date, value, 0)
        if not ok or type(formatted) ~= "string" then
            return nil, path .. ": invalid date/time format"
        end
    end

    return true
end

function Customization.read(path, objectName)
    local environment = {}
    if objectName == "Theme" then
        local themeHelpers = require("helpers.theme_helpers")
        environment.font = themeHelpers.font
    end

    local chunk, err = loadfile(path, "t", environment)
    if not chunk then
        local file, _, code = io.open(path, "r")
        if file then
            file:close()
        end
        return nil, err, code
    end

    local ok, result = pcall(chunk)
    if not ok then
        return nil, tostring(result)
    end

    if result == nil then
        result = environment[objectName]
    end
    return result
end

function Customization.load(loader, root, load_file)
    local function readValid(path)
        local object, err, code = Customization.read(path, loader.objectName)
        if err then
            return nil, err, code
        end

        local ok, validationError = validate(object, loader.schema, loader.objectName, loader.optional or {}, loader.dateFormats)
        if not ok then
            return nil, validationError
        end
        return object
    end

    local function useFallback(reason)
        local path = root .. loader.builtInDirectory .. "/" .. loader.fallback .. ".lua"
        if reason then
            print(("[Anxiety] %s: %s. Using %s."):format(loader.objectName, reason, loader.fallback))
        end
        local object, err = readValid(path)
        if not object then
            error(("[Anxiety] Invalid %s fallback at %s: %s"):format(loader.objectName, path, err), 0)
        end
        return object
    end

    if load_file == nil then
        return useFallback()
    end
    local name = type(load_file) == "string" and load_file:gsub("%.lua$", "")
    if not name or not name:match("^[%w_-]+$") then
        return useFallback("invalid file name in " .. loader.setting)
    end

    local file = "/" .. name .. ".lua"
    local path = root .. loader.customDirectory .. file
    local object, err, code = readValid(path)
    if object then
        return object
    end
    if code ~= 2 then -- ENOENT: the requested custom file does not exist.
        return useFallback(path .. ": " .. err)
    end

    if name == loader.fallback then
        return useFallback()
    end

    path = root .. loader.builtInDirectory .. file
    object, err = readValid(path)
    if object then
        return object
    end
    return useFallback(path .. ": " .. err)
end

return Customization
