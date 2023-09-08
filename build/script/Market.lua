local tbConfig = tbConfig

Market = {}     --用于包含响应客户端请求的函数
MarketMgr = {}  --市场模块的内部函数

-- 产品上线发布 {FuncName="Market", Operate="Publish", Id=1 }
function Market.Publish(tbParam, user)
    local product = tbParam.Id and user.tbProduct[tbParam.Id] or nil
    if not product then
        return "product not exist", false
    end
    if product.State ~= tbConfig.tbProductState.nEnabled and product.State ~= tbConfig.tbProductState.nRenovateDone then
        return "product state don't match", false
    end

    local renovate = product.State == tbConfig.tbProductState.nRenovateDone
    local quality10 = Production:Publish(product, user)
    if renovate then
        quality10 = math.floor((product.nOrigQuality10 + quality10) / 2)
    end

    if GameLogic:PROD_IsPlatformP(product) then
        user.nPlatformPQuality10 = quality10
    elseif GameLogic:PROD_IsPlatformQ(product) then
        user.nPlatformQQuality10 = quality10
    else
        GameLogic:PROD_NewPublished(tbParam.Id, product, renovate, false)
    end
    product.nOrigQuality10 = quality10
    product.nQuality10 = quality10

    local szReturnMsg = string.format("成功发布产品:%s%d", product.Category, tbParam.Id)
    return szReturnMsg, true
end

-- 提交市场营销费用 {FuncName="Market", Operate="Marketing", Product={{Id=1, Expense=10},{Id=5, Expense=40}}}
-- Product中数组元素说明：Id=产品id，Expense=当季市场营销费用
function Market.Marketing(tbParam, user)
    local nTotalExpense = 0
    local nPreTotalExpense = 0

    for _, tbProduct in pairs(tbParam.Product) do
        product = user.tbProduct[tbProduct.Id]

        if not product then
            return "product not exist", false
        end
        if not Production:IsPublished(product) then
            return "product hasn't been published yet", false
        end
        if tbProduct.Expense < 0 then
            return "market expense error", false
        end

        nPreTotalExpense    = nPreTotalExpense + product.nMarketExpense
        nTotalExpense       = nTotalExpense + tbProduct.Expense
    end 

    if user.nCash + nPreTotalExpense < nTotalExpense then
        return "cash not enough", false
    end

    GameLogic:FIN_Unpay(user, tbConfig.tbFinClassify.Mkt, nPreTotalExpense)
    GameLogic:FIN_Pay(user, tbConfig.tbFinClassify.Mkt, nTotalExpense)

    for _, tbProduct in pairs(tbParam.Product) do
        user.tbProduct[tbProduct.Id].nMarketExpense = tbProduct.Expense
    end
    return "success", true
end

function MarketMgr:DoStart()
    local data = GetTableRuntime()

    --初始化 品类信息 与 已发布产品列表
    data.tbCategoryInfo = {}
    for category, info in pairs(tbConfig.tbProductCategory) do
        if not GameLogic:PROD_IsPlatformCategory(category) then
            data.tbCategoryInfo[category] = Lib.copyTab(tbInitTables.tbInitCategoryInfo)
            data.tbCategoryInfo[category].nCommunalMarketShare = info.nTotalMarket
        end
    end

    --新建npc产品，npc产品新建时直接发布
    data.tbNpc = Lib.copyTab(tbInitTables.tbInitNpc)
    for category, _ in pairs(data.tbCategoryInfo) do
        for _ = 1, GameLogic:MKT_GetProductIdeaCount(category, 1, 1) do
            Market.NewNpcProduct(category, tbConfig.tbProductCategory[category].nNpcInitProductQuality10)
        end
    end
end

function MarketMgr:OnRecover()
    local data = GetTableRuntime()
    for _, user in pairs(data.tbUser) do
        for _, product in pairs(user.tbProduct) do
            local info = data.tbCategoryInfo[product.Category]
            if info then
                if info.tbPublishedProduct[product.Id] then
                    info.tbPublishedProduct[product.Id] = product
                end
            end
        end
    end
end

--产品份额的自然流失（受品类流失率及自身质量影响）
function MarketMgr:LossMarket()
    for c, info in pairs(GetTableRuntime().tbCategoryInfo) do
        local fRetentionRate = tbConfig.tbProductCategory[c].fProductRetentionRate
        for id, product in pairs(info.tbPublishedProduct) do
            product.nLastMarketScaleDelta = 0
            if product.nLastMarketScale > 0 then
                local fLossRate = (1.0 - fRetentionRate - 0.001 * product.nQuality10 * tbConfig.fQualityRatio)
                fLossRate = (fLossRate < 0) and 0 or fLossRate
                product.nLastMarketScaleDelta = - math.floor(product.nLastMarketScale * fLossRate)
                info.nCommunalMarketShare = info.nCommunalMarketShare - product.nLastMarketScaleDelta  --各产品流失的份额，流入品类内部共享份额
            end
        end
    end
