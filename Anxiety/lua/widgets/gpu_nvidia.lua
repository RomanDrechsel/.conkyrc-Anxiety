GPU_Nvidia = {}

function GPU_Nvidia:new()
    if Config.LineGraph.Graph.LineColor and Config.LineGraph.Graph.LineWidth and Config.LineGraph.Graph.LineWidth > 0 then
        self.GraphLine = LineGraph:new(Config.LineGraph, nil, 60)
    end

    return self
end

function GPU_Nvidia:Display(cr, y)
    y = Draw:Header(cr, Locale.VideoCard, y)

    local yStart = y
    local values = ReadCli("nvidia-smi --query-gpu=driver_version,name,temperature.gpu,utilization.gpu,memory.used,memory.total,fan.speed,power.draw,power.limit --format=csv,noheader,nounits")
    local fields = {}

    if values then
        for field in string.gmatch(values, "([^,]*)[,]?") do
            table.insert(fields, field:match("^%s*(.-)%s*$"))
        end
    end

    -- card name
    Draw:Font(cr, Config.Text.Special)
    _, y = Draw:LeftText(cr, fields[2] or "N/A", y)
    y = y + 5

    -- driver version
    Draw:Font(cr, Config.Text.Info)
    Draw:RightText(cr, fields[1] or "N/A", yStart)

    -- graph
    if self.GraphLine then
        y = self.GraphLine:Draw(cr, Config.MarginX, y, tonumber(fields[4]))
    end

    -- Utilization / Temperature
    y = Draw:Row(cr, y, Locale.GPU, Config.Text.Label, tonumber(fields[3]) .. "°C", Config.Text.Info, tonumber(fields[4]) .. "%", nil);

    -- Memory
    y = Draw:Row(cr, y, Locale.Memory, Config.Text.Label, self:MemTemp(), Config.Text.Info, self:VRAM(fields), nil);

    -- Fan
    y = Draw:Row(cr, y, Locale.Fan, Config.Text.Label, nil, nil, tonumber(fields[7]) .. " rpm", Config.Text.Info);

    -- Power
    y = Draw:Row(cr, y, Locale.Power, Config.Text.Label, nil, nil, self:Power(fields), Config.Text.Info);

    return y
end

function GPU_Nvidia:Update()
end

function GPU_Nvidia:MemTemp()
    local temp_output = ReadCli("nvidia-smi -q -d TEMPERATURE")

    if temp_output then
        local mem_temp = temp_output:match("Memory Temperature%s*:%s*(%d+)%s*C")
        if mem_temp then
            return mem_temp
        end
    end

    return ""
end

function GPU_Nvidia:VRAM(fields)
    return tonumber(fields[5]) .. " MB / " .. tonumber(fields[6]) .. " MB"
end

function GPU_Nvidia:Power(fields)
    local curr = tonumber(fields[8])
    local max = tonumber(fields[9])

    if curr then
        curr = ToNumber(curr)
        local percent = ToNumber(curr / max * 100)
        local percent_str = "";
        if percent then
            percent = math.floor(percent + 0.5)
            percent_str = " (" .. percent .. "%)"
        end

        return curr .. " W" .. percent_str
    end
end

GPU_Nvidia:new()
