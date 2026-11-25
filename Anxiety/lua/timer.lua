Timer = {}
Timer.__index = Timer

function Timer:new(interval, immediate)
    local instance = setmetatable({
        Interval = interval
    }, self)

    if not immediate then
        instance.LastRun = os.time()
    end

    return instance
end

function Timer:Ready()
    local now = os.time()

    if self.LastRun == nil
        or now < self.LastRun
        or now - self.LastRun >= self.Interval
    then
        self.LastRun = now
        return true
    end

    return false
end

function Timer:Reset()
    self.LastRun = os.time()
end
