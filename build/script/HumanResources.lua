local tbConfig = tbConfig
HumanResources = {}

-- RaiseSalary 调薪 {FuncName = "DoOperate", OperateType = "RaiseSalary"}
function HumanResources.RaiseSalary(tbParam)
    local tbRuntimeData = GetTableRuntime()
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bStepDone or tbRuntimeData.nCurSeason ~= 0 then
        return "该步骤已结束", false
    end
    tbUser.nSalaryLevel = tbUser.nSalaryLevel + 1
    local szReturnMsg = string.format("薪水等级提升至%d级", tbUser.nSalaryLevel)
    return szReturnMsg, true
end

-- 招聘 {FuncName = "DoOperate", OperateType = "CommitHire", nNum = 20, nExpense = 60}
function HumanResources.CommitHire(tbParam)
    local tbRuntimeData = GetTableRuntime()
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bManpowerMarketDone then
        return "已经设置过招聘计划", false
    end
    
    if tbRuntimeData.nCurSeason == 2 or tbRuntimeData.nCurSeason == 4 then
        return "只有1、3季度才可以招聘", false
    end

    if tbParam.nNum == 0 then
        return "招聘人数至少1人", false
    end

    if tbParam.nExpense > tbUser.nCash then
        return "资金不足", false
    end

    tbUser.nCash = tbUser.nCash - tbParam.nExpense
    tbUser.nSeverancePackage = tbUser.nSeverancePackage + tbParam.nExpense
    tbUser.tbHire = { nNum = tbParam.nNum, nExpense = tbParam.nExpense }

    tbUser.bManpowerMarketDone = true
    local szReturnMsg = string.format("招聘投标：%d人，花费：%d", tbParam.nNum, tbParam.nExpense)
    return szReturnMsg, true
end

-- 解雇 {FuncName = "DoOperate", OperateType = "CommitFire", nLevel = 1, nNum = 2}
function HumanResources.CommitFire(tbParam)
    local tbRuntimeData = GetTableRuntime()
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]

    if tbParam.nNum < 0 then
        return "解雇人数不能是"..tbParam.nNum, false
    end

    if tbUser.tbIdleManpower[tbParam.nLevel] < tbParam.nNum then
        return "人数不足", false
    end

    tbUser.tbFireManpower[tbParam.nLevel] = tbUser.tbFireManpower[tbParam.nLevel] + tbParam.nNum
    tbUser.tbIdleManpower[tbParam.nLevel] = tbUser.tbIdleManpower[tbParam.nLevel] - tbParam.nNum
    return string.format("成功解雇%d人,季度末将离开公司", tbParam.nNum), true
end

-- 培训 {FuncName = "DoOperate", OperateType = "CommitTrain", tbTrain = { 2, 1, 1, 0, 0}}
function HumanResources.CommitTrain(tbParam)
    local tbRuntimeData = GetTableRuntime()
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bCommitTrainDone then
        return "本季度已经设置过培训计划", false
    end

    local tbMax = Lib.copyTab(tbUser.tbIdleManpower)
    for i = 1, 5 do
        tbMax[i] = tbMax[i] + tbUser.tbFireManpower[i]
    end
    for _, tbProductInfo in pairs(tbUser.tbProduct) do
        for i = 1, 5 do
            tbMax[i] = tbMax[i] + tbProductInfo.tbManpower[i]
        end
    end

    for i = 1, 5 do
        tbMax[i] = math.max(1, math.floor(tbMax[i] * tbConfig.fTrainMaxRatioPerLevel))
    end

    tbMax[5] = 0

    local nTotalNum = 0
    for i = 1, 5 do
        nTotalNum = nTotalNum + tbParam.tbTrain[i]
        if tbParam.tbTrain[i] > tbMax[i] then
            return string.format("%d级员工最多只能培训%d个", i, tbMax[i]), false
        end
    end

    local nMaxTotalNum = math.floor(tbUser.nTotalManpower * tbConfig.fTrainMaxRatioTotal)
    if nTotalNum > nMaxTotalNum then
        return string.format("最多只能培训%d人", nMaxTotalNum), false
    end

    local nCost = nTotalNum * tbConfig.nSalary

    tbUser.nCash = tbUser.nCash - nCost
    tbUser.tbTrainManpower = tbParam.tbTrain
    tbUser.bCommitTrainDone = true
    return "成功设置培训", true
