-- Anxiety / Nebula: load after draw and before all graph and hardware modules.
local palette = {
    Background = '#080F1C', Surface = '#101D2E', Border = '#28445E',
    Cyan = '#55E6FF', Blue = '#4788F5', Violet = '#B49AFF',
    Text = '#E1EFFA', Muted = '#92AEC4', Amber = '#FFBE69'
}

local function font(family, size, color, bold)
    return {FontFamily=family, FontSize=size, FontColor=color, Bold=bold}
end

local function apply(target, values)
    for key, value in pairs(values) do target[key] = value end
end

Config.Nebula = {
    Palette = palette,
    UseOriginalBackground = false,
    HeaderFont = 'DejaVu Sans',
    DataFont = 'DejaVu Sans Mono',
    ClockFont = 'EP Boxi'
}
local theme = Config.Nebula
Config.Clock = font(theme.ClockFont, 40, palette.Cyan, false)
Config.Date = font(theme.HeaderFont, 16, palette.Muted, false)
Config.Header = font(theme.HeaderFont, 20, palette.Cyan, true)
Config.Text.Label = font(theme.HeaderFont, 13, palette.Muted, false)
Config.Text.Info = font(theme.DataFont, 13, palette.Text, false)
Config.Text.Special = font(theme.DataFont, 15, palette.Violet, true)
Config.Text.Large = font(theme.DataFont, 17, palette.Text, true)
Config.MarginX = 10
Config.MarginY = 10
Config.Padding = 3

local line = Config.LineGraph
apply(line, {Radius=6, Gradient=true, ShowLastPoint=true, Background='#101D2ECC'})
apply(line.Graph, {LineColor=palette.Cyan, LineWidth=1.5, Background='#55E6FF40'})
apply(line.Border, {Color=palette.Border, LineWidth=0.7})
apply(line.Grid, {Color='#92AEC425', LineWidth=0.5})
local bar = Config.BarGraph
apply(bar, {Radius=5, Background='#182A40'})
apply(bar.Graph, {Color=palette.Blue, EndColor=palette.Cyan})
apply(bar.Border, {Color=palette.Border, LineWidth=0.6})
bar.Grid.LineWidth = 0
local pie = Config.PieGraph
apply(pie.Graph, {Color=palette.Blue, EndColor=palette.Cyan, EmptyColor='#20334A',
    BarWidthPercent=24, StartAngle=-90, ShowValue=false,
    Label=font(theme.DataFont, 12, palette.Muted, false),
    ValueFont=font(theme.DataFont, 16, palette.Text, true)})
pie.Border.LineWidth = 0
apply(Config.NetworkGraph.Download, {LineColor=palette.Cyan, LineWidth=1.6, Background='#55E6FF48'})
apply(Config.NetworkGraph.Upload, {LineColor=palette.Violet, LineWidth=1.6, Background='#B49AFF48'})

-- A restrained HUD background, independent of image dimensions.
local originalBackground = Draw.Background
if not theme.UseOriginalBackground then
    Config.BackgroundImage = nil
end

function Draw:Background(cr, image)
    if theme.UseOriginalBackground then
        return originalBackground(self, cr, image)
    end

    local w, h = conky_window.width, conky_window.height
    if w <= 0 or h <= 0 then
        return
    end

    cairo_save(cr)
    local p = cairo_pattern_create_linear(0, 0, w, h)
    cairo_pattern_add_color_stop_rgba(p, 0, 0.055, 0.10, 0.17, 1)
    cairo_pattern_add_color_stop_rgba(p, 1, 0.025, 0.045, 0.085, 1)
    cairo_set_source(cr, p)
    cairo_pattern_destroy(p)
    cairo_paint(cr)
    self:Color(cr, '#55E6FF40')
    cairo_new_path(cr)
    cairo_rectangle(cr, 0, 0, 2, h)
    cairo_fill(cr)
    cairo_restore(cr)
end

-- Preserve the existing Header return contract and vertical spacing.
function Draw:Header(cr, text, y)
    y = y + 3 * Config.Padding
    local left = Config.MarginX
    local right = conky_window.width - Config.MarginX
    cairo_save(cr)
    self:Font(cr, Config.Header)
    local x, bottom = self:Text(cr, tostring(text or ''), left + 9, y)
    self:Color(cr, palette.Cyan)
    cairo_new_path(cr)
    cairo_rectangle(cr, left, bottom-10, 3, 10)
    cairo_fill(cr)
    if x + 9 < right then
        local p = cairo_pattern_create_linear(x+9, 0, right, 0)
        cairo_pattern_add_color_stop_rgba(p, 0, 0.33, 0.90, 1, 0.65)
        cairo_pattern_add_color_stop_rgba(p, 1, 0.33, 0.90, 1, 0.06)
        cairo_set_source(cr, p)
        cairo_pattern_destroy(p)
        cairo_new_path(cr)
        cairo_rectangle(cr, x+9, bottom-4, right-x-9, 1)
        cairo_fill(cr)
    end
    cairo_restore(cr)
    return bottom + Config.Padding
end
