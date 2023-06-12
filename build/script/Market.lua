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
    if product.State == tbConfig.tbProductState.nPublished or product.State == tbConfig.tbProductState.nRenovating then
        return "already published", false
    end
    if product.State ~= tbConfig.tbProductState.nEnabled then
        return "progress not enough", false
    end

    --复制已发布产品的数据初始化项
    for k, v in pairs(tbInitTables.tbInitPublishedProduct) do
        product[k] = v
    end
    product.State = tbConfig.tbProductState.nPublished
    local szReturnMsg = string.format("成功发布产品:%s%d", product.Category, tbParam.Id)
    return szReturnMsg, true
end

-- 提交市场竞标 {FuncName="Market", OperateType="CommitMarket", Id=1, Expense=1}
-- 以后可能改成全部产品一起提交
function Market.CommitMarket(tbParam, user)
    local product = nil
    if tbParam.Id then
        product = user.tbProduct[tbParam.Id]
    end
    if not product then
        return "product not exist", false
    end
    if product.State ~= tbConfig.tbProductState.nPublished then
        return "product hasn't been published yet", false
    end
    if tbParam.Expense < 1 then
        return "market expense not enough", false
    end
    product.nMarketExpance = tbParam.Expense
    return "success", true
end

-- 份额流失
function Market.LossMarket()
    --[[todo 越子重构中
    local tbRuntimeData = GetTableRuntime()
    
    for userName, tbUser in pairs(tbRuntimeData.tbUser) do
        for id, tbProduct in pairs(tbUser.tbProduct) do
            local nQuality = tbProduct.nQuality or 0
            local category = tbConfig.tbProductCategory[tbProduct.Category]
            local fLossRate = (1.0 - category.fProductRetentionRate - 0.01 * nQuality)
            if fLossRate < 0 then
                fLossRate = 0
            end

            local nLossMarket = math.floor(tbUser.tbMarket[id] * fLossRate)
            tbUser.tbMarket[id] = tbUser.tbMarket[id] - nLossMarket;
            tbRuntimeData.tbMarket[tbProduct.Category] = tbRuntimeData.tbMarket[tbProduct.Category] + nLossMarket
        end
    end
    --]]
end

-- 品类份额转移
function Market.LossMarketByQuality()
--[[todo 越子重构中
    local tbRuntimeData = GetTableRuntime()
    local tbCurrentTotalMarket = {}
    local tbInfos = {}
    local tbSortInfos = {}

    --math.randomseed(os.time())
    
    for category, _ in pairs(tbConfig.tbProductCategory) do
        tbCurrentTotalMarket[category] = tbRuntimeData.tbMarket[category]

        tbInfos[category] = {
            nHighestQuality = 0,
            nProductCount = 0,
            nTotalQuality = 0,
        }
    end

    for userName, tbUser in pairs(tbRuntimeData.tbUser) do
        for id, nMarket in pairs(tbUser.tbMarket) do
            local product = tbUser.tbProduct[id]
            tbCurrentTotalMarket[product.Category] = tbCurrentTotalMarket[product.Category] + nMarket
            if product and tbUser.tbProduct[productName].progress >= tbConfig.tbProduct[productName].maxProgress then
                local nQuality = tbUser.tbProduct[productName].nQuality or 0
                if tbInfos[productName].nHighestQuality < nQuality then
                    tbInfos[productName].nHighestQuality = nQuality
                end

                tbInfos[productName].nProductCount = tbInfos[productName].nProductCount + 1
                tbInfos[productName].nTotalQuality = tbInfos[productName].nTotalQuality + nQuality
            end
        end
    end

    for productName, tbInfo in pairs(tbInfos) do
        table.insert(tbSortInfos, {
            productName = productName,
            nHighestQuality = tbInfo.nHighestQuality,tbLossSortInfo,
            nProductCount = tbInfo.nProductCount,
            nTotalQuality = tbInfo.nTotalQuality,
        })
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
    local tbGainSortInfo    = tbSortInfos[1]
    local tbLossSortInfo    = tbSortInfos[nLossIndex]

    local nLossMarket = math.min(math.min(tbCurrentTotalMarket[tbLossSortInfo.productName] - tbConfig.tbMarketMinimumLimit[tbLossSortInfo.productName], tbConfig.nLossMarket), tbRuntimeData.tbMarket[tbLossSortInfo.productName])
    if nLossMarket < 0 then
        nLossMarket = 0
    end

    tbRuntimeData.tbMarket[tbLossSortInfo.productName] = tbRuntimeData.tbMarket[tbLossSortInfo.productName] - nLossMarket
    tbRuntimeData.tbMarket[tbGainSortInfo.productName] = tbRuntimeData.tbMarket[tbGainSortInfo.productName] + nLossMarket

    print("LossMarketByQuality LossMarket: " .. tostring(nLossMarket) .. " " .. tbLossSortInfo.productName .. " -> " .. tbGainSortInfo.productName)
    --]]