end

-- 挖掘人才 {FuncName = "DoOperate", OperateType = "Poach", TargetUser = szName, nLevel = 5, nExpense = 12})
function HumanResources.Poach(tbParam)
    local tbRuntimeData = GetTableRuntime()
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bPoachDone then
        return "本季度已经执行过挖掘", false
    end

    local tbTargetUser = tbRuntimeData.tbUser[tbParam.TargetUser]
    if not tbTargetUser then
        return "目标公司不存在", false
    end

    if not tbParam.nLevel or tbParam.nLevel < 1 then
        return "需要人才等级无效", false
    end

    if not tbParam.nExpense or tbParam.nExpense < tbConfig.tbPoachExpenseRatio[1] * tbConfig.nSalary then
        return "投入费用无效", false
    end

    local szResult
    local bSuccess = false
    local hasTargetLevelManpower = (tbTargetUser.tbIdleManpower[tbParam.nLevel] ~= 0)
    if not hasTargetLevelManpower then
        for _, tbProductInfo in pairs(tbTargetUser.tbProduct) do
            if tbProductInfo.tbManpower[tbParam.nLevel] ~= 0 then
                hasTargetLevelManpower = true
                break
            end
        end
    end

    if not hasTargetLevelManpower then
        szResult = "目标公司并没有你需要的人才"
    else
        local rand = math.random()
        local nSuccessWeight = tbParam.nExpense * 5 / tbParam.nLevel + tbConfig.nSalary * (1 + (tbUser.nSalaryLevel - 1) * tbConfig.fPoachSalaryLevelRatio) * tbConfig.nPoachSalaryWeight
        local nFailedWeight =  tbConfig.nSalary * (1 + (tbTargetUser.nSalaryLevel - 1) * tbConfig.fPoachSalaryLevelRatio) * tbConfig.nPoachSalaryWeight
        print("poach - success:", nSuccessWeight, "failed:", nFailedWeight, "rand:", rand, "sueecss ratio:", nSuccessWeight / (nSuccessWeight + nFailedWeight))
        if nSuccessWeight < nFailedWeight then
            szResult = "对于你提出的方案，对方坚决拒绝"
        elseif rand > nSuccessWeight / (nSuccessWeight + nFailedWeight) then
            szResult = "对于你提出的方案，对方犹豫了好一会儿"
        else
            szResult = "对方同意加入你"
            bSuccess = true
        end
    end

    local nCost
    if bSuccess then
        nCost = tbParam.nExpense
        tbTargetUser.tbDepartManpower[tbParam.nLevel] = tbTargetUser.tbDepartManpower[tbParam.nLevel] + 1
    else
        nCost = math.floor(tbParam.nExpense * (1 - tbConfig.fPoachFailedReturnExpenseRatio))
    end

    tbUser.nCash = tbUser.nCash - nCost
    tbUser.tbPoach = {
        TargetUser = tbParam.TargetUser,
        nLevel = tbParam.nLevel,
        nExpense = tbParam.nExpense,
        szResult = szResult,
        bSuccess = bSuccess
    }
    tbUser.bPoachDone = true
    return szResult, true
end

