require("Json")
require("Lib")
require("Config")

tbAdminFunc = {}
Administration = {}

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

-- 重置 {FuncName = "DoReset"}
function tbAdminFunc.DoReset(tbParam)
    Production:Reset()

    local runtime = GetTableRuntime()
    --runtime.nDataVersion = 0

    runtime.bPlaying = false
    runtime.nCurYear = 1
    runtime.nCurSeason = 1

    runtime.nGamerCount = 0
    runtime.tbLoginAccount = {}
    runtime.tbUser = {}

    runtime.tbMarket = {}

    runtime.tbCutdownProduct = {}
    runtime.tbManpowerInMarket = {0, 0, 0, 0, 0}
    return "success", true
end

function tbAdminFunc.DoStart(tbParam)
    local runtime = GetTableRuntime()
    if runtime.bPlaying then
        return "failed, already started", false
    end
    if runtime.nGamerCount < 1 then
        return "failed, no gamer", false
    end

    math.randomseed(os.time())
    --runtime.nDataVersion = 1
    --runtime.nGameID = runtime.nGameID + 1
    runtime.bPlaying = true
    runtime.nCurYear = tbParam.Year or 1
    runtime.nCurSeason = 0

    for userName, tbLoginAccountInfo in pairs(runtime.tbLoginAccount) do
        Administration:NewUser(userName)
    end

    InitManpowerData()

    runtime.tbOrder = Lib.copyTab(tbConfig.tbOrder)
    runtime.tbMarket = Lib.copyTab(tbConfig.tbMarket)
    return "success", true
end

function Administration:NewUser(name)
    local runtime = GetTableRuntime()
    local user = Lib.copyTab(tbInitTables.tbInitUserData)
    user.szAccount = name
    user.tbHistoryYearReport = {}
    if runtime.nCurYear == 1 then
        user.tbHistoryYearReport[1] = user.tbYearReport
    else
        for i = runtime.nCurYear - 1, 1, -1 do
            user.tbHistoryYearReport[i] = Lib.copyTab(user.tbYearReport)
        end
        user.tbHistoryYearReport[runtime.nCurYear] = user.tbYearReport
    end
    runtime.tbUser[name] = user
end

function tbAdminFunc.NextStep(tbParam)
    local runtime = GetTableRuntime()
    if tbParam.CurSeason ~= runtime.nCurSeason or tbParam.CurYear ~= runtime.nCurYear then
        return "failed, step mismatch", false    --避免在收到请求时，服务端已经刚刚变过步骤了
    end
    NextStepIfAllGamersDone(true)
    return "success", true
end
