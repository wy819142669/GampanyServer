print(package.path)

package.path = "./script/?.lua;" .. package.path
--print(package.path)
require("Json")
require("Lib")
require("Config")

local tbRuntimeData = {
    nDataVersion = 1,
    nGameID = 0,
    bPlaying = false,
    tbMarket = { 1 },
    tbLoginAccount = {
        -- "王" = 4151234,
    }, -- 已登录账号
    nReadyNextStepCount = 0,
    -- 当前年份
    nCurYear = 1,
    --nCurYearStep = 1,
    --nCurSeason = 0,
    --nCurSeasonStep = 0,
    tbCutdownProduct = {
        -- a1 = true,
        -- b1 = true,
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
            -- 预研
            tbResearch = { d = { manpower = 20, leftPoint = 20, done = false }, e = { manpower = 30, leftPoint = 30 } },
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

local tbFunc = {}

function Reload(jsonParam)
    print("[lua] reload")

    print(jsonParam)
    --jsonParam = '{"x":1, "y":2}'
    local tbParam = JsonDecode(jsonParam)
    print(type(tbParam))
    tbParam = tbParam or {}
    tbParam.result = "reload success!"
    print(JsonEncode(tbParam))
    return JsonEncode(tbParam)
end

function OnReloadFinish(jsonParam)
    tbConfig.nLuaVersion = tbConfig.nLuaVersion + 1
end

function Action(jsonParam)
    local tbParam = JsonDecode(jsonParam)
    local func = tbFunc.Action[tbParam.FuncName]
    local szMsg = ""
    local bRet = false
    if func then
        szMsg, bRet = func(tbParam)
    else
        szMsg = "invalid FuncName"
    end
    local tbResult = {
        code = bRet and 0 or -1,
        msg = szMsg,
        tbRuntimeData = tbRuntimeData
    }

    -- 客户端要用tbLoginAccount来判断登录状态
    -- tbRuntimeData.tbLoginAccount[tbParam.Account] = os.time()
    return JsonEncode(tbResult)
end

function Query(jsonParam)
    local tbParam = JsonDecode(jsonParam)
    local func = tbFunc["Query"][tbParam.FuncName]
    local resultText = ""
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

function QueryTest(tbParam)

    return "success"
end

--------------------接口实现---------------------------------------
tbFunc.Action = {}
function tbFunc.Action.GetLuaFile(tbParam)
    if tbConfig.nLuaVersion ~= tbParam.nLuaVersion then
        -- todo:
        --return "success", false, { LuaFileContent = "" }
    end
    return "success", false
end

function tbFunc.Action.QueryRunTimeData(tbParam)
    return "success", true
end

-- 登录 {FuncName = "Login"}
function tbFunc.Action.Login(tbParam)
    -- if tbRuntimeData.bPlaying then
    --     return "failed, already start", false
    -- end
    tbRuntimeData.tbLoginAccount[tbParam.Account] = os.time()
    return "success", true
end

-- 登出 {FuncName = "Logout"}
function tbFunc.Action.Logout(tbParam)
    tbRuntimeData.tbLoginAccount[tbParam.Account] = nil
    tbRuntimeData.tbUser[tbParam.Account] = nil
    return "success", true
end

-- 开始 {FuncName = "DoStart", tbAccount = { "王" }}
function tbFunc.Action.DoStart(tbParam)
    if tbRuntimeData.bPlaying then
        return "failed, already start", false
    end

    for userName, _ in pairs(tbRuntimeData.tbLoginAccount) do
        tbRuntimeData.tbUser[userName] = Lib.copyTab(tbConfig.tbInitUserData)
        tbRuntimeData.tbUser[userName].szAccount = userName
    end

    tbRuntimeData.tbOrder = Lib.copyTab(tbConfig.tbOrder)
    tbRuntimeData.nDataVersion = 1
    tbRuntimeData.nCurYear = 1
    tbRuntimeData.nGameID = tbRuntimeData.nGameID + 1
    tbRuntimeData.bPlaying = true
    return "success", true
end

-- 重置 {FuncName = "DoReset"}
function tbFunc.Action.DoReset(tbParam)
    tbRuntimeData.nDataVersion = 0
    tbRuntimeData.nCurYear = 1
    tbRuntimeData.tbUser = {}
    tbRuntimeData.nReadyNextStepCount = 0
    tbRuntimeData.tbLoginAccount = {}
    tbRuntimeData.tbCutdownProduct = {}
    tbRuntimeData.bPlaying = false
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
                        count = expense
                    })

                    if tbUser.tbMarketingExpense[productName][marketIndex] then
                        nExpenseCount = nExpenseCount + expense
                    end
                    --print("nExpenseCount"..tostring(nExpenseCount))
                end
            end

            table.sort(sortedUserList, function (x, y)
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
                --print("gain")
                local tbUser = tbRuntimeData.tbUser[sortedUserList[nIndex].user]
                tbUser.tbOrder[productName] = tbUser.tbOrder[productName] or {}
                table.insert(tbUser.tbOrder[productName], { market = marketIndex, cfg = tbOrder, done = false})

                sortedUserList[nIndex].count = sortedUserList[nIndex].count - 1
                nExpenseCount = nExpenseCount - 1
                nIndex = nIndex + 1

                table.remove(tbOrderList, 1)
            end
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
        tbUser.nCurYearStep = 0
        tbUser.nCurSeason = 1
        tbUser.nCurSeasonStep = 1
        tbUser.tbOrder = {}

        -- 历年财报
        tbUser.tbHistoryYearReport = tbUser.tbHistoryYearReport or {}
        tbUser.tbHistoryYearReport[tbRuntimeData.nCurYear - 1] = tbUser.tbYearReport
        -- 去年财报
        tbUser.tbLastYearReport = tbUser.tbYearReport
        -- 今年财报
        tbUser.tbYearReport = Lib.copyTab(tbConfig.tbInitReport)
         -- 把今年财报也引用进来，万一能看实时呢^_^
        tbUser.tbHistoryYearReport[tbRuntimeData.nCurYear] = tbUser.tbYearReport
    end
end

function tbFunc.finalAction.EnableNextMarket()
    local tbEnableMarket = tbConfig.tbEnableMarketPerYear[tbRuntimeData.nCurYear]
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

    tbUser.tbYearReport.nNetProfit = tbUser.tbYearReport.nProfitBeforeTax
                                        - tbUser.tbYearReport.nTax
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
        tbUser.szTitle = "你已完成所有订单"
    else
        tbUser.szTitle = "因未完成订单扣除订单面值50%罚金。 扣除现金"..tostring(nPay)
    end
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
    if tbRuntimeData.nReadyNextStepCount ~= table.get_len(tbRuntimeData.tbLoginAccount) then
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
    for _, v in pairs(tbUser.tbResearch) do
        v.done = false
    end
    tbUser.bStepDone = false
    tbUser.bReadyNextStep = false

    if tbNewStepCfg.enterAction then
        tbFunc.enterAction[tbNewStepCfg.enterAction](tbUser)
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
    return "success", true
end

-- 提交市场预算 {FuncName = "DoOperate", OperateType = "CommitMarket", tbMarketingExpense = {a1 = { 2, 1, 1}, a2 = { 5, 3, 3}, b1 = { 20, 40, 3}}}
function tbFunc.Action.funcDoOperate.CommitMarket(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bStepDone then
        return "already done", false
    end

    local nTotalCost = 0
    for productName, tbMarketingExpenseCurPrdt in pairs(tbParam.tbMarketingExpense) do
        if not tbUser.tbProduct[productName] or not tbUser.tbProduct[productName].published then
            return "need published", false
        end

        for i, v in ipairs(tbMarketingExpenseCurPrdt) do
            if v ~= 0 and not table.contain_value(tbUser.tbProduct[productName].market, i) then
                return "product not published in market"..tostring(i), false
            end

            nTotalCost = nTotalCost + v
        end
    end

    if nTotalCost > tbUser.nCash then
        return "cash not enough", false
    end

    tbUser.nCash = tbUser.nCash - nTotalCost
    tbUser.tbMarketingExpense = tbParam.tbMarketingExpense
    tbUser.nMarketingExpense = tbUser.nMarketingExpense + nTotalCost
    tbUser.bStepDone = true
    return "success", true
end

-- 提交市场预算 {FuncName = "DoOperate", OperateType = "SeasonCommitMarket", tbMarketingExpense = {a1 = { 2, 1, 1}, a2 = { 5, 3, 3}, b1 = { 20, 40, 3}}}
function tbFunc.Action.funcDoOperate.SeasonCommitMarket(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bStepDone then
        return "already done", false
    end

    local nTotalCost = 0
    for productName, tbMarketingExpenseCurPrdt in pairs(tbParam.tbMarketingExpense) do
        if not tbUser.tbProduct[productName] or not tbUser.tbProduct[productName].published then
            return "need published", false
        end

        for i, v in ipairs(tbMarketingExpenseCurPrdt) do
            if v ~= 0 and not table.contain_value(tbUser.tbProduct[productName].market, i) then
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

    if nTotalCost > tbUser.nCash then
        return "cash not enough", false
    end

    tbUser.nCash = tbUser.nCash - nTotalCost
    tbUser.tbMarketingExpense = tbParam.tbMarketingExpense
    tbUser.nMarketingExpense = tbUser.nMarketingExpense + nTotalCost
    tbUser.bStepDone = true
    return "success", true
end

-- 年初招聘 {FuncName = "DoOperate", OperateType = "CommitNormalHire", nNum = 20}
function tbFunc.Action.funcDoOperate.CommitNormalHire(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    local nTens = math.floor(tbParam.nNum / 10)
    local nCost = nTens * tbConfig.nNormalHireCost

    if nCost > tbUser.nCash then
        return "cash not enough", false
    end

    tbUser.nCash = tbUser.nCash - nCost
    tbUser.nSeverancePackage = tbUser.nSeverancePackage + nCost
    tbUser.nIdleManpower = tbUser.nIdleManpower + nTens * 10
    tbUser.nTotalManpower = tbUser.nTotalManpower + nTens * 10
    tbUser.bStepDone = true
    return "success", true
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

    local productType = string.sub(tbParam.PublishProduct, 1, 1)
    local productLevel = string.sub(tbParam.PublishProduct, 2, 2)
    if productLevel == "2" then
        tbRuntimeData.tbCutdownProduct[productType.."1"] = true
    end

    tbProduct.published = true
    tbUser.bStepDone = true
    return "success", true
end

-- 临时招聘 {FuncName = "DoOperate", OperateType = "CommitTempHire", nNum = 20}
function tbFunc.Action.funcDoOperate.CommitTempHire(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    local nTens = math.floor(tbParam.nNum / 10)
    local nCost = nTens * tbConfig.nTempHireCost

    if nCost > tbUser.nCash then
        return "cash not enough", false
    end

    tbUser.nCash = tbUser.nCash - nCost
    tbUser.nSeverancePackage = tbUser.nSeverancePackage + nCost
    tbUser.nIdleManpower = tbUser.nIdleManpower + nTens * 10
    tbUser.nTotalManpower = tbUser.nTotalManpower + nTens * 10
    tbUser.bStepDone = true
    return "success", true
end

-- 解雇 {FuncName = "DoOperate", OperateType = "CommitFire", GridType = "idle", GridName = "", nNum = 20} -- GridType:[research\product\idle], GridName:[d\e\a1\b2\""]
function tbFunc.Action.funcDoOperate.CommitFire(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    local nTens = math.floor(tbParam.nNum / 10)
    local nCost = nTens * tbConfig.nFireCost
    local checkFunc, doUpdateManpowerFunc
    if tbParam.GridType == "research" then
        checkFunc = function ()
            if not tbUser.tbResearch[tbParam.GridName] or tbUser.tbResearch[tbParam.GridName].manpower < nTens * 10 then
                return "manpower not enough", false
            end
            return "success", true
        end

        doUpdateManpowerFunc = function ()
            tbUser.tbResearch[tbParam.GridName].manpower = tbUser.tbResearch[tbParam.GridName].manpower - nTens * 10
        end
    elseif tbParam.GridType == "product" then
        checkFunc = function ()
            if not tbUser.tbProduct[tbParam.GridName] or tbUser.tbProduct[tbParam.GridName].manpower < nTens * 10 then
                return "manpower not enough", false
            end
            return "success", true
        end

        doUpdateManpowerFunc = function ()
            tbUser.tbProduct[tbParam.GridName].manpower = tbUser.tbProduct[tbParam.GridName].manpower - nTens * 10
        end
    elseif tbParam.GridType == "idle" then
        checkFunc = function ()
            if tbUser.nIdleManpower < nTens * 10 then
                return "manpower not enough", false
            end
            return "success", true
        end

        doUpdateManpowerFunc = function ()
            tbUser.nIdleManpower = tbUser.nIdleManpower - nTens * 10
        end
    end

    local result, bOk = checkFunc()
    if not bOk then
        return result, false
    end

    tbUser.nCash = tbUser.nCash - nCost
    tbUser.nSeverancePackage = tbUser.nSeverancePackage + nCost
    doUpdateManpowerFunc()
    tbUser.nTotalManpower = tbUser.nTotalManpower - nTens * 10
    tbUser.bStepDone = true
    return "success", true
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

    local productType = string.sub(tbParam.ProductName, 1, 1)
    if tbUser.tbResearch[productType] and tbUser.tbResearch[productType].leftPoint ~= 0 then
        return "need research ready", false
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
    tbUser.bStepDone = true
    return "success", true
end

-- 人员调整 {FuncName = "DoOperate", OperateType = "Turnover", GridType="product", GridName="b2"}
function tbFunc.Action.funcDoOperate.Turnover(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]

    if tbParam.GridType == "research" then
        local manpower = tbUser.tbResearch[tbParam.GridName].manpower
        local manpowerCfg = tbConfig.tbResearch[tbParam.GridName].manpower
        if manpower < manpowerCfg and manpower + tbUser.nIdleManpower >= manpowerCfg then
            tbUser.tbResearch[tbParam.GridName].manpower = manpowerCfg
            tbUser.nIdleManpower = tbUser.nIdleManpower + manpower - manpowerCfg
        else
            tbUser.tbResearch[tbParam.GridName].manpower = 0
            tbUser.nIdleManpower = tbUser.nIdleManpower + manpower
        end
    elseif tbParam.GridType == "product" then
        local tbProduct = tbUser.tbProduct[tbParam.GridName]
        local manpower = tbProduct.manpower
        local minManpowerCfg = tbConfig.tbProduct[tbParam.GridName].minManpower
        local maxManpowerCfg = tbConfig.tbProduct[tbParam.GridName].maxManpower
        if manpower < minManpowerCfg and manpower + tbUser.nIdleManpower >= minManpowerCfg then
            tbProduct.manpower = minManpowerCfg
            tbUser.nIdleManpower = tbUser.nIdleManpower + manpower - minManpowerCfg
        elseif not tbProduct.published and manpower < maxManpowerCfg and manpower + tbUser.nIdleManpower >= maxManpowerCfg then
            tbProduct.manpower = maxManpowerCfg
            tbUser.nIdleManpower = tbUser.nIdleManpower + manpower - maxManpowerCfg
        else
            tbProduct.manpower = 0
            tbUser.nIdleManpower = tbUser.nIdleManpower + manpower
        end
    end

    tbUser.bStepDone = true
    return "success", true
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
    return "success", true
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

    if tbProduct.done then
        return "already done", false
    end

    local nCashCount = 0
    local tbOrderList = tbUser.tbOrder[tbParam.ProductName]
    if not tbOrderList then
        return string.format("not order %s", tbParam.ProductName), false
    end
    for _, tbOrder in ipairs(tbOrderList) do
        if tbRuntimeData.tbCutdownProduct[tbParam.ProductName] then
            nCashCount = nCashCount + math.floor(tbOrder.cfg.n * tbOrder.cfg.arpu / 2 + 0.5)
        else
            nCashCount = nCashCount + math.floor(tbOrder.cfg.n * tbOrder.cfg.arpu + 0.5)
        end
        tbOrder.done = true
    end

    -- todo：高品质产品对低品质的碾压， 需要大家同步推进季度？
    tbUser.nCash = tbUser.nCash + nCashCount  -- todo: 还未定义收款期限
    tbUser.tbYearReport.nTurnover = tbUser.tbYearReport.nTurnover + nCashCount

    tbProduct.done = true
    tbUser.bStepDone = true
    return "success", true
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
    return "success", true
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

    for _, v in ipairs(tbParam.tbMarket) do
        if not table.contain_value(tbRuntimeData.tbMarket, v) then
            return "invalid market:" .. tostring(v), false
        end
    end

    for _, v in ipairs(tbProduct.market) do
        if not table.contain_value(tbParam.tbMarket, v) then
            return "can not unselect market:" .. tostring(v), false
        end
    end

    local nCost = 0
    if #tbParam.tbMarket > #tbProduct.market then
        local addMarketCost = tbConfig.tbProduct[tbParam.ProductName].addMarketCost
        nCost = math.floor(addMarketCost + 0.5) * (#tbParam.tbMarket - #tbProduct.market)

        if tbUser.nCash < nCost then
            return "cash not enough", false
        end
    end

    tbProduct.market = tbParam.tbMarket
    tbUser.nCash = tbUser.nCash - nCost
    tbUser.nAppendMarketCost = tbUser.nAppendMarketCost + nCost
    tbUser.bStepDone = true
    return "success", true
end

-- 随机研发进度 {FuncName = "DoOperate", OperateType = "RollResearchPoint", ResearchName="d"}
function tbFunc.Action.funcDoOperate.RollResearchPoint(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    local tbResearch = tbUser.tbResearch[tbParam.ResearchName]
    if tbResearch.done then
        return "already done", false
    end

    if tbResearch.manpower < tbConfig.tbResearch[tbParam.ResearchName].manpower then
        return "manpower not enough", false
    end

    local nResearchPoint = math.random(1, 6)
    tbResearch.leftPoint = tbResearch.leftPoint - nResearchPoint
    if tbResearch.leftPoint < 0 then
        tbResearch.leftPoint = 0
    end
    tbResearch.done = true
    tbUser.bStepDone = true
    return string.format("success，%s产品roll点成功：%d", tbParam.ResearchName, nResearchPoint), true
end

-- 发工资 {FuncName = "DoOperate", OperateType = "PayOffSalary"}
function tbFunc.Action.funcDoOperate.PayOffSalary(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bStepDone then
        return "already done", false
    end
    local nTens = math.floor(tbUser.nTotalManpower / 10 + 0.5)
    local nCost = nTens * tbConfig.nSalary

    tbUser.nCash = tbUser.nCash - nCost  -- 先允许负数， 让游戏继续跑下去
    tbUser.tbLaborCost[tbUser.nCurSeason] = nCost
    tbUser.bStepDone = true
    return "success", true
end

--------------------------------------------------------------------

print("load success")
