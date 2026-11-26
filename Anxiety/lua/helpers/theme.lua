local ThemeHelpers = {}

function ThemeHelpers.font(family, size, color, bold)
    return {
        FontFamily = family,
        FontSize = size,
        FontColor = color,
        Bold = bold
    }
end

return ThemeHelpers
