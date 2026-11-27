Sensors = {}

function Sensors:new()
    local sensors = setmetatable({}, self)
    if IsPackageInstalled("sensors") == false then
        print("Package \"sensors\" not installed!")
        print("run \"sudo pacman -Sq lm_sensors\"")
    else
        sensors.Init = true
    end

    return sensors
end

function Sensors:Update()
    local sensors = ReadCli("sensors -j")
    if IsEmpty(sensors) then
        self.Json = nil
    else
        local success, json = pcall(JSON.parse, sensors)
        if success and json and json ~= JSON.null then
            self.Json = json
        else
            self.Json = nil
        end
    end
end

function Sensors:Get(...)
    for i = 1, select("#", ...) do
        local key = select(i, ...)

        if type(self.Json) ~= "table" or key == nil then
            return nil
        end

        self.Json = self.Json[key]

        if self.Json == nil then
            return nil
        end
    end

    return self.Json
end

function Sensors:GetNumber(default, ...)
    return tonumber(self:Get(...)) or default
end

function Sensors:Find(chipPrefix, ...)
    local json = self.Json

    if type(json) ~= "table" then
        return nil
    end

    for chipName in pairs(json) do
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
