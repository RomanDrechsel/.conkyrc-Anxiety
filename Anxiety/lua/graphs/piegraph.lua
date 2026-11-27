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
    self.Config = TableCopy(config or Config.PieGraph or {})
    self.Config.Graph = self.Config.Graph or {}
end

function PieGraph:Draw(cr, x, y, data, label)
    local graph = self.Config.Graph or {}
    local width, height = GraphStyle.number(self.Width, 0), GraphStyle.number(self.Height, 0)

    if width <= 0 or height <= 0 or not graph.Color then
        return
    end

    local size = math.min(width, height) * (1 - GraphStyle.clamp(GraphStyle.number(self.Config.PaddingPercent, 5), 0, 95) / 100)
    local radius = size / 2
    local thickness = radius * GraphStyle.clamp(GraphStyle.number(graph.BarWidthPercent, 22), 1, 100) / 100
    local r = radius - thickness / 2
    self.Radius, self.BarWidth = radius, thickness
    local cx, cy = x + width / 2, y + height / 2
    local scale = GraphStyle.number(graph.Scale, 100)

    if scale <= 0 then
        scale = 100
    end

    local value = GraphStyle.number(data, 0)
    local fraction = GraphStyle.clamp(value / scale, 0, 1)
    local start = math.rad(GraphStyle.number(graph.StartAngle, -90))
    cairo_save(cr)
    cairo_set_line_width(cr, thickness)
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
    if graph.EmptyColor then
        cairo_new_path(cr); cairo_arc(cr, cx, cy, r, 0, 2 * math.pi)
        Draw:Color(cr, graph.EmptyColor); cairo_stroke(cr)
    end
    if fraction > 0 then
        cairo_new_path(cr)
        cairo_arc(cr, cx, cy, r, start, start + 2 * math.pi * fraction)
        if graph.EndColor then
            GraphStyle.gradient(cr, cx - radius, cy - radius, cx + radius, cy + radius, graph.Color, graph.EndColor)
        else
            Draw:Color(cr, graph.Color)
        end
        cairo_stroke(cr)
    end
    local border = self.Config.Border or {}
    local borderWidth = GraphStyle.clamp(GraphStyle.number(border.LineWidth, 0), 0, thickness)
    if borderWidth > 0 and border.Color then
        Draw:Color(cr, border.Color); cairo_set_line_width(cr, borderWidth)
        cairo_new_path(cr); cairo_arc(cr, cx, cy, radius - borderWidth / 2, 0, 2 * math.pi); cairo_stroke(cr)
        if radius - thickness > borderWidth / 2 then
            cairo_new_path(cr); cairo_arc(cr, cx, cy, radius - thickness + borderWidth / 2, 0, 2 * math.pi); cairo_stroke(cr)
        end
    end

    if graph.ShowValue then
        Draw:Font(cr, graph.ValueFont or graph.Label)
        local text = string.format('%.0f%%', fraction * 100)
        local ext = cairo_text_extents_t:create()
        cairo_text_extents(cr, text, ext)
        cairo_new_path(cr); cairo_move_to(cr, cx - ext.width / 2 - ext.x_bearing, cy - ext.height / 2 - ext.y_bearing); cairo_show_text(cr, text); cairo_new_path(cr)
    end
    if label ~= nil then
        if type(label) ~= 'table' then
            label = { label }
        end

        Draw:Font(cr, graph.Label)

        for i, line in ipairs(label) do
            Draw:PointText(cr, line, cx, cy + radius * 1.4 + GetFontHeight(cr) * (i - 1))
        end
    end

    cairo_restore(cr)
    return y + height
end