end

-- 份额分配
function Market.DistributionMarket()
    local tbRuntimeData = GetTableRuntime()
--[[
    for productName, nMarket in pairs(tbRuntimeData.tbMarket) do
        if nMarket > 0 then
            local tbInfos = {}
            local fTotalMarketValue = 0
            for userName, tbUser in pairs(tbRuntimeData.tbUser) do
                local nQuality = 0
                if tbUser.tbProduct[productName] then
                    nQuality = tbUser.tbProduct[productName].nQuality or 0
                end

                if tbUser.bMarketingDone == true and tbUser.tbMarketingExpense[productName] and nQuality > 0 then
                    -- TODO 当季度上线
                    local fMarketValue = tbUser.tbMarketingExpense[productName] * (1.3 ^ (nQuality - 1))
                    fTotalMarketValue = fTotalMarketValue + fMarketValue
                    table.insert(tbInfos, {
                        userName = userName,
                        fMarketValue = fMarketValue,
                    })
                end
            end

            if fTotalMarketValue > 0 then
                local nTotalMarket = tbRuntimeData.tbMarket[productName]
                local nTotalCost = 0
                for _, tbInfo in pairs(tbInfos) do
                    local nCost = math.floor(nTotalMarket * (tbInfo.fMarketValue / fTotalMarketValue))
                    tbRuntimeData.tbUser[tbInfo.userName].tbMarket[productName] = tbRuntimeData.tbUser[tbInfo.userName].tbMarket[productName] + nCost
                    nTotalCost = nTotalCost + nCost
                    print("user: " .. tostring(tbInfo.userName) .. " product: " .. tostring(productName) .. " Add Market: " .. tostring(nCost) .. 
                    " TotalMarket: " .. tostring(nTotalMarket) .. " MarketValue: " .. tostring(tbInfo.fMarketValue) .. " TotalMarketValue: " .. tostring(fTotalMarketValue))
                end

                tbRuntimeData.tbMarket[productName] = tbRuntimeData.tbMarket[productName] - nTotalCost
            end
        end
    end

    -- 清除
    for userName, tbUser in pairs(tbRuntimeData.tbUser) do
        tbUser.bMarketingDone = false
        tbUser.tbMarketingExpense = {}
    end
--]]
end

-- 获得收益
function Market.GainRevenue()
    local tbRuntimeData = GetTableRuntime()
--[[
    for userName, tbUser in pairs(tbRuntimeData.tbUser) do
        for productName, nMarket in pairs(tbUser.tbMarket) do
            if nMarket > 0 and tbUser.tbProduct[productName] and tbUser.tbProduct[productName].progress >= tbConfig.tbProduct[productName].maxProgress then
                local nQuality = tbUser.tbProduct[productName].nQuality or 0
                local nRevenue = nMarket * tbConfig.tbProductARPU[productName] * (0.9 + 0.1 * nQuality)

                tbUser.nCash = tbUser.nCash + nRevenue

                print(userName .. " " .. productName .. " Cash += " .. tostring(nRevenue))
            end
        end
    end
--]]
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
