tbConfig = {
    --[[未实际启用，暂时注释掉
    nLuaVersion = 1,
    --]]

    --==== 游戏整体性设置与控制 ====
    nMaxGamerCount = 9,     --最多允许容纳的玩家的数目，因为界面没有做灵活适配，所以限制数目上限
    bDebug = true,          --调试模式，允许玩家客户端发出一些管理请求
    szAdminPassword = "",   --管理者登录密码

    fTaxRate = 0.1,         --税率【每年税额=税前利润*税率，当年亏损（税前利润为负）则不扣税】

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

    --==== 产品研发相关设置，只读不写 ====
    fSmallTeamRatio = 0.8,          --团队规模不足时，新增工作量与质量的缩水后的比例
    fBigTeamRatio = 0.5,            --团队规模过大时，新增工作量与质量的缩水后的比例
    fRenovateWorkLoadRatio = 0.7,   --翻新所需人力比例

    -- 产品状态
    tbProductState = {
        nBuilding = 1,       -- 研发中
        nEnabled = 2,        -- 可上线（完成研发）
        nPublished = 3,      -- 发布
        nRenovating = 4,     -- 翻新
        nClosed = 5,         -- 关闭
    },
    -- 产品品类
    tbProductCategoryNames = { "A", "B", "C", "D" },

    tbProduct = {           --todo 待被整理
        a1 = { minManpower = 20, maxManpower = 60, maxProgress = 3, addMarketCost = 3, },
        a2 = { minManpower = 40, maxManpower = 120, maxProgress = 4, addMarketCost = 8,},
        b1 = { minManpower = 20, maxManpower = 60, maxProgress = 3, addMarketCost = 3,},
        b2 = { minManpower = 40, maxManpower = 120, maxProgress = 6, addMarketCost = 12,},
        d1 = { minManpower = 40, maxManpower = 120, maxProgress = 4, addMarketCost = 8,},
        d2 = { minManpower = 80, maxManpower = 240, maxProgress = 6, addMarketCost = 24,},
        e1 = { minManpower = 60, maxManpower = 180, maxProgress = 4, addMarketCost = 12,},
        e2 = { minManpower = 120, maxManpower = 360, maxProgress = 8, addMarketCost = 48,},
    },
    --tbProductSort = {"a1", "a2", "b1", "b2", "d1", "d2", "e1", "e2"},
    --tbYearStep = {},
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

    --- 品类份额转移
    nLossMarket = 25,

    --- npc市场营销费用
    tbNpcMarketExpance = {
        A = {
            nInitialExpenses = 200,
            nContinuousExpenses = 50,
        },
        B = {
            nInitialExpenses = 400,
            nContinuousExpenses = 100,
        },
        C = {
            nInitialExpenses = 1200,
            nContinuousExpenses = 150,
        },
        D = {
            nInitialExpenses = 2000,
            nContinuousExpenses = 250,
        },
    },

    --====== 产品品类设置, 此表中key的值必须等于tbConfig.tbProductCategoryNames中罗列的值====
    tbProductCategory = {
        A = {
            --==研发相关配置==
            nMinTeam = 8,       --团队最小人数需求
            nIdeaTeam = 20,     --团队理想人数
            nWorkLoad = 40,     --工作量
            nMaintainTeam = 10, --上线运营时需要维护团队规模
            fProductRetentionRate = 0.5,    --产品基础留存率
            --==市场运营相关配置==
            nBaseARPU = 10,     --基础ARPU
            nMaxMarketScale = 20,  --该品类市场总规模占全品类总规模上限百分比
        },
        B = {
            --==研发相关配置==
            nMinTeam = 8,       --团队最小人数需求
            nIdeaTeam = 20,     --团队理想人数
            nWorkLoad = 40,     --工作量
            nMaintainTeam = 10, --上线运营时需要维护团队规模
            fProductRetentionRate = 0.5,    --产品基础留存率
            --==市场运营相关配置==
            nBaseARPU = 10,     --基础ARPU
            nMaxMarketScale = 20,  --该品类市场总规模占全品类总规模上限百分比
        },
        C = {
            --==研发相关配置==
            nMinTeam = 8,       --团队最小人数需求
            nIdeaTeam = 20,     --团队理想人数
            nWorkLoad = 40,     --工作量
            nMaintainTeam = 10, --上线运营时需要维护团队规模
            fProductRetentionRate = 0.5,    --产品基础留存率
            --==市场运营相关配置==
            nBaseARPU = 10,     --基础ARPU
            nMaxMarketScale = 20,  --该品类市场总规模占全品类总规模上限百分比
        },
        D = {
            --==研发相关配置==
            nMinTeam = 8,       --团队最小人数需求
            nIdeaTeam = 20,     --团队理想人数
            nWorkLoad = 40,     --工作量
            nMaintainTeam = 10, --上线运营时需要维护团队规模
            fProductRetentionRate = 0.5,    --产品基础留存率
            --==市场运营相关配置==
            nBaseARPU = 10,     --基础ARPU
            nMaxMarketScale = 20,  --该品类市场总规模占全品类总规模上限百分比
        },
    },
}

