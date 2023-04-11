tbConfig = {
    nLuaVersion = 1,
    tbAccount = { "李", "陈", "薛", "王", "张", "刘" },  -- 准备弃用，客户端可以输入自己的名字
    nNormalHireCost = 1, -- 招聘费用
    nTempHireCost = 3, -- 临时招聘费用
    nFireCost = 3, -- 解雇 薪水*4
    nSalary = 1, -- 薪水
    fTaxRate = 0.1,
    tbEnableMarketPerYear = {{2}, {3}},
    tbBeginStepPerYear = {
        { desc = "支付税款", mustDone = true, syncNextStep = true, nStepUniqueId = 1},
        { desc = "追加额外市场，支付本地化费用", nStepUniqueId = 108},
        { desc = "市场竞标，抢订单", mustDone = true, syncNextStep = true, finalAction = "SettleOrder", nStepUniqueId = 2},
        { desc = "招聘并支付费用", nStepUniqueId = 3},
    },
    tbStepPerSeason = {
        { desc = "产品上线，把加倍进度的员工放到待岗区", syncNextStep = true, nStepUniqueId = 101},
        { desc = "季度竞标市场订单", syncNextStep = true, finalAction = "SettleOrder", nStepUniqueId = 111},
        { desc = "临时招聘，支付临时招聘费用", nStepUniqueId = 102},
        { desc = "解聘，支付解聘费用", nStepUniqueId = 112},
        { desc = "选择初始市场，并立项", nStepUniqueId = 103},
        { desc = "现有人力资源调整（产品线调整人力、预研人力投入）", nStepUniqueId = 104},
        { desc = "更新应收款", nStepUniqueId = 105},
        { desc = "本季收入结算—现结款收入、放置延期收款", nStepUniqueId = 106},
        { desc = "研发推进", nStepUniqueId = 107},
        { desc = "roll点扣除剩余点数，查看预研结果", nStepUniqueId = 109},
        { desc = "支付人员工资（总人力*工资）", mustDone = true, nStepUniqueId = 110},
    },
    tbEndStepPerYear = {
        { desc = "准备进入年底", syncNextStep = true, finalAction = "EnableNextMarket", nStepUniqueId = 201},  -- 下个步骤，开放海外市场应该是大家一起开的。所以这里加一步，等大家一起NextStep
        { desc = "海外市场自动开放", enterAction = "EnableMarketTip", nStepUniqueId = 202},
      --  { desc = "结算已抢但未完成的订单罚款（50%订单金额）", enterAction = "UndoneOrderPunish", nStepUniqueId = 203},
        { desc = "结清账务（填损益表、负债表）", syncNextStep = true, enterAction = "FinancialReport", nStepUniqueId = 204},
        { desc = "排名总结", syncNextStep = true, finalAction = "NewYear", nStepUniqueId = 205}
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
    tbMarketName = {"国内", "日韩", "欧美"},

    tbYearStep = {},

    tbResearch = {
        d = { manpower = 20, totalPoint = 15 },
        e = { manpower = 30, totalPoint = 20 },
    },
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
         -- 市场营销投入
        tbMarketingExpense = {},
        -- 预研
        tbResearch = { d = { manpower = 20, leftPoint = 15 }, e = { manpower = 30, leftPoint = 20 } },
        -- 产品
        tbProduct = {
            a1 = { manpower = 20, progress = 3, market = { 1 }, published = true, done = false },
            a2 = { manpower = 40, progress = 0, market = { 1 }, published = false, done = false },
            b1 = { manpower = 20, progress = 0, market = { 1 }, published = false, done = false },
        },
         -- 订单
        tbOrder = {
            --a1 = {{ cfg = { n = 2, arpu = 2}, done = false}}
        },
        -- 新品列表 （可参与季度竞标）
        tbNewProduct = {
            -- a1 = { 1, 2 }
        },
        -- 待岗
        nIdleManpower = 0,
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
        -- 上一年财报
        tbLastYearReport = {
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
        },
        tbYearReport = {
        },
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
    },
    tbOrder = { -- 订单
        [1] =  {  -- Y1
        a1={{{ n =12.6, arpu =2.2}, { n =11.1, arpu =2.1}, { n =9.5, arpu =2}, { n =7.9, arpu =1.9}, { n =6.3, arpu =1.8}, { n =4.7, arpu =1.7}},{{ n =12.6, arpu =2.2}, { n =11.1, arpu =2.1}, { n =9.5, arpu =2}, { n =7.9, arpu =1.9}, { n =6.3, arpu =1.8}, { n =4.7, arpu =1.7}},{{ n =12.6, arpu =2.2}, { n =11.1, arpu =2.1}, { n =9.5, arpu =2}, { n =7.9, arpu =1.9}, { n =6.3, arpu =1.8}, { n =4.7, arpu =1.7}},},
        a2={{{ n =6.6, arpu =5.5}, { n =5.8, arpu =5.3}, { n =5, arpu =5}, { n =4.2, arpu =4.8}, { n =3.3, arpu =4.5}, { n =2.5, arpu =4.3}},{{ n =6.6, arpu =5.5}, { n =5.8, arpu =5.3}, { n =5, arpu =5}, { n =4.2, arpu =4.8}, { n =3.3, arpu =4.5}, { n =2.5, arpu =4.3}},{{ n =6.6, arpu =5.5}, { n =5.8, arpu =5.3}, { n =5, arpu =5}, { n =4.2, arpu =4.8}, { n =3.3, arpu =4.5}, { n =2.5, arpu =4.3}},},
        b1={{{ n =15.8, arpu =1.8}, { n =13.8, arpu =1.7}, { n =11.9, arpu =1.6}, { n =9.9, arpu =1.5}, { n =7.9, arpu =1.4}, { n =5.9, arpu =1.4}},{{ n =15.8, arpu =1.8}, { n =13.8, arpu =1.7}, { n =11.9, arpu =1.6}, { n =9.9, arpu =1.5}, { n =7.9, arpu =1.4}, { n =5.9, arpu =1.4}},{{ n =15.8, arpu =1.8}, { n =13.8, arpu =1.7}, { n =11.9, arpu =1.6}, { n =9.9, arpu =1.5}, { n =7.9, arpu =1.4}, { n =5.9, arpu =1.4}},},
        b2={{{ n =6.3, arpu =7.3}, { n =5.5, arpu =6.9}, { n =4.7, arpu =6.6}, { n =3.9, arpu =6.3}, { n =3.1, arpu =5.9}, { n =2.4, arpu =5.6}},{{ n =6.3, arpu =7.3}, { n =5.5, arpu =6.9}, { n =4.7, arpu =6.6}, { n =3.9, arpu =6.3}, { n =3.1, arpu =5.9}, { n =2.4, arpu =5.6}},{{ n =6.3, arpu =7.3}, { n =5.5, arpu =6.9}, { n =4.7, arpu =6.6}, { n =3.9, arpu =6.3}, { n =3.1, arpu =5.9}, { n =2.4, arpu =5.6}},},
        d1={{{ n =5.45, arpu =4.4}, { n =4.75, arpu =4.2}, { n =4.1, arpu =4}, { n =3.4, arpu =3.8}, { n =2.75, arpu =3.6}, { n =2.05, arpu =3.4}},{{ n =5.45, arpu =4.4}, { n =4.75, arpu =4.2}, { n =4.1, arpu =4}, { n =3.4, arpu =3.8}, { n =2.75, arpu =3.6}, { n =2.05, arpu =3.4}},{{ n =5.45, arpu =4.4}, { n =4.75, arpu =4.2}, { n =4.1, arpu =4}, { n =3.4, arpu =3.8}, { n =2.75, arpu =3.6}, { n =2.05, arpu =3.4}},},
        d2={{{ n =4.1, arpu =11}, { n =3.6, arpu =10.5}, { n =3.05, arpu =10}, { n =2.55, arpu =9.5}, { n =2.05, arpu =9}, { n =1.55, arpu =8.5}},{{ n =4.1, arpu =11}, { n =3.6, arpu =10.5}, { n =3.05, arpu =10}, { n =2.55, arpu =9.5}, { n =2.05, arpu =9}, { n =1.55, arpu =8.5}},{{ n =4.1, arpu =11}, { n =3.6, arpu =10.5}, { n =3.05, arpu =10}, { n =2.55, arpu =9.5}, { n =2.05, arpu =9}, { n =1.55, arpu =8.5}},},
        e1={{{ n =4.45, arpu =7.3}, { n =3.85, arpu =6.9}, { n =3.3, arpu =6.6}, { n =2.75, arpu =6.3}, { n =2.2, arpu =5.9}, { n =1.65, arpu =5.6}},{{ n =4.45, arpu =7.3}, { n =3.85, arpu =6.9}, { n =3.3, arpu =6.6}, { n =2.75, arpu =6.3}, { n =2.2, arpu =5.9}, { n =1.65, arpu =5.6}},{{ n =4.45, arpu =7.3}, { n =3.85, arpu =6.9}, { n =3.3, arpu =6.6}, { n =2.75, arpu =6.3}, { n =2.2, arpu =5.9}, { n =1.65, arpu =5.6}},},
        e2={{{ n =5.75, arpu =14.6}, { n =5.05, arpu =14}, { n =4.3, arpu =13.3}, { n =3.6, arpu =12.6}, { n =2.9, arpu =12}, { n =2.15, arpu =11.3}},{{ n =5.75, arpu =14.6}, { n =5.05, arpu =14}, { n =4.3, arpu =13.3}, { n =3.6, arpu =12.6}, { n =2.9, arpu =12}, { n =2.15, arpu =11.3}},{{ n =5.75, arpu =14.6}, { n =5.05, arpu =14}, { n =4.3, arpu =13.3}, { n =3.6, arpu =12.6}, { n =2.9, arpu =12}, { n =2.15, arpu =11.3}},},
        
         
        },

        [2] = { -- Y2
        a1={{{ n =10.08, arpu =1.76}, { n =8.88, arpu =1.68}, { n =7.6, arpu =1.6}, { n =6.32, arpu =1.52}, { n =5.04, arpu =1.44}, { n =3.76, arpu =1.36}},{{ n =7.56, arpu =1.32}, { n =6.66, arpu =1.26}, { n =5.7, arpu =1.2}, { n =4.74, arpu =1.14}, { n =3.78, arpu =1.08}, { n =2.82, arpu =1.02}},{{ n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}},},
        a2={{{ n =5.28, arpu =4.4}, { n =4.64, arpu =4.24}, { n =4, arpu =4}, { n =3.36, arpu =3.84}, { n =2.64, arpu =3.6}, { n =2, arpu =3.44}},{{ n =3.96, arpu =3.3}, { n =3.48, arpu =3.18}, { n =3, arpu =3}, { n =2.52, arpu =2.88}, { n =1.98, arpu =2.7}, { n =1.5, arpu =2.58}},{{ n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}},},
        b1={{{ n =12.64, arpu =1.44}, { n =11.04, arpu =1.36}, { n =9.52, arpu =1.28}, { n =7.92, arpu =1.2}, { n =6.32, arpu =1.12}, { n =4.72, arpu =1.12}},{{ n =9.48, arpu =1.08}, { n =8.28, arpu =1.02}, { n =7.14, arpu =0.96}, { n =5.94, arpu =0.9}, { n =4.74, arpu =0.84}, { n =3.54, arpu =0.84}},{{ n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}},},
        b2={{{ n =5.04, arpu =5.84}, { n =4.4, arpu =5.52}, { n =3.76, arpu =5.28}, { n =3.12, arpu =5.04}, { n =2.48, arpu =4.72}, { n =1.92, arpu =4.48}},{{ n =3.78, arpu =4.38}, { n =3.3, arpu =4.14}, { n =2.82, arpu =3.96}, { n =2.34, arpu =3.78}, { n =1.86, arpu =3.54}, { n =1.44, arpu =3.36}},{{ n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}},},
        d1={{{ n =6.104, arpu =3.52}, { n =5.32, arpu =3.36}, { n =4.592, arpu =3.2}, { n =3.808, arpu =3.04}, { n =3.08, arpu =2.88}, { n =2.296, arpu =2.72}},{{ n =4.578, arpu =2.64}, { n =3.99, arpu =2.52}, { n =3.444, arpu =2.4}, { n =2.856, arpu =2.28}, { n =2.31, arpu =2.16}, { n =1.722, arpu =2.04}},{{ n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}},},
        d2={{{ n =4.592, arpu =8.8}, { n =4.032, arpu =8.4}, { n =3.416, arpu =8}, { n =2.856, arpu =7.6}, { n =2.296, arpu =7.2}, { n =1.736, arpu =6.8}},{{ n =3.444, arpu =6.6}, { n =3.024, arpu =6.3}, { n =2.562, arpu =6}, { n =2.142, arpu =5.7}, { n =1.722, arpu =5.4}, { n =1.302, arpu =5.1}},{{ n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}},},
        e1={{{ n =4.984, arpu =5.84}, { n =4.312, arpu =5.52}, { n =3.696, arpu =5.28}, { n =3.08, arpu =5.04}, { n =2.464, arpu =4.72}, { n =1.848, arpu =4.48}},{{ n =3.738, arpu =4.38}, { n =3.234, arpu =4.14}, { n =2.772, arpu =3.96}, { n =2.31, arpu =3.78}, { n =1.848, arpu =3.54}, { n =1.386, arpu =3.36}},{{ n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}},},
        e2={{{ n =6.44, arpu =11.68}, { n =5.656, arpu =11.2}, { n =4.816, arpu =10.64}, { n =4.032, arpu =10.08}, { n =3.248, arpu =9.6}, { n =2.408, arpu =9.04}},{{ n =4.83, arpu =8.76}, { n =4.242, arpu =8.4}, { n =3.612, arpu =7.98}, { n =3.024, arpu =7.56}, { n =2.436, arpu =7.2}, { n =1.806, arpu =6.78}},{{ n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}, { n =0, arpu =0}},},
        
        },

        [3] = { -- Y3
        a1={{{ n =8.82, arpu =1.54}, { n =7.77, arpu =1.47}, { n =6.65, arpu =1.4}, { n =5.53, arpu =1.33}, { n =4.41, arpu =1.26}, { n =3.29, arpu =1.19}},{{ n =8.82, arpu =1.54}, { n =7.77, arpu =1.47}, { n =6.65, arpu =1.4}, { n =5.53, arpu =1.33}, { n =4.41, arpu =1.26}, { n =3.29, arpu =1.19}},{{ n =6.3, arpu =1.1}, { n =5.55, arpu =1.05}, { n =4.75, arpu =1}, { n =3.95, arpu =0.95}, { n =3.15, arpu =0.9}, { n =2.35, arpu =0.85}},},
        a2={{{ n =4.62, arpu =3.85}, { n =4.06, arpu =3.71}, { n =3.5, arpu =3.5}, { n =2.94, arpu =3.36}, { n =2.31, arpu =3.15}, { n =1.75, arpu =3.01}},{{ n =4.62, arpu =3.85}, { n =4.06, arpu =3.71}, { n =3.5, arpu =3.5}, { n =2.94, arpu =3.36}, { n =2.31, arpu =3.15}, { n =1.75, arpu =3.01}},{{ n =3.3, arpu =2.75}, { n =2.9, arpu =2.65}, { n =2.5, arpu =2.5}, { n =2.1, arpu =2.4}, { n =1.65, arpu =2.25}, { n =1.25, arpu =2.15}},},
        b1={{{ n =11.06, arpu =1.26}, { n =9.66, arpu =1.19}, { n =8.33, arpu =1.12}, { n =6.93, arpu =1.05}, { n =5.53, arpu =0.98}, { n =4.13, arpu =0.98}},{{ n =11.06, arpu =1.26}, { n =9.66, arpu =1.19}, { n =8.33, arpu =1.12}, { n =6.93, arpu =1.05}, { n =5.53, arpu =0.98}, { n =4.13, arpu =0.98}},{{ n =7.9, arpu =0.9}, { n =6.9, arpu =0.85}, { n =5.95, arpu =0.8}, { n =4.95, arpu =0.75}, { n =3.95, arpu =0.7}, { n =2.95, arpu =0.7}},},
        b2={{{ n =4.41, arpu =5.11}, { n =3.85, arpu =4.83}, { n =3.29, arpu =4.62}, { n =2.73, arpu =4.41}, { n =2.17, arpu =4.13}, { n =1.68, arpu =3.92}},{{ n =4.41, arpu =5.11}, { n =3.85, arpu =4.83}, { n =3.29, arpu =4.62}, { n =2.73, arpu =4.41}, { n =2.17, arpu =4.13}, { n =1.68, arpu =3.92}},{{ n =3.15, arpu =3.65}, { n =2.75, arpu =3.45}, { n =2.35, arpu =3.3}, { n =1.95, arpu =3.15}, { n =1.55, arpu =2.95}, { n =1.2, arpu =2.8}},},
        d1={{{ n =6.867, arpu =3.08}, { n =5.985, arpu =2.94}, { n =5.166, arpu =2.8}, { n =4.284, arpu =2.66}, { n =3.465, arpu =2.52}, { n =2.583, arpu =2.38}},{{ n =6.867, arpu =3.08}, { n =5.985, arpu =2.94}, { n =5.166, arpu =2.8}, { n =4.284, arpu =2.66}, { n =3.465, arpu =2.52}, { n =2.583, arpu =2.38}},{{ n =4.905, arpu =2.2}, { n =4.275, arpu =2.1}, { n =3.69, arpu =2}, { n =3.06, arpu =1.9}, { n =2.475, arpu =1.8}, { n =1.845, arpu =1.7}},},
        d2={{{ n =5.166, arpu =7.7}, { n =4.536, arpu =7.35}, { n =3.843, arpu =7}, { n =3.213, arpu =6.65}, { n =2.583, arpu =6.3}, { n =1.953, arpu =5.95}},{{ n =5.166, arpu =7.7}, { n =4.536, arpu =7.35}, { n =3.843, arpu =7}, { n =3.213, arpu =6.65}, { n =2.583, arpu =6.3}, { n =1.953, arpu =5.95}},{{ n =3.69, arpu =5.5}, { n =3.24, arpu =5.25}, { n =2.745, arpu =5}, { n =2.295, arpu =4.75}, { n =1.845, arpu =4.5}, { n =1.395, arpu =4.25}},},
        e1={{{ n =5.607, arpu =5.11}, { n =4.851, arpu =4.83}, { n =4.158, arpu =4.62}, { n =3.465, arpu =4.41}, { n =2.772, arpu =4.13}, { n =2.079, arpu =3.92}},{{ n =5.607, arpu =5.11}, { n =4.851, arpu =4.83}, { n =4.158, arpu =4.62}, { n =3.465, arpu =4.41}, { n =2.772, arpu =4.13}, { n =2.079, arpu =3.92}},{{ n =4.005, arpu =3.65}, { n =3.465, arpu =3.45}, { n =2.97, arpu =3.3}, { n =2.475, arpu =3.15}, { n =1.98, arpu =2.95}, { n =1.485, arpu =2.8}},},
        e2={{{ n =7.245, arpu =10.22}, { n =6.363, arpu =9.8}, { n =5.418, arpu =9.31}, { n =4.536, arpu =8.82}, { n =3.654, arpu =8.4}, { n =2.709, arpu =7.91}},{{ n =7.245, arpu =10.22}, { n =6.363, arpu =9.8}, { n =5.418, arpu =9.31}, { n =4.536, arpu =8.82}, { n =3.654, arpu =8.4}, { n =2.709, arpu =7.91}},{{ n =5.175, arpu =7.3}, { n =4.545, arpu =7}, { n =3.87, arpu =6.65}, { n =3.24, arpu =6.3}, { n =2.61, arpu =6}, { n =1.935, arpu =5.65}},},
        
        },

        [4] =     { -- Y4
        a1={{{ n =7.56, arpu =1.32}, { n =6.66, arpu =1.26}, { n =5.7, arpu =1.2}, { n =4.74, arpu =1.14}, { n =3.78, arpu =1.08}, { n =2.82, arpu =1.02}},{{ n =10.08, arpu =1.76}, { n =8.88, arpu =1.68}, { n =7.6, arpu =1.6}, { n =6.32, arpu =1.52}, { n =5.04, arpu =1.44}, { n =3.76, arpu =1.36}},{{ n =6.93, arpu =1.21}, { n =6.105, arpu =1.155}, { n =5.225, arpu =1.1}, { n =4.345, arpu =1.045}, { n =3.465, arpu =0.99}, { n =2.585, arpu =0.935}},},
        a2={{{ n =3.96, arpu =3.3}, { n =3.48, arpu =3.18}, { n =3, arpu =3}, { n =2.52, arpu =2.88}, { n =1.98, arpu =2.7}, { n =1.5, arpu =2.58}},{{ n =5.28, arpu =4.4}, { n =4.64, arpu =4.24}, { n =4, arpu =4}, { n =3.36, arpu =3.84}, { n =2.64, arpu =3.6}, { n =2, arpu =3.44}},{{ n =3.63, arpu =3.025}, { n =3.19, arpu =2.915}, { n =2.75, arpu =2.75}, { n =2.31, arpu =2.64}, { n =1.815, arpu =2.475}, { n =1.375, arpu =2.365}},},
        b1={{{ n =9.48, arpu =1.08}, { n =8.28, arpu =1.02}, { n =7.14, arpu =0.96}, { n =5.94, arpu =0.9}, { n =4.74, arpu =0.84}, { n =3.54, arpu =0.84}},{{ n =12.64, arpu =1.44}, { n =11.04, arpu =1.36}, { n =9.52, arpu =1.28}, { n =7.92, arpu =1.2}, { n =6.32, arpu =1.12}, { n =4.72, arpu =1.12}},{{ n =8.69, arpu =0.99}, { n =7.59, arpu =0.935}, { n =6.545, arpu =0.88}, { n =5.445, arpu =0.825}, { n =4.345, arpu =0.77}, { n =3.245, arpu =0.77}},},
        b2={{{ n =3.78, arpu =4.38}, { n =3.3, arpu =4.14}, { n =2.82, arpu =3.96}, { n =2.34, arpu =3.78}, { n =1.86, arpu =3.54}, { n =1.44, arpu =3.36}},{{ n =5.04, arpu =5.84}, { n =4.4, arpu =5.52}, { n =3.76, arpu =5.28}, { n =3.12, arpu =5.04}, { n =2.48, arpu =4.72}, { n =1.92, arpu =4.48}},{{ n =3.465, arpu =4.015}, { n =3.025, arpu =3.795}, { n =2.585, arpu =3.63}, { n =2.145, arpu =3.465}, { n =1.705, arpu =3.245}, { n =1.32, arpu =3.08}},},
        d1={{{ n =6.54, arpu =2.64}, { n =5.7, arpu =2.52}, { n =4.92, arpu =2.4}, { n =4.08, arpu =2.28}, { n =3.3, arpu =2.16}, { n =2.46, arpu =2.04}},{{ n =8.72, arpu =3.52}, { n =7.6, arpu =3.36}, { n =6.56, arpu =3.2}, { n =5.44, arpu =3.04}, { n =4.4, arpu =2.88}, { n =3.28, arpu =2.72}},{{ n =5.995, arpu =2.42}, { n =5.225, arpu =2.31}, { n =4.51, arpu =2.2}, { n =3.74, arpu =2.09}, { n =3.025, arpu =1.98}, { n =2.255, arpu =1.87}},},
        d2={{{ n =4.92, arpu =6.6}, { n =4.32, arpu =6.3}, { n =3.66, arpu =6}, { n =3.06, arpu =5.7}, { n =2.46, arpu =5.4}, { n =1.86, arpu =5.1}},{{ n =6.56, arpu =8.8}, { n =5.76, arpu =8.4}, { n =4.88, arpu =8}, { n =4.08, arpu =7.6}, { n =3.28, arpu =7.2}, { n =2.48, arpu =6.8}},{{ n =4.51, arpu =6.05}, { n =3.96, arpu =5.775}, { n =3.355, arpu =5.5}, { n =2.805, arpu =5.225}, { n =2.255, arpu =4.95}, { n =1.705, arpu =4.675}},},
        e1={{{ n =5.34, arpu =4.38}, { n =4.62, arpu =4.14}, { n =3.96, arpu =3.96}, { n =3.3, arpu =3.78}, { n =2.64, arpu =3.54}, { n =1.98, arpu =3.36}},{{ n =7.12, arpu =5.84}, { n =6.16, arpu =5.52}, { n =5.28, arpu =5.28}, { n =4.4, arpu =5.04}, { n =3.52, arpu =4.72}, { n =2.64, arpu =4.48}},{{ n =4.895, arpu =4.015}, { n =4.235, arpu =3.795}, { n =3.63, arpu =3.63}, { n =3.025, arpu =3.465}, { n =2.42, arpu =3.245}, { n =1.815, arpu =3.08}},},
        e2={{{ n =6.9, arpu =8.76}, { n =6.06, arpu =8.4}, { n =5.16, arpu =7.98}, { n =4.32, arpu =7.56}, { n =3.48, arpu =7.2}, { n =2.58, arpu =6.78}},{{ n =9.2, arpu =11.68}, { n =8.08, arpu =11.2}, { n =6.88, arpu =10.64}, { n =5.76, arpu =10.08}, { n =4.64, arpu =9.6}, { n =3.44, arpu =9.04}},{{ n =6.325, arpu =8.03}, { n =5.555, arpu =7.7}, { n =4.73, arpu =7.315}, { n =3.96, arpu =6.93}, { n =3.19, arpu =6.6}, { n =2.365, arpu =6.215}},},
        

                  },
        [5] = { -- Y5
        a1={{{ n =8.82, arpu =1.54}, { n =7.77, arpu =1.47}, { n =6.65, arpu =1.4}, { n =5.53, arpu =1.33}, { n =4.41, arpu =1.26}, { n =3.29, arpu =1.19}},{{ n =8.19, arpu =1.43}, { n =7.215, arpu =1.365}, { n =6.175, arpu =1.3}, { n =5.135, arpu =1.235}, { n =4.095, arpu =1.17}, { n =3.055, arpu =1.105}},{{ n =9.45, arpu =1.65}, { n =8.325, arpu =1.575}, { n =7.125, arpu =1.5}, { n =5.925, arpu =1.425}, { n =4.725, arpu =1.35}, { n =3.525, arpu =1.275}},},
        a2={{{ n =4.62, arpu =3.85}, { n =4.06, arpu =3.71}, { n =3.5, arpu =3.5}, { n =2.94, arpu =3.36}, { n =2.31, arpu =3.15}, { n =1.75, arpu =3.01}},{{ n =4.29, arpu =3.575}, { n =3.77, arpu =3.445}, { n =3.25, arpu =3.25}, { n =2.73, arpu =3.12}, { n =2.145, arpu =2.925}, { n =1.625, arpu =2.795}},{{ n =4.95, arpu =4.125}, { n =4.35, arpu =3.975}, { n =3.75, arpu =3.75}, { n =3.15, arpu =3.6}, { n =2.475, arpu =3.375}, { n =1.875, arpu =3.225}},},
        b1={{{ n =11.06, arpu =1.26}, { n =9.66, arpu =1.19}, { n =8.33, arpu =1.12}, { n =6.93, arpu =1.05}, { n =5.53, arpu =0.98}, { n =4.13, arpu =0.98}},{{ n =10.27, arpu =1.17}, { n =8.97, arpu =1.105}, { n =7.735, arpu =1.04}, { n =6.435, arpu =0.975}, { n =5.135, arpu =0.91}, { n =3.835, arpu =0.91}},{{ n =11.85, arpu =1.35}, { n =10.35, arpu =1.275}, { n =8.925, arpu =1.2}, { n =7.425, arpu =1.125}, { n =5.925, arpu =1.05}, { n =4.425, arpu =1.05}},},
        b2={{{ n =4.41, arpu =5.11}, { n =3.85, arpu =4.83}, { n =3.29, arpu =4.62}, { n =2.73, arpu =4.41}, { n =2.17, arpu =4.13}, { n =1.68, arpu =3.92}},{{ n =4.095, arpu =4.745}, { n =3.575, arpu =4.485}, { n =3.055, arpu =4.29}, { n =2.535, arpu =4.095}, { n =2.015, arpu =3.835}, { n =1.56, arpu =3.64}},{{ n =4.725, arpu =5.475}, { n =4.125, arpu =5.175}, { n =3.525, arpu =4.95}, { n =2.925, arpu =4.725}, { n =2.325, arpu =4.425}, { n =1.8, arpu =4.2}},},
        d1={{{ n =7.63, arpu =3.08}, { n =6.65, arpu =2.94}, { n =5.74, arpu =2.8}, { n =4.76, arpu =2.66}, { n =3.85, arpu =2.52}, { n =2.87, arpu =2.38}},{{ n =7.085, arpu =2.86}, { n =6.175, arpu =2.73}, { n =5.33, arpu =2.6}, { n =4.42, arpu =2.47}, { n =3.575, arpu =2.34}, { n =2.665, arpu =2.21}},{{ n =8.175, arpu =3.3}, { n =7.125, arpu =3.15}, { n =6.15, arpu =3}, { n =5.1, arpu =2.85}, { n =4.125, arpu =2.7}, { n =3.075, arpu =2.55}},},
        d2={{{ n =5.74, arpu =7.7}, { n =5.04, arpu =7.35}, { n =4.27, arpu =7}, { n =3.57, arpu =6.65}, { n =2.87, arpu =6.3}, { n =2.17, arpu =5.95}},{{ n =5.33, arpu =7.15}, { n =4.68, arpu =6.825}, { n =3.965, arpu =6.5}, { n =3.315, arpu =6.175}, { n =2.665, arpu =5.85}, { n =2.015, arpu =5.525}},{{ n =6.15, arpu =8.25}, { n =5.4, arpu =7.875}, { n =4.575, arpu =7.5}, { n =3.825, arpu =7.125}, { n =3.075, arpu =6.75}, { n =2.325, arpu =6.375}},},
        e1={{{ n =6.23, arpu =5.11}, { n =5.39, arpu =4.83}, { n =4.62, arpu =4.62}, { n =3.85, arpu =4.41}, { n =3.08, arpu =4.13}, { n =2.31, arpu =3.92}},{{ n =5.785, arpu =4.745}, { n =5.005, arpu =4.485}, { n =4.29, arpu =4.29}, { n =3.575, arpu =4.095}, { n =2.86, arpu =3.835}, { n =2.145, arpu =3.64}},{{ n =6.675, arpu =5.475}, { n =5.775, arpu =5.175}, { n =4.95, arpu =4.95}, { n =4.125, arpu =4.725}, { n =3.3, arpu =4.425}, { n =2.475, arpu =4.2}},},
        e2={{{ n =8.05, arpu =10.22}, { n =7.07, arpu =9.8}, { n =6.02, arpu =9.31}, { n =5.04, arpu =8.82}, { n =4.06, arpu =8.4}, { n =3.01, arpu =7.91}},{{ n =7.475, arpu =9.49}, { n =6.565, arpu =9.1}, { n =5.59, arpu =8.645}, { n =4.68, arpu =8.19}, { n =3.77, arpu =7.8}, { n =2.795, arpu =7.345}},{{ n =8.625, arpu =10.95}, { n =7.575, arpu =10.5}, { n =6.45, arpu =9.975}, { n =5.4, arpu =9.45}, { n =4.35, arpu =9}, { n =3.225, arpu =8.475}},},
        
        },

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
        table.insert(tbConfig.tbYearStep, tbSeasonCfg)
    end
end

for i, v in ipairs(tbConfig.tbEndStepPerYear) do
    local tbEndStep = Lib.copyTab(v)
    tbEndStep.nCurSeasonStep = i
    table.insert(tbConfig.tbYearStep, tbEndStep)
end

for _, tbYearOrder in pairs(tbConfig.tbOrder) do
    for _, tbProductOrder in pairs(tbYearOrder) do
        for marketIdx, tbOrderList in ipairs(tbProductOrder) do
            if marketIdx == 2 or marketIdx == 3 then
                for _, tbOrder in ipairs(tbOrderList) do
                    tbOrder.delaySeason = 1
                end
            end
        end
    end
end

tbConfig.tbInitUserData.tbLastYearReport = Lib.copyTab(tbConfig.tbInitReport)
tbConfig.tbInitUserData.tbYearReport = Lib.copyTab(tbConfig.tbInitReport)

for nYear, tbOrders in pairs(tbConfig.tbOrder) do
    for szProductName, tbOrders2 in pairs(tbOrders) do
        for nMarketIndex, tbOrders3 in pairs(tbOrders2) do
            for nIndex, tbOrders4 in pairs(tbOrders3) do
                assert(type(tbOrders4) == "table" and tbOrders4.n and tbOrders4.arpu, string.format("order's format is invalid!! year:%d,szProductName:%s,nMarketIndex:%d,nIndex:%d,orderstr:%s,parent:%s", nYear, szProductName, nMarketIndex, nIndex, type(tbOrders4) == "table" and JsonEncode(tbOrders4) or tostring(tbOrders4), JsonEncode(tbOrders3)))
            end
        end
    end
end