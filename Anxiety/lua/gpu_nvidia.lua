GPU = { }

function GPU:new()
    if Config.LineGraph.Graph.LineColor and Config.LineGraph.Graph.LineWidth and Config.LineGraph.Graph.LineWidth > 0 then
        self.GraphLine = LineGraph:new(Config.LineGraph, nil, 60)
    end

    return self
end

function GPU:Display(cr, y)
    y = Draw:Header(cr, Locale.VideoCard, y)

    local y2 = y

    local values = pipe("nvidia-smi --query-gpu=driver_version,name,temperature.gpu,utilization.gpu,memory.used,memory.total,fan.speed,power.draw,power.limit --format=csv,noheader,nounits")
    local fields = {}
    for field in string.gmatch(values, "([^,]+)") do
        table.insert(fields, field:match("^%s*(.-)%s*$"))
    end

    -- card name
    if Config.Text then
        Draw:Font(cr, Config.Text.Special)
    end

    _, y = Draw:LeftText(cr, fields[2], y)
    y = y + 5

    -- driver version
    Draw:Font(cr, Config.Text.Info)
    Draw:RightText(cr, fields[1], y2)

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

function GPU:Update()
end


function GPU:MemTemp()
    local temp_output = pipe("nvidia-smi -q -d TEMPERATURE")
    local mem_temp = temp_output:match("Memory Temperature%s*:%s*(%d+)%s*C")

    if mem_temp then
        return mem_temp
    else
        return ""
    end
end

function GPU:VRAM(fields)
    return tonumber(fields[5]) .. " MB / " .. tonumber(fields[6]) .. " MB"
end

function GPU:Power(fields)
    local curr = tonumber(fields[8])
    local max =  tonumber(fields[9])

    if curr then
        curr = toInt(curr)
        local percent = toInt(curr / max * 100)
        local percent_str = "";
        if percent then
            percent = math.floor(percent + 0.5)
            percent_str = " (" .. toInt(curr / max * 100) .. "%)"
        end

        return curr .. " W" .. percent_str
    end
end

GPU:new()