function HumanResources.SettleDepart()
    local tbRuntimeData = GetTableRuntime()
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        for i = 1, #tbUser.tbDepartManpower do
            local nNum = tbUser.tbDepartManpower[i]

            if nNum > 0 then
                for _, tbProductInfo in pairs(tbUser.tbProduct) do
                    local nCount = math.min(nNum, tbProductInfo.tbManpower[i])
                    nNum = nNum - nCount
                    tbProductInfo.tbManpower[i] = tbProductInfo.tbManpower[i] - nCount

                    if nNum == 0 then
                        break
                    end
                end

                local nCount = math.min(nNum, tbUser.tbIdleManpower[i])
                nNum = nNum - nCount
                tbUser.tbIdleManpower[i] = tbUser.tbIdleManpower[i] - nCount

                nCount = math.min(nNum, tbUser.tbFireManpower[i])
                nNum = nNum - nCount
                tbUser.tbFireManpower[i] = tbUser.tbFireManpower[i] - nCount

                assert(nNum == 0)
            end
            tbUser.nTotalManpower = tbUser.nTotalManpower - tbUser.tbDepartManpower[i]
            tbUser.tbDepartManpower[i] = 0
        end
    end
end

function HumanResources.SettlePoach()
    local tbRuntimeData = GetTableRuntime()
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        if tbUser.tbPoach and tbUser.tbPoach.bSuccess then
            tbUser.tbIdleManpower[tbUser.tbPoach.nLevel] = tbUser.tbIdleManpower[tbUser.tbPoach.nLevel] + 1
            tbUser.nTotalManpower = tbUser.nTotalManpower + 1
        end

        tbUser.tbPoach = nil
        tbUser.bPoachDone = false
    end
end

