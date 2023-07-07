tbConfig = {
    --==== 游戏整体性设置与控制，只读不写 ====
    nMaxGamerCount = 9,     --最多允许容纳的玩家的数目，因为界面没有做灵活适配，所以限制数目上限
    bDebug = true,          --调试模式，允许玩家客户端发出一些管理请求
    bLogNpcProducts = true, --是否在屏幕显示npc产品每季度的表现
    szAdminPassword = "",   --管理者登录密码
    szRecoverDataFile = "20230703221718_Year1_Season2.std",

    --==== 财务设置相关，只读不写 ====
    nInitCash = 1000,       -- 初始时玩家公司的账上现金量
    fTaxRate = 0.1,         -- 税率【每年税额=税前利润*税率，当年亏损（税前利润为负）则不扣税】
    tbFinClassify = {       -- 财务现金流分类
        Revenue = 1,        -- 销售收入
        Tax = 2,            -- 税负
        Mkt = 3,            -- 市场
        HR = 4,             -- 人事（招募、挖人、培训、空闲人员薪酬）
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
    fPlatformManPowerRate = 0.005,  --中台对人力的影响参数
    fPlatformQualityRate = 0.005,   --中台对质量的影响参数

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
    nMarketShiftScale = 25,             --每季度各品类贡献这么市场份额，归入公共池，进行跨品类再分配
    fNewProductCoefficient = 1.2,       --新上线产品当季度市场额外加成
    fRenovateCoefficient = 1.1,         --翻新后的产品当季度市场额外加成
    nNpcCloseProductDelay = 3,          --Npc，因产品数目过多关闭产品的延迟（季度数）
    fNpcCloseWhenGainRatioLess = 3.0,   --NPC，收益/营销费低于这个值，会下架产品
    fNpcExpenseFloatRange = 0.1,        --NPC，营销费随机浮动
    nNpcInitProductQuality10 = 20,      --NPC，初始产品品质

    --====== 产品品类设置====
    tbProductCategory = {
        A = {
            --==研发相关配置==
            nMinTeam = 8,       --团队最小人数需求
            nIdeaTeam = 20,     --团队理想人数
            nRenovateMinTeam = 8,       --翻新时团队最小人数需求
            nRenovateIdeaTeam = 20,     --翻新时团队理想人数
            nWorkLoad = 40,     --工作量
            nRenovationWorkload = 30,       --翻新时的工作量
            nMaintainTeam = 10,             --上线运营时需要维护团队规模
            --==市场运营相关配置==
            fProductRetentionRate = 0.5,    --产品基础留存率
            nBaseARPU = 10,                 --基础ARPU
            nMaxMarketScale = 30,           --该品类市场总规模占全品类总规模上限百分比
            nTotalMarket = 250,             --市场总份额
            nProductIdeaCount = 10,         --产品数量控制，npc会控制自己的产品产生/销亡，以使市场上该品类产品的数量尽量为此数
            --==Npc相关配置==
            nNpcInitialExpenses = 50,
            nNpcContinuousExpenses = 45,
        },
        B = {
            --==研发相关配置==
            nMinTeam = 8,               --团队最小人数需求
            nIdeaTeam = 20,             --团队理想人数
            nRenovateMinTeam = 8,       --翻新时团队最小人数需求
            nRenovateIdeaTeam = 20,     --翻新时团队理想人数
            nWorkLoad = 40,             --工作量
            nRenovationWorkload = 30,   --翻新时的工作量
            nMaintainTeam = 10,         --上线运营时需要维护团队规模
            --==市场运营相关配置==
            fProductRetentionRate = 0.5,    --产品基础留存率
            nBaseARPU = 10,                 --基础ARPU
            nMaxMarketScale = 20,           --该品类市场总规模占全品类总规模上限百分比
            nTotalMarket = 150,             --市场总份额
            nProductIdeaCount = 10,         --产品数量控制，npc会控制自己的产品产生/销亡，以使市场上该品类产品的数量尽量为此数
            --==Npc相关配置==
            nNpcInitialExpenses = 60,
            nNpcContinuousExpenses = 55,
        },
        C = {
            --==研发相关配置==
            nMinTeam = 8,               --团队最小人数需求
            nIdeaTeam = 20,             --团队理想人数
            nRenovateMinTeam = 8,       --翻新时团队最小人数需求
            nRenovateIdeaTeam = 20,     --翻新时团队理想人数
            nWorkLoad = 40,             --工作量
            nRenovationWorkload = 30,   --翻新时的工作量
            nMaintainTeam = 10,         --上线运营时需要维护团队规模
            --==市场运营相关配置==
            fProductRetentionRate = 0.5,    --产品基础留存率
            nBaseARPU = 10,                 --基础ARPU
            nMaxMarketScale = 40,           --该品类市场总规模占全品类总规模上限百分比
            nTotalMarket = 350,             --市场总份额
            nProductIdeaCount = 10,         --产品数量控制，npc会控制自己的产品产生/销亡，以使市场上该品类产品的数量尽量为此数
            --==Npc相关配置==
            nNpcInitialExpenses = 70,
            nNpcContinuousExpenses = 65,
        },
        D = {
            --==研发相关配置==
            nMinTeam = 8,               --团队最小人数需求
            nIdeaTeam = 20,             --团队理想人数
            nRenovateMinTeam = 8,       --翻新时团队最小人数需求
            nRenovateIdeaTeam = 20,     --翻新时团队理想人数
            nWorkLoad = 40,             --工作量
            nRenovationWorkload = 30,   --翻新时的工作量
            nMaintainTeam = 10,         --上线运营时需要维护团队规模
            --==市场运营相关配置==
            fProductRetentionRate = 0.5,    --产品基础留存率
            nBaseARPU = 10,                 --基础ARPU
            nMaxMarketScale = 50,           --该品类市场总规模占全品类总规模上限百分比
            nTotalMarket = 450,             --市场总份额
            nProductIdeaCount = 10,         --产品数量控制，npc会控制自己的产品产生/销亡，以使市场上该品类产品的数量尽量为此数
            --==Npc相关配置==
            nNpcInitialExpenses = 80,
            nNpcContinuousExpenses = 75,
        },
        P = { --==中台项目==，设置项与产品项的有些不同
            --==研发相关配置==
            nMinTeam = 8,               --团队最小人数需求
            nIdeaTeam = 20,             --团队理想人数
            nRenovateMinTeam = 8,       --翻新时团队最小人数需求
            nRenovateIdeaTeam = 20,     --翻新时团队理想人数
            nWorkLoad = 40,             --工作量
            nRenovationWorkload = 30,       --翻新时的工作量
            nMaintainTeam = 10,             --上线运营时需要维护团队规模
            fProductRetentionRate = 0.5,    --产品基础留存率
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

        --==== 研发相关 ====
        nPlatformQuality10 = 0,   -- 已发布中台的当前质量的十倍值（0表示无已发布的中台）

        --==== 财务数 ====
        nCash = 0,                  -- 现金，游戏开始时的初始值由tbConfig.nInitCash设置
        tbYearReport = { },         -- 当年报告
        tbHistoryYearReport = {},   -- 历史年报

        -- 系统消息
        tbSysMsg = {},
        tbTips = {},
    },

    --年报初始表
    tbInitReport = {
        nTurnover = 0,          -- (销售)收入
        nLaborCosts = 0,        -- 人力费用，人事相关（人事（招募、挖人、培训、空闲人员薪酬））
        nSalaryDev = 0,         -- 研发项目与平台的薪酬成本
        nSalaryPub = 0,         -- 上线项目的薪酬成本
        nMarketingExpense = 0,  -- 销售费用
        nGrossProfit = 0,       -- 营业利润
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
        nFinishedQuality = 0,                       --已完成工作量的累积品质
        szName = "",
    },

    --新发布产品初始表
    tbInitPublishedProduct = {
        nOrigQuality10 = 0,         --产品研发或翻新完时的初始质量
        nQuality10 = 0,             --当前质量，以研发完成时的质量为初值，发布后受团队规模等影响各季度会动态变化
        nLastMarketExpense = 0,     --最后一个季度/上季度市场营销费用
        nLastMarketScale = 0,       --最后一个季度/上季度市场规模
        nLastMarketScaleDelta = 0,  --最后一个季度/上季度市场规模环比变化量
        nLastMarketScalePct = 0,    --最后一个季度/上季度市场规模在同品类中的占比（百分数）
        fLastARPU = 0,              --最后一个季度/上季度ARPU
        nLastMarketIncome = 0,      --最后一个季度/上季度收入
        nMarketExpense = 0,         --当季市场营销费用（设定）
        nSeasonCount = 0,           --产品上市后的时长（季度数）
    },

    --品类初始信息
    tbInitCategoryInfo = {
        nCommunalMarketShare = 0,   --品类内部产品共享的市场份额
        nTotalScale = 0,            --最后一个季度/上季度整体市场规模
        nTotalIncome = 0,           --最后一个季度/上季度整体市场营收
        newPublished = {},          --当季度新发布的产品
                                    --各key就是产品id；各value为布尔值，表示是否为翻新
        tbPublishedProduct = {},    --所有已发布的产品（不包含已关闭的）（的引用）
                                    --各key就是产品id，各value就是各产品的运行时数据表(是对 tbConfig.tbUser[xx].tbProduct[id]的引用)
        nPublishedCount = 0,        --上线产品总量
        nNpcProductCount = 0,       --Npc产品总量（都是已上线的）
    },

    --Npc动态信息的初始化
    tbInitNpc = {
        tbProduct = {},             --产品列表
        tbScheduleToNew = {},       --计划将新建产品
        tbScheduleToClose = {},     --计划将关闭产品
    },
}

tbInitTables.tbInitUserData.tbYearReport = Lib.copyTab(tbInitTables.tbInitReport)
