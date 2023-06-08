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


function Market.SettleMarket()
    local tbRuntimeData = GetTableRuntime()
    -- 份额流失
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

    -- 份额分配
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
                    print("user: " .. tostring(tbInfo.userName) .. " product: " .. tostring(productName) .. "Add Market: " .. tostring(nCost) .. 
                    "TotalMarket: " .. tostring(nTotalMarket) .. "MarketValue: " .. tostring(tbInfo.fMarketValue) .. "TotalMarketValue: " .. tostring(fTotalMarketValue))
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
