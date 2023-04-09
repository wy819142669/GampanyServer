tbConfig = {
    nLuaVersion = 1,
    tbAccount = { "李", "陈", "薛", "王", "张", "刘" },  -- 准备弃用，客户端可以输入自己的名字
    nNormalHireCost = 1, -- 招聘费用
    nTempHireCost = 2, -- 临时招聘费用
    nFireCost = 4, -- 解雇 薪水*4
    nSalary = 1, -- 薪水
    fTaxRate = 0.1,
    tbEnableMarketPerYear = {{2}, {3}},
    tbBeginStepPerYear = {
        { desc = "支付税款", mustDone = true, syncNextStep = true, nStepUniqueId = 1},
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
        { desc = "追加额外市场，支付本地化费用", nStepUniqueId = 108},
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
        tbResearch = { d = { manpower = 20, leftPoint = 15 }, e = { manpower = 30, leftPoint = 20 } },
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
            a1 = {
                {{n = 16, arpu = 2.2}, {n = 12, arpu = 2.1}, {n = 8, arpu = 2}, {n = 6.7, arpu = 1.9}, {n = 5.3, arpu = 1.8}, {n = 4, arpu = 1.7	}, },-- 国内
                {}, -- 日韩
                {}, -- 欧美
            },
            a2 = {
                {{n = 8.4, arpu = 5.5}, {n = 6.3, arpu = 5.3}, {n = 4.2, arpu = 5}, {n = 3.5, arpu = 4.8}, {n = 2.8, arpu = 4.5}, {n = 2.1, arpu = 4.3	}, },
            },
            b1 = {
                {{n = 20.1, arpu = 1.8}, {n = 15, arpu = 1.7}, {n = 10, arpu = 1.6}, {n = 8.4, arpu = 1.5}, {n = 6.7, arpu = 1.4}, {n = 5, arpu = 1.4	}, },
            },
            b2 = {
                {{n = 8, arpu = 7.3}, {n = 6, arpu = 6.9}, {n = 4, arpu = 6.6}, {n = 3.3, arpu = 6.3}, {n = 2.7, arpu = 5.9}, {n = 2, arpu = 5.6	}, },
            },
            d1 = {
                {{n = 6.9, arpu = 4.4}, {n = 5.2, arpu = 4.2}, {n = 3.5, arpu = 4}, {n = 2.9, arpu = 3.8}, {n = 2.3, arpu = 3.6}, {n = 1.8, arpu = 3.4	}, },-- 国内
                {}, -- 日韩
                {}, -- 欧美
            },
            d2 = {
                {{n = 5.2, arpu = 11}, {n = 3.9, arpu = 10.5}, {n = 2.6, arpu = 10}, {n = 2.2, arpu = 9.5}, {n = 1.8, arpu = 9}, {n = 1.3, arpu = 8.5	}, },
            },
            e1 = {
                {{n = 5.6, arpu = 7.3}, {n = 4.2, arpu = 6.9}, {n = 2.8, arpu = 6.6}, {n = 2.4, arpu = 6.3}, {n = 1.9, arpu = 5.9}, {n = 1.4, arpu = 5.6	}, },
            },
            e2 = {
                {{n = 7.3, arpu = 14.6}, {n = 5.5, arpu = 14}, {n = 3.7, arpu = 13.3}, {n = 3.1, arpu = 12.6}, {n = 2.5, arpu = 12}, {n = 1.9, arpu = 11.3	}, },

            },
        },

        [2] = { -- Y2
        a1 = {
            {{n = 12.8, arpu = 1.8}, {n = 9.6, arpu = 1.7}, {n = 6.4, arpu = 1.6}, {n = 5.4, arpu = 1.5}, {n = 4.2, arpu = 1.4}, {n = 3.2, arpu = 1.4}, },
            {{n = 9.6, arpu = 1.3}, {n = 7.2, arpu = 1.3}, {n = 4.8, arpu = 1.2}, {n = 4, arpu = 1.1}, {n = 3.2, arpu = 1.1}, {n = 2.4, arpu = 1	}, },
        },
        a2 = {
            {{n = 6.7, arpu = 4.4}, {n = 5, arpu = 4.2}, {n = 3.4, arpu = 4}, {n = 2.8, arpu = 3.8}, {n = 2.2, arpu = 3.6}, {n = 1.7, arpu = 3.4}, },	
            {{n = 5, arpu = 3.3}, {n = 3.8, arpu = 3.2}, {n = 2.5, arpu = 3}, {n = 2.1, arpu = 2.9}, {n = 1.7, arpu = 2.7}, {n = 1.3, arpu = 2.6	}, },
        },
        b1 = {
            {{n = 16.1, arpu = 1.4}, {n = 12, arpu = 1.4}, {n = 8, arpu = 1.3}, {n = 6.7, arpu = 1.2}, {n = 5.4, arpu = 1.1}, {n = 4, arpu = 1.1}, },
            	{{n = 12.1, arpu = 1.1}, {n = 9, arpu = 1}, {n = 6, arpu = 1}, {n = 5, arpu = 0.9}, {n = 4, arpu = 0.8}, {n = 3, arpu = 0.8	}, },
        },
        b2 = {
            {{n = 6.4, arpu = 5.8}, {n = 4.8, arpu = 5.5}, {n = 3.2, arpu = 5.3}, {n = 2.6, arpu = 5}, {n = 2.2, arpu = 4.7}, {n = 1.6, arpu = 4.5}, },
            {{n = 4.8, arpu = 4.4}, {n = 3.6, arpu = 4.1}, {n = 2.4, arpu = 4}, {n = 2, arpu = 3.8}, {n = 1.6, arpu = 3.5}, {n = 1.2, arpu = 3.4	}, },
        },
        d1 = {
            {{n = 7.7, arpu = 3.5}, {n = 5.8, arpu = 3.4}, {n = 3.9, arpu = 3.2}, {n = 3.2, arpu = 3}, {n = 2.6, arpu = 2.9}, {n = 2, arpu = 2.7}, },
            {{n = 5.8, arpu = 2.6}, {n = 4.4, arpu = 2.5}, {n = 2.9, arpu = 2.4}, {n = 2.4, arpu = 2.3}, {n = 1.9, arpu = 2.2}, {n = 1.5, arpu = 2	}, },
           },
        d2 = {
            {{n = 5.8, arpu = 8.8}, {n = 4.4, arpu = 8.4}, {n = 2.9, arpu = 8}, {n = 2.4, arpu = 7.6}, {n = 2, arpu = 7.2}, {n = 1.5, arpu = 6.8}, },
            {{n = 4.4, arpu = 6.6}, {n = 3.3, arpu = 6.3}, {n = 2.2, arpu = 6}, {n = 1.8, arpu = 5.7}, {n = 1.5, arpu = 5.4}, {n = 1.1, arpu = 5.1	}, },
        },
        e1 = {
            {{n = 6.3, arpu = 5.8}, {n = 4.7, arpu = 5.5}, {n = 3.1, arpu = 5.3}, {n = 2.6, arpu = 5}, {n = 2.1, arpu = 4.7}, {n = 1.6, arpu = 4.5}, },	
            {{n = 4.7, arpu = 4.4}, {n = 3.5, arpu = 4.1}, {n = 2.4, arpu = 4}, {n = 2, arpu = 3.8}, {n = 1.6, arpu = 3.5}, {n = 1.2, arpu = 3.4	}, },
        },
        e2 = {
            {{n = 8.2, arpu = 11.7}, {n = 6.2, arpu = 11.2}, {n = 4.1, arpu = 10.6}, {n = 3.4, arpu = 10.1}, {n = 2.7, arpu = 9.6}, {n = 2.1, arpu = 9}, },	
            {{n = 6.1, arpu = 8.8}, {n = 4.6, arpu = 8.4}, {n = 3.1, arpu = 8}, {n = 2.6, arpu = 7.6}, {n = 2.1, arpu = 7.2}, {n = 1.6, arpu = 6.8	}, },

        },
        },

        [3] = { -- Y3
        a1 = {
            {{n = 11.2, arpu = 1.5}, {n = 8.4, arpu = 1.5}, {n = 5.6, arpu = 1.4}, {n = 4.7, arpu = 1.3}, {n = 3.7, arpu = 1.3}, {n = 2.8, arpu = 1.2}, },	
            {{n = 	11.2, arpu = 1.5}, {n = 8.4, arpu = 1.5}, {n = 5.6, arpu = 1.4}, {n = 4.7, arpu = 1.3}, {n = 3.7, arpu = 1.3}, {n = 2.8, arpu = 1.2}, },	
            {{n = 	8, arpu = 1.1}, {n = 6, arpu = 1.1}, {n = 4, arpu = 1}, {n = 3.4, arpu = 1}, {n = 2.7, arpu = 0.9}, {n = 2, arpu = 0.9}, },
       },
        a2 = {
            {{n = 5.9, arpu = 3.9}, {n = 4.4, arpu = 3.7}, {n = 2.9, arpu = 3.5}, {n = 2.5, arpu = 3.4}, {n = 2, arpu = 3.2}, {n = 1.5, arpu = 3}, },	
            {{n = 	5.9, arpu = 3.9}, {n = 4.4, arpu = 3.7}, {n = 2.9, arpu = 3.5}, {n = 2.5, arpu = 3.4}, {n = 2, arpu = 3.2}, {n = 1.5, arpu = 3}, },	
            {{n = 	4.2, arpu = 2.8}, {n = 3.2, arpu = 2.7}, {n = 2.1, arpu = 2.5}, {n = 1.8, arpu = 2.4}, {n = 1.4, arpu = 2.3}, {n = 1.1, arpu = 2.2}, },
         },
        b1 = {
            {{n = 14.1, arpu = 1.3}, {n = 10.5, arpu = 1.2}, {n = 7, arpu = 1.1}, {n = 5.9, arpu = 1.1}, {n = 4.7, arpu = 1}, {n = 3.5, arpu = 1}, },	
            {{n = 	14.1, arpu = 1.3}, {n = 10.5, arpu = 1.2}, {n = 7, arpu = 1.1}, {n = 5.9, arpu = 1.1}, {n = 4.7, arpu = 1}, {n = 3.5, arpu = 1}, },	
            {{n = 	10.1, arpu = 0.9}, {n = 7.5, arpu = 0.9}, {n = 5, arpu = 0.8}, {n = 4.2, arpu = 0.8}, {n = 3.4, arpu = 0.7}, {n = 2.5, arpu = 0.7}, },
      },
        b2 = {
            {{n = 5.6, arpu = 5.1}, {n = 4.2, arpu = 4.8}, {n = 2.8, arpu = 4.6}, {n = 2.3, arpu = 4.4}, {n = 1.9, arpu = 4.1}, {n = 1.4, arpu = 3.9}, },	
            {{n = 	5.6, arpu = 5.1}, {n = 4.2, arpu = 4.8}, {n = 2.8, arpu = 4.6}, {n = 2.3, arpu = 4.4}, {n = 1.9, arpu = 4.1}, {n = 1.4, arpu = 3.9}, },	
            {{n = 	4, arpu = 3.7}, {n = 3, arpu = 3.5}, {n = 2, arpu = 3.3}, {n = 1.7, arpu = 3.2}, {n = 1.4, arpu = 3}, {n = 1, arpu = 2.8}, },
       },
        d1 = {
            {{n = 8.7, arpu = 3.1}, {n = 6.6, arpu = 2.9}, {n = 4.3, arpu = 2.8}, {n = 3.7, arpu = 2.7}, {n = 2.9, arpu = 2.5}, {n = 2.2, arpu = 2.4}, },	
            {{n = 	8.7, arpu = 3.1}, {n = 6.6, arpu = 2.9}, {n = 4.3, arpu = 2.8}, {n = 3.7, arpu = 2.7}, {n = 2.9, arpu = 2.5}, {n = 2.2, arpu = 2.4}, },	
            {{n = 	6.2, arpu = 2.2}, {n = 4.7, arpu = 2.1}, {n = 3.1, arpu = 2}, {n = 2.6, arpu = 1.9}, {n = 2.1, arpu = 1.8}, {n = 1.6, arpu = 1.7}, },
            },
        d2 = {
            {{n = 6.6, arpu = 7.7}, {n = 4.9, arpu = 7.4}, {n = 3.3, arpu = 7}, {n = 2.7, arpu = 6.7}, {n = 2.2, arpu = 6.3}, {n = 1.6, arpu = 6}, },	
            {{n = 	6.6, arpu = 7.7}, {n = 4.9, arpu = 7.4}, {n = 3.3, arpu = 7}, {n = 2.7, arpu = 6.7}, {n = 2.2, arpu = 6.3}, {n = 1.6, arpu = 6}, },	
            {{n = 	4.7, arpu = 5.5}, {n = 3.5, arpu = 5.3}, {n = 2.3, arpu = 5}, {n = 1.9, arpu = 4.8}, {n = 1.6, arpu = 4.5}, {n = 1.2, arpu = 4.3}, },
        },
        e1 = {
            {{n = 7.1, arpu = 5.1}, {n = 5.3, arpu = 4.8}, {n = 3.5, arpu = 4.6}, {n = 3, arpu = 4.4}, {n = 2.3, arpu = 4.1}, {n = 1.8, arpu = 3.9}, },	
            {{n = 	7.1, arpu = 5.1}, {n = 5.3, arpu = 4.8}, {n = 3.5, arpu = 4.6}, {n = 3, arpu = 4.4}, {n = 2.3, arpu = 4.1}, {n = 1.8, arpu = 3.9}, },	
            {{n = 	5, arpu = 3.7}, {n = 3.8, arpu = 3.5}, {n = 2.5, arpu = 3.3}, {n = 2.1, arpu = 3.2}, {n = 1.7, arpu = 3}, {n = 1.3, arpu = 2.8}, },
        },
        e2 = {
            {{n = 9.2, arpu = 10.2}, {n = 6.9, arpu = 9.8}, {n = 4.6, arpu = 9.3}, {n = 3.8, arpu = 8.8}, {n = 3.1, arpu = 8.4}, {n = 2.3, arpu = 7.9}, },	
            {{n = 	9.2, arpu = 10.2}, {n = 6.9, arpu = 9.8}, {n = 4.6, arpu = 9.3}, {n = 3.8, arpu = 8.8}, {n = 3.1, arpu = 8.4}, {n = 2.3, arpu = 7.9}, },	
            {{n = 	6.6, arpu = 7.3}, {n = 5, arpu = 7}, {n = 3.3, arpu = 6.7}, {n = 2.7, arpu = 6.3}, {n = 2.2, arpu = 6}, {n = 1.7, arpu = 5.7}, },
        },
        },

        [4] =     { -- Y4
        a1 = {
            {{n = 9.6, arpu = 1.3}, {n = 7.2, arpu = 1.3}, {n = 4.8, arpu = 1.2}, {n = 4, arpu = 1.1}, {n = 3.2, arpu = 1.1}, {n = 2.4, arpu = 1}, },	
            {{n = 	12.8, arpu = 1.8}, {n = 9.6, arpu = 1.7}, {n = 6.4, arpu = 1.6}, {n = 5.4, arpu = 1.5}, {n = 4.2, arpu = 1.4}, {n = 3.2, arpu = 1.4}, },	
            {{n = 	8.8, arpu = 1.2}, {n = 6.6, arpu = 1.2}, {n = 4.4, arpu = 1.1}, {n = 3.7, arpu = 1}, {n = 2.9, arpu = 1}, {n = 2.2, arpu = 0.9}, },
          },
        a2 = {
            {{n = 5, arpu = 3.3}, {n = 3.8, arpu = 3.2}, {n = 2.5, arpu = 3}, {n = 2.1, arpu = 2.9}, {n = 1.7, arpu = 2.7}, {n = 1.3, arpu = 2.6}, },	
            {{n = 	6.7, arpu = 4.4}, {n = 5, arpu = 4.2}, {n = 3.4, arpu = 4}, {n = 2.8, arpu = 3.8}, {n = 2.2, arpu = 3.6}, {n = 1.7, arpu = 3.4}, },	
            {{n = 	4.6, arpu = 3}, {n = 3.5, arpu = 2.9}, {n = 2.3, arpu = 2.8}, {n = 1.9, arpu = 2.6}, {n = 1.5, arpu = 2.5}, {n = 1.2, arpu = 2.4}, },
           },
        b1 = {
            {{n = 12.1, arpu = 1.1}, {n = 9, arpu = 1}, {n = 6, arpu = 1}, {n = 5, arpu = 0.9}, {n = 4, arpu = 0.8}, {n = 3, arpu = 0.8}, },	
            {{n = 	16.1, arpu = 1.4}, {n = 12, arpu = 1.4}, {n = 8, arpu = 1.3}, {n = 6.7, arpu = 1.2}, {n = 5.4, arpu = 1.1}, {n = 4, arpu = 1.1}, },	
            {{n = 	11.1, arpu = 1}, {n = 8.3, arpu = 0.9}, {n = 5.5, arpu = 0.9}, {n = 4.6, arpu = 0.8}, {n = 3.7, arpu = 0.8}, {n = 2.8, arpu = 0.8}, },
          },
        b2 = {
            {{n = 4.8, arpu = 4.4}, {n = 3.6, arpu = 4.1}, {n = 2.4, arpu = 4}, {n = 2, arpu = 3.8}, {n = 1.6, arpu = 3.5}, {n = 1.2, arpu = 3.4}, },	
            {{n = 	6.4, arpu = 5.8}, {n = 4.8, arpu = 5.5}, {n = 3.2, arpu = 5.3}, {n = 2.6, arpu = 5}, {n = 2.2, arpu = 4.7}, {n = 1.6, arpu = 4.5}, },	
            {{n = 	4.4, arpu = 4}, {n = 3.3, arpu = 3.8}, {n = 2.2, arpu = 3.6}, {n = 1.8, arpu = 3.5}, {n = 1.5, arpu = 3.2}, {n = 1.1, arpu = 3.1}, },
           },
        d1 = {
            {{n = 8.3, arpu = 2.6}, {n = 6.2, arpu = 2.5}, {n = 4.1, arpu = 2.4}, {n = 3.5, arpu = 2.3}, {n = 2.8, arpu = 2.2}, {n = 2.1, arpu = 2}, },	
            {{n = 	11, arpu = 3.5}, {n = 8.3, arpu = 3.4}, {n = 5.5, arpu = 3.2}, {n = 4.6, arpu = 3}, {n = 3.7, arpu = 2.9}, {n = 2.8, arpu = 2.7}, },	
            {{n = 	7.6, arpu = 2.4}, {n = 5.7, arpu = 2.3}, {n = 3.8, arpu = 2.2}, {n = 3.2, arpu = 2.1}, {n = 2.5, arpu = 2}, {n = 1.9, arpu = 1.9}, },
          },
        d2 = {
            {{n = 6.2, arpu = 6.6}, {n = 4.7, arpu = 6.3}, {n = 3.1, arpu = 6}, {n = 2.6, arpu = 5.7}, {n = 2.1, arpu = 5.4}, {n = 1.6, arpu = 5.1}, },	
            {{n = 	8.3, arpu = 8.8}, {n = 6.2, arpu = 8.4}, {n = 4.2, arpu = 8}, {n = 3.4, arpu = 7.6}, {n = 2.8, arpu = 7.2}, {n = 2.1, arpu = 6.8}, },	
            {{n = 	5.7, arpu = 6.1}, {n = 4.3, arpu = 5.8}, {n = 2.9, arpu = 5.5}, {n = 2.4, arpu = 5.2}, {n = 1.9, arpu = 5}, {n = 1.4, arpu = 4.7}, },
         },
        e1 = {
            {{n = 6.7, arpu = 4.4}, {n = 5, arpu = 4.1}, {n = 3.4, arpu = 4}, {n = 2.8, arpu = 3.8}, {n = 2.2, arpu = 3.5}, {n = 1.7, arpu = 3.4}, },	
            {{n = 	9, arpu = 5.8}, {n = 6.7, arpu = 5.5}, {n = 4.5, arpu = 5.3}, {n = 3.8, arpu = 5}, {n = 3, arpu = 4.7}, {n = 2.2, arpu = 4.5}, },	
            {{n = 	6.2, arpu = 4}, {n = 4.6, arpu = 3.8}, {n = 3.1, arpu = 3.6}, {n = 2.6, arpu = 3.5}, {n = 2, arpu = 3.2}, {n = 1.5, arpu = 3.1}, },
         },
        e2 = {
            {{n = 8.8, arpu = 8.8}, {n = 6.6, arpu = 8.4}, {n = 4.4, arpu = 8}, {n = 3.7, arpu = 7.6}, {n = 2.9, arpu = 7.2}, {n = 2.2, arpu = 6.8}, },	
            {{n = 	11.7, arpu = 11.7}, {n = 8.8, arpu = 11.2}, {n = 5.8, arpu = 10.6}, {n = 4.9, arpu = 10.1}, {n = 3.9, arpu = 9.6}, {n = 3, arpu = 9}, },	
            {{n = 	8, arpu = 8}, {n = 6.1, arpu = 7.7}, {n = 4, arpu = 7.3}, {n = 3.4, arpu = 6.9}, {n = 2.7, arpu = 6.6}, {n = 2, arpu = 6.2}, },       
            },

                  },
        [5] = { -- Y5
        a1 = {
            {{n = 11.2, arpu = 1.5}, {n = 8.4, arpu = 1.5}, {n = 5.6, arpu = 1.4}, {n = 4.7, arpu = 1.3}, {n = 3.7, arpu = 1.3}, {n = 2.8, arpu = 1.2}, },	
            {{n =	10.4, arpu = 1.4}, {n = 7.8, arpu = 1.4}, {n = 5.2, arpu = 1.3}, {n = 4.4, arpu = 1.2}, {n = 3.4, arpu = 1.2}, {n = 2.6, arpu = 1.1}, },	
            {{n =	12, arpu = 1.7}, {n = 9, arpu = 1.6}, {n = 6, arpu = 1.5}, {n = 5, arpu = 1.4}, {n = 4, arpu = 1.4}, {n = 3, arpu = 1.3}, },
       },
        a2 = {
            {{n = 5.9, arpu = 3.9}, {n = 4.4, arpu = 3.7}, {n = 2.9, arpu = 3.5}, {n = 2.5, arpu = 3.4}, {n = 2, arpu = 3.2}, {n = 1.5, arpu = 3}, },	
            {{n =	5.5, arpu = 3.6}, {n = 4.1, arpu = 3.4}, {n = 2.7, arpu = 3.3}, {n = 2.3, arpu = 3.1}, {n = 1.8, arpu = 2.9}, {n = 1.4, arpu = 2.8}, },	
            {{n =	6.3, arpu = 4.1}, {n = 4.7, arpu = 4}, {n = 3.2, arpu = 3.8}, {n = 2.6, arpu = 3.6}, {n = 2.1, arpu = 3.4}, {n = 1.6, arpu = 3.2}, },
       },
        b1 = {
            {{n = 14.1, arpu = 1.3}, {n = 10.5, arpu = 1.2}, {n = 7, arpu = 1.1}, {n = 5.9, arpu = 1.1}, {n = 4.7, arpu = 1}, {n = 3.5, arpu = 1}, },	
            {{n =	13.1, arpu = 1.2}, {n = 9.8, arpu = 1.1}, {n = 6.5, arpu = 1}, {n = 5.5, arpu = 1}, {n = 4.4, arpu = 0.9}, {n = 3.3, arpu = 0.9}, },	
            {{n =	15.1, arpu = 1.4}, {n = 11.3, arpu = 1.3}, {n = 7.5, arpu = 1.2}, {n = 6.3, arpu = 1.1}, {n = 5, arpu = 1.1}, {n = 3.8, arpu = 1.1}, },
      },
        b2 = {
            {{n = 5.6, arpu = 5.1}, {n = 4.2, arpu = 4.8}, {n = 2.8, arpu = 4.6}, {n = 2.3, arpu = 4.4}, {n = 1.9, arpu = 4.1}, {n = 1.4, arpu = 3.9}, },	
            {{n =	5.2, arpu = 4.7}, {n = 3.9, arpu = 4.5}, {n = 2.6, arpu = 4.3}, {n = 2.1, arpu = 4.1}, {n = 1.8, arpu = 3.8}, {n = 1.3, arpu = 3.6}, },	
            {{n =	6, arpu = 5.5}, {n = 4.5, arpu = 5.2}, {n = 3, arpu = 5}, {n = 2.5, arpu = 4.7}, {n = 2, arpu = 4.4}, {n = 1.5, arpu = 4.2}, },
         },
        d1 = {
            {{n = 9.7, arpu = 3.1}, {n = 7.3, arpu = 2.9}, {n = 4.8, arpu = 2.8}, {n = 4.1, arpu = 2.7}, {n = 3.2, arpu = 2.5}, {n = 2.5, arpu = 2.4}, },	
            {{n =	9, arpu = 2.9}, {n = 6.8, arpu = 2.7}, {n = 4.5, arpu = 2.6}, {n = 3.8, arpu = 2.5}, {n = 3, arpu = 2.3}, {n = 2.3, arpu = 2.2}, },	
            {{n =	10.4, arpu = 3.3}, {n = 7.8, arpu = 3.2}, {n = 5.2, arpu = 3}, {n = 4.4, arpu = 2.9}, {n = 3.5, arpu = 2.7}, {n = 2.6, arpu = 2.6}, },
          },
        d2 = {
            {{n = 7.3, arpu = 7.7}, {n = 5.5, arpu = 7.4}, {n = 3.6, arpu = 7}, {n = 3, arpu = 6.7}, {n = 2.5, arpu = 6.3}, {n = 1.8, arpu = 6}, },	
            {{n =	6.8, arpu = 7.2}, {n = 5.1, arpu = 6.8}, {n = 3.4, arpu = 6.5}, {n = 2.8, arpu = 6.2}, {n = 2.3, arpu = 5.9}, {n = 1.7, arpu = 5.5}, },	
            {{n =	7.8, arpu = 8.3}, {n = 5.9, arpu = 7.9}, {n = 3.9, arpu = 7.5}, {n = 3.2, arpu = 7.1}, {n = 2.6, arpu = 6.8}, {n = 2, arpu = 6.4}, },
        },
        e1 = {
            {{n = 7.8, arpu = 5.1}, {n = 5.9, arpu = 4.8}, {n = 3.9, arpu = 4.6}, {n = 3.3, arpu = 4.4}, {n = 2.6, arpu = 4.1}, {n = 2, arpu = 3.9}, },	
            {{n =	7.3, arpu = 4.7}, {n = 5.5, arpu = 4.5}, {n = 3.6, arpu = 4.3}, {n = 3.1, arpu = 4.1}, {n = 2.4, arpu = 3.8}, {n = 1.8, arpu = 3.6}, },	
            {{n =	8.4, arpu = 5.5}, {n = 6.3, arpu = 5.2}, {n = 4.2, arpu = 5}, {n = 3.5, arpu = 4.7}, {n = 2.8, arpu = 4.4}, {n = 2.1, arpu = 4.2}, },
       },
        e2 = {
            {{n = 10.2, arpu = 10.2}, {n = 7.7, arpu = 9.8}, {n = 5.1, arpu = 9.3}, {n = 4.3, arpu = 8.8}, {n = 3.4, arpu = 8.4}, {n = 2.6, arpu = 7.9}, },	
            {{n = 9.5, arpu = 9.5}, {n = 7.2, arpu = 9.1}, {n = 4.7, arpu = 8.6}, {n = 4, arpu = 8.2}, {n = 3.2, arpu = 7.8}, {n = 2.4, arpu = 7.3}, },	
            {{n =	11, arpu = 11}, {n = 8.3, arpu = 10.5}, {n = 5.5, arpu = 10}, {n = 4.6, arpu = 9.5}, {n = 3.7, arpu = 9}, {n = 2.8, arpu = 8.5}, },
 
        },
        },

    }
}

for _, v in ipairs(tbConfig.tbBeginStepPerYear) do
    table.insert(tbConfig.tbYearStep, Lib.copyTab(v))
end

for i = 1, 4 do
    for j, v in ipairs(tbConfig.tbStepPerSeason) do
        local tbSeasonCfg = Lib.copyTab(v)
        tbSeasonCfg.nCurSeason = i
        tbSeasonCfg.nCurSeasonStep = j
        table.insert(tbConfig.tbYearStep, tbSeasonCfg)
    end
end

for _, v in ipairs(tbConfig.tbEndStepPerYear) do
    table.insert(tbConfig.tbYearStep, Lib.copyTab(v))
end

tbConfig.tbInitUserData.tbLastYearReport = Lib.copyTab(tbConfig.tbInitReport)
tbConfig.tbInitUserData.tbYearReport = Lib.copyTab(tbConfig.tbInitReport)
