tbConfig = {
    --==== 游戏整体性设置与控制，只读不写 ====
    nMaxGamerCount = 9,     --最多允许容纳的玩家的数目，因为界面没有做灵活适配，所以限制数目上限
    bDebug = true,          --调试模式，允许玩家客户端发出一些管理请求
    szAdminPassword = "",   --管理者登录密码

    --==== 财务设置相关，只读不写 ====
    fTaxRate = 0.1,         -- 税率【每年税额=税前利润*税率，当年亏损（税前利润为负）则不扣税】
    tbFinClassify = {       -- 财务现金流分类
        Revenue = 1,        -- 销售收入
        Tax = 2,            -- 税负
        Mkt = 3,            -- 市场
        HR = 4,             -- 人事（招募、挖人、培训） 
        Salary_Dev = 5,     -- 薪酬(非发布产品)
        Salary_Pub = 6,     -- 薪酬(已发布产品，不包含平台)
    },

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
    fQualityPerManpowerLevel = 2.0, --每人力等级可以提供的品质点数，人力1~5级， 产品2~10级

    --==== 产品所有状态罗列，只读不写 ====
    tbProductState = {
        nBuilding = 1,       -- 研发中
        nEnabled = 2,        -- 可上线（完成研发）
        nPublished = 3,      -- 发布
        nRenovating = 4,     -- 翻新
        nRenovateDone = 5,   -- 翻新工作量已完成
        nClosed = 6,         -- 关闭
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

    --==== 产品市场运营相关，只读不写 ====
    nLossMarket = 25,   --- 品类份额转移

    -- npc配置
    tbNpc = {
        nInitialProductNum = 2,  -- 初始市场npc产品数
        nInitialProductQuality = 2.0, -- 初始市场npc产品品质

        nMinNpcProductNum = 3, -- npc产品数量少于此，会上架产品
        nMaxProductNum = 6,    -- 品类市场产品多余此，不再上架产品
        fCloseWhenGainRatioLess = 3.0, -- 收益/营销费低于这个值，会下架产品
        fExpenseFloatRange = 0.1,  -- 营销费随机浮动
        szName = "Npc",
    },

    --====== 产品品类设置====
    tbProductCategory = {
        A = {
            --==研发相关配置==
            nMinTeam = 8,       --团队最小人数需求
            nIdeaTeam = 20,     --团队理想人数
            nRenovateMinTeam = 8,       --翻新时团队最小人数需求
            nRenovateIdeaTeam = 20,     --翻新时团队理想人数
            nWorkLoad = 40,     --工作量
            nRenovationWorkload = 30,        --翻新时的工作量
            nMaintainTeam = 10,             --上线运营时需要维护团队规模
            --==市场运营相关配置==
            fProductRetentionRate = 0.5,    --产品基础留存率
            nBaseARPU = 10,                 --基础ARPU
            nMaxMarketScale = 30,           --该品类市场总规模占全品类总规模上限百分比
            nTotalMarket = 250,             --市场总份额
            nNewProductCoefficient = 1.2,   --新上线产品当季度市场额外加成
            --==Npc相关配置==
            nNpcInitialExpenses = 200,
            nNpcContinuousExpenses = 50,
        },
        B = {
            --==研发相关配置==
            nMinTeam = 8,       --团队最小人数需求
            nIdeaTeam = 20,     --团队理想人数
            nRenovateMinTeam = 8,       --翻新时团队最小人数需求
            nRenovateIdeaTeam = 20,     --翻新时团队理想人数
            nWorkLoad = 40,     --工作量
            nRenovationWorkload = 30,        --翻新时的工作量
            nMaintainTeam = 10,             --上线运营时需要维护团队规模
            --==市场运营相关配置==
            fProductRetentionRate = 0.5,    --产品基础留存率
            nBaseARPU = 10,                 --基础ARPU
            nMaxMarketScale = 20,           --该品类市场总规模占全品类总规模上限百分比
            nTotalMarket = 150,             --市场总份额
            nNewProductCoefficient = 1.2,   --新上线产品当季度市场额外加成
            --==Npc相关配置==
            nNpcInitialExpenses = 400,
            nNpcContinuousExpenses = 100,
        },
        C = {
            --==研发相关配置==
            nMinTeam = 8,       --团队最小人数需求
            nIdeaTeam = 20,     --团队理想人数
            nRenovateMinTeam = 8,       --翻新时团队最小人数需求
            nRenovateIdeaTeam = 20,     --翻新时团队理想人数
            nWorkLoad = 40,     --工作量
            nRenovationWorkload = 30,        --翻新时的工作量
            nMaintainTeam = 10,             --上线运营时需要维护团队规模
            --==市场运营相关配置==
            fProductRetentionRate = 0.5,    --产品基础留存率
            nBaseARPU = 10,                 --基础ARPU
            nMaxMarketScale = 40,           --该品类市场总规模占全品类总规模上限百分比
            nTotalMarket = 350,             --市场总份额
            nNewProductCoefficient = 1.2,   --新上线产品当季度市场额外加成
            --==Npc相关配置==
            nNpcInitialExpenses = 1200,
            nNpcContinuousExpenses = 150,
        },
        D = {
            --==研发相关配置==
            nMinTeam = 8,       --团队最小人数需求
            nIdeaTeam = 20,     --团队理想人数
            nRenovateMinTeam = 8,       --翻新时团队最小人数需求
            nRenovateIdeaTeam = 20,     --翻新时团队理想人数
            nWorkLoad = 40,     --工作量
            nRenovationWorkload = 30,        --翻新时的工作量
            nMaintainTeam = 10, --上线运营时需要维护团队规模
            --==市场运营相关配置==
            fProductRetentionRate = 0.5,    --产品基础留存率
            nBaseARPU = 10,     --基础ARPU
            nMaxMarketScale = 50,  --该品类市场总规模占全品类总规模上限百分比
            nTotalMarket = 450, --市场总份额
            nNewProductCoefficient = 1.2,   --新上线产品当季度市场额外加成
            --==Npc相关配置==
            nNpcInitialExpenses = 2000,
            nNpcContinuousExpenses = 250,
        },
        P = { --==中台项目==，设置项与产品项的有些不同
            --==研发相关配置==
            nMinTeam = 8,       --团队最小人数需求
            nIdeaTeam = 20,     --团队理想人数
            nRenovateMinTeam = 8,       --翻新时团队最小人数需求
            nRenovateIdeaTeam = 20,     --翻新时团队理想人数
            nWorkLoad = 40,     --工作量
            nRenovationWorkload = 30,        --翻新时的工作量
            nMaintainTeam = 10,             --上线运营时需要维护团队规模
            fProductRetentionRate = 0.5,    --产品基础留存率
            bIsPlatform = true,
        },
    },
}

tbConfig.tbDevelopingState = {      -- 研发进行中状态
    tbConfig.tbProductState.nBuilding,
    tbConfig.tbProductState.nEnabled,
    tbConfig.tbProductState.nRenovating,
    tbConfig.tbProductState.nRenovateDone,
}

tbConfig.tbPublishedState = {       -- 已发布状态
    tbConfig.tbProductState.nPublished,
    tbConfig.tbProductState.nRenovating,
    tbConfig.tbProductState.nRenovateDone,
}

tbConfig.tbUnClosedState = {       -- 未关闭状态
    tbConfig.tbProductState.nBuilding,
    tbConfig.tbProductState.nEnabled,
    tbConfig.tbProductState.nPublished,
    tbConfig.tbProductState.nRenovating,
    tbConfig.tbProductState.nRenovateDone,
}

--====所有已发布的产品（不包含已关闭的）（的引用），分品类组织====
-- tbPublishedProduct数组：各key是 产品品类名，各value又是个数组，
-- tbPublishedProduct的value数组：各key就是产品id，各value就是各产品的运行时数据表(是对 tbConfig.tbUser[xx].tbProduct[id]的引用)
tbPublishedProduct = { }

--一些初始表/空表设置，用于服务端运行时从此复制，以形成各项初始表，因不参与日常计算，所以不放人tbConfig不需同步到客户端
tbInitTables = {

    --玩家运行数据初始表
    tbInitUserData = {
        nDataVersion = 0,   -- 玩家数据版本号，一旦发生数据更新后，版本号就会改变
        bStepDone = false,  -- 当前步骤已经操作完，防止重复操作

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

        -- 系统消息
        tbSysMsg = {},
        tbTips = {},
    },

    --年报初始表
    tbInitReport = {
        -- 收入
        nTurnover = 0,
        -- 人力费用
        nLaborCosts = 0,
        -- 销售费用
        nMarketingExpense = 0,
        -- 营业利润
        nGrossProfit = 0,
        
        nProfitBeforeTax = 0,   -- 税前利润
        nTax = 0,               -- 税款
        nNetProfit = 0,         -- 净利润
        nBalance = 0,           -- 结余现金
    },

    --新立项产品初始表
    tbInitNewProduct = {
        --Category = "A",                           --产品品类，数据在立项时动态设置
        State = tbConfig.tbProductState.nBuilding,  --产品状态
        tbManpower = {0,0,0,0,0},                   --团队人员
        nNeedWorkLoad = 0,                          --研发或翻新需要完成的工作量
        nFinishedWorkLoad = 0,                      --已完成工作量
        fFinishedQuality = 0,                       --已完成工作量的累积品质
        szName = "",
    },

    --新发布产品初始表
    tbInitPublishedProduct = {
        nLastMarketExpance = 0,     --最后一个季度/上季度市场营销费用
        nLastMarketScale = 0,       --最后一个季度/上季度市场规模
        nLastMarketScalePct = 0,    --最后一个季度/上季度市场规模在同品类中的占比（百分数）
        fLastARPU = 0,              --最后一个季度/上季度ARPU
        nLastMarketIncome = 0,      --最后一个季度/上季度收入
        nOrigQuality = 0,           --产品研发或翻新完时的初始质量
        nQuality = 0,               --当前质量，以研发完成时的质量为初值，发布后受团队规模等影响各季度会动态变化
        bNewProduct = true,         --新品， 上市第一季度享受额外市场加成
    },
}

tbInitTables.tbInitUserData.tbYearReport = Lib.copyTab(tbInitTables.tbInitReport)