end

function MarketMgr:GetAverageQuality10(list)
    local count = 0
    local quality = 0
    for _, product in pairs(list) do
        count = count + 1
        quality = quality + product.nQuality10
    end
    if count > 0 then
        quality = math.floor(quality / count)
    end
    return quality
end

-- 品类份额变化
function MarketMgr:CategoryShareTransfer()
    local data = GetTableRuntime().tbCategoryInfo
    local nAllScale = 0     --整个市场的总规模
    local nShareScale = 0   --公共池
    local nAllWeight = 0    --分配权重总和
    local weights = {}
    local delta

    for c, info in pairs(data) do
        --累计以计算整个市场的总规模
        nAllScale = nAllScale + info.nTotalScale
        --各品类分一些份额到公共池里
        delta = math.min(info.nCommunalMarketShare, tbConfig.nMarketShiftScale)
        nShareScale = nShareScale + delta
        info.nCommunalMarketShare = info.nCommunalMarketShare - delta
        info.nTotalScale = info.nTotalScale - delta
        --各品类的再分配权重(以品类的平均产品质量为权重)
        local weight = MarketMgr:GetAverageQuality10(info.tbPublishedProduct)
        weight = math.max(1, weight)
        weights[c] = weight
        nAllWeight = nAllWeight + weight
    end

    --根据权重给各品类分配份额
    for c, info in pairs(data) do
        delta = math.floor(nShareScale * weights[c] / nAllWeight)
        local nMaxScale = nAllScale * tbConfig.tbProductCategory[c].nMaxMarketScale / 100
        if info.nTotalScale + delta > nMaxScale then
            delta = math.max(0, math.floor(nMaxScale - info.nTotalScale))
        end
        info.nCommunalMarketShare = info.nCommunalMarketShare + delta
        info.nTotalScale = info.nTotalScale + delta
        --print("MarketShare Category:".. c, delta, info.nTotalScale)
    end
end

-- 份额分配
function MarketMgr:DistributionMarket()
    for category, info in pairs(GetTableRuntime().tbCategoryInfo) do
        local nTotal = info.nCommunalMarketShare
        if nTotal > 0 then
            local fTotalWeight = 0  --分配权重总和
            local weights = {}
            --计算各产品的分配权重与权重总和
            for id, product in pairs(info.tbPublishedProduct) do
                if product.nMarketExpense > 0 then
                    local weight = product.nMarketExpense * (1.3 ^ ((product.nQuality10 * tbConfig.fQualityRatio - 10)*0.1) )
                    local new, renovate = GameLogic:PROD_IsNewProduct(category, id)
                    if new then
                        weight = weight * (renovate and tbConfig.fRenovateCoefficient or tbConfig.fNewProductCoefficient)
                    end
                    weights[id] = weight
                    fTotalWeight = fTotalWeight + weight
                    --print("DistributionMarket weight", id, product.nMarketExpense, weight)
                end
            end

            --根据权重，给各产品分配市场份额
            if fTotalWeight > 0 then
                for id, weight in pairs(weights) do
                    local delta = math.floor(nTotal * (weight / fTotalWeight))
                    local product = info.tbPublishedProduct[id]
                    product.nLastMarketScaleDelta = product.nLastMarketScaleDelta + delta
                    info.nCommunalMarketShare = info.nCommunalMarketShare - delta
                    --print("DistributionMarket", category, id, delta, product.nMarketExpense, product.nQuality10)
                end
            end
        end

        info.nTotalScale = 0
        for id, product in pairs(info.tbPublishedProduct) do
            --各产品根据当季度的市场规模变化量，计算当季的最后拥有的市场规模
            product.nLastMarketScale = product.nLastMarketScale + product.nLastMarketScaleDelta
            --print("DistributionMarket result:", category, id, product.nLastMarketScaleDelta, product.nLastMarketScale)
            --统计品类总市场规模
            info.nTotalScale = info.nTotalScale + product.nLastMarketScale

            --把当季的费用记录到最后一次记录上
            product.nLastMarketExpense = product.nMarketExpense
            product.nMarketExpense = 0
        end

        --计算各产品的市场占比
        if info.nTotalScale > 0 then
            for _, product in pairs(info.tbPublishedProduct) do
                product.nLastMarketScalePct = math.floor(product.nLastMarketScale * 100 / info.nTotalScale)
            end
        end
    end

    for _, user in pairs(GetTableRuntime().tbUser) do
        for _, product in pairs(user.tbProduct) do
            if product.nLastMarketScaleDelta and product.nLastMarketScaleDelta ~= 0 then
                if user.tbSysMsg then
                    table.insert(user.tbSysMsg, string.format("产品%s 用户%d（%+d）", 
                        product.szName, product.nLastMarketScale, product.nLastMarketScaleDelta))
                end
            end
        end
    end
