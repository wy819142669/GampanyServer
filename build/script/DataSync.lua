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
    return "success", true, { tbRuntimeData = GetTableRuntime() }
end

--=================================================================
--  游戏逻辑中的一些基本转换与微运算等    
GameLogic = {}
--=================================================================

--根据薪资等级获得薪资标准
function GameLogic:HR_GetSalary(level)
    return (tbConfig.nSalary * (1 + (level - 1) * tbConfig.fSalaryRatioPerLevel))
end

--企业付款
function GameLogic:FIN_Pay(user, classify, amount)
    if amount < 0 or user.nCash < amount then
        return false
    end
    user.nCash = user.nCash - amount
    GameLogic:ModifyReport(user.tbYearReport, classify, amount)
    return true
end

--企业付款后的退款
function GameLogic:FIN_Unpay(user, classify, amount)
    if amount < 0 then
        return false
    end
    user.nCash = user.nCash + amount
    GameLogic:ModifyReport(user.tbYearReport, classify, -amount)
    return true
end

--企业销售收入
function GameLogic:FIN_Revenue(user, amount)
    if amount < 0 then
        return false
    end
    user.nCash = user.nCash + amount
    GameLogic:ModifyReport(user.tbYearReport, tbConfig.tbFinClassify.Revenue, amount)
    return true
end

--根据现金异动修改财报
function GameLogic:ModifyReport(report, classify, amount)
    if classify == tbConfig.tbFinClassify.Revenue then -- 销售收入
    elseif classify == tbConfig.tbFinClassify.Tax then -- 税负
    elseif classify == tbConfig.tbFinClassify.Mkt then -- 市场
    elseif classify == tbConfig.tbFinClassify.HR then -- 人事（招募、挖人、培训）
        report.nLaborCosts = report.nLaborCosts + amount
    elseif classify == tbConfig.tbFinClassify.Salary_Dev then -- 薪酬(非发布产品)
        report.nLaborCosts = report.nLaborCosts + amount
    elseif classify == tbConfig.tbFinClassify.Salary_Pub then -- 薪酬(已发布产品，不包含平台)
    end
end
