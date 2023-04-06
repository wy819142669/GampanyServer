tbConfig = {
    nLuaVersion = 1,
    tbAccount = { "李", "陈", "薛", "王", "张", "刘" },  -- 准备弃用，客户端可以输入自己的名字
    nNormalHireCost = 2, -- 招聘费用
    nTempHireCost = 4, -- 临时招聘费用
    nFireCost = 8, -- 解雇 薪水*4
    nSalary = 2, -- 薪水
    tbBeginStepPerYear = {
        { desc = "支付税款", mustDone = true, syncNextStep = true, },
        { desc = "市场竞标，抢订单", mustDone = true, syncNextStep = true, finalAction = "SettleOrder"},
        { desc = "招聘并支付费用", },
    },
    tbStepPerSeason = {
        { desc = "产品上线，把加倍进度的员工放到待岗区", syncNextStep = true, },
        { desc = "临时招聘、解聘，支付临时招聘和解聘费用", },
        { desc = "选择初始市场，并立项", },
        { desc = "现有人力资源调整（产品线调整人力、预研人力投入）", },
        { desc = "更新应收款", },
        { desc = "本季收入结算—现结款收入、放置延期收款", },
        { desc = "研发推进", },
        { desc = "追加额外市场，支付本地化费用", },
        { desc = "roll点扣除剩余点数，查看预研结果", },
        { desc = "支付人员工资（总人力*工资）", mustDone = true,},
    },
    tbEndStepPerYear = {
        { desc = "海外市场自动开放", },
        { desc = "结算已抢但未完成的订单罚款（50%订单金额）", },
        { desc = "结清账务（填损益表、负债表）", syncNextStep = true, },
        { desc = "排名总结", syncNextStep = true, finalAction = "NewYear"}
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
    tbResearch = {
        d = { manpower = 20, totalPoint = 20 },
        e = { manpower = 30, totalPoint = 30 },
    },
    tbInitUserData = {
        -- 当前年步骤
        nCurYearStep = 1,
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
        tbMarketingExpense = {},
        -- 预研
        tbResearch = { d = { manpower = 20, leftPoint = 20 }, e = { manpower = 30, leftPoint = 30 } },
        -- 产品
        tbProduct = {
            a1 = { manpower = 20, progress = 4, market = { 1 }, published = true, done = false },
            a2 = { manpower = 40, progress = 0, market = { 1 }, published = false, done = false },
            b1 = { manpower = 20, progress = 0, market = { 1 }, published = false, done = false },
        },
         -- 订单
         tbOrder = {
            --a1 = {{ cfg = { n = 2, arpu = 2}, done = false}}
        },
        -- 待岗
        nIdleManpower = 0,
        -- 待收款
        tbReceivables = {0, 0, 0, 0},
        -- 现金
        nCash = 120,
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
        -- 上一年财报
        tbLastYearReport = {
            -- 利润
            nProfitBeforeTax = 0,
            -- 需要缴纳税款
            nTax = 0,
        },
    },
    tbOrder = { -- 订单
        [1] =  {  -- Y1
            a1 = {
                {{ n = 4, arpu = 6.6}, { n = 3, arpu = 6.3 }, { n = 2, arpu = 6 }, { n = 2, arpu = 5.7 }}, -- 国内
                {}, -- 日韩
                {}, -- 欧美
            },
            a2 = {
                {{ n = 4, arpu = 16.5}, { n = 3, arpu = 15.8 }, { n = 2, arpu = 15 }, { n = 2, arpu = 14.3 }},
            },
            b1 = {
                {{ n = 5, arpu = 5.5}, { n =4, arpu = 5.3 }, { n = 2, arpu = 5 }, { n = 2, arpu = 4.8 }},
            },
            b2 = {
                {{ n = 5, arpu = 22}, { n = 4, arpu = 21 }, { n = 2, arpu = 20 }, { n = 2, arpu = 19 }},
            },
        },
        [2] = { -- Y2

        },
    }
}