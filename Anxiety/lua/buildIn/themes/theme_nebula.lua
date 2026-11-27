local colors = {
    Background = "#080F1C",
    Surface = "#101D2E",
    Border = "#28445E",
    Cyan = "#55E6FF",
    Blue = "#4788F5",
    Violet = "#B49AFF",
    Text = "#E1EFFA",
    Muted = "FF9BABB8",
    Amber = "FFFA9614"
}

local headerFont = "DejaVu Sans"
local dataFont = "DejaVu Sans Mono"

Theme = {
    Colors = colors,
    BackgroundImage = nil,
    MarginX = 10,
    MarginY = 10,
    Padding = 3,

    Clock = _ENV.font("EP Boxi", 40, colors.Cyan, false),
    Date = _ENV.font(headerFont, 16, colors.Muted, false),
    Header = _ENV.font(headerFont, 20, colors.Cyan, true),
    Text = {
        Label = _ENV.font(headerFont, 14, colors.Muted, false),
        Info = _ENV.font(dataFont, 14, colors.Text, false),
        Special = _ENV.font(dataFont, 15, colors.Violet, true),
        Large = _ENV.font(dataFont, 17, colors.Text, true)
    },

    LineGraph = {
        DefaultHeight = 100,
        Background = "#101D2ECC",
        Radius = 6,
        Gradient = true,
        ShowLastPoint = true,
        Graph = {
            LineColor = colors.Cyan,
            LineWidth = 1.5,
            Background = "#55E6FF40"
        },
        Border = {
            Color = colors.Border,
            LineWidth = 0.7
        },
        Grid = {
            Color = "#92AEC425",
            LineWidth = 0.5,
            PartsX = 6,
            PartsY = 3
        }
    },

    PieGraph = {
        DefaultSize = 100,
        Background = "#00000060",
        PaddingPercent = 5,
        Graph = {
            Color = colors.Blue,
            EndColor = colors.Cyan,
            EmptyColor = "#20334A",
            BarWidthPercent = 24,
            PaddingPercent = 5,
            StartAngle = -90,
            ShowValue = false,
            Label = _ENV.font(dataFont, 12, colors.Muted, false),
            ValueFont = _ENV.font(dataFont, 16, colors.Text, true)
        },
        Border = {
            Color = "#007000",
            LineWidth = 0
        },
        Grid = {
            Color = "#CCCCCC30",
            LineWidth = 1,
            PartsX = 5
        }
    },

    BarGraph = {
        DefaultHeight = 15,
        Background = "#182A40",
        Radius = 5,
        Graph = {
            Color = colors.Blue,
            EndColor = colors.Cyan
        },
        Border = {
            Color = colors.Border,
            LineWidth = 0.6
        },
        Grid = {
            Color = "#CCCCCC30",
            LineWidth = 0,
            PartsX = 5
        }
    },

    NetworkGraph = {
        Download = {
            LineColor = colors.Cyan,
            LineWidth = 1.6,
            Background = "#55E6FF48"
        },
        Upload = {
            LineColor = colors.Violet,
            LineWidth = 1.6,
            Background = "#B49AFF48"
        }
    }
}

return Theme
