PieGraph = {}
PieGraph.__index = PieGraph

function PieGraph:new(config, width, height)
    local o = setmetatable({ Data = {} }, self)
    o:setConfig(config or Config.PieGraph)
    o.Width = width or o.Config.DefaultSize or 100
    o.Height = height or o.Width
    return o
end

function PieGraph:setConfig(config)
    self.Config = table_copy(config or Config.PieGraph or {})
    self.Config.Graph = self.Config.Graph or {}
end

function PieGraph:Draw(cr, x, y, data, label)
    local S = GraphStyle
    local c = self.Config
    local g = c.Graph or {}
    local w, h = S.number(self.Width, 0), S.number(self.Height, 0)

    if w <= 0 or h <= 0 or not g.Color then
        return
    end

    local size = math.min(w, h) * (1 - S.clamp(S.number(c.PaddingPercent, 5), 0, 95) / 100)
    local radius = size / 2
    local thickness = radius * S.clamp(S.number(g.BarWidthPercent, 22), 1, 100) / 100
    local r = radius - thickness / 2
    self.Radius, self.BarWidth = radius, thickness
    local cx, cy = x + w / 2, y + h / 2
    local scale = S.number(g.Scale, 100)

    if scale <= 0 then
        scale = 100
    end

    local value = S.number(data, 0)
    local fraction = S.clamp(value / scale, 0, 1)
    local start = math.rad(S.number(g.StartAngle, -90))
    cairo_save(cr)
    cairo_set_line_width(cr, thickness)
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
    if g.EmptyColor then
        cairo_new_path(cr); cairo_arc(cr, cx, cy, r, 0, 2 * math.pi)
        Draw:Color(cr, g.EmptyColor); cairo_stroke(cr)
    end
    if fraction > 0 then
        cairo_new_path(cr)
        cairo_arc(cr, cx, cy, r, start, start + 2 * math.pi * fraction)
        if g.EndColor then
            S.gradient(cr, cx - radius, cy - radius, cx + radius, cy + radius, g.Color, g.EndColor)
        else
            Draw:Color(cr, g.Color)
        end
        cairo_stroke(cr)
    end
    local b = c.Border or {}
    local bw = S.clamp(S.number(b.LineWidth, 0), 0, thickness)
    if bw > 0 and b.Color then
        Draw:Color(cr, b.Color); cairo_set_line_width(cr, bw)
        cairo_new_path(cr); cairo_arc(cr, cx, cy, radius - bw / 2, 0, 2 * math.pi); cairo_stroke(cr)
        if radius - thickness > bw / 2 then
            cairo_new_path(cr); cairo_arc(cr, cx, cy, radius - thickness + bw / 2, 0, 2 * math.pi); cairo_stroke(cr)
        end
    end
    if g.ShowValue then
        Draw:Font(cr, g.ValueFont or g.Label)
        local text = string.format('%.0f%%', fraction * 100)
        local ext = cairo_text_extents_t:create(); cairo_text_extents(cr, text, ext)
        cairo_new_path(cr); cairo_move_to(cr, cx - ext.width / 2 - ext.x_bearing, cy - ext.height / 2 - ext.y_bearing); cairo_show_text(
        cr, text); cairo_new_path(cr)
    end
    if label ~= nil then
        if type(label) ~= 'table' then label = { label } end
        Draw:Font(cr, g.Label)
        for i, line in ipairs(label) do
            Draw:PointText(cr, line, cx, cy + radius * 1.4 + GetFontHeight(cr) * (i - 1))
        end
    end
    cairo_restore(cr)
    return y + h
end
