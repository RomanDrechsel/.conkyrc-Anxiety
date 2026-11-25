Sensors = {}

function Sensors:new()
    if package_installed("sensors") == false then
        print("Package \"sensors\" not installed!")
        print("run \"sudo pacman -Sq lm_sensors\"")
    else
        self.Init = true
    end

    return self
end

function Sensors:Update()
    local sensors = pipe("sensors -j")
    if isEmpty(sensors) then
        self.Json = nil
    else
        local success, _json = pcall(JSON.parse, sensors)
        if success and _json and _json ~= JSON.null then
            self.Json = _json
        else
            self.Json = nil
        end
    end
end

function Sensors:Get(...)
    local value = self.Json

    for i = 1, select("#", ...) do
        local key = select(i, ...)

        if type(value) ~= "table" or key == nil then
            return nil
        end

        value = value[key]

        if value == nil then
            return nil
        end
    end

    return value
end

function Sensors:GetNumber(default, ...)
    return tonumber(self:Get(...)) or default
end

function Sensors:Find(chipPrefix, ...)
    if type(self.Json) ~= "table" then
        return nil
    end

    for chipName in pairs(self.Json) do
        if type(chipName) == "string" and chipName:sub(1, #chipPrefix) == chipPrefix then
            local value = self:Get(chipName, ...)
            if value ~= nil then
                return value
            end
        end
    end

    return nil
end

function Sensors:FindNumber(default, chipPrefix, ...)
    return tonumber(self:Find(chipPrefix, ...)) or default
end
