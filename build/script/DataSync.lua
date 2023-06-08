require("Json")
require("Lib")
require("Config")

local tbQueryFunc = {}

function Query(jsonParam)
    local tbParam = JsonDecode(jsonParam)
    local func = tbQueryFunc[tbParam.FuncName]
    local szMsg
    local bRet = false
    if func then
        szMsg, bRet, tbCustomData = func(tbParam)
    else
        szMsg = "invalid query FuncName"
    end
    local tbResult = {
        code = bRet and 0 or -1,
        msg = szMsg,
    }
    if tbCustomData then
        for k, v in pairs(tbCustomData) do
            tbResult[k] = v 
        end
    end
    return JsonEncode(tbResult)
end

--------------------接口实现---------------------------------------
function tbQueryFunc.GetConfigData(tbParam)
    return "success", true,  { tbConfig = tbConfig }
end

function tbQueryFunc.GetRunTimeData(tbParam)
    return "success", true, { tbRuntimeData = GetTableRuntime() }
end
