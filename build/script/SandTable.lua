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
    tbPlayAccount = {}, -- 参加游戏账号
    -- 当前年份
    nCurYear = 1,
    nCurYearStep = 1,
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
    local result = ""
    if func then
        result = func(tbParam)
    else
        result = "invalid FuncName"
    end
    local tbResult = {
        result = result,
        tbRuntimeData = tbRuntimeData
    }

    tbRuntimeData.tbLoginAccount[tbParam.Account] = os.time()
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
    if not table.contain_value(tbConfig.tbAccount, tbParam.Account)  then
        return "account invalid", false
    end

    tbRuntimeData.tbLoginAccount[tbParam.Account] = os.time()
    return "success", true
end

-- 开始 {FuncName = "DoStart", tbAccount = { "张", "王" }}
function tbFunc.Action.DoStart(tbParam)
    if #tbRuntimeData.bPlaying ~= 0 then
        return "failed, already start", true
    end

    tbRuntimeData.nDataVersion = 1
    tbRuntimeData.tbRuntimeData.nCurYear = 1
    tbRuntimeData.nCurYearStep = 1
    tbRuntimeData.tbPlayAccount = tbParam.tbAccount
    tbRuntimeData.nGameID = tbRuntimeData.nGameID + 1
    tbRuntimeData.bPlaying = true
    return "success", true
end

-- 重置 {FuncName = "DoReset"}
function tbFunc.Action.DoReset(tbParam)
    tbRuntimeData.nDataVersion = 0
    tbRuntimeData.tbPlayAccount = {}
    tbRuntimeData.tbRuntimeData.nCurYear = 1
    tbRuntimeData.nCurYearStep = 1
    tbRuntimeData.tbRuntimeData.tbUser = {}
    tbRuntimeData.bPlaying = false
    return "success", true
end

function tbFunc.Action.DoReset()
    
end

function tbFunc.Action.DoOperate(tbParam)
    return tbFunc.Action.funcDoOperate[tbParam.OperateType](tbParam)
end

tbFunc.Action.funcDoOperate = {}
-- 下一步 推进进度 {FuncName = "DoOperate", OperateType = "NextStep"}
function tbFunc.Action.funcDoOperate.NextStep(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]

    for _, v in pairs(tbUser.tbProduct) do
        v.done = false
    end
    tbUser.bStepDone = false
    return "success", true
end

