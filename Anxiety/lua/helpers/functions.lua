function trim(s)
    return tostring(s):match("^%s*(.-)%s*$")
end

function isEmpty(string)
    return string == nil or string == ''
end

function in_array(tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function format_bytes(bytes)
    if bytes then
        bytes = tonumber(trim(bytes))
        if bytes > 1073741824 then
            return string.format("%.2f GiB", bytes / 1073741824)
        elseif bytes > 1048576 then
            return string.format("%.2f MiB", bytes / 1048576)
        elseif bytes > 1024 then
            return string.format("%.2f KiB", bytes / 1024)
        else
            return string.format("%.0f B", bytes)
        end
    end
    return -1
end

function home()
    local home = os.getenv("HOME") or os.getenv("USERPROFILE")
    if home then
        return home .. "/"
    end
    return ""
end

function pipe(command)
    local handle = io.popen(command, "r")

    if not handle then
        return nil
    end

    local output = handle:read("*a")
    local success, reason, code = handle:close()

    if output then
        output = output:gsub("[\r\n]+$", "")
    end

    return output
end

function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

function package_installed(package)
    return os.execute(
        "pacman -Q " .. shell_quote(package) .. " >/dev/null 2>&1"
    ) == true
end

function dir_exists(path)
    return os.execute("test -d " .. shell_quote(path)) == true
end

function file_exists(path)
    return os.execute("test -f " .. shell_quote(path)) == true
end

function toInt(number)
    number = tonumber(number)
    if number then
        return math.floor(number + 0.5)
    end
    return -1
end

function table_copy(t)
    local ret = {};
    for k, v in pairs(t) do
        if type(v) == "table" then
            ret[k] = table_copy(v);
        else
            ret[k] = v;
        end
    end
    return ret;
end

function write_cache(file, content)
    local dir = home() .. ".cache/conky/Anxiety/"
    os.execute("mkdir -p '" .. dir .. "'")

    local cache_file = io.open(dir .. file, "w")
    if cache_file then
        cache_file:write(content)
        cache_file:close()
    end
end

function read_cache(file)
    local cache_file = io.open(home() .. ".cache/conky/Anxiety/" .. file, "r")
    if cache_file then
        local content = cache_file:read("*a")
        cache_file:close()
        return content
    end

    return nil
end

function split(str, delimiter)
    if delimiter == nil then
        delimiter = "\n"
    end
    local result               = {}
    local from                 = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from                 = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            local key = k
            if type(key) ~= 'number' then
                key = '"' .. tostring(key) .. '"'
            end
            s = s .. '[' .. key .. '] = ' .. dump(v) .. ','
        end

        return s .. '} '
    else
        return tostring(o)
    end
end
