local function font(family, size, color, bold)
    return { FontFamily = family, FontSize = size, FontColor = color, Bold = bold }
end

local colors = {
    Background = "#080F1C",
    Surface = "#101D2E",
    Border = "#28445E",
    Cyan = "#55E6FF",
    Blue = "#4788F5",
    Violet = "#B49AFF",
    Text = "#E1EFFA",
    Muted = "#9BABB8",
    Amber = "#FA9614"
}

local headerFont = "DejaVu Sans"
local dataFont = "DejaVu Sans Mono"

return {
    Language = "en",
    Theme = "theme_nebula",
    Partitions = { "/" },
    Network = {
        Interface = "eno1",
        DownloadMaxBytesPerSecond = 39321600,
        UploadMaxBytesPerSecond = 19660800
    },
    VideoCard = nil,
    AMDGPUAddress = nil,
    Colors = colors,
    BackgroundImage = nil,
    MarginX = 10,
    MarginY = 10,
    Padding = 6,

    Clock = font("EP Boxi", 40, colors.Cyan, false),
    Date = font(headerFont, 16, colors.Muted, false),
    Header = font(headerFont, 20, colors.Cyan, true),
    Text = {
        Label = font(headerFont, 14, colors.Muted, false),
        Info = font(dataFont, 14, colors.Text, false),
        Special = font(dataFont, 15, colors.Violet, true),
        Large = font(dataFont, 17, colors.Text, true)
    },

    LineGraph = {
        HistoryCount = 90,
        DefaultHeight = 100,
        Background = "#101D2ECC",
        Radius = 6,
        Gradient = true,
        ShowLastPoint = true,
        Graph = {
            Scale = 100,
            LineColor = colors.Cyan,
            LineWidth = 1.5,
            Background = "#55E6FF40",
            ShowLine = false
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
            Scale = 100,
            Color = colors.Blue,
            EndColor = colors.Cyan,
            EmptyColor = "#20334A",
            FillColor = "#4788F540",
            BarWidthPercent = 24,
            PaddingPercent = 5,
            StartAngle = -90,
            ShowValue = false,
            Label = font(dataFont, 12, colors.Muted, false),
            ValueFont = font(dataFont, 16, colors.Text, true)
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
            Scale = 100,
            Color = colors.Blue,
            FillColor = "#4788F540",
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
