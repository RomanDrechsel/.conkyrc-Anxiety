GPU_AMD = { Path = nil, HwmonPath = nil, DriverVersion = nil, CardName = nil }

function GPU_AMD:new()
    self.Path, self.PCIAddress = self:_findDevice()
    self.HwmonPath = nil
    self.DriverVersion = nil
    self.CardName = nil
    self.GraphLine = nil
    self.Data = {}
    self._timerEveryMin = Timer:new(60)

    if self.Path then
        print("AMD-GPU Device found: " .. self.Path)
        local graph = Config.LineGraph and Config.LineGraph.Graph
        if graph and graph.LineColor and (tonumber(graph.LineWidth) or 0) > 0 then
            self.GraphLine = LineGraph:new(Config.LineGraph, nil, 60)
        end
        self:_runOncePerMin()
        self:_readMeasurements()
    else
        print("No AMD-GPU Device found!")
    end
    return self
end

function GPU_AMD:_runOncePerMin()
    if not self.Path then
        return
    end

    self.HwmonPath = self:_findHwmon()

    -- Identify the selected PCI device, not the active OpenGL renderer.
    local name = Config.VideoCard
    if type(name) ~= "string" or name == "" then
        name = nil
        if self.PCIAddress and self.PCIAddress:match("^%x+:%x+:%x+%.%x+$") then
            local result = ReadCli("LC_ALL=C lspci -D -s " .. self.PCIAddress .. " 2>/dev/null")
            if result then
                name = result:match("^%S+%s+[^:]+:%s*(.-)%s*$")
            end
        end
    end
    self.CardName = name or "AMD GPU"

    -- The in-kernel AMDGPU driver follows the kernel release, not Mesa's version.
    local version = self:_readFile("/sys/module/amdgpu/version")
    self.DriverVersion = version or self:_readFile("/proc/sys/kernel/osrelease")
end

function GPU_AMD:_readMeasurements()
    local data = {}
    if not self.Path then
        self.Data = data; return
    end
    data.Utilization = self:_readNumber(self.Path .. "gpu_busy_percent")
    data.VRAMUsed = self:_readNumber(self.Path .. "mem_info_vram_used")
    data.VRAMTotal = self:_readNumber(self.Path .. "mem_info_vram_total")
    data.Edge = self:_readHwmon("temp1_input")
    data.Junction = self:_readHwmon("temp2_input")
    data.MemoryTemperature = self:_readHwmon("temp3_input")
    data.Fan = self:_readHwmon("fan1_input")
    data.FanMaximum = self:_readHwmon("fan1_max")
    data.Power = self:_readHwmon("power1_average") or self:_readHwmon("power1_input")
    data.PowerLimit = self:_readHwmon("power1_cap")
    local frequency = self:_readHwmon("freq1_input")
    if frequency then
        data.Clock = frequency / 1000000
    end

    -- DPM states provide the highest currently exposed clock, not a guaranteed boost limit.
    local states = self:_readFile(self.Path .. "pp_dpm_sclk") or ""
    for line in states:gmatch("[^\r\n]+") do
        local mhz = tonumber(line:match(":%s*(%d+%.?%d*)%s*[Mm][Hh][Zz]"))
        if mhz then
            data.ClockMaximum = math.max(data.ClockMaximum or 0, mhz)
            if not frequency and line:find("*", 1, true) then
                data.Clock = mhz
            end
        end
    end
    self.Data = data
end

function GPU_AMD:Update()
    if self._timerEveryMin:Ready() then
        local path, address = self:_findDevice()
        if path ~= self.Path or address ~= self.PCIAddress then
            self.Path, self.PCIAddress = path, address
            self.GraphLine = nil
            local graph = Config.LineGraph and Config.LineGraph.Graph
            if path and graph and graph.LineColor and (tonumber(graph.LineWidth) or 0) > 0 then
                self.GraphLine = LineGraph:new(Config.LineGraph, nil, 60)
            end
        end
        self:_runOncePerMin()
    end
    self:_readMeasurements()
end

function GPU_AMD:VRAM()
    local used, maximum = self.Data.VRAMUsed, self.Data.VRAMTotal
    if used == nil and maximum == nil then
        return Locale.NA
    end
    return (used ~= nil and FormatBytes(used) or Locale.NA) .. " / " .. (maximum ~= nil and FormatBytes(maximum) or Locale.NA)
end

