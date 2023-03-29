print(package.path)

package.path = "./script/?.lua;" .. package.path
--print(package.path)
require("Json")

local tbRuntimeData = {
    tbAccount = {},
    tbUser = {
        default = {
            tbResearch = { d = { manpower = 20, leftPoint = 20 }, e = { manpower = 30, leftPoint = 30 } },
            tbProject = {},
        }
    }
}

local tbConfig = {
    tbBeginStepPerYear = {
        { desc = "支付税款", },
        { desc = "市场竞标，抢订单", },
        { desc = "招聘并支付费用", },
    },
    tbMaxStepPerSeason = {
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
    tbEndStepPerYear = 3,
}

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


function ActionNewGame(tbParam)

end

function ActionNextStep(tbParam)

end

function ActionNextSeason(tbParam)

end

local tbFunc = {
    Query = {},
    Action = { NewGame = ActionNewGame, NextStep = ActionNextStep, NextSeason = ActionNextSeason },
    Reload = {},
}

print("load success")
