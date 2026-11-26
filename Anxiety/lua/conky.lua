--[[

Conky:
https://conky.cc/

]] --

local pwd = debug.getinfo(1, "S").source:sub(2):match("^.*/") or "./"
package.path = pwd .. "?.lua;" .. package.path

JSON = require("helpers.json")
require("helpers.functions")
local languageLoader = require("loader.language_loader")
local themeLoader = require("loader.theme_loader")
local root = pwd .. "../"

require('config')
Locale = languageLoader:load(root, Config.Language)
print("[Anxiety] Using localization: '" .. Config.Language .. "'")
Theme = themeLoader:load(root, Config.Theme)
print("[Anxiety] Using theme: '" .. Config.Theme .. "'")
themeLoader:apply(Config, Theme)

require('safe_config')
Config = safe_config(Config)

require('cairo')
CacheDir = home() .. ".cache/conky/Anxiety/"

require('helpers.timer')
require('helpers.draw')
require('graphs.graph_helpers')
require('graphs.linegraph')
require('graphs.piegraph')
require('graphs.bargraph')
require("helpers.sensors")
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

    if NVIDIA_GPU then
        NVIDIA_GPU:Update()
    elseif AMD_GPU then
        AMD_GPU:Update()
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
            if NVIDIA_GPU then
                y = NVIDIA_GPU:Display(cr, y) or 0
            elseif AMD_GPU then
                y = AMD_GPU:Display(cr, y) or 0
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
