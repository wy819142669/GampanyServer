print(package.path)

package.path = "./script/?.lua;" .. package.path
--print(package.path)
require("Json")
require("Lib")
require("Config")
require("Production")
require("Admin")
require("DataSync")

local tbRuntimeData = {
    nDataVersion = 1,
    nGameID = 0,
    nTimeLimitToNextSyncStep = 0,
    nSkipDestNextSyncStep = 0,
    bPlaying = false,
    tbMarket = { 1 },
    nGamerCount = 0,
    tbLoginAccount = {
        -- "王" = 4151234,
    }, -- 已登录账号
    nReadyNextStepCount = 0,
    nCurSyncStep = 0,
    -- 当前年份
    nCurYear = 1,
    tbCutdownProduct = {
        -- a1 = true,
        -- b1 = true,
    },
    tbAddNewManpower = { false, false, false, false },
    tbManpower = { -- 人才市场各等级人数
        0, 0, 0, 0, 0
    },
    tbUser = {
        --[[default = {
            -- 当前年步骤
            nCurYearStep = 4,
            -- 当前季度
            nCurSeason = 1,
            -- 当前季度步骤
            nCurSeasonStep = 1,
            -- 当前步骤已经操作完，防止重复操作
            bStepDone = false,
            -- 等待下一步
            bReadyNextStep = false,
            -- 提示
            szTitle = "",
            -- 市场营销投入
            tbMarketingExpense = {
                a1 = { 2, 1, 1},
                a2 = { 5, 3, 3},
                b1 = { 20, 40, 3},
            }
            -- 产品
            tbProduct = {
                a1 = { manpower = 20, progress = 4, market = { 1, 2, 3 }, published = true, done = false },
                a2 = {},
                b1 = {},
                b2 = {},
                d1 = {},
                d2 = {},
                e1 = {},
                e2 = {},
            },
            -- 订单
            tbOrder = {
                a1 = {{ cfg = {}, market = 1, done = false}, {cfg = {}, market = 2, done = true}}
            },
            -- 待岗
            nIdleManpower = 0,
            -- 代收款
            tbReceivables = {0, 0, 0, 0},
            -- 现金
            nCash = 0,
            -- 追加市场费
            nAppendMarketCost = 0,
            -- 税收
            nTax = 0,
            -- 市场营销费
            nMarketingExpense = 0,
            -- 总人力
            nTotalManpower = 0,
            -- 招聘、解雇费用
            nSeverancePackage = 0,
            -- 薪水
            tbLaborCost = {0, 0, 0, 0},
            -- 上一年财报
            tbLastYearReport = {

                -- 利润
                nProfitBeforeTax = 0,
                -- 需要缴纳税款
                nTax = 0,
            }
        }--]]
    }
}

local tbFunc = {
    Action = {},
    Query = {},
}

function OnReloadFinish(jsonParam)
    tbConfig.nLuaVersion = tbConfig.nLuaVersion + 1
end

function Action(jsonParam)
    CheckTimeLimit()

    local tbParam = JsonDecode(jsonParam)
    local func = tbFunc.Action[tbParam.FuncName]
    local szMsg
    local bRet = false
    if func then
        szMsg, bRet, tbCustomData = func(tbParam)
    else
        szMsg = "invalid action FuncName"
    end
    local tbResult = {
        code = bRet and 0 or -1,
        msg = szMsg,
        tbRuntimeData = tbRuntimeData
    }

    if tbCustomData then
        for k, v in pairs(tbCustomData) do
            tbResult[k] = v 
        end
    end

    -- 客户端要用tbLoginAccount来判断登录状态
    -- tbRuntimeData.tbLoginAccount[tbParam.Account] = os.time()
    return JsonEncode(tbResult)
end
--[[ 被越子注释掉。之前没被用到，之后Query的处理统一放到DataSync中
function Query(jsonParam)
    CheckTimeLimit()

    local tbParam = JsonDecode(jsonParam)
    local func = tbFunc["Query"][tbParam.FuncName]
    local resultText
    local isUpdateRuntimeData = true
    local responseParam = nil
    if func then
        resultText, isUpdateRuntimeData, responseParam = func(tbParam)
    else
        resultText = "invalid FuncName"
    end
    local tbResult = {
        szResult = resultText,
        tbRuntimeData = isUpdateRuntimeData and tbRuntimeData or nil
    }

    if responseParam then
        for k, v in pairs(responseParam) do
            tbResult[k] = v
        end
    end

    return JsonEncode(tbResult)
end
--]]

function QueryTest(tbParam)

    return "success"
end

function CheckTimeLimit()
    if tbRuntimeData.nTimeLimitToNextSyncStep == 0 or os.time() < tbRuntimeData.nTimeLimitToNextSyncStep then
        return
    end

    tbRuntimeData.nTimeLimitToNextSyncStep = 0

    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        while tbUser.nCurYearStep < tbRuntimeData.nSkipDestNextSyncStep do
            local tbStep = tbConfig.tbYearStep[tbUser.nCurYearStep]
            if tbStep.timeLimitAction then
                tbFunc.timeLimitAction[tbStep.timeLimitAction](tbUser)
            end

            userNewStep(tbUser)
        end
    end
end

function GetTableRuntime()
    return tbRuntimeData
end

--------------------接口实现---------------------------------------
-- 登录 {FuncName = "Login"}
function tbFunc.Action.Login(tbParam)
    local exist = table.contain_key(tbRuntimeData.tbLoginAccount, tbParam.Account)
    if tbRuntimeData.nGamerCount >= tbConfig.nMaxGamerCount and not exist then
        print("Login : failed, too much gamers")
        return "failed, too much gamers", false
    end

    if not table.contain_value(tbConfig.tbAdminAccount, tbParam.Account) then
        table.insert(tbConfig.tbAdminAccount, tbParam.Account)
    end

    local bAdmin = table.contain_value(tbConfig.tbAdminAccount, tbParam.Account)

    if tbRuntimeData.bPlaying then -- 已经开始后，非管理员不能再进入
        if not bAdmin then
            return "failed, already start", false
        end
    end

   -- tbRuntimeData.tbLoginAccount[tbParam.Account] = { loginTime = os.time(), admin = bAdmin, joinGame = not bAdmin}
    tbRuntimeData.tbLoginAccount[tbParam.Account] = { loginTime = os.time(), admin = bAdmin, joinGame = true}
    if not exist then
        tbRuntimeData.nGamerCount = tbRuntimeData.nGamerCount + 1
    end
    return "success", true
