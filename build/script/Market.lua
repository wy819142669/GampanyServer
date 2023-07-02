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
    for category, product in pairs(tbConfig.tbProductCategory) do
        if not GameLogic:PROD_IsPlatformC(category) then
            data.tbCategoryInfo[category] = Lib.copyTab(tbInitTables.tbInitCategoryInfo)
            data.tbCategoryInfo[category].nCommunalMarketShare = product.nTotalMarket; --todo : remove this line
        end
    end

    --新建npc产品
    Market.tbNpc = { tbProduct = {} }
    for category, _ in pairs(data.tbCategoryInfo) do
        for _ = 1, tbConfig.tbNpc.nInitialProductNum do
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
                local fLossRate = (1.0 - fRetentionRate - 0.01 * product.nQuality)
                fLossRate = (fLossRate < 0) and 0 or fLossRate
                product.nLastMarketScaleDelta = - math.floor(product.nLastMarketScale * fLossRate)
                info.nCommunalMarketShare = info.nCommunalMarketShare - product.nLastMarketScaleDelta  --各产品流失的份额，流入品类内部共享份额
            end
        end
    end
    --[[
                if tbUser.tbSysMsg then
                    table.insert(tbUser.tbSysMsg, string.format("产品%s 流失用户 %d", tbProduct.szName, nLossMarket))
                end
    ]]
end

-- 品类份额转移
function MarketMgr:LossMarketByQuality()
    local tbRuntimeData = GetTableRuntime()
    local tbSortInfos = {}

     --便利计算各品类的市场总规模，产品数，最高质量，质量加总
    for c, ci in pairs(tbRuntimeData.tbCategoryInfo) do
        local info = { category = c, nProductCount = 0, nHighestQuality = 0, nTotalQuality = 0,}
        for id, product in pairs(ci.tbPublishedProduct) do
            info.nProductCount = info.nProductCount + 1
            if info.nHighestQuality < product.nQuality then
                info.nHighestQuality = product.nQuality
            end
            info.nTotalQuality = info.nTotalQuality + product.nQuality            
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

-- 份额分配
function MarketMgr:DistributionMarket()
    local tbRuntimeData = GetTableRuntime()

    for category, info in pairs(tbRuntimeData.tbCategoryInfo) do
        local nMarket = info.nCommunalMarketShare
        if nMarket > 0 then
            local tbInfos = {}
            local fTotalMarketValue = 0
            for userName, tbUser in pairs(tbRuntimeData.tbUser) do
                for id, product in pairs(tbUser.tbProduct) do
                    local nQuality = product.nQuality or 0

                    if Production:IsPublished(product) and product.Category == category and product.nMarketExpense > 0 and nQuality > 0 then
                        
                        local fMarketValue = product.nMarketExpense * (1.3 ^ (nQuality - 1))
                        if GameLogic:PROD_IsNewProduct(category, id) then
                            fMarketValue = fMarketValue * tbConfig.tbProductCategory[category].nNewProductCoefficient
                        end

                        fTotalMarketValue = fTotalMarketValue + fMarketValue
                        table.insert(tbInfos, {
                            userName = userName,
                            id = id,
                            name = product.szName,
                            fMarketValue = fMarketValue,
                        })
                    end
                end
            end

            for id, product in pairs(Market.tbNpc.tbProduct) do
                local nQuality = product.nQuality or 0
                if Production:IsPublished(product) and product.Category == category and product.nMarketExpense > 0 and nQuality > 0 then
                    
                    local fMarketValue = product.nMarketExpense * (1.3 ^ (nQuality - 1))
                    if GameLogic:PROD_IsNewProduct(category, id) then
                        fMarketValue = fMarketValue * tbConfig.tbProductCategory[category].nNewProductCoefficient
                    end

                    fTotalMarketValue = fTotalMarketValue + fMarketValue
                    table.insert(tbInfos, {
                        userName = tbConfig.tbNpc.szName,
                        id = id,
                        name = product.szName,
                        fMarketValue = fMarketValue,
                    })
                end
            end

            if fTotalMarketValue > 0 then
                local nTotalMarket = nMarket
                local nTotalCost = 0
                for _, tbInfo in pairs(tbInfos) do
                    local nCost = math.floor(nTotalMarket * (tbInfo.fMarketValue / fTotalMarketValue))
                    local tbUser = tbRuntimeData.tbUser[tbInfo.userName] or Market.tbNpc

                    tbUser.tbProduct[tbInfo.id].nLastMarketScaleDelta = tbUser.tbProduct[tbInfo.id].nLastMarketScaleDelta + nCost
                    tbUser.tbProduct[tbInfo.id].nLastMarketScale = tbUser.tbProduct[tbInfo.id].nLastMarketScale + tbUser.tbProduct[tbInfo.id].nLastMarketScaleDelta

                    if tbUser.tbSysMsg then
                        table.insert(tbUser.tbSysMsg, string.format("产品%s 新获得用户 %d", tbInfo.name, nCost))
                    end
                    nTotalCost = nTotalCost + nCost
                    print("user: " .. tostring(tbInfo.userName) .. " productid: " .. tostring(tbInfo.id) .. " Add Market: " .. tostring(nCost))
                end

                tbRuntimeData.tbCategoryInfo[category].nCommunalMarketShare = tbRuntimeData.tbCategoryInfo[category].nCommunalMarketShare - nTotalCost
            end
        end
    end

    --把当次的费用记录到最后一次记录上，及统计品类总市场规模
    for _, info in pairs(tbRuntimeData.tbCategoryInfo) do
        info.nTotalScale = 0
        for _, product in pairs(info.tbPublishedProduct) do
            info.nTotalScale = info.nTotalScale + product.nLastMarketScale
            product.nLastMarketExpense = product.nMarketExpense
            product.nMarketExpense = 0
        end
    end

    --计算各产品的市场占比
    for _, info in pairs(tbRuntimeData.tbCategoryInfo) do
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
            GameLogic:FIN_Revenue(user, tbConfig.tbFinClassify.Revenue, income)
            table.insert(user.tbSysMsg, string.format("产品共获得收益 %d", income))
            print(userName .. " Cash += " .. tostring(income))
        end
    end
