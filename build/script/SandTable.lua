print(package.path)

package.path = "./script/?.lua;" .. package.path
--print(package.path)
require("Json")

local tbRuntimeData = {
    tbAccount = {},
    tbUser = {
        default = {
            -- 预研
            tbResearch = { d = { manpower = 20, leftPoint = 20 }, e = { manpower = 30, leftPoint = 30 } },
            -- 产品
            tbProject = {
                a1 = { manpower = 0, progress = 0, market = { 1, 2, 3 } },
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
            tbLaborCost = {0, 0, 0, 0}
        }
    }
}

local tbConfig = {
    tbBeginStepPerYear = {
        { desc = "支付税款", },
        { desc = "市场竞标，抢订单", },
        { desc = "招聘并支付费用", },
    },
    tbStepPerSeason = {
        { desc = "产品上线，额外市场上线", },
        { desc = "临时招聘、解聘，支付临时招聘和解聘费用", },
        { desc = "现有人力资源调整（选初始市场立项、产品线调整人力、预研人力投入）", },
        { desc = "更新应收款", },
        { desc = "本季收入结算—现结款收入、放置延期收款", },
        { desc = "招聘并支付费用", },
        { desc = "支付税款", },
        { desc = "市场竞标，抢订单", },
        { desc = "招聘并支付费用", },
    },
    tbEndStepPerYear = {
        { desc = "海外市场自动开放", },
        { desc = "结算已抢但未完成的订单罚款（50%订单金额）", },
        { desc = "结清账务（填损益表、负债表）", },
    },
    tbProduct = {
        a1 = { minManpower = 20, maxManpower = 60, maxProgress = 3, },

    },
    tbResearch = {
        d = { manpower = 20, totalPoint = 20 },
        e = { manpower = 30, totalPoint = 30 },
    },
    nInitialCash = 120,
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

function Action(jsonParam)
    local tbParam = JsonDecode(jsonParam)
    local func = tbFunc["Action"][tbParam.FuncName]
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
    return JsonEncode(tbResult)
end

function Query(jsonParam)
    local tbParam = JsonDecode(jsonParam)
    local func = tbFunc["Query"][tbParam.FuncName]
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
    return JsonEncode(tbResult)
end




function QueryTest(tbParam)

    return "success"
end

function ActionLogin(tbParam)

    return "success"
end

function ActionNewGame(tbParam)

    return "success"
end

function ActionNextStep(tbParam)

    return "success"
end

function ActionNextSeason(tbParam)

    return "success"
end

tbFunc.Query = {
    Test = QueryTest,
}
tbFunc.Action = {
    Login = ActionLogin,
    NewGame = ActionNewGame,
    NextStep = ActionNextStep,
    NextSeason = ActionNextSeason
}
tbFunc.Reload = {

}

print("load success")
