local tbConfig = tbConfig

Market = {}     --用于包含响应客户端请求的函数
MarketMgr = {}  --市场模块的内部函数

-- 产品上线发布 {FuncName="Market", Operate="Publish", Id=1 }
function Market.Publish(tbParam, user)
    local product = nil
    if tbParam.Id then
        product = user.tbProduct[tbParam.Id]
    end
    if not product then
        return "product not exist", false
    end
    if product.State == tbConfig.tbProductState.nPublished then
        return "already published", false
    elseif product.State == tbConfig.tbProductState.nRenovating and not Production:IsRenovateComplete(product) then
        return "renovate not completed", false
    elseif product.State ~= tbConfig.tbProductState.nEnabled then
        return "progress not enough", false
    end

    --复制已发布产品的数据初始化项
    for k, v in pairs(tbInitTables.tbInitPublishedProduct) do
        product[k] = v
    end

    Production:Publish(product)
    tbPublishedProduct[product.Category][tbParam.Id] = product
    
    local szReturnMsg = string.format("成功发布产品:%s%d", product.Category, tbParam.Id)
    return szReturnMsg, true
end

-- 提交市场营销费用 {FuncName="Market", Operate="Marketing", Product={{Id=1, Expense=10},{Id=5, Expense=40}}}
-- Product中数组元素说明：Id=产品id，Expense=当季市场营销费用
function Market.Marketing(tbParam, user)
    print("Marketing")
    local nTotalExpense = 0
    for _, tbProduct in pairs(tbParam.Product) do
        product = user.tbProduct[tbProduct.Id]

        if not product then
            return "product not exist", false
        end

        if product.State ~= tbConfig.tbProductState.nPublished then
            return "product hasn't been published yet", false
        end

        if tbProduct.Expense < 1 then
            return "market expense error", false
        end

        nTotalExpense = nTotalExpense + tbProduct.Expense
    end 

    if user.nCash < nTotalExpense then
        return "cash not enough", false
    end
    
    user.nCash = user.nCash - nTotalExpense

    for _, tbProduct in pairs(tbParam.Product) do
        user.tbProduct[tbProduct.Id].nMarketExpance = tbProduct.Expense
    end
    
    return "success", true
end


function MarketMgr:DoStart()
    local tbRuntimeData = GetTableRuntime()
    
    tbRuntimeData.tbMarket = {}
    tbPublishedProduct = { }
    for category, product in pairs(tbConfig.tbProductCategory) do
        tbPublishedProduct[category] = {}
        if IsPlatformCategory(category) == false then
            tbRuntimeData.tbMarket[category] = product.nTotalMarket;
        end
    end
end

function MarketMgr:OnCloseProduct(id, product)
    tbPublishedProduct[product.Category][id] = nil
end

-- 份额流失
function Market.LossMarket()
    local tbRuntimeData = GetTableRuntime()
    
    for userName, tbUser in pairs(tbRuntimeData.tbUser) do
        for id, tbProduct in pairs(tbUser.tbProduct) do
            local nQuality = tbProduct.nQuality or 0
            local category = tbConfig.tbProductCategory[tbProduct.Category]
            local fLossRate = (1.0 - category.fProductRetentionRate - 0.01 * nQuality)
            if fLossRate < 0 then
                fLossRate = 0
            end
            
            local nLossMarket = math.floor(tbProduct.nMarket * fLossRate)
            tbProduct.nMarket = tbProduct.nMarket - nLossMarket;
            tbRuntimeData.tbMarket[tbProduct.Category] = tbRuntimeData.tbMarket[tbProduct.Category] + nLossMarket
        end
    end
end