end

-- 获得收益
function MarketMgr:GainRevenue()
    local data = GetTableRuntime()
    --更新线上产品的arpu与收入, 统计品类总营收
    for _, info in pairs(data.tbCategoryInfo) do
        info.nTotalIncome = 0
        for id, product in pairs(info.tbPublishedProduct) do
            GameLogic:MKT_UpdateArpuAndIncome(product)
            info.nTotalIncome = info.nTotalIncome + product.nLastMarketIncome
            --print("GainRevenue", id, product.fLastARPU, product.nLastMarketScale, product.nLastMarketIncome)

            product.nSeasonCount = product.nSeasonCount + 1 --更新产品上市后的时长（季度数）
        end
    end
    --结算玩家收入
    for userName, user in pairs(data.tbUser) do
        local income = 0
        for _, product in pairs(user.tbProduct) do
            income = income + (product.nLastMarketIncome and product.nLastMarketIncome or 0) --非发布到市场的产品，不会有nLastMarketIncome
        end
        if income > 0 then
            GameLogic:FIN_Revenue(user, income)
            table.insert(user.tbSysMsg, string.format("产品共获得收益 %d", income))
        end
    end
end

--季度初自动设置市场费用，设置后可被修改
function MarketMgr:AutoSetMarketExpense()
    --对于玩家，若账面现金足够，则自动参照上季度市场费用 并扣除费用
    for _, user in pairs(GetTableRuntime().tbUser) do
        local total = 0
        for _, product in pairs(user.tbProduct) do
            if product.nLastMarketExpense and product.nLastMarketExpense > 0 then
                product.nMarketExpense = math.min(product.nLastMarketExpense, user.nCash - total)
                total = total + product.nMarketExpense
            end
        end
        GameLogic:FIN_Pay(user, tbConfig.tbFinClassify.Mkt, total)
    end

    --对于npc
    for id, product in pairs(GetTableRuntime().tbNpc.tbProduct) do
        if not GameLogic:PROD_IsNewProduct(product.Category, id) then
            product.nMarketExpense = tbConfig.tbProductCategory[product.Category].nNpcContinuousExpenses * (1 + (math.random() - 0.5) * 2 * tbConfig.fNpcExpenseFloatRange)
            --print("Npc id:"..id, "LastMarketIncome:",product.nLastMarketIncome, "MarketExpense:", product.nMarketExpense, "product.bNewProduct:", GameLogic:PROD_IsNewProduct(product.Category, id))
        end
    end
end

function MarketMgr:GetGamerProductHighestQuality(list)
    local quality = 0
    local npcProducts = GetTableRuntime().tbNpc.tbProduct
    for id, product in pairs(list) do
        if not table.contain_key(npcProducts, id) and product.nOrigQuality10 > quality then
            quality = product.nOrigQuality10
        end
    end
    return quality
end

function MarketMgr:NpcGetLowestRevenueProduct(category)
    local revenue = 100000000
    local chooseId = nil
    local chooseProduct = nil
    for id, product in pairs(GetTableRuntime().tbNpc.tbProduct) do
        if product.Category == category and product.nLastMarketIncome - product.nLastMarketExpense < revenue then
            revenue = product.nLastMarketIncome - product.nLastMarketExpense
            chooseId = id
            chooseProduct = product
        end
    end
    return chooseId, chooseProduct
end

function MarketMgr:NpcGetLowestQualityProduct(category)
    local quality = 100
    local chooseId = nil
    local chooseProduct = nil
    for id, product in pairs(GetTableRuntime().tbNpc.tbProduct) do
        if product.Category == category and product.nQuality10 < quality then
            quality = product.nQuality10
            chooseId = id
            chooseProduct = product
        end
    end
    return chooseId, chooseProduct
end

