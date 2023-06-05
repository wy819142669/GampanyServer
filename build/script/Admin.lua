require("Json")
require("Lib")
require("Config")

local tbFunc = {}

function Admin(jsonParam)
    local tbParam = JsonDecode(jsonParam)
    local func = tbFunc.Admin[tbParam.FuncName]
    local szMsg
    local bRet = false
    if func then
        szMsg, bRet, tbCustomData = func(tbParam)
    else
        szMsg = "invalid admin FuncName"
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
tbFunc.Admin = {}

-- 登录 {FuncName = "Login"}
function tbFunc.Admin.Login(tbParam)
    if tbParam.Password ~= tbConfig.szAdminPassword then
        return "failed, incorrect password", false
    end
    return "success", true
end

-- 登出 {FuncName = "Logout"}
function tbFunc.Admin.Logout(tbParam)
    return "success", true
end
