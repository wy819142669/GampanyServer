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
    --[[未实际启用，暂时注释掉
    nDataVersion = 1,
    nGameID = 0,
    --]]

    --==== 游戏整体运行信息 ====
    bPlaying = false,
    nCurYear = 1,       -- 当前年份
    nCurSeason = 1,     -- 当前季度, 取值未0~4, 0表示新年开始时且1季度开始前

    --==== 玩家相关信息 ====
    nGamerCount = 0,
    tbLoginAccount = {},    -- 已登录账号列表
    tbUser = {              -- 玩家运行时数据
        --[[default = {
            -- 当前季度
            nCurSeason = 1,
            -- 当前季度步骤
            nCurSeasonStep = 1,
            -- 当前步骤已经操作完，防止重复操作
            bStepDone = false,
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
    },

    --==== 产品市场相关信息 ====
    tbMarket = {},

    --==== 人才市场相关信息 ====
    tbManpower = { -- 人才市场各等级人数
        0, 0, 0, 0, 0
    },

    tbCutdownProduct = {
        -- a1 = true,
        -- b1 = true,
    },
    tbAddNewManpower = { false, false, false, false },    
}

local tbFunc = {
    Action = {},
    Query = {},
}

function Action(jsonParam)
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

function GetTableRuntime()
    return tbRuntimeData
end

--------------------接口实现---------------------------------------
-- 登录 {FuncName = "Login"}
function tbFunc.Action.Login(tbParam)
    if not table.contain_key(tbRuntimeData.tbLoginAccount, tbParam.Account) then
        if tbRuntimeData.nGamerCount >= tbConfig.nMaxGamerCount then
            print("Login : failed, too much gamers")
            return "failed, too much gamers", false
        end

        if tbRuntimeData.bPlaying and (not tbConfig.bDebug) then -- 已经开始后，非调试模式不能再进入
            return "failed, already start", false
        end

        tbRuntimeData.tbLoginAccount[tbParam.Account] = { loginTime = os.time()}
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

function tbFunc.Action.StepDone(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    tbUser.bStepDone = true
    NextStepIfAllGamersDone(false)
    return "success", true
end

function tbFunc.Action.DoOperate(tbParam)
    return tbFunc.Action.funcDoOperate[tbParam.OperateType](tbParam)
end

--todo: to delete
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

function SettleHire()
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

function SettleMarket()
    -- 份额流失
    for userName, tbUser in pairs(tbRuntimeData.tbUser) do
        for productName, tbProduct in pairs(tbUser.tbProduct) do
            local nQuality = tbProduct.nQuality or 0
            local fLossRate = (1.0 - tbConfig.tbProductRetentionRate[productName] - 0.01 * nQuality)
            if fLossRate < 0 then
                fLossRate = 0
            end

            local nLossMarket = math.floor(tbUser.tbMarket[productName] * fLossRate)
            tbUser.tbMarket[productName] = tbUser.tbMarket[productName] - nLossMarket;
            tbRuntimeData.tbMarket[productName] = tbRuntimeData.tbMarket[productName] + nLossMarket
        end
    end

    -- 份额分配
    for productName, nMarket in pairs(tbRuntimeData.tbMarket) do
        if nMarket > 0 then
            local tbInfos = {}
            local fTotalMarketValue = 0
            for userName, tbUser in pairs(tbRuntimeData.tbUser) do
                local nQuality = 0
                if tbUser.tbProduct[productName] then
                    nQuality = tbUser.tbProduct[productName].nQuality or 0
                end

                if tbUser.bMarketingDone == true and tbUser.tbMarketingExpense[productName] and nQuality > 0 then
                    -- TODO 当季度上线
                    local fMarketValue = tbUser.tbMarketingExpense[productName] * (1.3 ^ (nQuality - 1))
                    fTotalMarketValue = fTotalMarketValue + fMarketValue
                    table.insert(tbInfos, {
                        userName = userName,
                        fMarketValue = fMarketValue,
                    })
                end
            end

            if fTotalMarketValue > 0 then
                local nTotalMarket = tbRuntimeData.tbMarket[productName]
                local nTotalCost = 0
                for _, tbInfo in pairs(tbInfos) do
                    local nCost = math.floor(nTotalMarket * (tbInfo.fMarketValue / fTotalMarketValue))
                    tbRuntimeData.tbUser[tbInfo.userName].tbMarket[productName] = tbRuntimeData.tbUser[tbInfo.userName].tbMarket[productName] + nCost
                    nTotalCost = nTotalCost + nCost
                    print("user: " .. tostring(tbInfo.userName) .. " product: " .. tostring(productName) .. "Add Market: " .. tostring(nCost) .. 
                    "TotalMarket: " .. tostring(nTotalMarket) .. "MarketValue: " .. tostring(tbInfo.fMarketValue) .. "TotalMarketValue: " .. tostring(fTotalMarketValue))
                end

                tbRuntimeData.tbMarket[productName] = tbRuntimeData.tbMarket[productName] - nTotalCost
            end
        end
    end

    -- 清除
    for userName, tbUser in pairs(tbRuntimeData.tbUser) do
        tbUser.bMarketingDone = false
        tbUser.tbMarketingExpense = {}
    end
end

function tbFunc.finalAction.NewYear()
    print("new year")
    tbRuntimeData.nCurYear = tbRuntimeData.nCurYear + 1
    tbRuntimeData.tbAddNewManpower = { false, false, false, false }

    for _, tbUser in pairs(tbRuntimeData.tbUser) do
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

--todo: to delete
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

function SettleDepart()
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        for i = 1, #tbUser.tbDepartManpower do
            local nNum = tbUser.tbDepartManpower[i]

            if nNum > 0 then
                for _, tbProductInfo in pairs(tbUser.tbProduct) do
                    local nCount = math.min(nNum, tbProductInfo.tbManpower[i])
                    nNum = nNum - nCount
                    tbProductInfo.tbManpower[i] = tbProductInfo.tbManpower[i] - nCount

                    if nNum == 0 then
                        break
                    end
                end

                local nCount = math.min(nNum, tbUser.tbIdleManpower[i])
                nNum = nNum - nCount
                tbUser.tbIdleManpower[i] = tbUser.tbIdleManpower[i] - nCount

                nCount = math.min(nNum, tbUser.tbFireManpower[i])
                nNum = nNum - nCount
                tbUser.tbFireManpower[i] = tbUser.tbFireManpower[i] - nCount

                assert(nNum == 0)
            end
            tbUser.nTotalManpower = tbUser.nTotalManpower - tbUser.tbDepartManpower[i]
            tbUser.tbDepartManpower[i] = 0
        end
    end
end

function SettlePoach()
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        if tbUser.tbPoach and tbUser.tbPoach.bSuccess then
            tbUser.tbIdleManpower[tbUser.tbPoach.nLevel] = tbUser.tbIdleManpower[tbUser.tbPoach.nLevel] + 1
            tbUser.nTotalManpower = tbUser.nTotalManpower + 1
        end

        tbUser.tbPoach = nil
        tbUser.bPoachDone = false
    end
end

function AddNewManpower()
    local nCurSeason = tbRuntimeData.nCurSeason
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
end

function SettleFire()
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        for i = 1, #tbUser.tbFireManpower do
            if tbUser.tbFireManpower[i] ~= 0 then
                tbRuntimeData.tbManpower[i] = tbRuntimeData.tbManpower[i] + tbUser.tbFireManpower[i]
                tbUser.nTotalManpower = tbUser.nTotalManpower - tbUser.tbFireManpower[i]
                tbUser.tbFireManpower[i] = 0
            end
        end
    end
end

function SettleTrain()
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
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
end


tbFunc.Action.funcDoOperate = {}
--    tbUser.nCurSeason = tbNewStepCfg.nCurSeason or tbUser.nCurSeason
--    tbUser.nCurSeasonStep = tbNewStepCfg.nCurSeasonStep or tbUser.nCurSeasonStep

--    for _, v in pairs(tbUser.tbProduct) do
--        v.done = false
--    end
--    tbUser.bStepDone = false

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
    if tbUser.bStepDone or tbRuntimeData.nCurSeason ~= 0 then
        return "该步骤已结束", false
    end
    tbUser.nSalaryLevel = tbUser.nSalaryLevel + 1
    local szReturnMsg = string.format("薪水等级提升至%d级", tbUser.nSalaryLevel)
    return szReturnMsg, true
end

-- 提交市场竞标 {FuncName = "DoOperate", OperateType = "CommitMarket", tbMarketingExpense = {a = 1, b = 2, c = 1}}
function tbFunc.Action.funcDoOperate.CommitMarket(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bMarketingDone then
        return "已经设置过市场竞标计划", false
    end

    local nTotalCost = 0
    for productName, nMarketingExpense in pairs(tbParam.tbMarketingExpense) do
        if not tbUser.tbProduct[productName] or tbUser.tbProduct[productName].progress ~= tbConfig.tbProduct[productName].maxProgress then
            return "研发进度需要完成", false
        end

        nTotalCost = nTotalCost + nMarketingExpense;
    end

    if nTotalCost ~= 0 and nTotalCost > tbUser.nCash then
        return "资金不足", false
    end
    
    tbUser.nCash = tbUser.nCash - nTotalCost
    tbUser.tbMarketingExpense = tbParam.tbMarketingExpense

    tbUser.bMarketingDone = true
    local szReturnMsg = string.format("市场竞标:花费：%d", nTotalCost)
    return szReturnMsg, true

end

-- 提交市场预算 {FuncName = "DoOperate", OperateType = "SeasonCommitMarket", tbMarketingExpense = {a1 = { 2, 1, 1}, a2 = { 5, 3, 3}, b1 = { 20, 40, 3}}}
--[[function tbFunc.Action.funcDoOperate.SeasonCommitMarket(tbParam)
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
end]]

-- 招聘 {FuncName = "DoOperate", OperateType = "CommitHire", nNum = 20, nExpense = 60}
function tbFunc.Action.funcDoOperate.CommitHire(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bManpowerMarketDone then
        return "已经设置过招聘计划", false
    end
    
    if tbRuntimeData.nCurSeason == 2 or tbRuntimeData.nCurSeason == 4 then
        return "只有1、3季度才可以招聘", false
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

-- 挖掘人才 {FuncName = "DoOperate", OperateType = "Poach", TargetUser = szName, nLevel = 5, nExpense = 12})
function tbFunc.Action.funcDoOperate.Poach(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bPoachDone then
        return "本季度已经执行过挖掘", false
    end

    local tbTargetUser = tbRuntimeData.tbUser[tbParam.TargetUser]
    if not tbTargetUser then
        return "目标公司不存在", false
    end

    if not tbParam.nLevel or tbParam.nLevel < 1 then
        return "需要人才等级无效", false
    end

    if not tbParam.nExpense or tbParam.nExpense < tbConfig.tbPoachExpenseRatio[1] * tbConfig.nSalary then
        return "投入费用无效", false
    end

    local szResult = ""
    local bSuccess = false
    local hasTargetLevelManpower = (tbTargetUser.tbIdleManpower[tbParam.nLevel] ~= 0)
    if not hasTargetLevelManpower then
        for _, tbProductInfo in pairs(tbTargetUser.tbProduct) do
            if tbProductInfo.tbManpower[tbParam.nLevel] ~= 0 then
                hasTargetLevelManpower = true
                break
            end
        end
    end

    if not hasTargetLevelManpower then
        szResult = "目标公司并没有你需要的人才"
    else
        local rand = math.random()
        local nSuccessWeight = tbParam.nExpense * 5 / tbParam.nLevel + tbConfig.nSalary * (1 + (tbUser.nSalaryLevel - 1) * tbConfig.fPoachSalaryLevelRatio) * tbConfig.nPoachSalaryWeight
        local nFailedWeight =  tbConfig.nSalary * (1 + (tbTargetUser.nSalaryLevel - 1) * tbConfig.fPoachSalaryLevelRatio) * tbConfig.nPoachSalaryWeight
        print("poach - success:", nSuccessWeight, "failed:", nFailedWeight, "rand:", rand, "sueecss ratio:", nSuccessWeight / (nSuccessWeight + nFailedWeight))
        if nSuccessWeight < nFailedWeight then
            szResult = "对于你提出的方案，对方坚决拒绝"
        elseif rand > nSuccessWeight / (nSuccessWeight + nFailedWeight) then
            szResult = "对于你提出的方案，对方犹豫了好一会儿"
        else
            szResult = "对方同意加入你"
            bSuccess = true
        end
    end

    local nCost
    if bSuccess then
        nCost = tbParam.nExpense
        tbTargetUser.tbDepartManpower[tbParam.nLevel] = tbTargetUser.tbDepartManpower[tbParam.nLevel] + 1
    else
        nCost = math.floor(tbParam.nExpense * (1 - tbConfig.fPoachFailedReturnExpenseRatio))
    end

    tbUser.nCash = tbUser.nCash - nCost
    tbUser.tbPoach = {
        TargetUser = tbParam.TargetUser,
        nLevel = tbParam.nLevel,
        nExpense = tbParam.nExpense,
        szResult = szResult,
        bSuccess = bSuccess
    }
    tbUser.bPoachDone = true
    return szResult, true
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

function PayOffSalary()
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        local nCost = tbUser.nTotalManpower * tbConfig.nSalary * (1 + (tbUser.nSalaryLevel - 1) * tbConfig.fSalaryRatioPerLevel)

        tbUser.nCash = tbUser.nCash - nCost  -- 先允许负数， 让游戏继续跑下去
        tbUser.tbLaborCost[tbRuntimeData.nCurSeason] = nCost
    end
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
function NextStepIfAllGamersDone(forceAllDone)
    local bAllDone = true
    if not forceAllDone then
        for szAccount, tbUser in pairs(tbRuntimeData.tbUser) do
            if not tbUser.bStepDone then
                bAllDone = false
                break
            end
	    end
    end
    if not bAllDone then
        return
    end
   
    -- 切换到下一步骤
    if tbRuntimeData.nCurSeason == 0 then
        tbRuntimeData.nCurSeason = 1
        DoPreSeason()
    else
        DoPostSeason()
        if tbRuntimeData.nCurSeason < 4 then
            tbRuntimeData.nCurSeason = tbRuntimeData.nCurSeason +1
            DoPreSeason()
        else
            DoPostYear()
            tbRuntimeData.nCurYear = tbRuntimeData.nCurYear + 1
            tbRuntimeData.nCurSeason = 0
        end
    end
    -- 重置步骤完成标记
    for szAccount, tbUser in pairs(tbRuntimeData.tbUser) do
        tbUser.bStepDone = false
	end
    print("=============== Year:".. tbRuntimeData.nCurYear .. " Season:" .. tbRuntimeData.nCurSeason .. "  ===============")
end

-- 每个季度开始前的自动处理
function DoPreSeason()
    --[[{ desc = "获取上个季度市场收益", nStepUniqueId = 14},
        { desc = "市场份额刷新", nStepUniqueId = 17},
        { desc = "更新产品品质", nStepUniqueId = 3},]]

    AddNewManpower()  -- 新人才进入人才市场
    SettleDepart()  --办理离职（交付流失员工）
    SettleFire()  -- 解雇人员离职
    SettleTrain()  -- 培训中的员工升级
    SettlePoach()  -- 成功挖掘的人才入职
    SettleHire()   -- 人才市场招聘结果
end

-- 每个季度结束后的自动处理
function DoPostSeason()
    --{ desc = "推进研发进度", nStepUniqueId = 13},
    SettleMarket();
    PayOffSalary()
end

-- 每年结束后的自动处理
function DoPostYear()
end

print("load SandTable.lua success")