end

-- 登出 {FuncName = "Logout"}
function tbFunc.Action.Logout(tbParam)
    tbRuntimeData.tbLoginAccount[tbParam.Account] = nil
    tbRuntimeData.tbUser[tbParam.Account] = nil
    tbRuntimeData.nGamerCount = tbRuntimeData.nGamerCount - 1
    return "success", true
end

-- 该系统账号是否也参与游戏 {FuncName = "AdminJoinGame", Join = false}
function tbFunc.Action.AdminJoinGame(tbParam)
    if tbRuntimeData.tbLoginAccount[tbParam.Account].admin then
        tbRuntimeData.tbLoginAccount[tbParam.Account].joinGame = tbParam.Join
    end
    return "success", true
end

-- 开始 {FuncName = "DoStart", Year=1}  -- Year = 1(教学) or 2(跳过教学)
function tbFunc.Action.DoStart(tbParam)
    if tbRuntimeData.bPlaying then
        return "failed, already start", false
    end

    if not table.contain_value(tbConfig.tbAdminAccount, tbParam.Account) then
        return "failed, only admin can start", false
    end

    math.randomseed(os.time())

    tbParam.Year = tbParam.Year or 1

    for userName, tbLoginAccountInfo in pairs(tbRuntimeData.tbLoginAccount) do
        if tbLoginAccountInfo.joinGame then
            tbRuntimeData.tbUser[userName] = Lib.copyTab(tbConfig.tbInitUserData)
            tbRuntimeData.tbUser[userName].szAccount = userName
            tbRuntimeData.tbUser[userName].tbHistoryYearReport = {}
            if tbParam.Year == 1 then
                tbRuntimeData.tbUser[userName].tbHistoryYearReport[1] = tbRuntimeData.tbUser[userName].tbYearReport
            else
                tbRuntimeData.tbUser[userName].tbHistoryYearReport[1] = Lib.copyTab(tbRuntimeData.tbUser[userName].tbYearReport)
                tbRuntimeData.tbUser[userName].tbHistoryYearReport[2] = tbRuntimeData.tbUser[userName].tbYearReport
            end


            for k, v in pairs(tbConfig.tbInitUserDataYearPath[tbParam.Year]) do
                tbRuntimeData.tbUser[userName][k] = Lib.copyTab(v)
            end
        end
    end

    tbRuntimeData.tbOrder = Lib.copyTab(tbConfig.tbOrder)
    tbRuntimeData.nDataVersion = 1
    tbRuntimeData.nCurYear = tbParam.Year
    tbRuntimeData.nGameID = tbRuntimeData.nGameID + 1
    tbRuntimeData.bPlaying = true
    return "success", true
end

-- 重置 {FuncName = "DoReset"}
function tbFunc.Action.DoReset(tbParam)
    if not table.contain_value(tbConfig.tbAdminAccount, tbParam.Account) then
        return "failed, only admin can reset", false
    end

    tbRuntimeData.nDataVersion = 0
    tbRuntimeData.nCurYear = 1
    tbRuntimeData.tbUser = {}
    tbRuntimeData.nReadyNextStepCount = 0
    tbRuntimeData.tbLoginAccount = {}
    tbRuntimeData.tbCutdownProduct = {}
    tbRuntimeData.bPlaying = false
    tbRuntimeData.tbMarket = {1}
    tbRuntimeData.nTimeLimitToNextSyncStep = 0
    tbRuntimeData.nSkipDestNextSyncStep = 0
    tbRuntimeData.nCurSyncStep = 0
    return "success", true
end

-- 限时 {FuncName = "TimeLimitToNextSyncStep", TimeLimit = 0}  --TimeLimit 单位秒， 自动快进到下一个同步步骤的限时。0为取消限时
function tbFunc.Action.TimeLimitToNextSyncStep(tbParam)
    if not table.contain_value(tbConfig.tbAdminAccount, tbParam.Account) then
        return "failed, only admin can setTimeLimit", false
    end

    if tbParam.TimeLimit == 0 then
        tbRuntimeData.nTimeLimitToNextSyncStep = 0
    else
        tbRuntimeData.nTimeLimitToNextSyncStep = os.time() + tbParam.TimeLimit


        for i = tbRuntimeData.nCurSyncStep + 1, #tbConfig.tbYearStep do
            local tbStep = tbConfig.tbYearStep[i]
            if tbStep.syncNextStep then
                tbRuntimeData.nSkipDestNextSyncStep = i
                break
            end
        end
    end
    return "success", true
end

function tbFunc.Action.DoOperate(tbParam)
    return tbFunc.Action.funcDoOperate[tbParam.OperateType](tbParam)
end

tbFunc.finalAction = {}