--概率关低品质npc产品
function MarketMgr:NpcCloseLowQuality()
    local data = GetTableRuntime()
    for category, info in pairs(data.tbCategoryInfo) do
        local cat = tbConfig.tbProductCategory[category]
        local rand = math.random() * 100
        print(rand, cat.nNpcCloseLowQualityProbabilityPerProduct * info.nNpcProductCount)
        if rand < cat.nNpcCloseLowQualityProbabilityPerProduct * info.nNpcProductCount then
            local id, product = MarketMgr:NpcGetLowestQualityProduct(category)
            print("Npc close product: ", product.Category .. tostring(id))
            product.State = tbConfig.tbProductState.nClosed
            GameLogic:OnCloseProduct(id, product, true)
            data.tbNpc.tbProduct[id] = nil
        end
    end
end

function MarketMgr:NpcExecSchedule()
    local data =  GetTableRuntime()
    local npc = data.tbNpc
    --处理新建产品计划
    local schedule = npc.tbScheduleToNew
    for category, _ in pairs(schedule) do
        local info = data.tbCategoryInfo[category]
        local productIdeaCount = GameLogic:MKT_GetProductIdeaCount(category, data.nCurYear, data.nCurSeason)
        if info.nPublishedCount >= productIdeaCount then
            --产品数量过多，取消新品上市计划
            schedule[category] = nil
        else
            --新产品上市, 每个季度最多上市2款
            for _ = 1, math.min(2, productIdeaCount - info.nPublishedCount) do
                local nAverage = MarketMgr:GetAverageQuality10(info.tbPublishedProduct)
                local nHighest = MarketMgr:GetGamerProductHighestQuality(info.tbPublishedProduct)
                local quality = nHighest > nAverage and math.random(nAverage, nHighest) or nAverage
                local id = Market.NewNpcProduct(category, quality)
                print("Npc  new Product: ", category .. tostring(id))
            end
        end
    end
end

function MarketMgr:NpcSetSchedule()
    local data =  GetTableRuntime()
    local npc = data.tbNpc
    for category, info in pairs(data.tbCategoryInfo) do
        local productIdeaCount = GameLogic:MKT_GetProductIdeaCount(category, data.nCurYear, data.nCurSeason)
        if info.nPublishedCount < productIdeaCount then
            npc.tbScheduleToNew[category] = true    --推到下个季度才会检查执行
        end
    end
end

function MarketMgr:LogNpcProducts()
    local data = GetTableRuntime()
    local npc = data.tbNpc
    for category, info in pairs(data.tbCategoryInfo) do
        for id, product in pairs(npc.tbProduct) do
            if product.Category == category then
                print(string.format("Npc product %s%d :", category ,id),
                    string.format("Quality:%.1f", product.nQuality10 / 10),
                    string.format("Arpu:%.1f", product.fLastARPU),
                    "Expense:" .. tostring(math.floor(product.nLastMarketExpense)),
                    string.format("Scale:%d(%+d)", product.nLastMarketScale, product.nLastMarketScaleDelta),                    
                    "Income:" .. tostring(product.nLastMarketIncome))
            end
        end
    end
end

function MarketMgr:PreSeason()
    MarketMgr:AutoSetMarketExpense()    -- 自动设置市场费用
    MarketMgr:NpcCloseLowQuality()      -- 概率关低品质npc产品
    MarketMgr:NpcExecSchedule()         -- Npc执行产品计划
    MarketMgr:NpcSetSchedule()          -- Npc设置产品计划
end

function MarketMgr:PostSeason()
    MarketMgr:LossMarket()              -- 各产品份额自然流失，归入品类内部共享待分配份额
    MarketMgr:CategoryShareTransfer()   -- 品类间份额转移：各品类的待分配份额，取一部分根据品类间的质量差距，在品类间转移
    MarketMgr:DistributionMarket()      -- 各品类内部，根据产品质量情况与市场费用，分配份额
    MarketMgr:GainRevenue()             -- 获得收益
    if tbConfig.bLogNpcProducts then
        MarketMgr:LogNpcProducts()          -- 输出npc产品信息
    end
end

function Market.NewNpcProduct(category, nQuality10)
    local id, product = Production:CreateUserProduct(category, GetTableRuntime().tbNpc)
    product.State = tbConfig.tbProductState.nPublished
    product.bIsNpc = true
    GameLogic:PROD_NewPublished(id, product, false, true)
    product.nOrigQuality10 = nQuality10
    product.nQuality10 = nQuality10
    product.nMarketExpense = math.floor(tbConfig.tbProductCategory[category].nNpcInitialExpenses * (1 + (math.random() - 0.5) * 2 * tbConfig.fNpcExpenseFloatRange))
    return id
end
