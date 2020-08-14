local utils = {}

local delimiter = "|"
local cachedScriptName
local cachedScriptPath

-- GLOBAL
-- FUNCTIONS

function split(s)
    local res = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(res, match);
    end
    return unpack(res);
end

function split_in_table(s, separator)
    local res = {}
    for match in (s..separator):gmatch("(.-)"..separator) do
        table.insert(res, match);
    end
    return res
end

function log_e(error)
    --utils.log("ОШИБКА  ".. utils.script_file_name() ..":  " .. error)
    utils.log("ERROR  ".. utils.script_file_name() ..":  " .. error)
end

function log_i(info)
    --utils.log("ИНФОРМ.  ".. utils.script_file_name() ..":  " .. info)
    utils.log("INFO  ".. utils.script_file_name() ..":  " .. info)
end

function notify(text)
    if getScriptPath then
        message(text)
    end
    log_i(text)
end


-- LOCAL
-- FUNCTIONS

-- Returns the name of the file that calls this function (without extension)
function utils.script_file_name()
    if cachedScriptName then
        return cachedScriptName
    end
    --message(debug.traceback("Trace"))
    -- Check that Lua runtime was built with debug information enabled
    if not debug or not debug.getinfo then
        return nil
    end
    local fullPath = debug.getinfo(2, "S").source:sub(2)
    cachedScriptName = string.gsub(fullPath, "^.*[\\/](.*)[.]lua[c]?$", "%1")
    return cachedScriptName
end

-- Returns the path of the file with separator
function utils.script_path()
    if cachedScriptPath ~= nil then
        return cachedScriptPath
    end

    -- Quik is running, return path from it
    if getScriptPath ~= nil then
        cachedScriptPath = getScriptPath() .. pathSeparator
        return cachedScriptPath
    end

    -- Check that Lua runtime was built with debug information enabled
    if not debug or not debug.getinfo then
        return nil
    end
    cachedScriptPath = string.gsub(debug.getinfo(1).source, "^@(.+[\\/])[^\\/]+$", "%1")
    return cachedScriptPath
end

-- Create log directory
function utils.get_log_file()
    local logsPath = utils.script_path() .. "logs"
    os.execute("mkdir \"".. logsPath .. "\"")
    -- Opens a file in append mode
    return io.open(logsPath .. pathSeparator .. os.date("%Y%m%d") .. ".txt", "a")
end

local log = utils.get_log_file()

function utils.close_log_file()
    log:close()
end

function utils.log(text)
    -- appends something to the last line of the file
    pcall(log.write, log, os.date("%d.%m.%Y, %X") .. "  " .. text .. '\n')
    pcall(log.flush, log)
end

-- Returns contents of config.json file or nil if no such file exists
function utils.read_config_as_json()
    local conf = io.open (utils.script_path() .. "config.json", "r")
    if not conf then
        return nil
    end
    local content = conf:read "*a"
    conf:close()
    return json.decode(content)
end

function utils.params_from_config(scriptName)
    local params = {}
    -- just default values
    table.insert(params, "127.0.0.1") -- responseHostname
    table.insert(params, 15515)       -- responsePort
    table.insert(params, "127.0.0.1") -- callbackHostname
    table.insert(params, 15516)       -- callbackPort

    local config = utils.read_config_as_json()
    if not config or not config.servers then
        return nil
    end
    local found = false
    for i=1,#config.servers do
        local server = config.servers[i]
        if server.scriptName == scriptName then
            found = true
            if server.responseHostname then
                params[1] = server.responseHostname
            end
            if server.responsePort then
                params[2] = server.responsePort
            end
            if server.callbackHostname then
                params[3] = server.callbackHostname
            end
            if server.callbackPort then
                params[4] = server.callbackPort
            end
        end
    end

    if found then
        return params
    else
        return nil
    end
end

function utils.print_running_message(responseHost, responsePort, callbackHost, callbackPort)
    --log_i("Запущен с параметрами: основной сокет " .. responseHost .. ":" .. responsePort ..", коллбэк ".. " "..
    --        callbackHost ..":".. callbackPort)
    log_i("Running with params: response " .. responseHost .. ":" .. responsePort ..", callback ".. " "..
            callbackHost ..":".. callbackPort)
end

return utils