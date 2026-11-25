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
    local r = S.clamp(radius or 0, 0, math.min(w,h)/2)
    cairo_new_path(cr)
    if r == 0 then cairo_rectangle(cr,x,y,w,h); return end
    cairo_arc(cr,x+w-r,y+r,r,-math.pi/2,0)
    cairo_arc(cr,x+w-r,y+h-r,r,0,math.pi/2)
    cairo_arc(cr,x+r,y+h-r,r,math.pi/2,math.pi)
    cairo_arc(cr,x+r,y+r,r,math.pi,math.pi*1.5)
    cairo_close_path(cr)
end
function S.gradient(cr, x1,y1,x2,y2,color1,color2,fade)
    local p = cairo_pattern_create_linear(x1,y1,x2,y2)
    local r,g,b,a = hexToRGBA(color1)
    cairo_pattern_add_color_stop_rgba(p,0,r,g,b,a)
    if fade then
        cairo_pattern_add_color_stop_rgba(p,1,r,g,b,0)
    else
        r,g,b,a = hexToRGBA(color2 or color1)
        cairo_pattern_add_color_stop_rgba(p,1,r,g,b,a)
    end
    cairo_set_source(cr,p)
    cairo_pattern_destroy(p)
end
function S.frame(cr,x,y,w,h,c)
    S.rounded(cr,x,y,w,h,S.number(c.Radius,5))
    if c.Background then Draw:Color(cr,c.Background); cairo_fill_preserve(cr) end
    cairo_clip(cr)
end
function S.border(cr,x,y,w,h,c)
    local b=c.Border or {}
    local lw=S.clamp(S.number(b.LineWidth,0),0,math.min(w,h))
    if lw<=0 or not b.Color then return end
    S.rounded(cr,x+lw/2,y+lw/2,w-lw,h-lw,math.max(0,S.number(c.Radius,5)-lw/2))
    Draw:Color(cr,b.Color); cairo_set_line_width(cr,lw); cairo_stroke(cr)
end
function S.grid(cr,x,y,w,h,c)
    local g=c.Grid or {}
    local lw=S.number(g.LineWidth,0)
    if lw<=0 or not g.Color then return end
    local nx=S.clamp(math.floor(S.number(g.PartsX,0)),0,120)
    local ny=S.clamp(math.floor(S.number(g.PartsY,0)),0,120)
    cairo_new_path(cr)
    for i=1,nx-1 do local p=x+w*i/nx; cairo_move_to(cr,p,y); cairo_line_to(cr,p,y+h) end
    for i=1,ny-1 do local p=y+h*i/ny; cairo_move_to(cr,x,p); cairo_line_to(cr,x+w,p) end
    Draw:Color(cr,g.Color); cairo_set_line_width(cr,lw); cairo_stroke(cr)
end
-- Preserve the caller's transformation and source.
function Draw:Background(cr,image)
    if not cr or not image then return end
    local w,h=cairo_image_surface_get_width(image),cairo_image_surface_get_height(image)
    if w<=0 or h<=0 then return end
    cairo_save(cr)
    cairo_scale(cr,conky_window.width/w,conky_window.height/h)
    cairo_set_source_surface(cr,image,0,0)
    cairo_paint(cr)
    cairo_restore(cr)
end
function Draw:Text(cr,text,x,y)
    text=tostring(text or '')
    local extents=cairo_text_extents_t:create()
    cairo_text_extents(cr,text,extents)
    y=y+getFontHeight(cr)
    cairo_new_path(cr)
    cairo_move_to(cr,x,y)
    cairo_show_text(cr,text)
    cairo_new_path(cr)
    return x+extents.x_advance,y
end
function Draw:PointText(cr,text,cx,cy)
    text=tostring(text or '')
    local extents=cairo_text_extents_t:create()
    cairo_text_extents(cr,text,extents)
    local x=cx-extents.width/2
    local y=cy-getFontHeight(cr)/2
    return self:Text(cr,text,x,y)
end