-- 品类份额转移
function Market.LossMarketByQuality()
    local tbRuntimeData = GetTableRuntime()
    local tbCurrentTotalMarket = {}
    local tbInfos = {}
    local tbSortInfos = {}

    --math.randomseed(os.time())
    
    for category, _ in pairs(tbConfig.tbProductCategory) do
        if IsPlatformCategory(category) == false then
            tbCurrentTotalMarket[category] = tbRuntimeData.tbMarket[category]

            tbInfos[category] = {
                nHighestQuality = 0,
                nProductCount = 0,
                nTotalQuality = 0,
            }
        end
    end

    for userName, tbUser in pairs(tbRuntimeData.tbUser) do
        for id, product in pairs(tbUser.tbProduct) do
            if IsPlatformCategory(product.Category) == false then
                tbCurrentTotalMarket[product.Category] = tbCurrentTotalMarket[product.Category] + product.nMarket
                if product.State == tbConfig.tbProductState.nPublished then
                    local nQuality = product.nQuality or 0
                    if tbInfos[product.Category].nHighestQuality < nQuality then
                        tbInfos[product.Category].nHighestQuality = nQuality
                    end

                    tbInfos[product.Category].nProductCount = tbInfos[product.Category].nProductCount + 1
                    tbInfos[product.Category].nTotalQuality = tbInfos[product.Category].nTotalQuality + nQuality
                end
            end
        end
    end

    for category, tbInfo in pairs(tbInfos) do
        table.insert(tbSortInfos, {
            category = category,
            nHighestQuality = tbInfo.nHighestQuality,tbLossSortInfo,
            nProductCount = tbInfo.nProductCount,
            nTotalQuality = tbInfo.nTotalQuality,
        })
    end

    if #tbSortInfos <= 1 then
        return
    end

    table.sort(tbSortInfos, function(l,r)
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
    end)

    local nIndex = #tbSortInfos
    for i = #tbSortInfos - 1, 1, -1 do
        if tbSortInfos[i].nTotalQuality * tbSortInfos[i + 1].nProductCount > tbSortInfos[i + 1].nTotalQuality * tbSortInfos[i].nProductCount then
            break
        end

        if tbSortInfos[i].nProductCount > tbSortInfos[i + 1].nProductCount then
            break
        end

        if tbSortInfos[i].nHighestQuality > tbSortInfos[i + 1].nHighestQuality then
            break
        end

        nIndex = i
    end

    local nLossIndex        = math.random(nIndex, #tbSortInfos)
    local tbLossSortInfo    = tbSortInfos[nLossIndex]

    nIndex = 1
    for i = 2, #tbSortInfos do
        if tbSortInfos[i - 1].nTotalQuality * tbSortInfos[i].nProductCount > tbSortInfos[i].nTotalQuality * tbSortInfos[i - 1].nProductCount then
            break
        end

        if tbSortInfos[i - 1].nProductCount > tbSortInfos[i].nProductCount then
            break
        end

        if tbSortInfos[i - 1].nHighestQuality > tbSortInfos[i].nHighestQuality then
            break
        end

        nIndex = i
    end

    local nGainIndex        = math.random(1, nIndex)
    if nGainIndex == nLossIndex then
        if nGainIndex > 1 then
            nGainIndex = nGainIndex - 1
        else
            nGainIndex = nGainIndex + 1
        end
    end

    local tbGainSortInfo    = tbSortInfos[nGainIndex]
    local nMaxMarket      = 0

    for Category, ProductCategory in pairs(tbConfig.tbProductCategory) do
        if IsPlatformCategory(Category) == false then
            nMaxMarket = nMaxMarket + ProductCategory.nTotalMarket
        end
    end

    nMaxMarket = math.floor(nMaxMarket * tbConfig.tbProductCategory[tbGainSortInfo.category].nMaxMarketScale * 0.01)

    local nLossMarket = math.min(math.min(nMaxMarket - tbCurrentTotalMarket[tbGainSortInfo.category], tbConfig.nLossMarket), tbRuntimeData.tbMarket[tbLossSortInfo.category])
    if nLossMarket < 0 then
        nLossMarket = 0
    end

    tbRuntimeData.tbMarket[tbLossSortInfo.category] = tbRuntimeData.tbMarket[tbLossSortInfo.category] - nLossMarket
    tbRuntimeData.tbMarket[tbGainSortInfo.category] = tbRuntimeData.tbMarket[tbGainSortInfo.category] + nLossMarket

    print("LossMarketByQuality LossMarket: " .. tostring(nLossMarket) .. " " .. tbLossSortInfo.category .. " -> " .. tbGainSortInfo.category)
end

-- 份额分配
function Market.DistributionMarket()
    local tbRuntimeData = GetTableRuntime()

    for category, nMarket in pairs(tbRuntimeData.tbMarket) do
        if nMarket > 0 then
            local tbInfos = {}
            local fTotalMarketValue = 0
            for userName, tbUser in pairs(tbRuntimeData.tbUser) do
                for id, product in pairs(tbUser.tbProduct) do
                    local nQuality = product.nQuality or 0

                    if product.Category == category and product.nMarketExpance > 0 and nQuality > 0 then
                        -- TODO 当季度上线
                        local fMarketValue = product.nMarketExpance * (1.3 ^ (nQuality - 1))
                        fTotalMarketValue = fTotalMarketValue + fMarketValue
                        table.insert(tbInfos, {
                            userName = userName,
                            id = id,
                            fMarketValue = fMarketValue,
                        })
                    end
                end
            end

            if fTotalMarketValue > 0 then
                local nTotalMarket = nMarket
                local nTotalCost = 0
                for _, tbInfo in pairs(tbInfos) do
                    local nCost = math.floor(nTotalMarket * (tbInfo.fMarketValue / fTotalMarketValue))
                    tbRuntimeData.tbUser[tbInfo.userName].tbProduct[tbInfo.id].nMarket = tbRuntimeData.tbUser[tbInfo.userName].tbProduct[tbInfo.id].nMarket + nCost
                    nTotalCost = nTotalCost + nCost
                    print("user: " .. tostring(tbInfo.userName) .. " productid: " .. tostring(tbInfo.id) .. " Add Market: " .. tostring(nCost))
                end

                tbRuntimeData.tbMarket[category] = tbRuntimeData.tbMarket[category] - nTotalCost
            end
        end
    end

    -- 清除
    for userName, tbUser in pairs(tbRuntimeData.tbUser) do
        for id, product in pairs(tbUser.tbProduct) do
            product.nMarketExpance = 0
        end
    end
end

-- 获得收益
function Market.GainRevenue()
    local tbRuntimeData = GetTableRuntime()

    for userName, tbUser in pairs(tbRuntimeData.tbUser) do
        for id, product in pairs(tbUser.tbProduct) do
            if product.nMarket > 0 and product.State == tbConfig.tbProductState.nPublished then
                local nQuality = product.nQuality or 0
                local nRevenue = math.floor(product.nMarket * tbConfig.tbProductCategory[product.Category].nBaseARPU * (0.9 + 0.1 * nQuality))

                tbUser.nCash = tbUser.nCash + nRevenue

                print(userName .. " " .. tostring(id) .. " Cash += " .. tostring(nRevenue))
            end
        end
    end
end

function Market.SettleMarket()

    -- 份额流失
    Market.LossMarket()

    -- 品类份额转移
    Market.LossMarketByQuality()

    -- 份额分配
    Market.DistributionMarket()

    -- 获得收益 
    Market.GainRevenue()
end
