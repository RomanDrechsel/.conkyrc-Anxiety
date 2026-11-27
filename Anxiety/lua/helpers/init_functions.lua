function GetAvailableScreenGeometry(monitor)
    if type(monitor) ~= "string"
        or not monitor:match("^[%w_%-%.]+$") then
        return nil
    end

    local command = string.format("busctl --user call org.kde.plasmashell /StrutManager org.kde.PlasmaShell.StrutManager availableScreenRect s %s 2>/dev/null", monitor)

    local handle = io.popen(command)

    if not handle then
        return nil
    end

    local output = handle:read("*a")
    handle:close()

    local x, y, width, height = output:match(
        "%(iiii%)%s+(-?%d+)%s+(-?%d+)%s+(%d+)%s+(%d+)"
    )

    if not width or not height then
        return nil
    end

    width = tonumber(width)
    height = tonumber(height)

    if width <= 0 or height <= 0 then
        return nil
    end

    return {
        X = tonumber(x),
        Y = tonumber(y),
        Width = width,
        Height = height
    }
end

function GetRightmostMonitor()
    local handle = io.popen([[
        kscreen-doctor -j 2>/dev/null | jq -r '
            [.outputs[] | select(.connected and .enabled)]
            | max_by(.pos.x)
            | .name // empty
        '
    ]])

    if not handle then
        return nil
    end

    local name = handle:read("*l")
    handle:close()

    if name and name ~= "" then
        return name
    end

    return nil
end
