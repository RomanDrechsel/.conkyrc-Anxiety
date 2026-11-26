LineGraph = {}
LineGraph.__index = LineGraph

function LineGraph:new(config, width, height)
    local o = setmetatable({ Data = {}, Lines = {}, Width = width, Height = height }, self)
    o:setConfig(config or Config.LineGraph)
    return o
end

function LineGraph:setConfig(config)
    self.Config = table_copy(config or {})
    local c = self.Config
    c.Graph = c.Graph or {}; c.Border = c.Border or {}; c.Grid = c.Grid or {}
    c.Graph.Scale = c.Graph.Scale or 100
end

function LineGraph:Draw(cr, x, y, data)
    local S = GraphStyle
    local c = self.Config
    if data == nil and next(self.Data) == nil then return end
    local w = S.number(self.Width, conky_window.width - x - Config.MarginX)
    if w < 0 then w = conky_window.width - x - Config.MarginX end
    local h = S.number(self.Height, 0)
    if h <= 0 then h = S.number(c.DefaultHeight, 100) end
    if w <= 0 or h <= 0 then return end
    local count = math.max(2, math.min(120, math.floor(w), math.floor(S.number(c.HistoryCount, 10))))
    if data == nil then data = {} elseif type(data) ~= 'table' then data = { line = data } end
    for key, _ in pairs(data) do
        self.Data[key] = self.Data[key] or {}
        self.Lines[key] = self.Lines[key] or c.Graph
    end
    local keys = {}
    for key, history in pairs(self.Data) do
        history[#history + 1] = S.number(data[key], 0)
        while #history > count do table.remove(history, 1) end
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    cairo_save(cr)
    S.frame(cr, x, y, w, h, c)
    S.grid(cr, x, y, w, h, c)
    local series = {}
    for _, key in ipairs(keys) do
        local history = self.Data[key]
        local style = self.Lines[key] or c.Graph
        local scale = S.number(style.Scale, 100)
        if scale <= 0 then scale = 100 end
        local lw = S.clamp(S.number(style.LineWidth, 1), 0, math.min(w, h))
        local dot = style.ShowLastPoint ~= false and c.ShowLastPoint ~= false and lw > 0
        local inset = math.min(math.min(w, h) / 2, math.max(lw / 2, dot and math.max(2, lw * 1.4) or 0))
        local left, right = x + inset, x + w - inset
        local top, bottom = y + inset, y + h - inset
        local step = (right - left) / (count - 1)
        local points = {}
        for i, value in ipairs(history) do
            points[i] = { right - (#history - i) * step, bottom - (bottom - top) * S.clamp(value / scale, 0, 1) }
        end
        series[#series + 1] = { points = points, style = style, lw = lw, dot = dot }
        if style.Background and #points > 1 then
            cairo_new_path(cr)
            cairo_move_to(cr, points[1][1], y + h)
            for _, p in ipairs(points) do cairo_line_to(cr, p[1], p[2]) end
            cairo_line_to(cr, points[#points][1], y + h); cairo_close_path(cr)
            if c.Gradient ~= false and style.Gradient ~= false then
                S.gradient(cr, x, y, x, y + h, style.Background, nil, true)
            else
                Draw:Color(cr, style.Background)
            end
            cairo_fill(cr)
        end
    end
    -- Draw all strokes above all fills.
    for _, s in ipairs(series) do
        local p, style = s.points, s.style
        if style.LineColor and s.lw > 0 and #p > 0 then
            cairo_new_path(cr); cairo_move_to(cr, p[1][1], p[1][2])
            for i = 2, #p do cairo_line_to(cr, p[i][1], p[i][2]) end
            Draw:Color(cr, style.LineColor)
            cairo_set_line_width(cr, s.lw)
            cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND)
            cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
            cairo_stroke(cr)
            if s.dot then
                local last = p[#p]
                cairo_new_path(cr); cairo_arc(cr, last[1], last[2], math.max(2, s.lw * 1.4), 0, 2 * math.pi); cairo_fill(
                    cr)
            end
        end
    end
    cairo_restore(cr)
    cairo_save(cr); S.border(cr, x, y, w, h, c); cairo_restore(cr)
    return y + h
end
