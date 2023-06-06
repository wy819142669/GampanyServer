require("Json")
require("Lib")
require("Config")

tbAdminFunc = {}

function Admin(jsonParam)
    local tbParam = JsonDecode(jsonParam)
    local func = tbAdminFunc[tbParam.FuncName]
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
-- 登录 {FuncName = "Login"}
function tbAdminFunc.Login(tbParam)
    if tbParam.Password ~= tbConfig.szAdminPassword then
        return "failed, incorrect password", false
    end
    return "success", true
end

-- 登出 {FuncName = "Logout"}
function tbAdminFunc.Logout(tbParam)
    return "success", true
end

function tbAdminFunc.DoStart(tbParam)
    local runtime = GetTableRuntime()
    if runtime.bPlaying then
        return "failed, already started", false
    end

    math.randomseed(os.time())
    tbParam.Year = tbParam.Year or 1

    for userName, tbLoginAccountInfo in pairs(runtime.tbLoginAccount) do
        if tbLoginAccountInfo.joinGame then
            runtime.tbUser[userName] = Lib.copyTab(tbConfig.tbInitUserData)
            runtime.tbUser[userName].szAccount = userName
            runtime.tbUser[userName].tbHistoryYearReport = {}
            if tbParam.Year == 1 then
                runtime.tbUser[userName].tbHistoryYearReport[1] = runtime.tbUser[userName].tbYearReport
            else
                runtime.tbUser[userName].tbHistoryYearReport[1] = Lib.copyTab(runtime.tbUser[userName].tbYearReport)
                runtime.tbUser[userName].tbHistoryYearReport[2] = runtime.tbUser[userName].tbYearReport
            end

            for k, v in pairs(tbConfig.tbInitUserDataYearPath[tbParam.Year]) do
                runtime.tbUser[userName][k] = Lib.copyTab(v)
            end
        end
    end

    runtime.tbOrder = Lib.copyTab(tbConfig.tbOrder)
    runtime.nDataVersion = 1
    runtime.nCurYear = tbParam.Year
    runtime.nGameID = runtime.nGameID + 1
    runtime.bPlaying = true
    return "success", true
end
