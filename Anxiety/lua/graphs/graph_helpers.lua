-- Append to draw.lua, or load after draw.lua and before drawing graphs.
GraphStyle = {}
local S = GraphStyle
function S.number(value, fallback)
    if type(value) ~= "number" and type(value) ~= "string" then return fallback end
    local n = tonumber(value)
    if not n or n ~= n or math.abs(n) == math.huge then return fallback end
    return n
end

function S.clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

function S.rounded(cr, x, y, w, h, radius)
    local r = S.clamp(radius or 0, 0, math.min(w, h) / 2)
    cairo_new_path(cr)
    if r == 0 then
        cairo_rectangle(cr, x, y, w, h); return
    end
    cairo_arc(cr, x + w - r, y + r, r, -math.pi / 2, 0)
    cairo_arc(cr, x + w - r, y + h - r, r, 0, math.pi / 2)
    cairo_arc(cr, x + r, y + h - r, r, math.pi / 2, math.pi)
    cairo_arc(cr, x + r, y + r, r, math.pi, math.pi * 1.5)
    cairo_close_path(cr)
end

function S.gradient(cr, x1, y1, x2, y2, color1, color2, fade)
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

function S.frame(cr, x, y, w, h, c)
    S.rounded(cr, x, y, w, h, S.number(c.Radius, 5))
    if c.Background then
        Draw:Color(cr, c.Background); cairo_fill_preserve(cr)
    end
    cairo_clip(cr)
end

function S.border(cr, x, y, w, h, c)
    local b = c.Border or {}
    local lw = S.clamp(S.number(b.LineWidth, 0), 0, math.min(w, h))
    if lw <= 0 or not b.Color then return end
    S.rounded(cr, x + lw / 2, y + lw / 2, w - lw, h - lw, math.max(0, S.number(c.Radius, 5) - lw / 2))
    Draw:Color(cr, b.Color); cairo_set_line_width(cr, lw); cairo_stroke(cr)
end

function S.grid(cr, x, y, w, h, c)
    local g = c.Grid or {}
    local lw = S.number(g.LineWidth, 0)
    if lw <= 0 or not g.Color then return end
    local nx = S.clamp(math.floor(S.number(g.PartsX, 0)), 0, 120)
    local ny = S.clamp(math.floor(S.number(g.PartsY, 0)), 0, 120)
    cairo_new_path(cr)
    for i = 1, nx - 1 do
        local p = x + w * i / nx; cairo_move_to(cr, p, y); cairo_line_to(cr, p, y + h)
    end
    for i = 1, ny - 1 do
        local p = y + h * i / ny; cairo_move_to(cr, x, p); cairo_line_to(cr, x + w, p)
    end
    Draw:Color(cr, g.Color); cairo_set_line_width(cr, lw); cairo_stroke(cr)
end