function tbFunc.finalAction.SettleOrder()
    --[[
        tbOrder = { -- 订单cfg
        [1] =  {  -- Y1
            a1 = {
                { n = 4, arpu = 6.6}, { n = 3, arpu = 6.3 }, { n = 2, arpu = 6 }, { n = 2, arpu = 5.7 }, -- 国内
                {}, -- 日韩
                {}, -- 欧美
            },

        tbOrder = {
            a1 = {{ cfg = {}, done = false}, {cfg = {}, done = true}}
        }

    ]]

    local tbProductName = {}
    local tbOrderCfg = tbRuntimeData.tbOrder[tbRuntimeData.nCurYear]
    for productName, tbMarketOrder in pairs(tbOrderCfg) do
        --print("productName:" .. productName)

        for marketIndex, tbOrderList in ipairs(tbMarketOrder) do
            --print("----------------------------------------------------------")
            --print("marketIndex:" .. tostring(marketIndex))

            local sortedUserList = {}
            local nExpenseCount = 0
            for userName, tbUser in pairs(tbRuntimeData.tbUser) do
                --print("userName:" .. userName)
                if tbUser.tbMarketingExpense[productName] then
                    local expense = tbUser.tbMarketingExpense[productName][marketIndex] or 0
                    table.insert(sortedUserList, {
                        user = userName,
                        count = expense,
                        rand = math.random(100),
                    })

                    if tbUser.tbMarketingExpense[productName][marketIndex] then
                        nExpenseCount = nExpenseCount + expense
                    end
                    --print("nExpenseCount"..tostring(nExpenseCount))
                end
            end

            table.sort(sortedUserList, function (x, y)
                if x.count == y.count then
                    return x.rand > y.rand
                end

                return x.count > y.count
            end)

            local nIndex = 1
           -- print("#tbOrderList:"..tostring(#tbOrderList))
            while #tbOrderList > 0 do
                --print(" #tbOrderList")
                local tbOrder =  tbOrderList[1]

                if nExpenseCount == 0 then break end

                if nIndex > #sortedUserList or sortedUserList[nIndex].count == 0 then
                    --nIndex = 1 -- 改成每个产品最多一个订单
                    break
                end
                
                local tbUser = tbRuntimeData.tbUser[sortedUserList[nIndex].user]
                tbUser.tbOrder[productName] = tbUser.tbOrder[productName] or {}
                table.insert(tbUser.tbOrder[productName], {
                    market = marketIndex,
                    expense = sortedUserList[nIndex].count,
                    cfg = tbOrder,
                    done = false
                })
                tbProductName[productName] = true

                nExpenseCount = nExpenseCount - 1
                nIndex = nIndex + 1

                table.remove(tbOrderList, 1)
            end
        end
    end

    for productName, _ in pairs(tbProductName) do
        local productType = string.sub(productName, 1, 1)
        local productLevel = string.sub(productName, 2, 2)
        if productLevel == "2" then
            tbRuntimeData.tbCutdownProduct[productType.."1"] = true
        end
    end

    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        tbUser.tbMarketingExpense = {}
    end
end

function tbFunc.finalAction.SettleHire()
    --[[
    tbManpower = { -- 人才市场各等级人数
        0, 0, 0, 0, 0
    },
    tbNewManpowerPerYear = {  -- 每年人才市场各等级新进人数
        {61, 26, 12, 1, 0},
        {66, 39, 21, 4, 0},
        {77, 54, 38, 11, 0},
        {76, 65, 50, 19, 0},
        {53, 54, 41, 19, 3},
        {43, 43, 45, 21, 8},
        {32, 36, 38, 24, 10},
        {25, 29, 30, 24, 12},
        {20, 23, 29, 26, 12},
        {21, 20, 30, 31, 18},
    },
    fSeason1NewManpowerRatio = 0.3,  -- 一季度新进人数占全年人数比例， 剩下的三季度新进

    tbUser.tbHire = { nNum = tbParam.nNum, nExpense = tbParam.nExpense }
    ]]

    -- 计算权重
    local tbUserHireInfo = {}
    local nTotalWeight = 0
    local nTotalNeed = 0
    for userName, tbUser in pairs(tbRuntimeData.tbUser) do
        if tbUser.tbHire and tbUser.tbHire.nNum and tbUser.tbHire.nNum  > 0 then
            local nWeight = math.floor(tbUser.tbHire.nExpense / tbUser.tbHire.nNum * (1 + (tbUser.nSalaryLevel - 1) * tbConfig.fHireWeightRatioPerLevel) * 1000 + 0.5)
            table.insert(tbUserHireInfo, {
                userName = userName,
                nNum = tbUser.tbHire.nNum,
                nWeight = nWeight,
                tbNewManpower = {0, 0, 0, 0, 0}
            })

            nTotalWeight = nTotalWeight + nWeight
            nTotalNeed = nTotalNeed + tbUser.tbHire.nNum
        end
    end

    -- 开始随机发派人才
    local nTopLevel = #tbRuntimeData.tbManpower
    while nTotalNeed > 0 do
        while nTopLevel > 0 and tbRuntimeData.tbManpower[nTopLevel] == 0 do
            nTopLevel = nTopLevel - 1
        end

        if nTopLevel == 0 then
            break
        end

        local nRand = math.random(nTotalWeight)
        for _, tbHireInfo in ipairs(tbUserHireInfo) do
            if tbHireInfo.nNum > 0 then
                if nRand <= tbHireInfo.nWeight then
                    tbRuntimeData.tbManpower[nTopLevel] = tbRuntimeData.tbManpower[nTopLevel] - 1

                    tbHireInfo.nNum = tbHireInfo.nNum - 1
                    tbHireInfo.tbNewManpower[nTopLevel] = tbHireInfo.tbNewManpower[nTopLevel] + 1

                    nTotalNeed = nTotalNeed - 1
                    if tbHireInfo.nNum == 0 then
                        nTotalWeight = nTotalWeight - tbHireInfo.nWeight
                    end
                    break
                else
                    nRand = nRand - tbHireInfo.nWeight
                end
            end
        end
    end

    -- 竞标结果更新到人力
    for _, tbHire in ipairs(tbUserHireInfo) do
        local tbUser = tbRuntimeData.tbUser[tbHire.userName]
        for i = 1, #tbUser.tbIdleManpower do
            tbUser.tbIdleManpower[i] = tbUser.tbIdleManpower[i] + tbHire.tbNewManpower[i]
            tbUser.nTotalManpower = tbUser.nTotalManpower + tbHire.tbNewManpower[i]
        end
    end

    -- TODO: tbUserHireInfo 里的数据存一下

    -- 清除招聘投标数据
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        tbUser.tbHire = { nNum = 0 , nExpense = 0}
        tbUser.bManpowerMarketDone = false
    end
end

function tbFunc.finalAction.NewYear()
    print("new year")
    tbRuntimeData.nCurYear = tbRuntimeData.nCurYear + 1
    tbRuntimeData.nCurSyncStep = 0
    tbRuntimeData.tbAddNewManpower = { false, false, false, false }

    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        tbUser.nCurYearStep = 0
        tbUser.nCurSeason = 0
        tbUser.nCurSeasonStep = 1
        tbUser.tbOrder = {}
        tbUser.tbLaborCost = {0, 0, 0, 0}
        tbUser.nMarketingExpense = 0
        tbUser.nAppendMarketCost = 0
        tbUser.nTax = 0
        tbUser.nSeverancePackage = 0

        -- 历年财报
        -- 去年财报
        tbUser.tbLastYearReport = tbUser.tbYearReport
        -- 今年财报
        tbUser.tbYearReport = Lib.copyTab(tbConfig.tbInitReport)
         -- 把今年财报也引用进来，万一能看实时呢^_^
        tbUser.tbHistoryYearReport[tbRuntimeData.nCurYear] = tbUser.tbYearReport
    end
end

function tbFunc.finalAction.EnableNextMarket()
    local tbEnableMarket = tbConfig.tbEnableMarketPerYear[tbRuntimeData.nCurYear] or {}
    for _, v in ipairs(tbEnableMarket) do
        if not table.contain_value(tbRuntimeData.tbMarket, v) then
            table.insert(tbRuntimeData.tbMarket, v)
            break
        end
    end
end

tbFunc.enterAction = {}
function tbFunc.enterAction.FinancialReport(tbUser)
    tbUser.tbYearReport.nLaborCosts = tbUser.tbYearReport.nLaborCosts + tbUser.nSeverancePackage
    for _, v in ipairs(tbUser.tbLaborCost) do
        tbUser.tbYearReport.nLaborCosts = tbUser.tbYearReport.nLaborCosts + v
    end

    tbUser.tbYearReport.nMarketingExpense = tbUser.nMarketingExpense
    tbUser.tbYearReport.nSGA = tbUser.tbYearReport.nSGA + tbUser.nAppendMarketCost
    tbUser.tbYearReport.nGrossProfit = tbUser.tbYearReport.nTurnover
                                        - tbUser.tbYearReport.nLaborCosts
                                        - tbUser.tbYearReport.nMarketingExpense
                                        - tbUser.tbYearReport.nSGA

    tbUser.tbYearReport.nFinancialExpenses = 0
    tbUser.tbYearReport.nProfitBeforeTax = tbUser.tbYearReport.nGrossProfit
                                        - tbUser.tbYearReport.nFinancialExpenses

    tbUser.tbYearReport.nTax = math.floor(tbUser.tbYearReport.nProfitBeforeTax * tbConfig.fTaxRate + 0.5)
    if tbUser.tbYearReport.nTax < 0 then
        tbUser.tbYearReport.nTax = 0
    end

    tbUser.tbYearReport.nNetProfit = tbUser.tbYearReport.nProfitBeforeTax
                                        - tbUser.tbYearReport.nTax

    tbUser.tbYearReport.nEquity = tbUser.tbLastYearReport.nEquity
                                + tbUser.tbYearReport.nNetProfit
                                + tbUser.tbYearReport.nFinance

    tbUser.tbYearReport.nFounderEquity = math.floor(tbUser.tbYearReport.nEquity * tbUser.fEquityRatio + 0.5)

    tbUser.tbYearReport.nCash = tbUser.nCash
end

function tbFunc.enterAction.Year1FixManpower(tbUser)
    if tbRuntimeData.nCurYear ~= 1 then
        return
    end

    tbUser.nIdleManpower = tbUser.nIdleManpower + 70
    tbUser.nTotalManpower = tbUser.nTotalManpower + 70
end

function tbFunc.enterAction.EnableMarketTip(tbUser)
    local tbEnableMarket = tbConfig.tbEnableMarketPerYear[tbRuntimeData.nCurYear]
    if tbEnableMarket and #tbEnableMarket > 0 then
        tbUser.szTitle = "开放市场:"..table.concat(tbEnableMarket, ", ")
    else
        tbUser.szTitle = "无新开放市场"
    end
end

function tbFunc.enterAction.UndoneOrderPunish(tbUser)
    local nPay = 0
    for _, tbProductOrder in pairs(tbUser.tbOrder) do
        for _, tbOrder in pairs(tbProductOrder) do
            if not tbOrder.done then
                nPay = nPay + math.floor(tbOrder.cfg.n * tbOrder.cfg.arpu / 2 + 0.5)
            end
        end
    end

    tbUser.nCash = tbUser.nCash - nPay
    if nPay == 0 then
        tbUser.szTitle = "你已完成所有用户"
    else
        tbUser.szTitle = "因未完成用户扣除用户面值50%罚金。 扣除现金"..tostring(nPay)
    end
end

function tbFunc.enterAction.SkipStep(tbUser)
    userNewStep(tbUser)
end

function tbFunc.enterAction.AutoDoneIfNoLoss(tbUser)
    tbUser.bStepDone = true
end

function tbFunc.enterAction.AutoDoneIfNoInflow(tbUser)
    tbUser.bStepDone = true
end

function tbFunc.enterAction.AddNewManpower(tbUser)
    local nCurSeason = tbUser.nCurSeason

    -- 第一个进入该步骤的玩家，触发人才市场补充人才
    if tbRuntimeData.tbAddNewManpower[nCurSeason] then
        return
    end

    if tbRuntimeData.nCurYear <= #tbConfig.tbNewManpowerPerYear then
        local tbNewManpower = tbConfig.tbNewManpowerPerYear[tbRuntimeData.nCurYear]
        for i = 1, #tbRuntimeData.tbManpower do
            local nNew = 0
            if nCurSeason == 1 then
                nNew = math.floor(tbNewManpower[i] * tbConfig.fSeason1NewManpowerRatio + 0.5)
            elseif nCurSeason == 3 then
                nNew = tbNewManpower[i] - math.floor(tbNewManpower[i] * tbConfig.fSeason1NewManpowerRatio + 0.5)
            end

            tbRuntimeData.tbManpower[i] = tbRuntimeData.tbManpower[i] + nNew
        end
    end

    tbRuntimeData.tbAddNewManpower[nCurSeason] = true
end

function tbFunc.enterAction.SettleFire(tbUser)
    for i = 1, #tbUser.tbFireManpower do
        tbRuntimeData.tbManpower[i] = tbRuntimeData.tbManpower[i] + tbUser.tbFireManpower[i]

        tbUser.nTotalManpower = tbUser.nTotalManpower - tbUser.tbFireManpower[i]
        tbUser.tbFireManpower[i] = 0
    end

    userNewStep(tbUser)
end

function tbFunc.enterAction.SettleTrain(tbUser)
    for i = 5 - 1, 1, -1 do -- 从高到低遍历， 防止某级没有员工了但是设置了培训，会出现某员工连升级2次的情况
        for _, tbProduct in pairs(tbUser.tbProduct) do -- TODO：改成按照产品优先级排序
            if tbProduct.tbManpower[i] > 0 then
                local nLevelUpCount = math.min(tbProduct.tbManpower[i], tbUser.tbTrainManpower[i])
                
                tbUser.tbTrainManpower[i] = tbUser.tbTrainManpower[i] - nLevelUpCount
                tbProduct.tbManpower[i] = tbProduct.tbManpower[i] - nLevelUpCount
                tbProduct.tbManpower[i + 1] = tbProduct.tbManpower[i + 1] + nLevelUpCount
            end
        end

        local nLevelUpCount = math.min(tbUser.tbIdleManpower[i], tbUser.tbTrainManpower[i])
        tbUser.tbTrainManpower[i] = tbUser.tbTrainManpower[i] - nLevelUpCount
        tbUser.tbIdleManpower[i] = tbUser.tbIdleManpower[i] - nLevelUpCount
        tbUser.tbIdleManpower[i + 1] = tbUser.tbIdleManpower[i + 1] + nLevelUpCount
    end

    tbUser.bCommitTrainDone = false
end

tbFunc.timeLimitAction = {}
function tbFunc.timeLimitAction.PayOffSalary(tbUser)
    if tbUser.bStepDone then
        return
    end
    DoPayOffSalary(tbUser)
end

tbFunc.Action.funcDoOperate = {}
-- 下一步 推进进度 {FuncName = "DoOperate", OperateType = "NextStep"}   -- 考虑校验当前Step，防止点了2次Step
function tbFunc.Action.funcDoOperate.NextStep(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    local tbStepCfg = tbConfig.tbYearStep[tbUser.nCurYearStep]

    if tbStepCfg.mustDone and not tbUser.bStepDone then
        return "must done step", false
    end

    if tbUser.bReadyNextStep then
        return "waitting others", true
    end

    if tbStepCfg.syncNextStep then
        tbUser.bReadyNextStep = true
        tbRuntimeData.nReadyNextStepCount = tbRuntimeData.nReadyNextStepCount + 1
        checkAllNextStep(tbStepCfg)
        return "success", true
    else
        userNewStep(tbUser)
    end

    return "success", true
end

function checkAllNextStep(tbStepCfg)
    if tbRuntimeData.nReadyNextStepCount ~= table.get_len(tbRuntimeData.tbUser) then
        return
    end
    tbRuntimeData.nReadyNextStepCount = 0

    if tbStepCfg.finalAction then
        tbFunc.finalAction[tbStepCfg.finalAction]()
    end

    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        userNewStep(tbUser)
    end
end

function userNewStep(tbUser)
    tbUser.nCurYearStep = tbUser.nCurYearStep + 1

    local tbNewStepCfg = tbConfig.tbYearStep[tbUser.nCurYearStep]
    tbUser.nCurSeason = tbNewStepCfg.nCurSeason or tbUser.nCurSeason
    tbUser.nCurSeasonStep = tbNewStepCfg.nCurSeasonStep or tbUser.nCurSeasonStep

    for _, v in pairs(tbUser.tbProduct) do
        v.done = false
    end
    tbUser.bStepDone = false
    tbUser.bReadyNextStep = false

    if tbNewStepCfg.enterAction then
        tbFunc.enterAction[tbNewStepCfg.enterAction](tbUser)
    end

    if tbNewStepCfg.syncNextStep then
        tbRuntimeData.nCurSyncStep = tbUser.nCurYearStep
    end

    if tbRuntimeData.nTimeLimitToNextSyncStep ~= 0 and tbUser.nCurYearStep > tbRuntimeData.nSkipDestNextSyncStep then
        tbRuntimeData.nTimeLimitToNextSyncStep = 0
        tbRuntimeData.nSkipDestNextSyncStep = 0
    end
end

-- 交税{FuncName = "DoOperate", OperateType = "Tax"}
function tbFunc.Action.funcDoOperate.Tax(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bStepDone then
        return "already done", false
    end

    if tbUser.tbLastYearReport and tbUser.tbLastYearReport.nTax > 0 then
        tbUser.nCash = tbUser.nCash - tbUser.tbLastYearReport.nTax -- 暂时允许玩家金钱为负
        tbUser.nTax = tbUser.tbLastYearReport.nTax
    end
    tbUser.bStepDone = true
    local szReturnMsg = string.format("成功交税，花费：%d", tbUser.tbLastYearReport and tbUser.tbLastYearReport.nTax or 0)
    return szReturnMsg, true
end

-- RaiseSalary 调薪 {FuncName = "DoOperate", OperateType = "RaiseSalary"}
function tbFunc.Action.funcDoOperate.RaiseSalary(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bStepDone then
        return "已经完成操作", false
    end

    tbUser.nSalaryLevel = tbUser.nSalaryLevel + 1
    tbUser.bStepDone = true

    local szReturnMsg = string.format("薪水等级提升至%d级", tbUser.nSalaryLevel)
    return szReturnMsg, true
end

-- 提交市场预算 {FuncName = "DoOperate", OperateType = "CommitMarket", tbMarketingExpense = {a1 = { 2, 1, 1}, a2 = { 5, 3, 3}, b1 = { 20, 40, 3}}}
function tbFunc.Action.funcDoOperate.CommitMarket(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bStepDone then
        return "already done", false
    end

    local nTotalCost = 0
    for productName, tbMarketingExpenseCurPrdt in pairs(tbParam.tbMarketingExpense) do
        if not tbUser.tbProduct[productName] or tbUser.tbProduct[productName].progress ~= tbConfig.tbProduct[productName].maxProgress then
            return "need develpment max progress", false
        end

        for i, v in ipairs(tbMarketingExpenseCurPrdt) do
            if v ~= 0 and not table.contain_value(tbUser.tbProduct[productName].market, i) then
                return "product not published in market"..tostring(i), false
            end

            nTotalCost = nTotalCost + v
        end
    end

    if nTotalCost ~= 0 and nTotalCost > tbUser.nCash then
        return "cash not enough", false
    end

    tbUser.nCash = tbUser.nCash - nTotalCost
    tbUser.tbMarketingExpense = tbParam.tbMarketingExpense
    tbUser.nMarketingExpense = tbUser.nMarketingExpense + nTotalCost
    tbUser.bStepDone = true
    local szReturnMsg = string.format("成功提交市场营销预算，共花费：%d", nTotalCost)
    return szReturnMsg, true
end

-- 提交市场预算 {FuncName = "DoOperate", OperateType = "SeasonCommitMarket", tbMarketingExpense = {a1 = { 2, 1, 1}, a2 = { 5, 3, 3}, b1 = { 20, 40, 3}}}
function tbFunc.Action.funcDoOperate.SeasonCommitMarket(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bStepDone then
        return "already done", false
    end

    local nTotalCost = 0
    for productName, tbMarketingExpenseCurPrdt in pairs(tbParam.tbMarketingExpense) do
        if not tbUser.tbProduct[productName] or tbUser.tbProduct[productName].progress ~= tbConfig.tbProduct[productName].maxProgress then
            return "need develpment max progress", false
        end

        for i, v in ipairs(tbMarketingExpenseCurPrdt) do
            if v ~= 0 then
                if  not table.contain_value(tbUser.tbProduct[productName].market, i) then
                    return "product not published in market"..tostring(i), false
                end

                local tbProductOrder = tbUser.tbOrder[productName]
                if tbProductOrder then
                    for _, tbOrder in pairs(tbProductOrder) do
                        if i == tbOrder.market then
                            return "already has order", false
                        end
                    end
                end

                nTotalCost = nTotalCost + v
            end
        end
    end

    if nTotalCost ~= 0 and nTotalCost > tbUser.nCash then
        return "cash not enough", false
    end

    tbUser.nCash = tbUser.nCash - nTotalCost
    tbUser.tbMarketingExpense = tbParam.tbMarketingExpense
    tbUser.nMarketingExpense = tbUser.nMarketingExpense + nTotalCost
    tbUser.bStepDone = true
    return "success", true
end

-- 招聘 {FuncName = "DoOperate", OperateType = "CommitHire", nNum = 20, nExpense = 60}
function tbFunc.Action.funcDoOperate.CommitHire(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bManpowerMarketDone then
        return "已经设置过招聘计划", false
    end
    
    if tbParam.nNum == 0 then
        return "招聘人数至少1人", false
    end

    if tbParam.nExpense > tbUser.nCash then
        return "资金不足", false
    end

    tbUser.nCash = tbUser.nCash - tbParam.nExpense
    tbUser.nSeverancePackage = tbUser.nSeverancePackage + tbParam.nExpense
    tbUser.tbHire = { nNum = tbParam.nNum, nExpense = tbParam.nExpense }

    tbUser.bManpowerMarketDone = true
    local szReturnMsg = string.format("招聘投标：%d人，花费：%d", tbParam.nNum, tbParam.nExpense)
    return szReturnMsg, true
end

-- 产品上线 {FuncName = "DoOperate", OperateType = "PublishProduct", PublishProduct = "b2"}}
function tbFunc.Action.funcDoOperate.PublishProduct(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    local tbProduct = tbUser.tbProduct[tbParam.PublishProduct]
    if not tbProduct then
        return "product not exist", false
    end

    if tbProduct.published then
        return "already published", false
    end

    local tbProductCfg = tbConfig.tbProduct[tbParam.PublishProduct]
    if tbProduct.progress ~= tbProductCfg.maxProgress then
        return "progress not enough", false
    end

    if tbProduct.manpower > tbProductCfg.minManpower then
        local moveNum = tbProduct.manpower - tbProductCfg.minManpower

        tbProduct.manpower = tbProduct.manpower - moveNum
        tbUser.nIdleManpower = tbUser.nIdleManpower + moveNum
    end

    tbProduct.published = true
    tbUser.bStepDone = true
    local szReturnMsg = string.format("成功发布产品:%s", tbParam.PublishProduct)
    return szReturnMsg, true
end

-- 解雇 {FuncName = "DoOperate", OperateType = "CommitFire", nLevel = 1, nNum = 2}
function tbFunc.Action.funcDoOperate.CommitFire(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]

    if tbParam.nNum < 0 then
        return "解雇人数不能是"..tbParam.nNum, false
    end

    if tbUser.tbIdleManpower[tbParam.nLevel] < tbParam.nNum then
        return "人数不足", false
    end

    tbUser.tbFireManpower[tbParam.nLevel] = tbUser.tbFireManpower[tbParam.nLevel] + tbParam.nNum
    tbUser.tbIdleManpower[tbParam.nLevel] = tbUser.tbIdleManpower[tbParam.nLevel] - tbParam.nNum
    return string.format("成功解雇%d人,季度末将离开公司", tbParam.nNum), true
end

-- 培训 {FuncName = "DoOperate", OperateType = "CommitTrain", tbTrain = { 2, 1, 1, 0, 0}}
function tbFunc.Action.funcDoOperate.CommitTrain(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bCommitTrainDone then
        return "本季度已经设置过培训计划", false
    end

    local tbMax = Lib.copyTab(tbUser.tbIdleManpower)
    for i = 1, 5 do
        tbMax[i] = tbMax[i] + tbUser.tbFireManpower[i]
    end
    for _, tbProductInfo in pairs(tbUser.tbProduct) do
        for i = 1, 5 do
            tbMax[i] = tbMax[i] + tbProductInfo.tbManpower[i]
        end
    end

    for i = 1, 5 do
        tbMax[i] = math.max(1, math.floor(tbMax[i] * tbConfig.fTrainMaxRatioPerLevel))
    end

    tbMax[5] = 0

    local nTotalNum = 0
    for i = 1, 5 do
        nTotalNum = nTotalNum + tbParam.tbTrain[i]
        if tbParam.tbTrain[i] > tbMax[i] then
            return string.format("%d级员工最多只能培训%d个", i, tbMax[i]), false
        end
    end

    local nMaxTotalNum = math.floor(tbUser.nTotalManpower * tbConfig.fTrainMaxRatioTotal)
    if nTotalNum > nMaxTotalNum then
        return string.format("最多只能培训%d人", nMaxTotalNum), false
    end

    local nCost = nTotalNum * tbConfig.nSalary

    tbUser.nCash = tbUser.nCash - nCost
    tbUser.tbTrainManpower = tbParam.tbTrain
    tbUser.bCommitTrainDone = true
    return "成功设置培训", true
end

-- 立项 {FuncName = "DoOperate", OperateType = "CreateProduct", ProductName="b2", tbMarket = {1,2,3}}
function tbFunc.Action.funcDoOperate.CreateProduct(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if not table.contain_key(tbConfig.tbProduct, tbParam.ProductName) then
        return "invalid product name", false
    end

    if table.contain_key(tbUser.tbProduct, tbParam.ProductName) then
        return "product already exist", false
    end

    local productType = string.sub(tbParam.ProductName, 1, 1)
    local productLevel = string.sub(tbParam.ProductName, 2, 2)
    if productLevel == "2" then
        local lowProductName = productType.."1"
        if not tbUser.tbProduct[lowProductName] or not tbUser.tbProduct[lowProductName].published then
            return "need product "..productType.."1 published", false
        end
    end

    if #tbParam.tbMarket < 1 then
        return "at least on market", false
    end

    for _, v in ipairs(tbParam.tbMarket) do
        if not table.contain_value(tbRuntimeData.tbMarket, v) then
            return "invalid market:" .. tostring(v), false
        end
    end

    local nCost = 0
    if #tbParam.tbMarket > 1 then
        local addMarketCost = tbConfig.tbProduct[tbParam.ProductName].addMarketCost
        nCost = math.floor(addMarketCost / 2 + 0.5) * (#tbParam.tbMarket - 1)

        if tbUser.nCash < nCost then
            return "cash not enough", false
        end
    end

    tbUser.tbProduct[tbParam.ProductName] = { manpower = 0, progress = 0, market = tbParam.tbMarket, published = false, done = false }
    tbUser.nCash = tbUser.nCash - nCost
    tbUser.nAppendMarketCost = tbUser.nAppendMarketCost + nCost
    tbUser.bStepDone = true
    local szReturnMsg = string.format("成功立项：%s，初始市场：", tbParam.ProductName)
    for _, v in ipairs(tbParam.tbMarket) do
       -- szReturnMsg = string.format("%s %s", szReturnMsg, tbConfig.tbMarketName[v])
    end
    return szReturnMsg, true
end

-- 人员调整 {FuncName = "DoOperate", OperateType = "Turnover", GridType="product", GridName="b2"}
function tbFunc.Action.funcDoOperate.Turnover(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    local szReturnMsg = "success"

    if tbParam.GridType == "product" then
        local tbProduct = tbUser.tbProduct[tbParam.GridName]
        if not tbProduct then
            return "not product "..tbParam.GridName, false
        end
        local manpower = tbProduct.manpower
        local minManpowerCfg = tbConfig.tbProduct[tbParam.GridName].minManpower
        local maxManpowerCfg = tbConfig.tbProduct[tbParam.GridName].maxManpower
        if manpower < minManpowerCfg and manpower + tbUser.nIdleManpower >= minManpowerCfg then
            tbProduct.manpower = minManpowerCfg
            tbUser.nIdleManpower = tbUser.nIdleManpower + manpower - minManpowerCfg
            szReturnMsg = string.format("产品%s研发人员+%d", tbParam.GridName, minManpowerCfg)
        elseif not tbProduct.published and manpower < maxManpowerCfg and manpower + tbUser.nIdleManpower >= maxManpowerCfg then
            tbProduct.manpower = maxManpowerCfg
            tbUser.nIdleManpower = tbUser.nIdleManpower + manpower - maxManpowerCfg
            szReturnMsg = string.format("产品%s研发人员+%d", tbParam.GridName, maxManpowerCfg - manpower)
        else
            tbProduct.manpower = 0
            tbUser.nIdleManpower = tbUser.nIdleManpower + manpower
            szReturnMsg = string.format("产品%s研发人员-%d", tbParam.GridName, manpower)
        end
    end

    tbUser.bStepDone = true
    return szReturnMsg, true
end

-- 更新应收款 {FuncName = "DoOperate", OperateType = "UpdateReceivables"}
function tbFunc.Action.funcDoOperate.UpdateReceivables(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bStepDone then
        return "already done", false
    end

    local nCash = tbUser.tbReceivables[1]
    table.remove(tbUser.tbReceivables, 1)
    table.insert(tbUser.tbReceivables, 0)
    tbUser.nCash = tbUser.nCash + nCash
    tbUser.bStepDone = true
    local szReturnMsg = string.format("本季度更新应收款收入:%d", nCash)
    return szReturnMsg, true
end

-- 订单收款 {FuncName = "DoOperate", OperateType = "GainMoney", ProductName="b2"}
function tbFunc.Action.funcDoOperate.GainMoney(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    local tbProduct = tbUser.tbProduct[tbParam.ProductName]
    if not tbProduct then
        return "product not exist", false
    end

    if not tbProduct.published then
        return "unpublished", false
    end

    if tbProduct.manpower < tbConfig.tbProduct[tbParam.ProductName].minManpower then
        return "need more manpower", false
    end

    if tbProduct.done then
        return "already done", false
    end

    local nCashCount = 0
    local nTurnover = 0
    local tbOrderList = tbUser.tbOrder[tbParam.ProductName]
    if not tbOrderList then
        return string.format("not order %s", tbParam.ProductName), false
    end
    for _, tbOrder in ipairs(tbOrderList) do
        local nCash
        if tbRuntimeData.tbCutdownProduct[tbParam.ProductName] then
            nCash = math.floor(tbOrder.cfg.n * tbOrder.cfg.arpu / 2 + 0.5)
        else
            nCash = math.floor(tbOrder.cfg.n * tbOrder.cfg.arpu + 0.5)
        end

        -- if tbOrder.cfg.delaySeason and tbOrder.cfg.delaySeason > 0 then
        --     tbUser.tbReceivables[tbOrder.cfg.delaySeason] = tbUser.tbReceivables[tbOrder.cfg.delaySeason] + nCash
        -- else
            nCashCount = nCashCount + nCash
       -- end

        nTurnover = nTurnover + nCash
        tbOrder.done = true
    end

    tbUser.nCash = tbUser.nCash + nCashCount
    tbUser.tbYearReport.nTurnover = tbUser.tbYearReport.nTurnover + nTurnover

    tbProduct.done = true
    tbUser.bStepDone = true
    local szReturnMsg = string.format("产品%s本季度成功营收:%d", tbParam.ProductName, nTurnover)
    return szReturnMsg, true
end

-- 推进进度 {FuncName = "DoOperate", OperateType = "UpdateProductProgress", ProductName="b2"}
function tbFunc.Action.funcDoOperate.UpdateProductProgress(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    local tbProduct = tbUser.tbProduct[tbParam.ProductName]
    if not tbProduct then
        return "product not exist", false
    end

    if tbProduct.published then
        return "published", false
    end

    if tbProduct.done then
        return "already done", false
    end

    local tbProductCfg = tbConfig.tbProduct[tbParam.ProductName]
    if tbProduct.manpower == tbProductCfg.minManpower then
        tbProduct.progress = tbProduct.progress + 1
    elseif tbProduct.manpower == tbProductCfg.maxManpower then
        tbProduct.progress = tbProduct.progress + 2
    end

    if tbProduct.progress > tbProductCfg.maxProgress then
        tbProduct.progress = tbProductCfg.maxProgress
    end
    tbProduct.done = true
    tbUser.bStepDone = true
    
    local szReturnMsg = string.format("产品%s进度推进:%d/%d", tbParam.ProductName, tbProduct.progress, tbProduct.maxProgress)
    return szReturnMsg, true
end

-- 追加市场 {FuncName = "DoOperate", OperateType = "AddMarket", ProductName="b2", tbMarket={1, 2, 3}}
function tbFunc.Action.funcDoOperate.AddMarket(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if not table.contain_key(tbConfig.tbProduct, tbParam.ProductName) then
        return "invalid product name", false
    end

    local tbProduct = tbUser.tbProduct[tbParam.ProductName]
    if not tbProduct then
        return "product not exist", false
    end

    if tbProduct.progress ~= tbConfig.tbProduct[tbParam.ProductName].maxProgress then
        return "need develpment max progress", false
    end

    for _, v in ipairs(tbParam.tbMarket) do
        if not table.contain_value(tbRuntimeData.tbMarket, v) then
            return "invalid market:" .. tostring(v), false
        end
    end

    for _, v in ipairs(tbProduct.market) do
        if table.contain_value(tbParam.tbMarket, v) then
            return "can not select market:" .. tostring(v), false
        end
    end

    local nCost = 0
    if #tbParam.tbMarket > 0 then
        local addMarketCost = tbConfig.tbProduct[tbParam.ProductName].addMarketCost
        nCost = math.floor(addMarketCost + 0.5) * #tbParam.tbMarket

        if tbUser.nCash < nCost then
            return "cash not enough", false
        end
    end

    for _, v in ipairs(tbParam.tbMarket) do
        table.insert(tbProduct.market, v)
    end

    tbUser.nCash = tbUser.nCash - nCost
    tbUser.nAppendMarketCost = tbUser.nAppendMarketCost + nCost
    tbUser.bStepDone = true

    local szReturnMsg = "跳过追加市场"
    if #tbParam.tbMarket > 0 then
        szReturnMsg = string.format("%s产品成功追加市场：", tbParam.ProductName)
        for _, v in ipairs(tbParam.tbMarket) do
         --   szReturnMsg = string.format("%s %s", szReturnMsg, tbConfig.tbMarketName[v])
        end
    end
    return szReturnMsg, true
end

-- 发工资 {FuncName = "DoOperate", OperateType = "PayOffSalary"}
function tbFunc.Action.funcDoOperate.PayOffSalary(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bStepDone then
        return "already done", false
    end
    DoPayOffSalary(tbUser)
    return string.format("成功支付工资：%d", nCost), true
end

function DoPayOffSalary(tbUser)
    local nCost = tbUser.nTotalManpower * tbConfig.nSalary * (1 + (tbUser.nSalaryLevel - 1) * tbConfig.fSalaryRatioPerLevel)

    tbUser.nCash = tbUser.nCash - nCost  -- 先允许负数， 让游戏继续跑下去
    tbUser.tbLaborCost[tbUser.nCurSeason] = nCost
    tbUser.bStepDone = true
end

-- 融资 { FuncName = "DoOperate", OperateType = "Finance"}
function tbFunc.Action.funcDoOperate.Finance(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    local nFinance = tbUser.tbLastYearReport.nTurnover

    tbUser.tbYearReport.nFinance = tbUser.tbYearReport.nFinance + nFinance
    tbUser.nCash = tbUser.nCash + nFinance
    tbUser.fEquityRatio = tbUser.fEquityRatio / 2
end
--------------------------------------------------------------------

print("load SandTable.lua success")
