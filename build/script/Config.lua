tbConfig = {
    --[[未实际启用，暂时注释掉
    nLuaVersion = 1,
    --]]

    --==== 游戏整体性设置与控制 ====
    nMaxGamerCount = 9,     --最多允许容纳的玩家的数目，因为界面没有做灵活适配，所以限制数目上限
    bDebug = true,          --调试模式，允许玩家客户端发出一些管理请求
    szAdminPassword = "",   --管理者登录密码

    --==== 人力相关系统设置，只读不写 ====
    nSalary = 1,                    -- 薪水
    fSalaryRatioPerLevel = 0.2,     -- 每薪水等级薪水涨幅
    fHireWeightRatioPerLevel = 0.5, -- 每薪水等级增加招聘权重系数
    nManpowerMaxExpLevel = 5,       -- 人员能力等级最大值
    fTrainMaxRatioPerLevel = 0.2,   -- 每级可培训人数比例
    fTrainMaxRatioTotal = 0.1,      -- 总可培训人数比例
    fPoachSalaryLevelRatio = 1.2,   -- 挖掘时薪水等级系数
    nPoachSalaryWeight = 1,         -- 挖掘时薪水等级部分的权重， 此参数越高，挖掘费用效果越不明显
    tbPoachExpenseRatio = { 2, 4, 8, 12, 16},   -- 挖掘人才可选薪水倍数
    fPoachFailedReturnExpenseRatio = 0.8,       -- 挖掘人才失败时候返还费用比例

    fTaxRate = 0.1,

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

    --tbYearStep = {},

    tbResearchSort = {"d", "e"},
    tbInitUserData = {
        -- 当前步骤已经操作完，防止重复操作
        bStepDone = false,

        --==== 人力相关数据项 ====
        nSalaryLevel = 1,       -- 薪水等级
        nTotalManpower = 40,    -- 总人力
        nSeverancePackage = 0,                  -- 招聘、解雇费用
        tbLaborCost = {0, 0, 0, 0},             -- 薪水
        --tbHire = { nNum = , nExpense = },     --运行时产生的数据项: 向市场发出的招聘计划
        tbIdleManpower = { 10, 5, 4, 1, 0 },    -- 待岗员工。【以下几个表，元素个数需要等于 tbConfig.nManpowerMaxExpLevel】
        tbFireManpower = { 0, 0, 0, 0, 0},      -- 待解雇员工
        tbJobManpower = { 10, 5, 4, 1, 0 },     -- 在岗员工
        -- tbTrainManpower = { 0, 0, 0, 0, 0},     -- 培训员工，运行时动态产生消亡的数据
        -- tbDepartManpower = {0, 0, 0, 0, 0},     -- 即将离职员工，运行时动态产生消亡的数据

        -- 提示
        szTitle = "",
         -- 市场营销投入
        tbMarketingExpense = {},
        -- 产品
        tbProduct = {
            a1 = { manpower = 20, tbManpower = { 10, 5, 4, 1, 0 }, progress = 3, published = true, done = false, nQuality = 1 },
        },
         -- 订单
        tbOrder = {
            --a1 = {{ cfg = { n = 2, arpu = 2}, done = false}}
        },

        -- 待收款
        tbReceivables = {0, 0, 0, 0},
        -- 现金
        nCash = 1000,
        -- 追加市场费
        nAppendMarketCost = 0,
        -- 税收
        nTax = 0,
        -- 市场营销费
        nMarketingExpense = 0,

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

        bMarketingDone = false,

        -- 市场份额
        tbMarket = {
            a1 = 0,
            a2 = 0,
            b1 = 0,
            b2 = 0,
            d1 = 0,
            d2 = 0,
            e1 = 0,
            e2 = 0,
        },

        -- 市场投标计划
        tbMarketingExpense = {
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
    },

    --==== 人力相关系统设置数据，只读不写 ====
    tbNewManpowerPerYear = {  -- 每年人才市场各等级新进人数，子表元素个数需要等于tbConfig.nManpowerMaxExpLevel
        {61, 26, 12, 1, 0},
        {66, 39, 21, 4, 0},
        {77, 54, 38, 11, 0},
        {76, 65, 50, 19, 0},
        {53, 54, 41, 19, 3},
        {43, 43, 45, 21, 8},
        {32, 36, 38, 24, 10},
        {25, 29, 30, 24, 12},
        {20, 23, 29, 26, 12},
        {21, 20, 30, 31, 18},
    },
    fSeason1NewManpowerRatio = 0.3,  -- 第一季度新进人数占全年人数比例， 剩下的在第三季度新进

    -- 产品状态
    tbProductState = {
        nBuilding = 1,       -- 研发中
        nEnabled = 2,        -- 可上线
        nPublished = 3,      -- 发布
        nRenovating = 4,     -- 翻新
        nClosed = 5,         -- 关闭
    },

    --- 市场初始总份额
    tbMarket = {
        a1 = 250,
        a2 = 250,
        b1 = 150,
        b2 = 150,
        d1 = 350,
        d2 = 350,
        e1 = 450,
        e2 = 450,
    },

    --- 市场总份额下限
    tbMarketMinimumLimit = {
        a1 = 150,
        a2 = 150,
        b1 = 50,
        b2 = 50,
        d1 = 250,
        d2 = 250,
        e1 = 350,
        e2 = 350,
    },

    --- 品类份额转移
    nLossMarket = 25,

    --- 产品基础留存率
    tbProductRetentionRate = {
        a1 = 0.5,
        a2 = 0.5,
        b1 = 0.5,
        b2 = 0.5,
        d1 = 0.5,
        d2 = 0.5,
        e1 = 0.5,
        e2 = 0.5,
    },

    tbProductARPU = {
        a1 = 3,
        a2 = 3,
        b1 = 9,
        b2 = 9,
        d1 = 8,
        d2 = 8,
        e1 = 10,
        e2 = 10,
    },
}

tbConfig.tbInitUserData.tbLastYearReport = Lib.copyTab(tbConfig.tbInitReport)
tbConfig.tbInitUserData.tbYearReport = Lib.copyTab(tbConfig.tbInitReport)
