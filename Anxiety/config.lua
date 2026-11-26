-- set new theme here
-- Themes are defined in /lua/customizable/themes/
local ThemeFile = "theme_nebula.lua"

-- set language here
-- new langauges can be added in /lua/customizable/language/
local LanguageFile = "default.lua"

-- Copy nested style tables so changes to Config cannot alter Theme.
local function copyStyle(style)
    local copy = {}
    for key, value in pairs(style) do
        if type(value) == "table" then
            copy[key] = copyStyle(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- Load the theme from the same directory as this file.
local configPath = debug.getinfo(1, "S").source:sub(2)
local configDirectory = configPath:match("^(.*[/])") or ""

Config = {}

-- Conky language
Config.Locale = dofile(configDirectory .. "customizable/language/" .. LanguageFile)

-- Conky Theme
Config.Theme = dofile(configDirectory .. "customizable/themes/" .. ThemeFile)

-- Videocard name
-- nil meens Determine automatically
Config.VideoCard = nil

-- Partitions to be displayed
Config.Partitions = {
    "/",
    "/mnt/zusatz",
    "/mnt/backup"
}

-- Network interface
Config.Network = {}
Config.Network.Interface = "eno1"                  -- network interface to display, must be found in /proc/net/dev
Config.Network.DownloadMaxBytePerSecond = 39321600 -- maximum download speed in bytes per second (maximum of the download network graph)
Config.Network.UploadMaxBytesPerSecond = 19660800  -- maximum upload speed in bytes per second (maximum of the upload network graph)

-- Window appearance
Config.Colors = copyStyle(Theme.Colors)        -- colors used in the window
Config.BackgroundImage = Theme.BackgroundImage -- use a background image (or nil if not)
Config.MarginY = Theme.MarginY                 -- vertical margin of the upper edge the window
Config.MarginX = Theme.MarginX                 -- horizontal margin of right and left edge the window
Config.Padding = Theme.Padding                 -- default padding of the window and some elements

-- Typography
Config.Clock = copyStyle(Theme.Clock)   -- clock widget styles
Config.Date = copyStyle(Theme.Date)     -- date widget styles
Config.Header = copyStyle(Theme.Header) -- styles for widget headers (eg 'CPU', 'Memory', etc)
Config.Text = copyStyle(Theme.Text)     -- styles for widget texts

-- Graph appearance and data settings
Config.LineGraph = copyStyle(Theme.LineGraph)                                -- default styles for line graphs
Config.LineGraph.HistoryCount = 90                                           -- how many data points will be shown in line graph by default
Config.LineGraph.Graph.Scale = 100                                           -- maximum amount of y axis values in line graph by default

Config.PieGraph = copyStyle(Theme.PieGraph)                                  -- default styles for pie graphs
Config.PieGraph.Graph.Scale = 100                                            -- maximum amount of y axis values in pie graph by default

Config.BarGraph = copyStyle(Theme.BarGraph)                                  -- default styles for bar graphs
Config.BarGraph.Graph.Scale = 100                                            -- maximum amount of y axis values in bar graph by default

Config.NetworkGraph = copyStyle(Theme.NetworkGraph)                          -- default styles for network graphs
Config.NetworkGraph.Download.Scale = Config.Network.DownloadMaxBytePerSecond -- maximum amount of y axis values in network graph by default
Config.NetworkGraph.Upload.Scale = Config.Network.UploadMaxBytesPerSecond    -- maximum amount of y axis values in network graph by default
