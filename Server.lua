pathSeparator = package.config:sub(1,1)
local scriptPath
local linuxLibDir = ""
if pathSeparator == '/' then
    linuxLibDir = "/usr/lib/lua/5.3"
end
if getScriptPath then
    scriptPath = getScriptPath() .. "\\"
else
    utils = require "utils"
    scriptPath = utils.script_path()
end
local libDir
if not getScriptPath or tonumber(string.match(getInfoParam("VERSION"), "%d+[.]%d+")) >= 8.5 then
    libDir = "53"
elseif tonumber(string.match(getInfoParam("VERSION"), "%d+[.]%d+")) >= 8 then
    libDir = "51-x64"
else
    libDir = "51-x86"
end

package.path = package.path .. ";" .. scriptPath .. "?.lua"
package.cpath = package.cpath .. ";".. linuxLibDir .. scriptPath .. "libs".. pathSeparator .. libDir .. pathSeparator .. "?.dll"

socketsAttached = false
socket = require "libs/socket"
json = require "libs/dkjson"
utils = require "utils"
routes = require "routes"
require "callbacks"

function main()
    setup(utils.script_file_name())
end

function setup(scriptName)
    if not scriptName then
        --notify("Не удалось автоматически определить название файла. Пожалуйста, напишите его сами вместо script_file_name() " ..
        --        "в файле, который запущен в Квике")
        notify("File name of this script is unknown. Please, set it explicitly instead of script_file_name() " ..
                "call inside your custom file")
        return false
    end

    local list = utils.params_from_config(scriptName)
    if list and #list == 4 then
        local responseHost, responsePort, callbackHost, callbackPort = unpack(list)
        utils.print_running_message(responseHost, responsePort, callbackHost, callbackPort)
        start_waiting(responseHost, responsePort, callbackHost, callbackPort)
    elseif scriptName == "Server" then
        -- use default values for this file in case no custom config found for it
        local responseHost, responsePort, callbackHost, callbackPort = { "127.0.0.1", 15515, "127.0.0.1", 15516 }
        utils.print_running_message(responseHost, responsePort, callbackHost, callbackPort)
        start_waiting(responseHost, responsePort, callbackHost, callbackPort)
    else
        -- do nothing when config is not found
        --notify("Файл config.json не найден или не содержит записи о скрипте: " .. scriptName .. ".lua")
        notify("File config.json is not found or contains no entries for this script: " .. scriptName .. ".lua")
        return false
    end

    return true
end

local mainSocket
local callbackSocket

function start_waiting(responseHost, responsePort, callbackHost, callbackPort)
    --notify(responseHost .. responsePort .. callbackHost .. callbackPort)
    local s1 = assert(socket.bind(responseHost, responsePort))
    local s2 = assert(socket.bind(callbackHost, callbackPort))
    while true and s1 and s2 do
        mainSocket = assert(s1:accept())
        callbackSocket = assert(s2:accept())
        --notify("Evraon соединился")
        notify("Evraon: Connected")
        socketsAttached = true
        local req, error = mainSocket:receive()
        while not error do
            -- print("REQ " .. req)
            local parsedReq = json.decode(req)
            if type(parsedReq) == "table" then
                process_request(parsedReq)
            else
                -- Received something that is not a table, close connection, unexpected situation
                break
            end
            mainSocket:send(json.encode(parsedReq) .. '\n')
            req, error = mainSocket:receive()
        end
        socketsAttached = false
        pcall(callbackSocket.send, callbackSocket, "null")
        pcall(mainSocket.close, mainSocket)
        pcall(callbackSocket.close, callbackSocket)
        mainSocket = nil
        callbackSocket = nil
        --notify("Evraon отсоединился")
        notify("Evraon: Disconnected")
        socket.sleep(1)
    end
    s1:close()
    s2:close()
end

function process_request(request)
    local statusOk, res, errFromRoute = pcall(route_command, request.c, request.p)
    request.p = nil
    if statusOk then
        if not errFromRoute then
            request.r = res
        else
            request.e = errFromRoute
        end
    else
        request.e = res
    end
end

function route_command(command, params)
    action = {
        ["get_security_info"] = function() return routes.get_security_info(split(params)) end,
        ["get_class_securities"] = function() return routes.get_class_securities(params) end,
        ["get_class_info"] = function() return routes.get_class_info(params) end,
        ["get_info_param"] = function() return routes.get_info_param(params) end,
        ["get_futures_holding"] = function() return routes.get_futures_holding(split(params)) end,
        ["get_futures_client_limits"] = function() return routes.get_futures_client_limits() end,
        ["get_depo_limit"] = function() return routes.get_depo_limit(split(params)) end,
        ["get_money_limits"] = function() return routes.get_money_limits() end,
        ["get_trade_accounts"] = function() return routes.get_trade_accounts() end,
        ["get_candlesticks"] = function() return routes.get_candlesticks(split(params)) end,
        ["get_quote_level_2"] = function() return routes.get_quote_level_2(split(params)) end,

        ["subscribe_level_2_quotes"] = function() return routes.subscribe_level_2_quotes(split(params)) end,
        ["unsubscribe_level_2_quotes"] = function() return routes.unsubscribe_level_2_quotes(split(params)) end,
        ["is_subscribed_level_2_quotes"] = function() return routes.is_subscribed_level_2_quotes(split(params)) end,

        ["get_security_info_bulk"] = function() return routes.get_security_info_bulk(params) end,
        ["get_param_ex2_bulk"] = function() return routes.get_param_ex2_bulk(params) end,
        ["param_request_bulk"] = function() return routes.param_request_bulk(params) end,
        ["cancel_param_request_bulk"] = function() return routes.cancel_param_request_bulk(params) end,

        ["get_orders"] = function() return routes.get_orders(split(params)) end,
        ["get_order_by_id"] = function() return routes.get_order_by_id(split(params)) end,
        ["get_order_by_num"] = function() return routes.get_order_by_num(params) end,
        ["get_stop_orders"] = function() return routes.get_stop_orders(split(params)) end,
        ["get_stop_order_by_id"] = function() return routes.get_stop_order_by_id(split(params)) end,
        ["get_stop_order_by_num"] = function() return routes.get_stop_order_by_num(params) end,
        ["send_transaction"] = function() return routes.send_transaction(params) end,

    }
    local act = action[command]
    if act then
        return action[command]()
    else
        return nil, "No such function"
    end
end

function new_callback(command, data)
    --log_i(command, data)
    if callbackSocket then
        local res = {}
        res.c = command
        res.r = data
        local statusOk, err = pcall(callbackSocket.send, callbackSocket, json.encode(res) .. '\n')
        if not statusOk then
            --notify("Не удалось отправить коллбэк: " .. err)
            notify("Unable to send a callback: " .. err)
            --log_e("Коллбэк не был отправлен, отсоединяюсь: " .. err)
            log_e("Callback wasn't sent, disconnecting: " .. err)
            if mainSocket then
                pcall(mainSocket.close, mainSocket)
            end
        end
    end
end

function on_stop()
    if mainSocket then
        pcall(mainSocket.close, mainSocket)
    end
    --log_i("Работа прекращена")
    log_i("Stopped working")
    utils.close_log_file()
end

--if getScriptPath == nil and utils.script_file_name() == "Server" then main() end