function GPU_AMD:Temp()
    local parts = {}
    if self.Data.Edge ~= nil then
        parts[#parts + 1] = string.format("%.0f °C", self.Data.Edge / 1000)
    end
    if self.Data.Junction ~= nil then
        parts[#parts + 1] = string.format("%.0f °C", self.Data.Junction / 1000)
    end
    return table.concat(parts, " / ")
end

function GPU_AMD:MemTemp()
    local value = self.Data.MemoryTemperature
    return value ~= nil and string.format("%.0f °C", value / 1000) or ""
end

function GPU_AMD:ClockSpeed()
    local current, maximum = self.Data.Clock, self.Data.ClockMaximum
    if current == nil and maximum == nil then
        return Locale.NA
    end
    if maximum == nil then
        return string.format("%.0f MHz", current)
    end
    return (current ~= nil and string.format("%.0f MHz", current) or Locale.NA) .. " / " .. string.format("%.0f MHz", maximum)
end

function GPU_AMD:Fan()
    local current, maximum = self.Data.Fan, self.Data.FanMaximum
    if current == nil then
        return Locale.NA
    end
    local text = string.format("%.0f rpm", current)
    if maximum and maximum > 0 then
        text = text .. string.format(" (%.0f%%)", current / maximum * 100)
    end
    return text
end

function GPU_AMD:Power()
    local current, maximum = self.Data.Power, self.Data.PowerLimit
    if current == nil then
        return Locale.NA
    end
    local text = string.format("%.1f W", current / 1000000)
    if maximum and maximum > 0 then
        text = text .. string.format(" (%.0f%%)", current / maximum * 100)
    end
    return text
end

function GPU_AMD:Display(cr, y)
    if not self.Path then
        return y
    end
    y = Draw:Header(cr, Locale.VideoCard, y)

    if self.CardName then
        Draw:Font(cr, Config.Text.Special)
        local _, nextY = Draw:LeftText(cr, self.CardName, y)
        y = nextY + 5
    end

    if self.DriverVersion then
        Draw:Font(cr, Config.Text.Info)
        local _, nextY = Draw:LeftText(cr, self.DriverVersion, y)
        y = nextY
    end

    if self.GraphLine and self.Data.Utilization ~= nil then
        y = self.GraphLine:Draw(cr, Config.MarginX, y, self.Data.Utilization) or y
    end

    local temp, clock = self:Temp(), self:ClockSpeed()
    if temp ~= "" or clock ~= Locale.NA then
        y = Draw:Row(cr, y, Locale.GPU, Config.Text.Label, temp, Config.Text.Info, clock, nil)
    end

    local memory, memoryTemperature = self:VRAM(), self:MemTemp()
    if memory ~= Locale.NA or memoryTemperature ~= "" then
        y = Draw:Row(cr, y, Locale.Memory, Config.Text.Label, memoryTemperature, Config.Text.Info, memory, nil)
    end

    local fan = self:Fan()
    if fan ~= Locale.NA then
        y = Draw:Row(cr, y, Locale.Fan, Config.Text.Label, nil, nil, fan, Config.Text.Info)
    end

    local power = self:Power()
    if power ~= Locale.NA then
        y = Draw:Row(cr, y, Locale.Power, Config.Text.Label, nil, nil, power, Config.Text.Info)
    end

    return y
end

function GPU_AMD:_readFile(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end

    local value = file:read("*a")
    file:close()
    if not value then
        return nil
    end
    value = value:match("^%s*(.-)%s*$")
    return value ~= "" and value or nil
end

function GPU_AMD:_readNumber(path)
    local value = tonumber(self:_readFile(path))
    if value == nil or value ~= value or math.abs(value) == math.huge then
        return nil
    end
    return value
end

function GPU_AMD:_readHwmon(name)
    if not self.HwmonPath then
        return nil
    end
    return self:_readNumber(self.HwmonPath .. name)
end

function GPU_AMD:_findDevice()
    -- Optional PCI address, e.g. 0000:03:00.0.
    local requested = Config.AMDGPUAddress
    local cards = ReadCli("ls /sys/class/drm/ 2>/dev/null") or ""
    for card in cards:gmatch("%S+") do
        if card:match("^card%d+$") then
            local path = "/sys/class/drm/" .. card .. "/device/"
            local uevent = self:_readFile(path .. "uevent") or ""
            local driver = ("\n" .. uevent .. "\n"):match("\nDRIVER=([^\n]+)")
            local address = ("\n" .. uevent .. "\n"):match("\nPCI_SLOT_NAME=([^\n]+)")
            if self:_readFile(path .. "vendor") == "0x1002" and driver == "amdgpu" and (not requested or requested == address) then
                return path, address
            end
        end
    end
    return nil, nil
end

function GPU_AMD:_findHwmon()
    if not self.Path then
        return nil
    end
    -- Device path is generated from a validated DRM card name.
    local directories = ReadCli("ls " .. self.Path .. "hwmon/ 2>/dev/null") or ""
    for directory in directories:gmatch("%S+") do
        if directory:match("^hwmon%d+$") then
            local path = self.Path .. "hwmon/" .. directory .. "/"
            if self:_readFile(path .. "name") == "amdgpu" then
                return path
            end
        end
    end
    return nil
end

GPU_AMD:new()
