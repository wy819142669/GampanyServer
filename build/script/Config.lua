tbConfig = {
    nLuaVersion = 1,
    tbAdminAccount = {"sys01", "sys02", "sys03" },
    nNormalHireCost = 1, -- 招聘费用
    nTempHireCost = 3, -- 临时招聘费用
    nFireCost = 3, -- 解雇 薪水*3
    nSalary = 1, -- 薪水
    tbAdminCost = {  -- 行政管理费用
        {step = 300, cost = 0.1, quickCalc = -30 }, -- quickCalc 速算扣除数， 费用 = totalManpower * cost + quickCalc
    },
    fTaxRate = 0.1,
    tbEnableMarketPerYear = { {}, {2}, {3}},
    tbBeginStepPerYear = {
        { desc = "调整薪资", nStepUniqueId = 1},
        --{ desc = "支付税款", mustDone = true, nStepUniqueId = 1},
        --{ desc = "追加额外市场，支付本地化费用", nStepUniqueId = 108},
       -- { desc = "市场竞标，抢用户", mustDone = true, syncNextStep = true, finalAction = "SettleOrder", nStepUniqueId = 2},
       -- { desc = "招聘并支付费用", nStepUniqueId = 3},
    },
    tbStepPerSeason = {
        { desc = "产品上线", nStepUniqueId = 2 },
        { desc = "更新产品品质", nStepUniqueId = 3 },
        { desc = "市场竞标", syncNextStep = true, nStepUniqueId = 4 },
        { desc = "办理离职（交付流失员工）",  mustDone = true, enterAction = "AutoDoneIfNoLoss", nStepUniqueId = 5 },
        { desc = "培训中的员工升级", nStepUniqueId = 6 },
        { desc = "成功挖掘的人才入职", mustDone = true, enterAction = "AutoDoneIfNoInflow", nStepUniqueId = 7 },
        { desc = "人才市场招募", syncNextStep = true, nStepUniqueId = 8 },
        { desc = "解雇待岗员工", nStepUniqueId = 9 },
        { desc = "选择目标公司挖人、支付挖人费用", nStepUniqueId = 10 },
        { desc = "设置培训员工、支付培训费用", nStepUniqueId = 11 },
        { desc = "研发分配人力", nStepUniqueId = 12 },
        { desc = "推进要发进度", nStepUniqueId = 13 },
        { desc = "获取市场收益", nStepUniqueId = 14 },
        { desc = "支付薪水", mustDone = true, nStepUniqueId = 15, timeLimitAction = "PayOffSalary" },
        -- { desc = "产品上线，把加倍进度的员工放到待岗区", nStepUniqueId = 101},
        -- { desc = "季度竞标市场用户", syncNextStep = true, finalAction = "SettleOrder", nStepUniqueId = 111},
        -- { desc = "临时招聘，支付临时招聘费用", nStepUniqueId = 102},
        -- { desc = "解聘，支付解聘费用", nStepUniqueId = 112},
        -- { desc = "选择初始市场，并立项", nStepUniqueId = 103},
        -- { desc = "现有人力资源调整（产品线调整人力、预研人力投入）", nStepUniqueId = 104},
        -- { desc = "更新应收款", nStepUniqueId = 105},
        -- { desc = "本季收入结算—现结款收入、放置延期收款", nStepUniqueId = 106},
        -- { desc = "研发推进", nStepUniqueId = 107},
        -- { desc = "roll点扣除剩余点数，查看预研结果", nStepUniqueId = 109},
        -- { desc = "支付人员工资（总人力*工资）", mustDone = true, nStepUniqueId = 110, timeLimitAction = "PayOffSalary"},
    },
    tbEndStepPerYear = {
        -- { desc = "准备进入年底", syncNextStep = true, finalAction = "EnableNextMarket", nStepUniqueId = 201},  -- 下个步骤，开放海外市场应该是大家一起开的。所以这里加一步，等大家一起NextStep
        -- { desc = "海外市场自动开放", enterAction = "EnableMarketTip", nStepUniqueId = 202},
        -- { desc = "结清账务（填损益表、负债表）", syncNextStep = true, enterAction = "FinancialReport", nStepUniqueId = 204},
        -- { desc = "排名总结", syncNextStep = true, finalAction = "NewYear", enterAction = "Year1FixManpower", nStepUniqueId = 205},
    },
    tbProduct = {
        a1 = { minManpower = 20, maxManpower = 60, maxProgress = 3, addMarketCost = 3, },
        a2 = { minManpower = 40, maxManpower = 120, maxProgress = 4, addMarketCost = 8,},
        b1 = { minManpower = 20, maxManpower = 60, maxProgress = 3, addMarketCost = 3,},
        b2 = { minManpower = 40, maxManpower = 120, maxProgress = 6, addMarketCost = 12,},
        d1 = { minManpower = 40, maxManpower = 120, maxProgress = 4, addMarketCost = 8,},
        d2 = { minManpower = 80, maxManpower = 240, maxProgress = 6, addMarketCost = 24,},
        e1 = { minManpower = 60, maxManpower = 180, maxProgress = 4, addMarketCost = 12,},
        e2 = { minManpower = 120, maxManpower = 360, maxProgress = 8, addMarketCost = 48,},
    },
    tbProductSort = {"a1", "a2", "b1", "b2", "d1", "d2", "e1", "e2"},

    tbYearStep = {},

    tbResearchSort = {"d", "e"},
    tbInitUserData = {
        -- 当前年步骤
        nCurYearStep = 1,
        -- 当前季度
        nCurSeason = 0,
        -- 当前季度步骤
        nCurSeasonStep = 1,
        -- 当前步骤已经操作完，防止重复操作
        bStepDone = false,
        -- 等待下一步
        bReadyNextStep = false,
        -- 提示
        szTitle = "",
        -- 薪水等级
        nSalaryLevel = 1,
         -- 市场营销投入
        tbMarketingExpense = {},
        -- 产品
        tbProduct = {
            a1 = { manpower = 20, tbManpower = {10, 5, 4, 1, 0, 0, 0, 0, 0, 0}, progress = 3, published = true, done = false },
        },
         -- 订单
        tbOrder = {
            --a1 = {{ cfg = { n = 2, arpu = 2}, done = false}}
        },
        -- 待岗
        nIdleManpower = { 10, 5, 4, 1, 0, 0, 0, 0, 0, 0 },
        -- 待收款
        tbReceivables = {0, 0, 0, 0},
        -- 现金
        nCash = 60,
        -- 追加市场费
        nAppendMarketCost = 0,
        -- 税收
        nTax = 0,
        -- 市场营销费
        nMarketingExpense = 0,
        -- 总人力
        nTotalManpower = 130,
        -- 招聘、解雇费用
        nSeverancePackage = 0,
        -- 薪水
        tbLaborCost = {0, 0, 0, 0},
        -- 权益占比
        fEquityRatio = 1.0,
        -- 上一年财报
        tbLastYearReport = {
            -- 收入
            nTurnover = 40,
            -- 人力费用
            nLaborCosts = 0,
            -- 销售费用
            nMarketingExpense = 0,
            -- 行政+本地化费用
            nSGA = 0,
            -- 营业利润
            nGrossProfit = 0,
            -- 财务费用
            nFinancialExpenses = 0,
            -- 利润
            nProfitBeforeTax = 0,
            -- 需要缴纳税款
            nTax = 0,
            -- 净利润
            nNetProfit = 0,
            -- 权益
            nEquity = 60,
            -- 现金
            nCash = 60,
            -- 融资
            nFinance = 0,
            --创始人权益
            nFounderEquity = 60,
        },
        tbYearReport = {
        },
    },
    tbInitUserDataYearPath = {
        [1] = {  -- 第一年开始的初始数据补丁
        },
        [2] = {},
    },
    tbInitReport = {
        -- 收入
        nTurnover = 0,
        -- 人力费用
        nLaborCosts = 0,
        -- 销售费用
        nMarketingExpense = 0,
        -- 行政+本地化费用
        nSGA = 0,
        -- 营业利润
        nGrossProfit = 0,
        -- 财务费用
        nFinancialExpenses = 0,
        -- 利润
        nProfitBeforeTax = 0,
        -- 需要缴纳税款
        nTax = 0,
        -- 净利润
        nNetProfit = 0,
        -- 权益
        nEquity = 0,
        -- 现金
        nCash = 0,
    },
    tbOrder = { -- 订单
    }
}

