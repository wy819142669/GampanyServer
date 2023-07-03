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
    --==== 对于新发布的产品(不是翻新项目), 复制已发布产品的数据初始化项 ====
    if not renovate then
        for k, v in pairs(tbInitTables.tbInitPublishedProduct) do
            product[k] = v
        end
    end
    if not GameLogic:PROD_IsPlatform(product) then
        GameLogic:PROD_NewPublished(tbParam.Id, product, renovate)
    end

    Production:Publish(product, user)
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
        if not GameLogic:PROD_IsPlatformC(category) then
            data.tbCategoryInfo[category] = Lib.copyTab(tbInitTables.tbInitCategoryInfo)
            data.tbCategoryInfo[category].nCommunalMarketShare = info.nTotalMarket
            data.tbCategoryInfo[category].nMaxMarketScale = info.nMaxMarketScale
            data.tbCategoryInfo[category].nProductIdeaCount = info.nProductIdeaCount
        end
    end

    --新建npc产品
    Market.tbNpc = { tbProduct = {} }
    for category, info in pairs(data.tbCategoryInfo) do
        for _ = 1, info.nProductIdeaCount do
            Market.NewNpcProduct(category)
        end
    end

    --发布npc的产品
    for id, product in pairs(Market.tbNpc.tbProduct) do
        GameLogic:PROD_NewPublished(id, product, false)
    end
end

function MarketMgr:OnCloseProduct(id, product)
    local info = GetTableRuntime().tbCategoryInfo[product.Category]
    info.tbPublishedProduct[id] = nil
    info.newPublished[id] = nil
    info.nCommunalMarketShare = info.nCommunalMarketShare + product.nLastMarketScale
end

--产品份额的自然流失（受品类流失率及自身质量影响）
function MarketMgr:LossMarket()
    for c, info in pairs(GetTableRuntime().tbCategoryInfo) do
        local fRetentionRate = tbConfig.tbProductCategory[c].fProductRetentionRate
        for id, product in pairs(info.tbPublishedProduct) do
            product.nLastMarketScaleDelta = 0
            if product.nLastMarketScale > 0 then
                local fLossRate = (1.0 - fRetentionRate - 0.001 * product.nQuality10)
                fLossRate = (fLossRate < 0) and 0 or fLossRate
                product.nLastMarketScaleDelta = - math.floor(product.nLastMarketScale * fLossRate)
                info.nCommunalMarketShare = info.nCommunalMarketShare - product.nLastMarketScaleDelta  --各产品流失的份额，流入品类内部共享份额
            end
        end
    end
end