end

function MarketMgr:SettleMarket()

    -- 份额流失
    MarketMgr:LossMarket()

    -- 品类份额转移
    MarketMgr:LossMarketByQuality()

    -- 份额分配
    MarketMgr:DistributionMarket()

    -- 获得收益 
    MarketMgr:GainRevenue()
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
                if tbProduct.nQuality > nUserMaxQuality then
                    nUserMaxQuality = tbProduct.nQuality
                end
            end

            nTotalQuality = nTotalQuality + tbProduct.nQuality
        end

        if nProductNum > nNpcProductNum and nProductNum < tbConfig.tbNpc.nMaxProductNum and nNpcProductNum < tbConfig.tbNpc.nMinNpcProductNum then
            local nAvgQuality = math.ceil(math.min(nTotalQuality / nProductNum, nUserMaxQuality))
            local product = Market.NewNpcProduct(category, nAvgQuality)
            print("NewNpcProduct:", product.nID)
            tbProductList[product.nID] = product
        end
    end

    for id, tbProduct in pairs(Market.tbNpc.tbProduct) do
        if Production:IsPublished(tbProduct) and not GameLogic:PROD_IsNewProduct(tbProduct.Category, id) then
            tbProduct.nMarketExpense = tbConfig.tbProductCategory[tbProduct.Category].nNpcContinuousExpenses * (1 + (math.random() - 0.5) * 2 * tbConfig.tbNpc.fExpenseFloatRange)
        end

        print("Npc id:"..id, "nLastMarketIncome:",tbProduct.nLastMarketIncome, "nMarketExpense:", tbProduct.nMarketExpense, "tbProduct.bNewProduct:", GameLogic:PROD_IsNewProduct(tbProduct.Category, id))
        if not GameLogic:PROD_IsNewProduct(tbProduct.Category, id) and tbProduct.nLastMarketIncome and tbProduct.nLastMarketIncome / tbProduct.nMarketExpense < tbConfig.tbNpc.fCloseWhenGainRatioLess then
            print("Npc id:"..id, "close")
            tbProduct.State = tbConfig.tbProductState.nClosed
            MarketMgr:OnCloseProduct(id, tbProduct)
        end

        tbProduct.nLastMarketIncome = nil
    end
end

function Market.NewNpcProduct(category, nQuality)
    local id, product = Production:CreateUserProduct(category, Market.tbNpc)
    product.State = tbConfig.tbProductState.nPublished
    product.bIsNpc = true
    product.nID = id

    for k, v in pairs(tbInitTables.tbInitPublishedProduct) do   --复制已发布产品的数据初始化项
        product[k] = v
    end

    product.nMarketExpense = tbConfig.tbProductCategory[category].nNpcInitialExpenses * (1 + (math.random() - 0.5) * 2 * tbConfig.tbNpc.fExpenseFloatRange)
    product.nQuality = nQuality or 2

    return product
end