function HumanResources.SettleHire()
    --[[
    tbManpower = { -- 人才市场各等级人数
        0, 0, 0, 0, 0
    },
    tbNewManpowerPerYear = {  -- 每年人才市场各等级新进人数
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
    fSeason1NewManpowerRatio = 0.3,  -- 一季度新进人数占全年人数比例， 剩下的三季度新进

    tbUser.tbHire = { nNum = tbParam.nNum, nExpense = tbParam.nExpense }
    ]]

    local tbRuntimeData = GetTableRuntime()

    -- 计算权重
    local tbUserHireInfo = {}
    local nTotalWeight = 0
    local nTotalNeed = 0
    for userName, tbUser in pairs(tbRuntimeData.tbUser) do
        if tbUser.tbHire and tbUser.tbHire.nNum and tbUser.tbHire.nNum  > 0 then
            local nWeight = math.floor(tbUser.tbHire.nExpense / tbUser.tbHire.nNum * (1 + (tbUser.nSalaryLevel - 1) * tbConfig.fHireWeightRatioPerLevel) * 1000 + 0.5)
            table.insert(tbUserHireInfo, {
                userName = userName,
                nNum = tbUser.tbHire.nNum,
                nWeight = nWeight,
                tbNewManpower = {0, 0, 0, 0, 0}
            })

            nTotalWeight = nTotalWeight + nWeight
            nTotalNeed = nTotalNeed + tbUser.tbHire.nNum
        end
    end

    -- 开始随机发派人才
    local nTopLevel = #tbRuntimeData.tbManpower
    while nTotalNeed > 0 do
        while nTopLevel > 0 and tbRuntimeData.tbManpower[nTopLevel] == 0 do
            nTopLevel = nTopLevel - 1
        end

        if nTopLevel == 0 then
            break
        end

        local nRand = math.random(nTotalWeight)
        for _, tbHireInfo in ipairs(tbUserHireInfo) do
            if tbHireInfo.nNum > 0 then
                if nRand <= tbHireInfo.nWeight then
                    tbRuntimeData.tbManpower[nTopLevel] = tbRuntimeData.tbManpower[nTopLevel] - 1

                    tbHireInfo.nNum = tbHireInfo.nNum - 1
                    tbHireInfo.tbNewManpower[nTopLevel] = tbHireInfo.tbNewManpower[nTopLevel] + 1

                    nTotalNeed = nTotalNeed - 1
                    if tbHireInfo.nNum == 0 then
                        nTotalWeight = nTotalWeight - tbHireInfo.nWeight
                    end
                    break
                else
                    nRand = nRand - tbHireInfo.nWeight
                end
            end
        end
    end

    -- 竞标结果更新到人力
    for _, tbHire in ipairs(tbUserHireInfo) do
        local tbUser = tbRuntimeData.tbUser[tbHire.userName]
        for i = 1, #tbUser.tbIdleManpower do
            tbUser.tbIdleManpower[i] = tbUser.tbIdleManpower[i] + tbHire.tbNewManpower[i]
            tbUser.nTotalManpower = tbUser.nTotalManpower + tbHire.tbNewManpower[i]
        end
    end

    -- TODO: tbUserHireInfo 里的数据存一下

    -- 清除招聘投标数据
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        tbUser.tbHire = { nNum = 0 , nExpense = 0}
        tbUser.bManpowerMarketDone = false
    end
end

function HumanResources.AddNewManpower()
    local tbRuntimeData = GetTableRuntime()
    print("AddNewManpower", tbRuntimeData.nCurSeason, tbRuntimeData.nCurYear, #tbConfig.tbNewManpowerPerYear)
    local nCurSeason = tbRuntimeData.nCurSeason
    if tbRuntimeData.nCurYear <= #tbConfig.tbNewManpowerPerYear then
        local tbNewManpower = tbConfig.tbNewManpowerPerYear[tbRuntimeData.nCurYear]
        for i = 1, #tbRuntimeData.tbManpower do
            local nNew = 0
            if nCurSeason == 1 then
                nNew = math.floor(tbNewManpower[i] * tbConfig.fSeason1NewManpowerRatio + 0.5)
            elseif nCurSeason == 3 then
                nNew = tbNewManpower[i] - math.floor(tbNewManpower[i] * tbConfig.fSeason1NewManpowerRatio + 0.5)
            end

            tbRuntimeData.tbManpower[i] = tbRuntimeData.tbManpower[i] + nNew
        end
    end
end

function HumanResources.SettleFire()
    local tbRuntimeData = GetTableRuntime()
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        for i = 1, #tbUser.tbFireManpower do
            if tbUser.tbFireManpower[i] ~= 0 then
                tbRuntimeData.tbManpower[i] = tbRuntimeData.tbManpower[i] + tbUser.tbFireManpower[i]
                tbUser.nTotalManpower = tbUser.nTotalManpower - tbUser.tbFireManpower[i]
                tbUser.tbFireManpower[i] = 0
            end
        end
    end
end

function HumanResources.SettleTrain()
    local tbRuntimeData = GetTableRuntime()
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        for i = 5 - 1, 1, -1 do -- 从高到低遍历， 防止某级没有员工了但是设置了培训，会出现某员工连升级2次的情况
            for _, tbProduct in pairs(tbUser.tbProduct) do -- TODO：改成按照产品优先级排序
                if tbProduct.tbManpower[i] > 0 then
                    local nLevelUpCount = math.min(tbProduct.tbManpower[i], tbUser.tbTrainManpower[i])

                    tbUser.tbTrainManpower[i] = tbUser.tbTrainManpower[i] - nLevelUpCount
                    tbProduct.tbManpower[i] = tbProduct.tbManpower[i] - nLevelUpCount
                    tbProduct.tbManpower[i + 1] = tbProduct.tbManpower[i + 1] + nLevelUpCount
                end
            end

            local nLevelUpCount = math.min(tbUser.tbIdleManpower[i], tbUser.tbTrainManpower[i])
            tbUser.tbTrainManpower[i] = tbUser.tbTrainManpower[i] - nLevelUpCount
            tbUser.tbIdleManpower[i] = tbUser.tbIdleManpower[i] - nLevelUpCount
            tbUser.tbIdleManpower[i + 1] = tbUser.tbIdleManpower[i + 1] + nLevelUpCount
        end

        tbUser.bCommitTrainDone = false
    end
end

function HumanResources.PayOffSalary()
    local tbRuntimeData = GetTableRuntime()
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        local nCost = tbUser.nTotalManpower * tbConfig.nSalary * (1 + (tbUser.nSalaryLevel - 1) * tbConfig.fSalaryRatioPerLevel)
        nCost = math.floor(nCost + 0.5)

        tbUser.nCash = tbUser.nCash - nCost  -- 先允许负数， 让游戏继续跑下去
        tbUser.tbLaborCost[tbRuntimeData.nCurSeason] = nCost
    end
end
