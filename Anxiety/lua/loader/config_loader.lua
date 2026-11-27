local ConfigLoader = {}
ConfigLoader.__index = ConfigLoader

function ConfigLoader:new(builtInDirectory, customDirectory)
    return setmetatable({
        BuiltInDirectory = builtInDirectory,
        CustomDirectory = customDirectory,
        DefaultFile = "default_config.lua",
        CustomFile = "config.lua",
        Debug = false,

        -- Tables that must be replaced instead of merged
        ReplaceTables = {
            ["Config.Partitions"] = true
        },

        -- Optional properties without a default value
        OptionalTypes = {
            ["Config.VideoCard"] = "string",
            ["Config.AMDGPUAddress"] = "string"
        }
    }, self)
end

function ConfigLoader:load(filename)
    filename = filename or self.CustomFile

    if type(filename) ~= "string" or not filename:match("^[%w_%-]+%.lua$") then
        error("Invalid configuration filename.")
    end

    local defaultPath = self:_joinPath(self.BuiltInDirectory, self.DefaultFile)
    local customPath = self:_joinPath(self.CustomDirectory, filename)
    local defaults, defaultError = self:_loadFile(defaultPath)

    if not defaults then
        error("[ConfigLoader] Unable to load default configuration: " .. tostring(defaultError))
    end

    local custom, customError = self:_loadFile(customPath)

    if not custom then
        print("[ConfigLoader] Using default configuration: " .. tostring(customError))
        return self:_copy(defaults)
    end

    return self:_merge(defaults, custom, "Config")
end

function ConfigLoader:finalize(config)
    config.NetworkGraph.Download.Scale = config.Network.DownloadMaxBytesPerSecond
    config.NetworkGraph.Upload.Scale = config.Network.UploadMaxBytesPerSecond
    return config
end

function ConfigLoader:_log(message)
    if self.Debug then
        print("[ConfigLoader] " .. message)
    end
end

function ConfigLoader:_joinPath(directory, filename)
    return directory:gsub("/+$", "") .. "/" .. filename
end

function ConfigLoader:_copy(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}

    for key, entry in pairs(value) do
        result[key] = self:_copy(entry)
    end

    return result
end

function ConfigLoader:_loadFile(path)
    -- Execute the configuration in an isolated environment
    local environment = {}
    local chunk, loadError = loadfile(path, "t", environment)

    if not chunk then
        return nil, loadError
    end

    local success, result = pcall(chunk)

    if not success then
        return nil, result
    end

    if type(result) ~= "table" then
        return nil, "Configuration must return a table."
    end

    return result
end

function ConfigLoader:_merge(defaults, overrides, path)
    local result = self:_copy(defaults)

    if type(overrides) ~= "table" then
        return result
    end

    for key, value in pairs(overrides) do
        local currentPath = path .. "." .. tostring(key)
        local defaultValue = defaults[key]
        local expectedType = self.OptionalTypes[currentPath]

        if defaultValue ~= nil then
            expectedType = type(defaultValue)
        end

        if expectedType and type(value) ~= expectedType then
            self:_log("Invalid type: " .. currentPath .. " (expected " .. expectedType .. ", got " .. type(value) .. ")")
        elseif type(value) == "number" and (value ~= value or math.abs(value) == math.huge) then
            self:_log("Invalid number: " .. currentPath)
        elseif type(value) == "table" and type(defaultValue) == "table" and not self.ReplaceTables[currentPath] then
            result[key] = self:_merge(defaultValue, value, currentPath)
        else
            result[key] = self:_copy(value)
            self:_log("Override: " .. currentPath)
        end
    end

    return result
end

return ConfigLoader
