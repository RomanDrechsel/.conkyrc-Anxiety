CPU = { CPUName = "", GraphMain = nil, CPUCount = 1 }

function CPU:new()
    self.CPUName = ReadCli("grep model /proc/cpuinfo | cut -d : -f2 | tail -1 | sed 's/\\s//'")
    self.CPUCount = tonumber(ReadCli("lscpu | grep '^CPU(s):' | awk '{print $2}'") or nil)

    if Config.PieGraph.Graph.Color then
        local configMainGraph = TableCopy(Config.PieGraph)
        configMainGraph.Graph.Radius = 30
        self.GraphMain = PieGraph:new(configMainGraph, 90, 170)
        self._configSmallGraph = TableCopy(Config.PieGraph)
        self._configSmallGraph.Graph.BarWidthPercent = 75
        self._configSmallGraph.Graph.Label.FontSize = 12
        self._configSmallGraph.PaddingPercent = 20
    end

    if Config.LineGraph.Graph.LineColor and Config.LineGraph.Graph.LineWidth and Config.LineGraph.Graph.LineWidth > 0 then
        self.GraphLine = LineGraph:new(Config.LineGraph, nil, 70)
    end

    return self
end

function CPU:Display(cr, y)
    y = Draw:Header(cr, Locale.CPU, y)
    Draw:Font(cr, Config.Text.Special)
    _, y = Draw:LeftText(cr, self.CPUName, y)

    y = y + (Config.Padding * 2)

    if self.GraphMain then
        -- Calculate the core grid dimensions
        local smallGraphWidth = 25
        local smallGraphHeight = 40
        local spacingX = 7
        local spacingY = 7
        local rx = Config.MarginX + self.GraphMain.Width + 10
        local availableWidth = conky_window.width - rx - Config.MarginX
        local graphsPerRow = math.max(1, math.floor((availableWidth + spacingX) / (smallGraphWidth + spacingX)))
        local showCores = self._configSmallGraph and self.CPUCount > 1
        local cpuRows = showCores and math.ceil(self.CPUCount / graphsPerRow) or 0
        local coresHeight = math.max(0, cpuRows * (smallGraphHeight + spacingY) - spacingY)
        local height = math.max(self.GraphMain.Height, coresHeight) + spacingY

        Draw:FillRect(cr, Config.MarginX, y, conky_window.width - (2 * Config.MarginX), height, "#00000060")

        -- Draw total CPU utilization
        local util = self:Utilization(0)
        self.GraphMain:Draw(cr, Config.MarginX, y, util, { util .. "%", self:Temp() })

        self.GraphsSmall = self.GraphsSmall or {}

        if showCores then
            for i = 1, self.CPUCount do
                local usage = self:Utilization(i)
                if usage then
                    if not self.GraphsSmall[i] then
                        self.GraphsSmall[i] = PieGraph:new(self._configSmallGraph, smallGraphWidth, smallGraphHeight)
                    end

                    local column = (i - 1) % graphsPerRow
                    local row = math.floor((i - 1) / graphsPerRow)
                    local dx = rx + column * (smallGraphWidth + spacingX)
                    local dy = y + row * (smallGraphHeight + spacingY)

                    self.GraphsSmall[i]:Draw(cr, dx, dy, usage, usage .. "%")
                end
            end
        end

        y = y + height + spacingY

        if self.GraphLine then
            y = self.GraphLine:Draw(cr, Config.MarginX, y, util)
        end
    end

    return y
end

function CPU:Temp()
    if Sensors and Sensors.Json then
        local temp = Sensors:FindNumber(nil, "k10temp-", "Tctl", "temp1_input")
        if temp then
            return ToNumber(temp) .. "°C"
        end
    end
    return ""
end

function CPU:Utilization(cpu)
    return tonumber(conky_parse("${cpu cpu" .. cpu .. "}"))
end

CPU:new()
