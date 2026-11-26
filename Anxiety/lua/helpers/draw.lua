-- https://www.cairographics.org/manual/
-- https://github.com/lutherush/conky/blob/master/conky/pie-ring-text/text.lua

Draw = {}

function Draw:Background(cr, image)
    if not cr or not image then
        return
    end
    local w, h = cairo_image_surface_get_width(image), cairo_image_surface_get_height(image)
    if w <= 0 or h <= 0 then
        return
    end
    cairo_save(cr)
    cairo_scale(cr, conky_window.width / w, conky_window.height / h)
    cairo_set_source_surface(cr, image, 0, 0)
    cairo_paint(cr)
    cairo_restore(cr)
end

function Draw:Text(cr, text, x, y)
    text = tostring(text or '')
    local extents = cairo_text_extents_t:create()
    cairo_text_extents(cr, text, extents)
    y = y + GetFontHeight(cr)
    cairo_new_path(cr)
    cairo_move_to(cr, x, y)
    cairo_show_text(cr, text)
    cairo_new_path(cr)
    return x + extents.x_advance, y
end

function Draw:LeftText(cr, text, y)
    return self:Text(cr, text, Config.MarginX, y)
end

function Draw:CenterText(cr, text, y, offset_x)
    local extents = cairo_text_extents_t:create()
    cairo_text_extents(cr, text, extents)

    if offset_x == nil then
        offset_x = 0
    end

    local x = (conky_window.width / 2) - (extents.width / 2) + offset_x
    return self:Text(cr, text, x, y)
end

function Draw:RightText(cr, text, y, right_x)
    local extents = cairo_text_extents_t:create()
    cairo_text_extents(cr, text, extents)

    if right_x == nil then
        right_x = conky_window.width - Config.MarginX
    end

    local x = right_x - extents.width
    return self:Text(cr, text, x, y)
end

function Draw:PointText(cr, text, cx, cy)
    text = tostring(text or '')
    local extents = cairo_text_extents_t:create()
    cairo_text_extents(cr, text, extents)
    local x = cx - extents.width / 2
    local y = cy - GetFontHeight(cr) / 2
    return self:Text(cr, text, x, y)
end


function Draw:Row(cr, y, text_left, font_left, text_center, font_center, text_right, font_right)
    local bottom = y
    if text_left then
        if font_left then
            Draw:Font(cr, font_left)
        end
        _, bottom = Draw:LeftText(cr, text_left, y)
    end

    if text_center then
        if font_center then
            Draw:Font(cr, font_center)
        end
        local _, b = Draw:CenterText(cr, text_center, y, -30);
        if b > bottom then
            bottom = b
        end
    end

    if text_right then
        if font_right then
            Draw:Font(cr, font_right)
        end
        local _, b = Draw:RightText(cr, text_right, y);
        if b > bottom then
            bottom = b
        end
    end

    return bottom + Config.Padding
end

function Draw:Font(cr, font)
    if font then
        if font.FontFamily then
            local weight = CAIRO_FONT_WEIGHT_NORMAL
            if font.Bold then
                weight = CAIRO_FONT_WEIGHT_BOLD
            end
            cairo_select_font_face(cr, font.FontFamily, CAIRO_FONT_SLANT_NORMAL, weight)
        end
        if font.FontSize then
            cairo_set_font_size(cr, font.FontSize)
        end

        self:Color(cr, font.FontColor)
    end
end

function Draw:Color(cr, color)
    if color then
        local c1, c2, c3, c4 = HexToRGBA(color)
        if c4 >= 1 then
            cairo_set_source_rgb(cr, c1, c2, c3)
        else
            cairo_set_source_rgba(cr, c1, c2, c3, c4)
        end
    end
end

function Draw:Header(cr, text, y)
    y = y + 3 * Config.Padding
    local left = Config.MarginX
    local right = conky_window.width - Config.MarginX
    cairo_save(cr)
    self:Font(cr, Config.Header)
    local x, bottom = self:Text(cr, tostring(text or ''), left + 9, y)
    self:Color(cr, Theme.Colors.Cyan)
    cairo_new_path(cr)
    cairo_rectangle(cr, left, bottom - 10, 3, 10)
    cairo_fill(cr)
    if x + 9 < right then
        local p = cairo_pattern_create_linear(x + 9, 0, right, 0)
        cairo_pattern_add_color_stop_rgba(p, 0, 0.33, 0.90, 1, 0.65)
        cairo_pattern_add_color_stop_rgba(p, 1, 0.33, 0.90, 1, 0.06)
        cairo_set_source(cr, p)
        cairo_pattern_destroy(p)
        cairo_new_path(cr)
        cairo_rectangle(cr, x + 9, bottom - 4, right - x - 9, 1)
        cairo_fill(cr)
    end
    cairo_restore(cr)
    return bottom + Config.Padding