--[[
-- 品类份额转移
function MarketMgr:LossMarketByQuality()
    local tbRuntimeData = GetTableRuntime()
    local tbSortInfos = {}

     --便利计算各品类的市场总规模，产品数，最高质量，质量加总
    for c, ci in pairs(tbRuntimeData.tbCategoryInfo) do
        local info = { category = c, nProductCount = 0, nHighestQuality = 0, nTotalQuality = 0,}
        for id, product in pairs(ci.tbPublishedProduct) do
            info.nProductCount = info.nProductCount + 1
            if info.nHighestQuality < product.nQuality10 then
                info.nHighestQuality = product.nQuality10
            end
            info.nTotalQuality = info.nTotalQuality + product.nQuality10
        end
        table.insert(tbSortInfos, info)
    end

    --对品类信息进行排序
    local SortFunc = function(l,r)
        if l.nTotalQuality * r.nProductCount > r.nTotalQuality * l.nProductCount then
            return true
        elseif l.nTotalQuality * r.nProductCount == r.nTotalQuality * l.nProductCount then
            if l.nProductCount > r.nProductCount then
                return true
            elseif l.nProductCount == r.nProductCount then
                if l.nHighestQuality > r.nHighestQuality then
                    return true
                end
            end
        end
        return false
    end
    table.sort(tbSortInfos, SortFunc)

    local numCategory = #tbSortInfos
    if numCategory <= 1 then
        return
    end

    --计算确定转出的品类
    local nIndex = numCategory
    while nIndex > 1 and not SortFunc(tbSortInfos[nIndex - 1], tbSortInfos[nIndex]) do
        nIndex = nIndex - 1
    end
    local nLossIndex = math.random(nIndex, numCategory)

    --计算确定转入的品类
    nIndex = 1
    while nIndex < numCategory and not SortFunc(tbSortInfos[nIndex], tbSortInfos[nIndex + 1]) do
        nIndex = nIndex + 1
    end
    local nGainIndex = math.random(1, nIndex)
 
    --如果算得的转入转出品类为同一个，做些调整
    if nGainIndex == nLossIndex then
        nGainIndex = nGainIndex + math.random(1, numCategory - 1)
        nGainIndex = (nGainIndex > numCategory) and (nGainIndex - numCategory) or nGainIndex
    end

    --计算全市场规模
    local nMaxMarket      = 0
    for _, info in pairs(tbSortInfos) do
        nMaxMarket = nMaxMarket + tbConfig.tbProductCategory[info.category].nTotalMarket
        --print("info", info.category, info.nScale, info.nTotalQuality/info.nProductCount, info.nProductCount, info.nHighestQuality, info.nTotalQuality)
    end

    local tbLossSortInfo    = tbSortInfos[nLossIndex]
    local tbGainSortInfo    = tbSortInfos[nGainIndex]
    local lossCategory      = tbRuntimeData.tbCategoryInfo[tbLossSortInfo.category]
    local gainCategory      = tbRuntimeData.tbCategoryInfo[tbGainSortInfo.category]

    nMaxMarket = math.floor(nMaxMarket * tbConfig.tbProductCategory[tbGainSortInfo.category].nMaxMarketScale * 0.01)

    local nLossMarket = math.min(math.min(nMaxMarket - gainCategory.nTotalScale, tbConfig.nLossMarket), lossCategory.nCommunalMarketShare)
    if nLossMarket < 0 then
        nLossMarket = 0
    end

    lossCategory.nCommunalMarketShare = lossCategory.nCommunalMarketShare - nLossMarket
    gainCategory.nCommunalMarketShare = gainCategory.nCommunalMarketShare + nLossMarket

    print("LossMarketByQuality: " .. tostring(nLossMarket) .. " " .. tbLossSortInfo.category .. " -> " .. tbGainSortInfo.category)
end
--]]

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
    local nTotalScale = 0   --整个市场的总规模
    local nShareScale = 0   --公共池
    local nTotalWeight = 0  --分配权重总和
    local weights = {}

    for c, info in pairs(data) do
        --累计以计算整个市场的总规模
        nTotalScale = nTotalScale + info.nTotalScale
        --各品类分一些份额到公共池里
        nShareScale = nShareScale + math.floor(info.nCommunalMarketShare * tbConfig.fMarketScaleShare)
        --各品类的再分配权重(以品类的平均产品质量为权重)
        local weight = MarketMgr:GetAverageQuality10(info.tbPublishedProduct)
        weights[c] = weight
        nTotalWeight = nTotalWeight + weight
    end

    --根据权重给各品类分配份额
    for c, info in pairs(data) do
        local delta = math.floor(nShareScale * weights[c] / nTotalWeight)
        local nMaxScale = nTotalScale * info.nMaxMarketScale / 100
        if info.nTotalScale + delta > nMaxScale then
            delta = math.max(0, math.floor(nMaxScale - info.nTotalScale))
        end
        info.nCommunalMarketShare = info.nCommunalMarketShare + delta
--        print("CategoryShareTransfer", c, delta, info.nCommunalMarketShare)
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
                    local weight = product.nMarketExpense * (1.3 ^ ((product.nQuality10  - 10)*0.1) )
                    local new, renovate = GameLogic:PROD_IsNewProduct(category, id)
                    if new then
                        weight = weight * (renovate and tbConfig.fRenovateCoefficient or tbConfig.fNewProductCoefficient)
                    end
                    weights[id] = weight
                    fTotalWeight = fTotalWeight + weight
                end
            end

            --根据权重，给各产品分配市场份额
            if fTotalWeight > 0 then
                for id, weight in pairs(weights) do
                    local delta = math.floor(nTotal * (weight / fTotalWeight))
                    local product = info.tbPublishedProduct[id]
                    product.nLastMarketScaleDelta = product.nLastMarketScaleDelta + delta
                    info.nCommunalMarketShare = info.nCommunalMarketShare - delta
--                    print("DistributionMarket", category, id, delta, product.nMarketExpense, product.nQuality10)
                end
            end
        end

        info.nTotalScale = 0
        for id, product in pairs(info.tbPublishedProduct) do
            --各产品根据当季度的市场规模变化量，计算当季的最后拥有的市场规模
            product.nLastMarketScale = product.nLastMarketScale + product.nLastMarketScaleDelta
--            print("DistributionMarket done", category, id, product.nLastMarketScaleDelta, product.nLastMarketScale)
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
            print(userName .. " Cash += " .. tostring(income))
        end
    end
end

