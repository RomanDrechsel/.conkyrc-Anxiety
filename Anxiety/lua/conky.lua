--[[

Conky:
https://conky.cc/

]] --

local pwd = debug.getinfo(1, "S").source:sub(2):match("^.*/") or "./"
package.path = pwd .. "?.lua;" .. package.path

JSON = require("helpers.json")
require("helpers.functions")
local root = pwd .. "../"

require('config')
Locale = require("loader.language_loader"):load(root, Config.Language)

local ConfigLoader = require("loader.config_loader")
local configLoader = ConfigLoader:new(pwd .. "buildIn/", pwd .. "../customizable/")
configLoader.Debug = true
Config = configLoader:load()

local themeLoader = require("loader.theme_loader")

Theme = themeLoader:load(root, Config.Theme)
themeLoader:apply(Config, Theme)

Config = configLoader:finalize(Config)

print("[Anxiety] Using localization: '" .. Config.Language .. "'")
print("[Anxiety] Using theme: '" .. Config.Theme .. "'")

require('cairo')
CacheDir = HomePath() .. ".cache/conky/Anxiety/"

require('helpers.timer')
require('helpers.draw')
require("helpers.sensors")
require('graphs.graph_style')
require('graphs.linegraph')
require('graphs.piegraph')
require('graphs.bargraph')
require('widgets.clock')
require('widgets.system')
require("widgets.gpu_nvidia")
require("widgets.cpu")
require("widgets.harddisk")
require("widgets.ram")
require("widgets.network")
require("widgets.processes")
local background = nil

function conky_pre()
    if conky_window == nil or conky_window.width <= 0 or conky_window.height <= 0 then
        return
    end

    if Sensors then
        Sensors:Update()
    end

    if GPU_Nvidia then
        GPU_Nvidia:Update()
    elseif GPU_AMD then
        GPU_AMD:Update()
    end

    if Disk then
        Disk:Update()
    end

    if RAM then
        RAM:Update()
    end

    if NET then
        NET:Update()
    end

    local cs = conky_surface()
    if not cs then
        print("No cairo surface")
        return
    end
    local cr = cairo_create(cs)

    if background == nil and Config.BackgroundImage then
        background = cairo_image_surface_create_from_png(pwd .. "../" .. Config.BackgroundImage)
    end

    if cr then
        if Draw then
            Draw:Background(cr, background)
        end

        local y = Config.MarginY
        if Clock then
            y = Clock:Display(cr, y)
        end
        if System and y < conky_window.height then
            y = System:Display(cr, y)
        end
        if CPU and y < conky_window.height then
            y = CPU:Display(cr, y) or 0
        end
        if RAM and y < conky_window.height then
            y = RAM:Display(cr, y) or 0
        end

        if y < conky_window.height then
            if GPU_Nvidia then
                y = GPU_Nvidia:Display(cr, y) or 0
            elseif GPU_AMD then
                y = GPU_AMD:Display(cr, y) or 0
            end
        end
        if Disk and y < conky_window.height then
            y = Disk:Display(cr, y)
        end
        if NET and y < conky_window.height then
            y = NET:Display(cr, y) or 0
        end
        if Processes then
            y = Processes:Display(cr, y)
        end
    end

    cairo_destroy(cr)
end
