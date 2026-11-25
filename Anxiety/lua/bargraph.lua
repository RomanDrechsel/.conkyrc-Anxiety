BarGraph={}
BarGraph.__index=BarGraph
function BarGraph:new(config,height)
    local o=setmetatable({},self)
    o:setConfig(config or Config.BarGraph)
    o.Height=height or o.Config.DefaultHeight
    return o
end
function BarGraph:setConfig(config)
    self.Config=table_copy(config or {})
end
function BarGraph:Draw(cr,x,y,data)
    local S=GraphStyle
    local c=self.Config
    local g=c.Graph or {}
    local w=conky_window.width-x-Config.MarginX
    local h=S.number(self.Height,0)
    if w<=0 or h<=0 then return end
    local scale=S.number(g.Scale,100)
    if scale<=0 then scale=100 end
    local fill=w*S.clamp(S.number(data,0)/scale,0,1)
    cairo_save(cr)
    S.frame(cr,x,y,w,h,c)
    if fill>0 and g.Color then
        S.rounded(cr,x,y,fill,h,S.number(c.Radius,5))
        if g.EndColor then S.gradient(cr,x,y,x+fill,y,g.Color,g.EndColor)
        else Draw:Color(cr,g.Color) end
        cairo_fill(cr)
    end
    S.grid(cr,x,y,w,h,c)
    cairo_restore(cr)
    cairo_save(cr); S.border(cr,x,y,w,h,c); cairo_restore(cr)
    return y+h
end