function MarketMgr:SettleMarket()
    MarketMgr:LossMarket()              -- 各产品份额自然流失，归入品类内部共享待分配份额
    MarketMgr:CategoryShareTransfer()   -- 品类间份额转移：各品类的待分配份额，取一部分根据品类间的质量差距，在品类间转移
    --MarketMgr:LossMarketByQuality()   -- 品类份额转移
    MarketMgr:DistributionMarket()      -- 各品类内部，根据产品质量情况与市场费用，分配份额
    MarketMgr:GainRevenue()             -- 获得收益
end

--季度初自动设置市场费用，设置后可被修改
function MarketMgr:AutoSetMarketExpense()
    local data = GetTableRuntime()
    --先自动参照上季度市场费用，重设本季度市场费用
    for _, info in pairs(data.tbCategoryInfo) do
        for _, product in pairs(info.tbPublishedProduct) do
            product.nMarketExpense = product.nLastMarketExpense
        end
    end

    --再按
    for _, user in pairs(data.tbUser) do
        local total = 0
        for _, product in pairs(user.tbProduct) do
            if product.nMarketExpense and product.nMarketExpense > 0 then
                if total + product.nMarketExpense <= user.nCash then
                    total = total + product.nMarketExpense
                else
                    product.nMarketExpense = user.nCash - total
                    total = total + product.nMarketExpense
                end
            end
        end
        GameLogic:FIN_Pay(user, tbConfig.tbFinClassify.Mkt, total)
    end
end

function MarketMgr:UpdateNpc()
    for category, info in pairs(GetTableRuntime().tbCategoryInfo) do
        tbProductList = info.tbPublishedProduct
        local nProductNum = 0
        local nNpcProductNum = 0
        local nTotalQuality = 0
        local nUserMaxQuality = 0
        for id, tbProduct in pairs(tbProductList) do
            nProductNum = nProductNum + 1
            if tbProduct.bIsNpc then
                nNpcProductNum = nNpcProductNum + 1
            else
                if tbProduct.nQuality10 > nUserMaxQuality then
                    nUserMaxQuality = tbProduct.nQuality10
                end
            end

            nTotalQuality = nTotalQuality + tbProduct.nQuality10
        end

        if nProductNum > nNpcProductNum and nProductNum < tbConfig.tbNpc.nMaxProductNum and nNpcProductNum < tbConfig.tbNpc.nMinNpcProductNum then
            local nAvgQuality10 = math.ceil(math.min(nTotalQuality / nProductNum, nUserMaxQuality))
            local product = Market.NewNpcProduct(category, nAvgQuality10)
            print("NewNpcProduct:", product.nID)
            tbProductList[product.nID] = product
        end
    end

    for id, tbProduct in pairs(Market.tbNpc.tbProduct) do
        if Production:IsPublished(tbProduct) and not GameLogic:PROD_IsNewProduct(tbProduct.Category, id) then
            tbProduct.nMarketExpense = tbConfig.tbProductCategory[tbProduct.Category].nNpcContinuousExpenses * (1 + (math.random() - 0.5) * 2 * tbConfig.tbNpc.fExpenseFloatRange)
        end

        --print("Npc id:"..id, "nLastMarketIncome:",tbProduct.nLastMarketIncome, "nMarketExpense:", tbProduct.nMarketExpense, "tbProduct.bNewProduct:", GameLogic:PROD_IsNewProduct(tbProduct.Category, id))
        if not GameLogic:PROD_IsNewProduct(tbProduct.Category, id) and tbProduct.nLastMarketIncome and tbProduct.nLastMarketIncome / tbProduct.nMarketExpense < tbConfig.tbNpc.fCloseWhenGainRatioLess then
            print("Npc id:"..id, "close")
            tbProduct.State = tbConfig.tbProductState.nClosed
            MarketMgr:OnCloseProduct(id, tbProduct)
        end

        tbProduct.nLastMarketIncome = nil
    end
end

function Market.NewNpcProduct(category, nQuality10)
    local id, product = Production:CreateUserProduct(category, Market.tbNpc)
    product.State = tbConfig.tbProductState.nPublished
    product.bIsNpc = true
    product.nID = id

    for k, v in pairs(tbInitTables.tbInitPublishedProduct) do   --复制已发布产品的数据初始化项
        product[k] = v
    end

    product.nLastMarketExpense = math.floor(tbConfig.tbProductCategory[category].nNpcInitialExpenses * (1 + (math.random() - 0.5) * 2 * tbConfig.tbNpc.fExpenseFloatRange))
    product.nQuality10 = nQuality10 or 20

    return product
end
