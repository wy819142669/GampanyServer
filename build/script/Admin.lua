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

-- 重置 {FuncName = "DoReset"}
function tbAdminFunc.DoReset(tbParam)
    local runtime = GetTableRuntime()
    runtime.nDataVersion = 0
    runtime.nCurYear = 1
    runtime.nCurSeason = 1
    runtime.sCurrentStep = STEP.PreSeason
    runtime.tbUser = {}
    runtime.nReadyNextStepCount = 0
    runtime.tbLoginAccount = {}
    runtime.tbCutdownProduct = {}
    runtime.bPlaying = false
    runtime.tbMarket = {}
    runtime.tbManpower = {0, 0, 0, 0, 0}
    runtime.nTimeLimitToNextSyncStep = 0
    runtime.nSkipDestNextSyncStep = 0
    runtime.nCurSyncStep = 0
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
    tbParam.Year = tbParam.Year or 1

    for userName, tbLoginAccountInfo in pairs(runtime.tbLoginAccount) do
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

    runtime.tbOrder = Lib.copyTab(tbConfig.tbOrder)
    runtime.tbMarket = Lib.copyTab(tbConfig.tbMarket)
    runtime.nDataVersion = 1
    runtime.nCurYear = tbParam.Year
    runtime.nCurSeason = 1
    runtime.sCurrentStep = STEP.PreSeason
    runtime.nGameID = runtime.nGameID + 1
    runtime.bPlaying = true
    return "success", true
end

function tbAdminFunc.NextStep(tbParam)
    local runtime = GetTableRuntime()
    if tbParam.CurStep ~= runtime.sCurrentStep or tbParam.CurSeason ~= runtime.nCurSeason then
        return "failed, step mismatch", false    --避免在收到请求时，服务端已经刚刚变过步骤了
    end
    NextStepIfAllGamersDone(true)
    return "success", true
end
