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
    local data = GetTableRuntime()
    local ret
    if tbParam.ConfigVersion and tbParam.ConfigVersion == tbConfig.nDataVersion then
        ret = { tbRuntimeData = data }
    else
        ret = { tbRuntimeData = data, tbConfig = tbConfig }
    end
    return "success", true, ret
end

--=================================================================
--  游戏逻辑中的一些基本转换与微运算等    
GameLogic = {}
--=================================================================

--根据薪资等级获得薪资标准
function GameLogic:HR_GetSalary(level)
    return (tbConfig.nSalary * (1 + (level - 1) * tbConfig.fSalaryRatioPerLevel))
end

--计算税额
function GameLogic:FIN_Tax(profit)
    return math.max(0, math.floor(profit * tbConfig.fTaxRate + 0.5))
end

--企业付款
function GameLogic:FIN_Pay(user, classify, amount)
    if amount < 0 or user.nCash < amount then
        return false
    end
    user.nCash = user.nCash - amount
    GameLogic:FIN_ModifyReport(user.tbYearReport, classify, amount)
    return true
end

--企业付款后的退款
function GameLogic:FIN_Unpay(user, classify, amount)
    if amount < 0 then
        return false
    end
    user.nCash = user.nCash + amount
    GameLogic:FIN_ModifyReport(user.tbYearReport, classify, -amount)
    return true
end

--企业销售收入
function GameLogic:FIN_Revenue(user, amount)
    if amount < 0 then
        return false
    end
    user.nCash = user.nCash + amount
    GameLogic:FIN_ModifyReport(user.tbYearReport, tbConfig.tbFinClassify.Revenue, amount)
    return true
end

--根据现金异动修改财报
function GameLogic:FIN_ModifyReport(report, classify, amount)
    if classify == tbConfig.tbFinClassify.Revenue then -- 销售收入
        report.nTurnover = report.nTurnover + amount
        report.nGrossProfit = report.nGrossProfit + amount
    elseif classify == tbConfig.tbFinClassify.Tax then -- 税负
        report.nTax = report.nTax + amount
        report.nNetProfit = report.nGrossProfit - report.nTax
    elseif classify == tbConfig.tbFinClassify.Mkt then -- 市场
        report.nMarketingExpense = report.nMarketingExpense + amount
        report.nGrossProfit = report.nGrossProfit - amount
    elseif classify == tbConfig.tbFinClassify.HR then -- 人事（招募、挖人、培训、空闲人员薪酬）
        report.nLaborCosts = report.nLaborCosts + amount
        report.nGrossProfit = report.nGrossProfit - amount
    elseif classify == tbConfig.tbFinClassify.Salary_Dev then -- 薪酬(非发布产品)
        report.nSalaryDev = report.nSalaryDev + amount
        report.nGrossProfit = report.nGrossProfit - amount
    elseif classify == tbConfig.tbFinClassify.Salary_Pub then -- 薪酬(已发布产品，不包含平台)
        report.nSalaryPub = report.nSalaryPub + amount
        report.nGrossProfit = report.nGrossProfit - amount
    end
end

--是否是发布到市场中的产品
function GameLogic:PROD_IsInMarket(product)
    return product.Category ~= "P" and table.contain_value(tbConfig.tbPublishedState, product.State)
end

--是否是已发布的产品（包括市场中的，与已发布的中台）
function GameLogic:PROD_IsPublished(product)
    return table.contain_value(tbConfig.tbPublishedState, product.State)
end

--是否是研发中的产品（包括翻新的，包括中台）
function GameLogic:PROD_IsDeveloping(product)
    return table.contain_value(tbConfig.tbDevelopingState, product.State)
end

--是否是中台产品
function GameLogic:PROD_IsPlatform(product)
    return product.Category == "P"
end

--是否是中台品类
function GameLogic:PROD_IsPlatformC(category)
    return category == "P"
end

--是否是当季度新上线的产品，返回两个布尔值，前者表示是否新产品（包括翻新），后者表示是否为翻新的新品
function GameLogic:PROD_IsNewProduct(category, id)
    local result = GetTableRuntime().tbCategoryInfo[category].newPublished[id]
    if result ~= nil then
        return true, result
    end
    return false, false
end

--一个新产品发布了
function GameLogic:PROD_NewPublished(id, product, renovate, npc)
    local info = GetTableRuntime().tbCategoryInfo[product.Category]
    info.tbPublishedProduct[id] = product
    info.newPublished[id] = renovate
    info.nPublishedCount = info.nPublishedCount + 1
    if npc then
        info.nNpcProductCount = info.nNpcProductCount + 1
    end
    --对于新发布的产品(不是翻新项目), 复制已发布产品的数据初始化项
    if not renovate then
        for k, v in pairs(tbInitTables.tbInitPublishedProduct) do
            product[k] = v
        end
    end
end

--关闭一个产品
function GameLogic:OnCloseProduct(id, product, npc)
    local info = GetTableRuntime().tbCategoryInfo[product.Category]
    info.tbPublishedProduct[id] = nil
    info.newPublished[id] = nil
    info.nCommunalMarketShare = info.nCommunalMarketShare + product.nLastMarketScale
    info.nPublishedCount = info.nPublishedCount - 1
    if npc then
        info.nNpcProductCount = info.nNpcProductCount - 1
    end
end

--对产品列表中每个产品进行某项处理
function GameLogic:PROD_ForEachProcess(list, process, params)
    for id, product in pairs(list) do
        process(id, product, params)
    end
end

--更新产品的ARPU值
function GameLogic:MKT_UpdateArpuAndIncome(product)
    local totalMan = Production:GetTeamScaleQuality(product)
    local category = tbConfig.tbProductCategory[product.Category]

    product.fLastARPU = tbConfig.tbProductCategory[product.Category].nBaseARPU * (0.9 + 0.01 * product.nQuality10)
    if product.nLastMarketScale > 0 and (product.bIsNpc or totalMan >= category.nMaintainMinTeam) then
        product.nLastMarketIncome = math.floor(product.nLastMarketScale * product.fLastARPU)
    else
        product.nLastMarketIncome = 0
    end
end
