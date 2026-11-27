BarGraph = {}
BarGraph.__index = BarGraph
function BarGraph:new(config, height)
    local graph = setmetatable({}, self)
    graph:setConfig(config or Config.BarGraph)
    graph.Height = height or graph.Config.DefaultHeight
    return graph
end

function BarGraph:setConfig(config)
    self.Config = TableCopy(config or {})
end

function BarGraph:Draw(cr, x, y, data)
    local graph = self.Config.Graph or {}
    local width = conky_window.width - x - Config.MarginX
    local height = GraphStyle.number(self.Height, 0)
    if width <= 0 or height <= 0 then
        return
    end

    local scale = GraphStyle.number(graph.Scale, 100)
    if scale <= 0 then
        scale = 100
    end

    local fill = width * GraphStyle.clamp(GraphStyle.number(data, 0) / scale, 0, 1)
    cairo_save(cr)

    GraphStyle.frame(cr, x, y, width, height, self.Config)

    if fill > 0 and graph.Color then
        GraphStyle.rounded(cr, x, y, fill, height, GraphStyle.number(self.Config.Radius, 5))
        if graph.EndColor then
            GraphStyle.gradient(cr, x, y, x + fill, y, graph.Color, graph.EndColor)
        else
            Draw:Color(cr, graph.Color)
        end
        cairo_fill(cr)
    end

    GraphStyle.grid(cr, x, y, width, height, self.Config)
    cairo_restore(cr)
    cairo_save(cr); GraphStyle.border(cr, x, y, width, height, self.Config); cairo_restore(cr)

    return y + height
end
