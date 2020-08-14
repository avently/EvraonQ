local callbacks = {}

function OnAccountBalance(acc_bal) new_callback("OnAccountBalance", acc_bal) end

function OnAccountPosition(acc_pos) new_callback("OnAccountPosition", acc_pos) end

function OnAllTrade(alltrade) new_callback("OnAllTrade", alltrade) end

function OnCleanUp() new_callback("OnCleanUp", nil) end

function OnClose() new_callback("OnClose", nil) end

function OnConnected(flag) new_callback("OnConnected", flag) end

function OnDepoLimit(dlimit) new_callback("OnDepoLimit", dlimit) end

function OnDepoLimitDelete(dlimit_del) new_callback("OnDepoLimitDelete", dlimit_del) end

function OnDisconnected() new_callback("OnDisconnected", flag) end

function OnFirm(firm) new_callback("OnFirm", firm) end

function OnFuturesClientHolding(fut_pos) new_callback("OnFuturesClientHolding", fut_pos) end

function OnFuturesLimitChange(fut_limit) new_callback("OnFuturesLimitChange", fut_limit) end

function OnFuturesLimitDelete(lim_del) new_callback("OnFuturesLimitDelete", lim_del) end

function OnInit(script_path) new_callback("OnInit", script_path) end

function OnMoneyLimit(mlimit) new_callback("OnMoneyLimit", mlimit) end

function OnMoneyLimitDelete(mlimit_del) new_callback("OnMoneyLimitDelete", mlimit_del) end

function OnNegDeal(neg_deals) new_callback("OnNegDeal", neg_deals) end

function OnNegTrade(neg_trade) new_callback("OnNegTrade", neg_trade) end

function OnOrder(order) new_callback("OnOrder", order) end

function OnParam(class_code, sec_code)
    local r = {}
    r.sec_code = sec_code
    r.class_code = class_code
    new_callback("OnParam", r)
end

function OnQuote(class_code, sec_code)
    if not socketsAttached then return end
    local statusOk, r = pcall(getQuoteLevel2, class_code, sec_code)
    if statusOk then
        r.sec_code = sec_code
        r.class_code = class_code
        new_callback("OnQuote", r)
    end
end

function OnStop(signal)
    new_callback("OnStop", signal)
    on_stop()
    return 500
end

function OnStopOrder(stop_order) new_callback("OnStopOrder", stop_order) end

function OnTrade(trade) new_callback("OnTrade", trade) end

function OnTransReply(trans_reply) new_callback("OnTransReply", trans_reply) end

return callbacks