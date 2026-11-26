Config = {}

-- Names without the .lua extension. See customizable/languages and customizable/themes.
Config.Language = "de"
Config.Theme = "theme_nebula"

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

-- Graph history and data scales
Config.LineGraph = {
    HistoryCount = 90,
    Graph = { Scale = 100 }
}

Config.PieGraph = {
    Graph = { Scale = 100 }
}

Config.BarGraph = {
    Graph = { Scale = 100 }
}

Config.NetworkGraph = {
    Download = { Scale = Config.Network.DownloadMaxBytePerSecond },
    Upload = { Scale = Config.Network.UploadMaxBytesPerSecond }
}