end

function Draw:Line(cr, x1, y1, x2, y2, linewidth, color)
    if linewidth == nil or linewidth <= 0 then
        linewidth = 1
    end

    self:Color(cr, color)

    if x2 < 0 then
        x2 = conky_window.width - Config.MarginX
    end

    cairo_move_to(cr, x1, y1)
    cairo_line_to(cr, x2, y2)
    cairo_set_line_width(cr, linewidth)
    cairo_stroke(cr)
end

function Draw:Rect(cr, x, y, width, height, lineheight, bordercolor)
    if width < 0 then
        width = conky_window.width - x - Config.MarginX
    end

    if lineheight == nil or lineheight <= 0 then
        return
    end

    self:Color(cr, bordercolor)

    cairo_rectangle(cr, x, y, width, height)
    cairo_set_line_width(cr, lineheight)
    cairo_stroke(cr)
end

function Draw:FillRect(cr, x, y, width, height, color)
    if width < 0 then
        width = conky_window.width - x - Config.MarginX
    end

    self:Color(cr, color)
    cairo_rectangle(cr, x, y, width, height)
    cairo_fill(cr)
end

function Draw:Polygon(cr, points, color, linewidth)
    if #points < 4 or linewidth == nil or linewidth <= 0 then
        return
    end

    self:Color(cr, color)

    cairo_move_to(cr, points[1], points[2])

    local i = 3
    while i < #points do
        if i > #points - 1 then
            break
        end

        cairo_line_to(cr, points[i], points[i + 1])
        i = i + 2
    end
    cairo_stroke(cr)
end

function Draw:FillPolygon(cr, points, color)
    if #points < 4 or color == nil then
        return
    end

    self:Color(cr, color)

    cairo_move_to(cr, points[1], points[2])

    local i = 3
    while i < #points do
        if i > #points - 1 then
            break
        end

        cairo_line_to(cr, points[i], points[i + 1])
        i = i + 2
    end
    cairo_fill(cr)
end

function Draw:Circle(cr, cx, cy, r, color, linewidth)
    if linewidth == nil or linewidth <= 0 or r == nil or r <= 0 then
        return
    end

    self:Color(cr, color)
    cairo_arc(cr, cx, cy, r, 0, 2 * math.pi)
    cairo_set_line_width(cr, linewidth)
    cairo_stroke(cr)
end

function Draw:Arc(cr, cx, cy, r, color, linewidth, a_start, a_end)
    if linewidth == nil or linewidth <= 0 or r == nil or r <= 0 then
        return
    end

    self:Color(cr, color)
    cairo_arc_negative(cr, cx, cy, r, a_start, a_end)
    cairo_set_line_width(cr, linewidth)
    cairo_stroke(cr)
end

function TextWidth(cr, texts)
    if type(texts) ~= "table" then
        texts = { texts }
    end

    local width = 0
    for _, t in ipairs(texts) do
        local extents = cairo_text_extents_t:create()
        cairo_text_extents(cr, t, extents)
        if width < extents.x_advance then
            width = extents.x_advance
        end
    end

    return width
end

function HexToRGBA(hex)
    if hex == nil then
        return 1, 1, 1, 1
    end

    hex = hex:gsub("#", "")
    local hexWithoutAlpha = hex:sub(1, 6)
    local alphaHex = hex:sub(7, 8)
    local r = tonumber(hexWithoutAlpha:sub(1, 2), 16) / 255
    local g = tonumber(hexWithoutAlpha:sub(3, 4), 16) / 255
    local b = tonumber(hexWithoutAlpha:sub(5, 6), 16) / 255

    local a = 1
    if isEmpty(alphaHex) == false then
        a = tonumber(alphaHex, 16) / 255
    end

    return r, g, b, a
end

function GetFontHeight(cr)
    local font_extents = cairo_font_extents_t.create()
    cairo_font_extents(cr, font_extents)
    return font_extents.height
end