-- 交税{FuncName = "DoOperate", OperateType = "Tax"}
function tbFunc.Action.funcDoOperate.Tax(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bStepDone then
        return "already done", true
    end

    if tbUser.tbLastYearReport and tbUser.tbLastYearReport.nTax > 0 then
        tbUser.nCash = tbUser.nCash - tbUser.tbLastYearReport.nTax -- 暂时允许玩家金钱为负
        tbUser.nTax = tbUser.tbLastYearReport.nTax
    end
    tbUser.bStepDone = true
    return "success", true
end

-- 提交市场预算 {FuncName = "DoOperate", OperateType = "CommitMarket", tbMarketingExpense = {a1 = { 2, 1, 1}, a2 = { 5, 3, 3}, b1 = { 20, 40, 3}}
function tbFunc.Action.funcDoOperate.CommitMarket(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bStepDone then
        return "already done", true
    end

    local nTotalCost = 0
    for _, tbMarketingExpenseCurPrdt in pairs(tbParam.tbMarketingExpense) do
        for _, v in ipairs(tbMarketingExpenseCurPrdt) do
            nTotalCost = nTotalCost + v
        end
    end

    if nTotalCost > tbUser.nCash then
        return "cash not enough", true
    end

    tbUser.nCash = tbUser.nCash - nTotalCost
    tbUser.tbMarketingExpense = tbParam.tbMarketingExpense
    tbUser.nMarketingExpense = nTotalCost
    tbUser.bStepDone = true
    return "success", true
end

-- 年初招聘 {FuncName = "DoOperate", OperateType = "CommitNormalHire", nNum = 20}
function tbFunc.Action.funcDoOperate.CommitNormalHire(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    local nTens = math.floor(tbParam.nNum / 10)
    local nCost = nTens * tbConfig.nNormalHireCost

    if nCost > tbUser.nCash then
        return "cash not enough", true
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
    if tbProduct.published then
        return "already published", true
    end

    local tbProductCfg = tbConfig.tbProduct[tbParam.PublishProduct]
    if tbProduct.progress ~= tbProductCfg.maxProgress then
        return "progress not enough", true
    end

    if tbProduct.manpower > tbProductCfg.minManpower then
        local moveNum = tbProduct.manpower - tbProductCfg.minManpower

        tbProduct.manpower = tbProduct.manpower - moveNum
        tbUser.nIdleManpower = tbUser.nIdleManpower + moveNum
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
        return "cash not enough", true
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
                return false, "manpower not enough"
            end
            return true
        end

        doUpdateManpowerFunc = function ()
            tbUser.tbResearch[tbParam.GridName].manpower = tbUser.tbResearch[tbParam.GridName].manpower - nTens * 10
        end
    elseif tbParam.GridType == "product" then
        checkFunc = function ()
            if not tbUser.tbProduct[tbParam.GridName] or tbUser.tbProduct[tbParam.GridName].manpower < nTens * 10 then
                return false, "manpower not enough"
            end
            return true
        end

        doUpdateManpowerFunc = function ()
            tbUser.tbProduct[tbParam.GridName].manpower = tbUser.tbProduct[tbParam.GridName].manpower - nTens * 10
        end
    elseif tbParam.GridType == "idle" then
        checkFunc = function ()
            if tbUser.nIdleManpower < nTens * 10 then
                return false, "manpower not enough"
            end
            return true
        end

        doUpdateManpowerFunc = function ()
            tbUser.nIdleManpower = tbUser.nIdleManpower - nTens * 10
        end
    end

    local bOk, result = checkFunc()
    if not bOk then
        return result, true
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
        return "invalid product name", true
    end

    if table.contain_key(tbUser.tbProduct, tbParam.ProductName) then
        return "product already exist", true
    end

    if #tbParam.tbMarket < 1 then
        return "at least on market", true
    end

    for _, v in ipairs(tbParam.tbMarket) do
        if not table.contain_value(tbRuntimeData.tbMarket, v) then
            return "invalid market:" .. tostring(v), true
        end
    end

    local productType = string.sub(tbParam.ProductName, 1, 1)
    if tbUser.tbResearch[productType] and tbUser.tbResearch[productType].leftPoint ~= 0 then
        return "need research ready", true
    end

    local nCost = 0
    if #tbParam.tbMarket > 1 then
        local addMarketCost = tbConfig.tbProduct[tbParam.ProductName].addMarketCost
        nCost = math.floor(addMarketCost / 2 + 0.5) * (#tbParam.tbMarket - 1)

        if tbUser.nCash < nCost then
            return "cash not enough", true
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

    if GridType == "research" then
        local manpower = tbUser.tbResearch[tbParam.GridName].manpower
        local manpowerCfg = tbConfig.tbResearch[tbParam.GridName].manpower
        if manpower < manpowerCfg and manpower + tbUser.nIdleManpower >= manpowerCfg then
            tbUser.tbResearch[tbParam.GridName].manpower = manpowerCfg
            tbUser.nIdleManpower = tbUser.nIdleManpower + manpower - manpowerCfg
        else
            tbUser.tbResearch[tbParam.GridName].manpower = 0
            tbUser.nIdleManpower = tbUser.nIdleManpower + manpower
        end
    elseif GridType == "product" then
        local manpower = tbUser.tbProduct[tbParam.GridName].manpower
        local minManpowerCfg = tbConfig.tbProduct[tbParam.GridName].minManpower
        local maxManpowerCfg = tbConfig.tbProduct[tbParam.GridName].maxManpower
        if manpower < minManpowerCfg and manpower + tbUser.nIdleManpower >= minManpowerCfg then
            tbUser.tbProduct[tbParam.GridName].manpower = minManpowerCfg
            tbUser.nIdleManpower = tbUser.nIdleManpower + manpower - minManpowerCfg
        elseif manpower < maxManpowerCfg and manpower + tbUser.nIdleManpower >= maxManpowerCfg then
            tbUser.tbProduct[tbParam.GridName].manpower = maxManpowerCfg
            tbUser.nIdleManpower = tbUser.nIdleManpower + manpower - maxManpowerCfg
        else
            tbUser.tbProduct[tbParam.GridName].manpower = 0
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
        return "already done", true
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
    

    tbUser.bStepDone = true
    return "success", true
end

-- 推进进度 {FuncName = "DoOperate", OperateType = "UpdateProductProgress", ProductName="b2"}
function tbFunc.Action.funcDoOperate.UpdateProductProgress(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    local tbProduct = tbUser.tbProduct[tbParam.ProductName]
    if not tbProduct.published then
        return "unpublished", true
    end

    if tbProduct.done then
        return "already done", true
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
        return "invalid product name", true
    end

    local tbProduct = tbUser.tbProduct[tbParam.ProductName]
    if not tbProduct then
        return "product not exist", true
    end

    for _, v in ipairs(tbParam.tbMarket) do
        if not table.contain_value(tbRuntimeData.tbMarket, v) then
            return "invalid market:" .. tostring(v), true
        end
    end

    for _, v in ipairs(tbProduct.market) do
        if not table.contain_value(tbParam.tbMarket, v) then
            return "can not unselect market:" .. tostring(v), true
        end
    end

    local nCost = 0
    if #tbParam.tbMarket > #tbProduct.market then
        local addMarketCost = tbConfig.tbProduct[tbParam.ProductName].addMarketCost
        nCost = math.floor(addMarketCost + 0.5) * (#tbParam.tbMarket - #tbProduct.market)

        if tbUser.nCash < nCost then
            return "cash not enough", true
        end
    end

    tbProduct.market = tbParam.tbMarket
    tbUser.nCash = tbUser.nCash - nCost
    tbUser.nAppendMarketCost = tbUser.nAppendMarketCost + nCost
    tbUser.bStepDone = true
    return "success", true
end

-- 随机研发进度 {FuncName = "DoOperate", OperateType = "RollResearchPoint", ResearchName:"d"}
function tbFunc.Action.funcDoOperate.RollResearchPoint(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    local tbResearch = tbUser.tbResearch[tbParam.ResearchName]
    if tbResearch.done then
        return "already done", true
    end

    if tbResearch.manpower < tbConfig.tbResearch[tbParam.ResearchName].manpower then
        return "manpower not enough", true
    end

    local nResearchPoint = math.random(1, 6)
    tbResearch.leftPoint = tbResearch.leftPoint - nResearchPoint
    if tbResearch.leftPoint < 0 then
        tbResearch.leftPoint = 0
    end
    tbResearch.done = true
    tbUser.bStepDone = true
    return "success", true
end

-- 发工资 {FuncName = "DoOperate", OperateType = "PayOffSalary"}
function tbFunc.Action.funcDoOperate.PayOffSalary(tbParam)
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    local nTens = math.floor(tbUser.nTotalManpower / 10 + 0.5)
    local nCost = nTens * tbConfig.nSalary

    tbUser.nCash = tbUser.nCash - nCost  -- 先允许负数， 让游戏继续跑下去
    tbUser.bStepDone = true
    return "success", true
end

--------------------------------------------------------------------

print("load success")
