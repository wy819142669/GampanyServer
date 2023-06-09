local tbConfig = tbConfig
Market = {}

-- 提交市场竞标 {FuncName = "DoOperate", OperateType = "CommitMarket", tbMarketingExpense = {a = 1, b = 2, c = 1}}
function Market.CommitMarket(tbParam)
    local tbRuntimeData = GetTableRuntime()
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bMarketingDone then
        return "已经设置过市场竞标计划", false
    end

    local nTotalCost = 0
    for productName, nMarketingExpense in pairs(tbParam.tbMarketingExpense) do
        if not tbUser.tbProduct[productName] or tbUser.tbProduct[productName].progress ~= tbConfig.tbProduct[productName].maxProgress then
            return "研发进度需要完成", false
        end

        nTotalCost = nTotalCost + nMarketingExpense;
    end

    if nTotalCost ~= 0 and nTotalCost > tbUser.nCash then
        return "资金不足", false
    end
    
    tbUser.nCash = tbUser.nCash - nTotalCost
    tbUser.tbMarketingExpense = tbParam.tbMarketingExpense

    tbUser.bMarketingDone = true
    local szReturnMsg = string.format("市场竞标:花费：%d", nTotalCost)
    return szReturnMsg, true
end

-- 份额流失
function Market.LossMarket()
    local tbRuntimeData = GetTableRuntime()
    
    for userName, tbUser in pairs(tbRuntimeData.tbUser) do
        for productName, tbProduct in pairs(tbUser.tbProduct) do
            local nQuality = tbProduct.nQuality or 0
            local fLossRate = (1.0 - tbConfig.tbProductRetentionRate[productName] - 0.01 * nQuality)
            if fLossRate < 0 then
                fLossRate = 0
            end

            local nLossMarket = math.floor(tbUser.tbMarket[productName] * fLossRate)
            tbUser.tbMarket[productName] = tbUser.tbMarket[productName] - nLossMarket;
            tbRuntimeData.tbMarket[productName] = tbRuntimeData.tbMarket[productName] + nLossMarket
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
    
    for _, productName in pairs(tbConfig.tbProductSort) do
        tbCurrentTotalMarket[productName] = tbRuntimeData.tbMarket[productName]

        tbInfos[productName] = {
            nHighestQuality = 0,
            nProductCount = 0,
            nTotalQuality = 0,
        }
    end

    for userName, tbUser in pairs(tbRuntimeData.tbUser) do
        for productName, nMarket in pairs(tbUser.tbMarket) do
            tbCurrentTotalMarket[productName] = tbCurrentTotalMarket[productName] + nMarket
            if tbUser.tbProduct[productName] and tbUser.tbProduct[productName].progress >= tbConfig.tbProduct[productName].maxProgress then
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

end

-- 份额分配
function Market.DistributionMarket()
    local tbRuntimeData = GetTableRuntime()

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
end

-- 获得收益
function Market.GainRevenue()
    local tbRuntimeData = GetTableRuntime()

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
