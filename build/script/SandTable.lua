print(package.path)

package.path = "./script/?.lua;" .. package.path
--print(package.path)
require("Json")
require("Lib")
require("Config")
require("Production")
require("Admin")
require("DataSync")
require("Market")
require("HumanResources")

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

function tbFunc.finalAction.NewYear()
    print("new year")
    tbRuntimeData.nCurYear = tbRuntimeData.nCurYear + 1

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

tbFunc.Action.funcDoOperate = {}
tbFunc.Action.funcDoOperate.RaiseSalary = HumanResources.RaiseSalary  -- RaiseSalary 调薪 {FuncName = "DoOperate", OperateType = "RaiseSalary"}
tbFunc.Action.funcDoOperate.CommitHire = HumanResources.CommitHire  -- 招聘 {FuncName = "DoOperate", OperateType = "CommitHire", nNum = 20, nExpense = 60}
tbFunc.Action.funcDoOperate.CommitFire = HumanResources.CommitFire  -- 解雇 {FuncName = "DoOperate", OperateType = "CommitFire", nLevel = 1, nNum = 2}
tbFunc.Action.funcDoOperate.CommitTrain = HumanResources.CommitTrain  -- 培训 {FuncName = "DoOperate", OperateType = "CommitTrain", tbTrain = { 2, 1, 1, 0, 0}}
tbFunc.Action.funcDoOperate.Poach = HumanResources.Poach            -- 挖掘人才 {FuncName = "DoOperate", OperateType = "Poach", TargetUser = szName, nLevel = 5, nExpense = 12})
tbFunc.Action.funcDoOperate.CommitMarket = Market.CommitMarket      -- 提交市场竞标 {FuncName = "DoOperate", OperateType = "CommitMarket", tbMarketingExpense = {a = 1, b = 2, c = 1}}


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
        for _, tbUser in pairs(tbRuntimeData.tbUser) do
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
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        tbUser.bStepDone = false
	end
    print("=============== Year:".. tbRuntimeData.nCurYear .. " Season:" .. tbRuntimeData.nCurSeason .. "  ===============")
end

-- 每个季度开始前的自动处理
function DoPreSeason()
    HumanResources.AddNewManpower()  -- 新人才进入人才市场
    HumanResources.SettleDepart()  --办理离职（交付流失员工）
                    -- 更新产品品质
    HumanResources.SettleFire()  -- 解雇人员离职
    HumanResources.SettleTrain()  -- 培训中的员工升级
    HumanResources.SettlePoach()  -- 成功挖掘的人才入职
    HumanResources.SettleHire()   -- 人才市场招聘结果
                   -- 各品类市场份额刷新、Npc调整
end

-- 每个季度结束后的自动处理
function DoPostSeason()
                    -- 推进研发进度
    Market.SettleMarket()  -- 更新市场竞标结果
                    -- 获取上个季度市场收益
    HumanResources.PayOffSalary()  -- 支付薪水
end

-- 每年结束后的自动处理
function DoPostYear()
end

print("load SandTable.lua success")
