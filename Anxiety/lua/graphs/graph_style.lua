GraphStyle = {}

function GraphStyle.number(value, fallback)
    if type(value) ~= "number" and type(value) ~= "string" then
        return fallback
    end

    local n = tonumber(value)
    if not n or n ~= n or math.abs(n) == math.huge then
        return fallback
    end

    return n
end

function GraphStyle.clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

function GraphStyle.rounded(cr, x, y, width, height, radius)
    local r = GraphStyle.clamp(radius or 0, 0, math.min(width, height) / 2)
    cairo_new_path(cr)

    if r == 0 then
        cairo_rectangle(cr, x, y, width, height)
        return
    end

    cairo_arc(cr, x + width - r, y + r, r, -math.pi / 2, 0)
    cairo_arc(cr, x + width - r, y + height - r, r, 0, math.pi / 2)
    cairo_arc(cr, x + r, y + height - r, r, math.pi / 2, math.pi)
    cairo_arc(cr, x + r, y + r, r, math.pi, math.pi * 1.5)
    cairo_close_path(cr)
end

function GraphStyle.gradient(cr, x1, y1, x2, y2, color1, color2, fade)
    local p = cairo_pattern_create_linear(x1, y1, x2, y2)
    local r, g, b, a = HexToRGBA(color1)
    cairo_pattern_add_color_stop_rgba(p, 0, r, g, b, a)

    if fade then
        cairo_pattern_add_color_stop_rgba(p, 1, r, g, b, 0)
    else
        r, g, b, a = HexToRGBA(color2 or color1)
        cairo_pattern_add_color_stop_rgba(p, 1, r, g, b, a)
    end

    cairo_set_source(cr, p)
    cairo_pattern_destroy(p)
end

function GraphStyle.frame(cr, x, y, width, hheight, graph_config)
    GraphStyle.rounded(cr, x, y, width, hheight, GraphStyle.number(graph_config.Radius, 5))
    if graph_config.Background then
        Draw:Color(cr, graph_config.Background); cairo_fill_preserve(cr)
    end
    cairo_clip(cr)
end

function GraphStyle.border(cr, x, y, width, height, graph_config)
    local border = graph_config.Border or {}
    local lw = GraphStyle.clamp(GraphStyle.number(border.LineWidth, 0), 0, math.min(width, height))
    if lw <= 0 or not border.Color then
        return
    end
    GraphStyle.rounded(cr, x + lw / 2, y + lw / 2, width - lw, height - lw, math.max(0, GraphStyle.number(graph_config.Radius, 5) - lw / 2))
    Draw:Color(cr, border.Color); cairo_set_line_width(cr, lw); cairo_stroke(cr)
end

function GraphStyle.grid(cr, x, y, width, height, graph_config)
    local g = graph_config.Grid or {}
    local lw = GraphStyle.number(g.LineWidth, 0)
    if lw <= 0 or not g.Color then return end
    local nx = GraphStyle.clamp(math.floor(GraphStyle.number(g.PartsX, 0)), 0, 120)
    local ny = GraphStyle.clamp(math.floor(GraphStyle.number(g.PartsY, 0)), 0, 120)
    cairo_new_path(cr)
    for i = 1, nx - 1 do
        local p = x + width * i / nx; cairo_move_to(cr, p, y); cairo_line_to(cr, p, y + height)
    end
    for i = 1, ny - 1 do
        local p = y + height * i / ny; cairo_move_to(cr, x, p); cairo_line_to(cr, x + width, p)
    end
    Draw:Color(cr, g.Color); cairo_set_line_width(cr, lw); cairo_stroke(cr)
end