for i, v in ipairs(tbConfig.tbBeginStepPerYear) do
    local tbBeginStep = Lib.copyTab(v)
    tbBeginStep.nCurSeason = 0
    tbBeginStep.nCurSeasonStep = i
    table.insert(tbConfig.tbYearStep, tbBeginStep)
end

for i = 1, 4 do
    for j, v in ipairs(tbConfig.tbStepPerSeason) do
        local tbSeasonCfg = Lib.copyTab(v)
        tbSeasonCfg.nCurSeason = i
        tbSeasonCfg.nCurSeasonStep = j
        if (i == 2 or i == 4) and tbSeasonCfg.nStepUniqueId == 8 then --2、4季度跳过人才市场竞标
            tbSeasonCfg.syncNextStep = false
            tbSeasonCfg.enterAction = "SkipStep"
        end

        table.insert(tbConfig.tbYearStep, tbSeasonCfg)
    end
end

for i, v in ipairs(tbConfig.tbEndStepPerYear) do
    local tbEndStep = Lib.copyTab(v)
    tbEndStep.nCurSeasonStep = i
    table.insert(tbConfig.tbYearStep, tbEndStep)
end

tbConfig.tbInitUserData.tbLastYearReport = Lib.copyTab(tbConfig.tbInitReport)
tbConfig.tbInitUserData.tbYearReport = Lib.copyTab(tbConfig.tbInitReport)
