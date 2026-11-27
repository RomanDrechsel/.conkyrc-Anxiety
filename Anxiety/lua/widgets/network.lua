NET = { CurrentIP = Locale.NA, CurrentPing = -1, _lastInet = nil }

function NET:new()
    self._timerIP = Timer:new(60)
    self._timerPing = Timer:new(5)
    self:_getIP()
    self:_getPing()

    self._json = nil
    if Config.NetworkGraph then
        self.Graph = LineGraph:new(Config.LineGraph, nil, 70)

        self.Graph.Lines = {
            ["down"] = Config.NetworkGraph.Download,
            ["up"] = Config.NetworkGraph.Upload,
        }
    end
    return self
end

function NET:Display(cr, y)
    y = Draw:Header(cr, Locale.Network, y)

    y = Draw:Row(cr, y, Locale.ExternIP, Config.Text.Label, nil, nil, Locale.Ping, nil)

    y = Draw:Row(cr, y, self.CurrentIP, Config.Text.Large, nil, nil, self:Ping(), nil)

    if self._json and self.Graph then
        local down = self._json["speed_down"]
        local up = self._json["speed_up"]
        local speed = self:Speed()
        local total = self:Total()
        if not IsEmpty(speed) or not IsEmpty(total) then
            y = Draw:Row(cr, y, speed, Config.Text.Info, nil, nil, total, nil)
        end

        local data = {
            ["down"] = down,
            ["up"] = up,
        }

        y = self.Graph:Draw(cr, Config.MarginX, y + 5, data)
    end

    return y
end

function NET:Update()
    self:_getTraffic()

    if self._timerIP:Ready() then
        self:_getIP()
    end

    if self._timerPing:Ready() then
        self:_getPing()
    end
end

function NET:Speed()
    if self._json then
        local down = self._json["speed_down"]
        local up = self._json["speed_up"]

        if up or down then
            local ret = ""
            if down then
                ret = FormatBytes(down)
            else
                ret = "-"
            end

            ret = ret .. " / ";
            if up then
                ret = ret .. FormatBytes(up)
            else
                ret = ret .. "-"
            end

            return ret
        end
    end

    return nil
end

function NET:Total()
    if self._json then
        local down = self._json["total_down"]
        local up = self._json["total_up"]

        if up or down then
            local ret = ""
            if down then
                ret = FormatBytes(down)
            else
                ret = "-"
            end

            ret = ret .. " / ";
            if up then
                ret = ret .. FormatBytes(up)
            else
                ret = ret .. "-"
            end

            return ret
        end
    end

    return nil
end

function NET:Ping()
    if self.CurrentPing and self.CurrentPing >= 0 then
        return string.format("%.1f ms", self.CurrentPing)
    end

    local ret = Locale.NoNetwork
    if not self._lastInet then
        self._lastInet = tonumber(ReadFromCacheFile("inet"))
    end

    if self._lastInet then
        local diff = math.max(0, os.time() - self._lastInet)

        local seconds = math.floor(diff % 60)
        local minutes = math.floor(diff / 60) % 60
        local hours = math.floor(diff / 3600)

        ret = ret .. " " .. (hours > 0 and hours .. "h " or "") .. (minutes > 0 and minutes .. "m " or "") .. seconds .. "s"
    end

    return ret
end

function NET:_getIP()
    local ip = ReadCli("curl -s https://ipinfo.io/ip")
    if ip then
        self.CurrentIP = ip
    else
        self.CurrentIP = Locale.NA
    end
end

function NET:_getPing()
    local ping = tonumber(ReadCli(
        "LC_ALL=C ping -c 1 -q -w 1 google.com"
        .. " 2>/dev/null | awk -F'/' '/^rtt/ {print $5}'"
    ))

    if ping and ping >= 0 then
        self.CurrentPing = ping
        self._lastInet = os.time()

        WriteToCacheFile("inet", self._lastInet)
    else
        self.CurrentPing = -1
    end
end

function NET:_getCounters(interface)
    local file = io.open("/proc/net/dev", "r")

    if not file then
        return nil, nil
    end

    for line in file:lines() do
        local name, counters = line:match("^%s*(.-):%s*(.+)$")

        if name == interface then
            local fields = {}

            for value in counters:gmatch("%d+") do
                fields[#fields + 1] = tonumber(value)
            end

            file:close()

            return fields[1], fields[9]
        end
    end

    file:close()
    return nil, nil
end

function NET:_getTimestamp()
    local file = io.open("/proc/uptime", "r")

    if not file then
        return nil
    end

    local uptime = file:read("*n")
    file:close()

    return uptime
end

function NET:_getTraffic()
    local interface = Config.Network and Config.Network.Interface

    if not interface or interface == "" then
        self._json = nil
        self._lastTraffic = nil
        return
    end

    local received, transmitted = self:_getCounters(interface)
    local now = self:_getTimestamp()

    if not received or not transmitted or not now then
        self._json = nil
        self._lastTraffic = nil
        return
    end

    local speedDown = 0
    local speedUp = 0
    local previous = self._lastTraffic

    -- Calculate transfer rates in bytes per second
    if previous and previous.interface == interface then
        local elapsed = now - previous.timestamp

        if elapsed > 0 then
            speedDown = math.max(0, received - previous.received) / elapsed
            speedUp = math.max(0, transmitted - previous.transmitted) / elapsed
        end
    end

    received = math.floor(received + 0.5)
    transmitted = math.floor(transmitted + 0.5)

    -- Store counters for the next update
    self._lastTraffic = {
        interface = interface,
        timestamp = now,
        received = received,
        transmitted = transmitted
    }

    -- Preserve the existing data structure
    self._json = {
        speed_down = speedDown,
        speed_up = speedUp,
        total_down = received,
        total_up = transmitted
    }
end

NET:new()
