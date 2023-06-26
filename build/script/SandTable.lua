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
            -- 市场营销投入
            tbMarketingExpense = {
                a1 = { 2, 1, 1},
                a2 = { 5, 3, 3},
                b1 = { 20, 40, 3},
            }
            -- 订单
            tbOrder = {
                a1 = {{ cfg = {}, market = 1, done = false}, {cfg = {}, market = 2, done = true}}
            },
            -- 代收款
            tbReceivables = {0, 0, 0, 0},
        }--]]
    },

    --==== 人才市场相关信息 ====
    tbManpowerInMarket = { 0, 0, 0, 0, 0 }, -- 人才市场各等级人数。元素个数需要等于tbConfig.nManpowerMaxExpLevel

    tbCutdownProduct = {
        -- a1 = true,
        -- b1 = true,
    },

    tbNpc = {
        tbProduc = {}
    },

    tbMarket = {},
    tbPublishedProduct = {},
}

local tbFunc = {
    Action = {},
}

function Action(jsonParam)
    local tbParam = JsonDecode(jsonParam)
    local func = tbFunc.Action[tbParam.FuncName]
    local szMsg
    local bRet = false
    if func then
        szMsg, bRet, tbCustomData = func(tbParam)
        --简单处理，只要收到客户端来的指令就认为数据变更了
        DoUpdateGamerDataVersion(tbParam.Account)
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

function InitManpowerData()
    HumanResources:UpdateAllUserManpower()
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
        
        if tbRuntimeData.bPlaying then
            Administration:NewUser(tbParam.Account)
        end
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

function tbFunc.Action.HR(tbParam)
    local user = tbRuntimeData.tbUser[tbParam.Account]
    local func = HR[tbParam.Operate]
    if func then
        return func(tbParam, user)
    end
    return "invalid HR operate", false
end

function tbFunc.Action.Develop(tbParam)
    local user = tbRuntimeData.tbUser[tbParam.Account]
    local func = Develop[tbParam.Operate]
    if func then
        return func(tbParam, user)
    end
    return "invalid Develop operate", false
end

function tbFunc.Action.Market(tbParam)
    local user = tbRuntimeData.tbUser[tbParam.Account]
    local func = Market[tbParam.Operate]
    if func then
        return func(tbParam, user)
    end
    return "invalid Market operate", false
end

tbFunc.Action.funcDoOperate = {}

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
            DoPreYear()
        end
    end
    -- 重置步骤完成标记
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        tbUser.bStepDone = false
	end
    DoUpdateGamerDataVersion(nil)
    print("=============== Year:".. tbRuntimeData.nCurYear .. " Season:" .. tbRuntimeData.nCurSeason .. "  ===============")
end

-- 每个季度开始前的自动处理
function DoPreSeason()
    HumanResources:AddNewManpower() -- 新人才进入人才市场
    HumanResources:SettleDepart()  --办理离职（交付流失员工）
    HumanResources:SettleFire()     -- 解雇人员离职
    HumanResources:SettleTrain()    -- 培训中的员工升级
    HumanResources:SettlePoach()    -- 成功挖掘的人才入职
    HumanResources:SettleHire()     -- 人才市场招聘结果
    MarketMgr:UpdateNpc()              -- Npc调整

    HumanResources:RecordProductManpower() -- 记录季度开始时的人力
end

-- 每个季度结束后的自动处理
function DoPostSeason()
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        tbUser.tbSysMsg = {}
    end
                    -- 推进研发进度
                    -- 更新产品品质
                    -- 流失份额、各品类市场份额刷新、更新市场竞标结果
                    -- 获取收益
    MarketMgr:SettleMarket()  -- 更新市场竞标结果 -- 获取上个季度市场收益

    HumanResources:PayOffSalary()   -- 支付薪水
    Production:PostSeason()         -- 推进研发进度
end

-- 每年结束后的自动处理
function DoPostYear()
    for _, user in pairs(tbRuntimeData.tbUser) do
        DoPayTax(user)
        DoYearReport(user)
    end
    --以下内容拷贝自原本的 tbFunc.finalAction.NewYear
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
--        tbUser.tbOrder = {}
    end
end

-- 每年开始时的自动处理
function DoPreYear()
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        tbUser.tbYearReport = Lib.copyTab(tbInitTables.tbInitReport)    --清空年报
        tbUser.tbHistoryYearReport[tbRuntimeData.nCurYear] = tbUser.tbYearReport
    end
end

-- 更新玩家数据版本
function DoUpdateGamerDataVersion(accoount)
    for key, user in pairs(tbRuntimeData.tbUser) do
        if account == nil or key == account then
            user.nDataVersion = user.nDataVersion + 1
        end
    end
end

--年尾扣税
function DoPayTax(user)
    user.tbYearReport.nTax = math.floor(user.tbYearReport.nProfitBeforeTax * tbConfig.fTaxRate + 0.5)
    user.tbYearReport.nTax = user.tbYearReport.nTax < 0 and 0 or user.tbYearReport.nTax
    user.nCash = user.nCash - user.tbYearReport.nTax
    user.tbYearReport.nNetProfit = user.tbYearReport.nProfitBeforeTax - user.tbYearReport.nTax
end

--处理年报
function DoYearReport(user)
    user.tbYearReport.nBalance = user.nCash
    -- todo to be finished
    -- tbUser.tbYearReport.nLaborCosts = tbUser.tbYearReport.nLaborCosts + tbUser.nSeverancePackage
--    for _, v in ipairs(tbUser.tbLaborCost) do
--        tbUser.tbYearReport.nLaborCosts = tbUser.tbYearReport.nLaborCosts + v
--    end

    --tbUser.tbYearReport.nMarketingExpense = tbUser.nMarketingExpense
    --tbUser.tbYearReport.nGrossProfit = tbUser.tbYearReport.nTurnover
    --                                    - tbUser.tbYearReport.nLaborCosts
    --                                    - tbUser.tbYearReport.nMarketingExpense
    --                                    - tbUser.tbYearReport.nSGA

    --tbUser.tbYearReport.nProfitBeforeTax = tbUser.tbYearReport.nGrossProfit
end

function IsPlatformProduct(product)
    return product.Category == "P"
end

function IsPlatformCategory(category)
    return category == "P"
end

print("load SandTable.lua success")
