LineGraph = {}
LineGraph.__index = LineGraph

function LineGraph:new(config, width, height)
    local o = setmetatable({ Data = {}, Lines = {}, Width = width, Height = height }, self)
    o:setConfig(config or Config.LineGraph)
    return o
end

function LineGraph:setConfig(config)
    self.Config = TableCopy(config or {})
    self.Config.Graph = self.Config.Graph or {}
    self.Config.Border = self.Config.Border or {}
    self.Config.Grid = self.Config.Grid or {}
    self.Config.Graph.Scale = self.Config.Graph.Scale or 100
end

function LineGraph:Draw(cr, x, y, data)
    if data == nil and next(self.Data) == nil then
        return
    end

    local width = GraphStyle.number(self.Width, conky_window.width - x - Config.MarginX)
    if width < 0 then
        width = conky_window.width - x - Config.MarginX
    end

    local height = GraphStyle.number(self.Height, 0)
    if height <= 0 then
        height = GraphStyle.number(self.Config.DefaultHeight, 100)
    end
    if width <= 0 or height <= 0 then return end

    local count = math.max(2, math.min(120, math.floor(width), math.floor(GraphStyle.number(self.Config.HistoryCount, 10))))
    if data == nil then
        data = {}
    elseif type(data) ~= 'table' then
        data = { line = data }
    end

    for key, _ in pairs(data) do
        self.Data[key] = self.Data[key] or {}
        self.Lines[key] = self.Lines[key] or self.Config.Graph
    end

    local keys = {}
    for key, history in pairs(self.Data) do
        history[#history + 1] = GraphStyle.number(data[key], 0)
        while #history > count do table.remove(history, 1) end
        keys[#keys + 1] = key
    end

    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    cairo_save(cr)

    GraphStyle.frame(cr, x, y, width, height, self.Config)
    GraphStyle.grid(cr, x, y, width, height, self.Config)

    local series = {}
    for _, key in ipairs(keys) do
        local history = self.Data[key]
        local style = self.Lines[key] or self.Config.Graph
        local scale = GraphStyle.number(style.Scale, 100)
        if scale <= 0 then
            scale = 100
        end
        local lw = GraphStyle.clamp(GraphStyle.number(style.LineWidth, 1), 0, math.min(width, height))
        local dot = style.ShowLastPoint ~= false and self.Config.ShowLastPoint ~= false and lw > 0
        local inset = math.min(math.min(width, height) / 2, math.max(lw / 2, dot and math.max(2, lw * 1.4) or 0))
        local left, right = x + inset, x + width - inset
        local top, bottom = y + inset, y + height - inset
        local step = (right - left) / (count - 1)
        local points = {}
        for i, value in ipairs(history) do
            points[i] = { right - (#history - i) * step, bottom - (bottom - top) * GraphStyle.clamp(value / scale, 0, 1) }
        end

        series[#series + 1] = { points = points, style = style, lw = lw, dot = dot }
        if style.Background and #points > 1 then
            cairo_new_path(cr)
            cairo_move_to(cr, points[1][1], y + height)
            for _, p in ipairs(points) do
                cairo_line_to(cr, p[1], p[2])
            end
            cairo_line_to(cr, points[#points][1], y + height); cairo_close_path(cr)
            if self.Config.Gradient ~= false and style.Gradient ~= false then
                GraphStyle.gradient(cr, x, y, x, y + height, style.Background, nil, true)
            else
                Draw:Color(cr, style.Background)
            end
            cairo_fill(cr)
        end
    end

    -- Draw all strokes above all fills.
    for _, s in ipairs(series) do
        if s.style.LineColor and s.lw > 0 and #s.points > 0 then
            cairo_new_path(cr); cairo_move_to(cr, s.points[1][1], s.points[1][2])
            for i = 2, #s.points do
                cairo_line_to(cr, s.points[i][1], s.points[i][2])
            end
            Draw:Color(cr, s.style.LineColor)
            cairo_set_line_width(cr, s.lw)
            cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND)
            cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
            cairo_stroke(cr)
            if s.dot then
                local last = s.points[#s.points]
                cairo_new_path(cr); cairo_arc(cr, last[1], last[2], math.max(2, s.lw * 1.4), 0, 2 * math.pi); cairo_fill(cr)
            end
        end
    end
    cairo_restore(cr)
    cairo_save(cr); GraphStyle.border(cr, x, y, width, height, self.Config); cairo_restore(cr)
    return y + height
end