--====所有已发布的产品（不包含已关闭的）（的引用），分品类组织====
-- tbPublishedProduct数组：各key是 产品品类名，各value又是个数组，
-- tbPublishedProduct的value数组：各key就是产品id，各value就是各产品的运行时数据表(是对 tbConfig.tbUser[xx].tbProduct[id]的引用)
tbPublishedProduct = { }

--一些初始表/空表设置，用于服务端运行时从此复制，以形成各项初始表，因不参与日常计算，所以不放人tbConfig不需同步到客户端
tbInitTables = {

    --玩家运行数据初始表
    tbInitUserData = {
        -- 当前步骤已经操作完，防止重复操作
        bStepDone = false,

        --==== 人力相关数据项 ====
        nSalaryLevel = 1,       -- 薪水等级
        nTotalManpower = 40,    -- 总人力
        tbIdleManpower = { 10, 5, 4, 1, 0 },    -- 待岗员工。【以下几个表，元素个数需要等于 tbConfig.nManpowerMaxExpLevel】
        tbFireManpower = { 0, 0, 0, 0, 0},      -- 待解雇员工
        tbJobManpower = { 10, 5, 4, 1, 0 },     -- 在岗员工
        -- tbHire = { nNum = , nExpense = },    -- 向市场发出的招聘计划【运行时动态产生消亡的数据】
        -- tbTrainManpower = { 0, 0, 0, 0, 0},  -- 培训员工【运行时动态产生消亡的数据】
        -- tbDepartManpower = {0, 0, 0, 0, 0},  -- 即将离职员工【运行时动态产生消亡的数据】

        --==== 所有产品列表 ====
        tbProduct = { },        -- 所有未关闭的产品
        tbClosedProduct = { },  -- 所有已关闭的产品

        --==== 财务数 ====
        nCash = 1000,               -- 现金
        tbYearReport = { },         -- 当年报告
        tbHistoryYearReport = {},   -- 历史年报

        -- 提示
        szTitle = "",
        -- 系统消息
        tbSysMsg = {},
        tbTips = {},
         -- 市场营销投入
        tbMarketingExpense = {},    --todo tobe delete
         -- 订单
        tbOrder = {
            --a1 = {{ cfg = { n = 2, arpu = 2}, done = false}}
        },

        -- 待收款
        tbReceivables = {0, 0, 0, 0},

        -- 市场投标计划
        tbMarketingExpense = {  --todo tobe delete
        },
    },

    --年报初始表
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
        
        nProfitBeforeTax = 0,   -- 税前利润
        nTax = 0,               -- 税款
        nNetProfit = 0,         -- 净利润
        nBalance = 0,           -- 结余现金
    },

    --新立项产品初始表，此表中key的值必须等于tbConfig.tbProductCategory中罗列的值
    tbInitNewProduct = {
        --Category = "A",                           --产品品类，数据在立项时动态设置
        Sate = tbConfig.tbProductState.nBuilding,   --产品状态
        tbManpower = {0,0,0,0,0},                   --团队人员
        nFinishedWorkLoad = 0,                      --已完成工作量
        fFinishedQuality = 0,                       --已完成工作量的累积品质
        nRenovatedWorkLoad = 0,                     --已翻新工作量
        fRenovatedQuality = 0,                      --已翻新工作量的累积品质
    },

    --新发布产品初始表，此表中key的值必须等于tbConfig.tbProductCategory中罗列的值
    tbInitPublishedProduct = {
        nMarketExpance = 1,         --市场营销费用，至少为1
        nLastMarketExpance = 1,      --最后一个季度/上季度市场营销费用
        nLastMarketScale = 0,        --最后一个季度/上季度市场规模
        nLastARPU = 0,               --最后一个季度/上季度ARPU
        nLastMarketIncome = 0,       --最后一个季度/上季度收入
        fCurQuality = 0,            --当前质量，以研发完成时的质量为初值，发布后受团队规模等影响各季度会动态变化
    },
}

tbInitTables.tbInitUserData.tbYearReport = Lib.copyTab(tbInitTables.tbInitReport)
