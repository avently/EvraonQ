local json = require("libs/dkjson")
local routes = {}

function routes.get_security_info(secCode, classCode)
    return getSecurityInfo(classCode, secCode)
end

function routes.get_class_info(classCode)
    return getClassInfo(classCode)
end

function routes.get_class_securities(classCode)
    local res = split_in_table(getClassSecurities(classCode), ",")
    if #res >= 1 then
        res[#res] = nil
    end
    return res
end

function routes.get_info_param(paramName)
    return getInfoParam(paramName)
end

function routes.get_futures_holding(firmId, trdAccId, secCode, type)
    return getFuturesHolding(firmId, trdAccId, secCode, tonumber(type))
end

function routes.get_futures_client_limits()
    local res = {}
    for i = 0, getNumberOf("futures_client_limits") - 1 do
        table.insert(res, getItem("futures_client_limits", i))
    end
    return res
end

function routes.get_depo_limit(firmId, clientCode, secCode, trdAccId, limitKind)
    return getDepoEx(firmId, clientCode, secCode, trdAccId, tonumber(limitKind))
end

function routes.get_money_limits()
    local res = {}
    for i = 0, getNumberOf("money_limits") - 1 do
        table.insert(res, getItem("money_limits", i))
    end
    return res
end

function routes.get_trade_accounts()
    local res = {}
    for i = 0, getNumberOf("trade_accounts") - 1 do
        local account = getItem("trade_accounts", i)
        if account.class_codes ~= "" then
            table.insert(res, account)
        end
    end
    return res
end

function routes.get_candlesticks(secCode, classCode, interval, limit, skip)
    --log_i("Candles loading started " .. secCode .. " class " .. classCode .. " interval " .. interval)
    local dataSource, err = CreateDataSource(classCode, secCode, tonumber(interval))
    local limit = tonumber(limit)
    if limit == 0 then
        limit = 10000000
    end
    local skip = tonumber(skip)
    if dataSource then
        local res = {}
        local sleepTime = 0
        while dataSource:Size() == 0 and sleepTime < 5000 do
            sleep(10)
            sleepTime = sleepTime + 10
        end
        --log_i("Candles loading ended " .. sleepTime)
        local size = dataSource:Size()
        if size == 0 then
            return nil
        end

        local start = math.max(1, size - limit - skip)
        local to = math.min(size, start - 1 + limit)
        for i = start - 1, to do
            local candle = {}
            candle.O = dataSource:O(i)
            candle.H = dataSource:H(i)
            candle.L = dataSource:L(i)
            candle.C = dataSource:C(i)
            candle.V = dataSource:V(i)
            candle.T = dataSource:T(i)
            table.insert(res, candle)
        end
        dataSource:Close()
        return res
    else
        log_e("Candlesticks were not loaded: " .. err)
        return nil, err
    end
end

function routes.get_quote_level_2(secCode, classCode)
    return getQuoteLevel2(classCode, secCode)
end

function routes.subscribe_level_2_quotes(secCode, classCode)
    return Subscribe_Level_II_Quotes(classCode, secCode)
end

function routes.unsubscribe_level_2_quotes(secCode, classCode)
    return Unsubscribe_Level_II_Quotes(classCode, secCode)
end

function routes.is_subscribed_level_2_quotes(secCode, classCode)
    return IsSubscribed_Level_II_Quotes(classCode, secCode)
end

--
-- ORDERS
--

function routes.get_orders(secCode, classCode)
    local res = {}
    for i = 0, getNumberOf("orders") - 1 do
        local order = getItem("orders", i)
        if order.sec_code == secCode and order.class_code == classCode then
            table.insert(res, routes.fill_order_with_trades_data(order))
        end
    end
    return res
end

function routes.get_order_by_id(secCode, classCode, transId)
    local transId = tonumber(transId)
    for i = getNumberOf("orders") - 1, 0, -1 do
        local order = getItem("orders", i)
        if order.sec_code == secCode and order.class_code == classCode and order.trans_id == transId then
            return routes.fill_order_with_trades_data(order)
        end
    end
    return nil
end

function routes.get_order_by_num(orderNumber)
    local orderNum = tonumber(orderNumber)
    for i = getNumberOf("orders") - 1, 0, -1 do
        local order = getItem("orders", i)
        if order.order_num == orderNum then
            return routes.fill_order_with_trades_data(order)
        end
    end
    return nil
end

function routes.get_stop_orders(secCode, classCode)
    local res = {}
    for i = 0, getNumberOf("stop_orders") - 1 do
        local order = getItem("stop_orders", i)
        if order.sec_code == secCode and order.class_code == classCode then
            table.insert(res, order)
        end
    end
    return res
end

function routes.get_stop_order_by_id(secCode, classCode, transId)
    local transId = tonumber(transId)
    for i = getNumberOf("stop_orders") - 1, 0, -1 do
        local order = getItem("stop_orders", i)
        if order.sec_code == secCode and order.class_code == classCode and order.trans_id == transId then
            return routes.fill_order_with_trades_data(order)
        end
    end
    return nil
end

function routes.get_stop_order_by_num(orderNumber)
    local orderNum = tonumber(orderNumber)
    for i = getNumberOf("stop_orders") - 1, 0, -1 do
        local order = getItem("stop_orders", i)
        if order.order_num == orderNum then
            return routes.fill_order_with_trades_data(order)
        end
    end
    return nil
end

function routes.get_trades_by_num(orderNumber)
    local orderNum = tonumber(orderNumber)
    local res = {}
    for i = 0, getNumberOf("trades") - 1 do
        local trade = getItem("trades", i)
        if trade.order_num == orderNum then
            table.insert(res, trade)
        end
    end
    return res
end

function routes.fill_order_with_trades_data(order)
    local qty_of_trades = 0
    local price_qty = 0
    for i = 0, getNumberOf("trades") - 1 do
        local trade = getItem("trades", i)
        if trade.order_num == order.order_num then
            price_qty = price_qty + trade.price * trade.qty
            qty_of_trades = qty_of_trades + trade.qty
            order.last_trade_datetime_ex = trade.datetime
        end
    end
    if qty_of_trades > 0 then
        order.average_price_ex = price_qty / qty_of_trades
    end
    return order
end

function routes.send_transaction(transaction)
    local err = sendTransaction(transaction)
    if err ~= "" then
        return nil, err
    else
        return true
    end
end

--
-- BULK REQUESTS
--

function routes.get_security_info_bulk(secsClasses)
    local res = {}
    for i = 1, #secsClasses do
        local secCode, classCode = split(secsClasses[i])
        local security = getSecurityInfo(classCode, secCode)
        if security then
            table.insert(res, security)
        else
            table.insert(res, json.null)
        end
    end
    return res
end

function routes.get_param_ex2_bulk(secsClassesParams)
    local res = {}
    for i = 1, #secsClassesParams do
        local secCode, classCode, param = split(secsClassesParams[i])
        table.insert(res, getParamEx2(classCode, secCode, param))
    end
    return res
end

function routes.param_request_bulk(secsClassesParams)
    local res = {}
    for i = 1, #secsClassesParams do
        local secCode, classCode, param = split(secsClassesParams[i])
        table.insert(res, ParamRequest(classCode, secCode, param))
    end
    return res
end

function routes.cancel_param_request_bulk(secsClassesParams)
    local res = {}
    for i = 1, #secsClassesParams do
        local secCode, classCode, param = split(secsClassesParams[i])
        table.insert(res, CancelParamRequest(classCode, secCode, param))
    end
    return res
end

return routes