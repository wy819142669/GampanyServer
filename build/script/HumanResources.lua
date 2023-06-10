local tbConfig = tbConfig
HumanResources = {}

-- 调薪 {FuncName = "DoOperate", OperateType = "RaiseSalary"}
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
-- 同一个季度，新的招聘计划会替换旧提交的计划
function HumanResources.CommitHire(tbParam)
    local tbRuntimeData = GetTableRuntime()
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    
    if tbRuntimeData.nCurSeason == 2 or tbRuntimeData.nCurSeason == 4 then
        return "只有1、3季度才可以招聘", false
    end

    if tbParam.nExpense < tbParam.nNum * tbConfig.nSalary then
        return "预算费用太低，不能低于人均工资", false
    end

    if tbUser.tbHire then
        tbUser.nCash = tbUser.nCash + tbUser.tbHire.nExpense
        tbUser.nSeverancePackage = tbUser.nSeverancePackage - tbUser.tbHire.nExpense
        tbUser.tbHire = nil
    end
    if tbParam.nExpense > tbUser.nCash then
        return "资金不足", false
    end

    local szReturnMsg
    if tbParam.nExpense > 0 and tbParam.nNum > 0 then
        tbUser.nCash = tbUser.nCash - tbParam.nExpense
        tbUser.nSeverancePackage = tbUser.nSeverancePackage + tbParam.nExpense
        tbUser.tbHire = { nNum = tbParam.nNum, nExpense = tbParam.nExpense }
        szReturnMsg = string.format("招聘投标：%d人，花费：%d", tbParam.nNum, tbParam.nExpense)
    else
        szReturnMsg = "success"
    end
    return szReturnMsg, true
end

-- 解雇 {FuncName = "DoOperate", OperateType = "CommitFire", nLevel = 1, nNum = 2}
-- 传入的nNum表示把欲解雇的人数更新为nNum，而不是再增加解雇nNum人
function HumanResources.CommitFire(tbParam)
    local tbRuntimeData = GetTableRuntime()
    if tbRuntimeData.nCurSeason == 0 then
        return "年初阶段不能解雇员工", false
    end
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbParam.nNum < 0 then
        return "解雇人数不能是"..tbParam.nNum, false
    end
    local total = tbUser.tbIdleManpower[tbParam.nLevel] + tbUser.tbFireManpower[tbParam.nLevel]
    if total < tbParam.nNum then
        return "人数不足", false
    end
    tbUser.tbIdleManpower[tbParam.nLevel] = total - tbParam.nNum
    tbUser.tbFireManpower[tbParam.nLevel] = tbParam.nNum
    local msg
    if tbParam.nNum > 0 then
        msg = string.format("解雇%d位%d级员工，季度末将离开公司", tbParam.nNum, tbParam.nLevel)
    else
        msg = "success"
    end
    return msg, true
end

-- 培训 {FuncName = "DoOperate", OperateType = "CommitTrain", tbTrain = { 2, 1, 1, 0, 0}}
function HumanResources.CommitTrain(tbParam)
    local tbRuntimeData = GetTableRuntime()
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    local result = "success"

    -- 如果有旧的提交记录，则undo
    local nTotalNum = 0
    if tbUser.tbTrainManpower then
        for i = 1, tbConfig.nManpowerMaxExpLevel do
            nTotalNum = nTotalNum + tbUser.tbTrainManpower[i]
        end
        tbUser.nCash = tbUser.nCash + nTotalNum * tbConfig.nSalary
        tbUser.tbTrainManpower = nil
        result = "成功取消培训计划"
    end

    --计算最多允许培训的人员数目
    local tbMax = Lib.copyTab(tbUser.tbIdleManpower)
    for i = 1, tbConfig.nManpowerMaxExpLevel do
        tbMax[i] = tbMax[i] + tbUser.tbFireManpower[i]
        tbMax[i] = tbMax[i] + tbUser.tbJobManpower[i]
        tbMax[i] = math.max(1, math.floor(tbMax[i] * tbConfig.fTrainMaxRatioPerLevel))
    end
    tbMax[tbConfig.nManpowerMaxExpLevel] = 0

    nTotalNum = 0
    for i = 1, tbConfig.nManpowerMaxExpLevel do
        nTotalNum = nTotalNum + tbParam.tbTrain[i]
        if tbParam.tbTrain[i] > tbMax[i] then
            return string.format("%d级员工最多只能培训%d个", i, tbMax[i]), false
        end
    end

    if nTotalNum > 0 then
        local nMaxTotalNum = math.floor(tbUser.nTotalManpower * tbConfig.fTrainMaxRatioTotal)
        if nTotalNum > nMaxTotalNum then
            return string.format("最多只能培训%d人", nMaxTotalNum), false
        end

        local nCost = nTotalNum * tbConfig.nSalary
        if nCost < tbUser.nCash then
            return "没有足够的费用进行培训", false
        end
        tbUser.nCash = tbUser.nCash - nCost
        tbUser.tbTrainManpower = tbParam.tbTrain
        result = "成功设置培训"
    end
    return result, true
end

-- 挖掘人才 {FuncName = "DoOperate", OperateType = "Poach", TargetUser = szName, nLevel = 5, nExpense = 12})
function HumanResources.Poach(tbParam)
    local tbRuntimeData = GetTableRuntime()
    local tbUser = tbRuntimeData.tbUser[tbParam.Account]
    if tbUser.bPoachDone then
        return "本季度已经执行过挖掘", false
    end

    if tbUser.nCash < tbParam.nExpense then
        return "没有足够的资金进行挖人", false
    end

    local tbTargetUser = tbRuntimeData.tbUser[tbParam.TargetUser]
    if not tbTargetUser then
        return "目标公司不存在", false
    end
    if not tbParam.nLevel or tbParam.nLevel < 1 or tbParam.nLevel > tbConfig.nManpowerMaxExpLevel then
        return "需要人才等级无效", false
    end

    if not tbParam.nExpense or tbParam.nExpense < tbConfig.tbPoachExpenseRatio[1] * tbConfig.nSalary then
        return "投入费用无效", false
    end

    local szResult
    local bSuccess = false
    local hasTargetLevelManpower = tbTargetUser.tbIdleManpower[tbParam.nLevel] + tbTargetUser.tbFireManpower[tbParam.nLevel] + tbTargetUser.tbJobManpower[tbParam.nLevel] - tbTargetUser.tbDepartManpower[tbParam.nLevel] > 0

    if not hasTargetLevelManpower then
        szResult = "目标公司并没有你需要的人才"
    else
        local rand = math.random()
        local nSuccessWeight = tbParam.nExpense * tbConfig.nManpowerMaxExpLevel / tbParam.nLevel + tbConfig.nSalary * (1 + (tbUser.nSalaryLevel - 1) * tbConfig.fPoachSalaryLevelRatio) * tbConfig.nPoachSalaryWeight
        local nFailedWeight =  tbConfig.nSalary * (1 + (tbTargetUser.nSalaryLevel - 1) * tbConfig.fPoachSalaryLevelRatio) * tbConfig.nPoachSalaryWeight
        print("poach - success:".. nSuccessWeight, "failed:" .. nFailedWeight, "rand:" .. rand, "sueecss ratio:" .. nSuccessWeight / (nSuccessWeight + nFailedWeight))
        if nSuccessWeight < nFailedWeight then
            szResult = "对方坚决拒绝了你的挖角"
        elseif rand > nSuccessWeight / (nSuccessWeight + nFailedWeight) then
            szResult = "对方犹豫一阵后拒绝了你的挖角"
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
            print("SettleDepart=====", tbUser.szAccount, i, nNum)
            if nNum > 0 then
                local nCount = math.min(nNum, tbUser.tbFireManpower[i])
                nNum = nNum - nCount
                tbUser.tbFireManpower[i] = tbUser.tbFireManpower[i] - nCount

                nCount = math.min(nNum, tbUser.tbIdleManpower[i])
                nNum = nNum - nCount
                tbUser.tbIdleManpower[i] = tbUser.tbIdleManpower[i] - nCount

                for _, tbProductInfo in pairs(tbUser.tbProduct) do
                    nCount = math.min(nNum, tbProductInfo.tbManpower[i])
                    nNum = nNum - nCount
                    tbProductInfo.tbManpower[i] = tbProductInfo.tbManpower[i] - nCount
                    if nNum == 0 then
                        break
                    end
                end
                assert(nNum == 0)
            end
            tbUser.nTotalManpower = tbUser.nTotalManpower - tbUser.tbDepartManpower[i]
            tbUser.tbDepartManpower[i] = 0
        end
        HumanResources.UpdateJobManpower(tbUser)
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

-- 人才市场予以处理各企业的招聘计划
function HumanResources.SettleHire()
    -- tbManpowerInMarket = { 0, 0, 0, 0, 0 } -- 人才市场各等级人数，元素个数需要等于tbConfig.nManpowerMaxExpLevel
    -- tbUser.tbHire = { nNum = tbParam.nNum, nExpense = tbParam.nExpense }
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
                tbNewManpower = {0, 0, 0, 0, 0} --元素个数需要等于tbConfig.nManpowerMaxExpLevel
            })

            nTotalWeight = nTotalWeight + nWeight
            nTotalNeed = nTotalNeed + tbUser.tbHire.nNum
        end
    end

    -- 开始随机发派人才
    local nTopLevel = tbConfig.nManpowerMaxExpLevel
    while nTotalNeed > 0 do
        while nTopLevel > 0 and tbRuntimeData.tbManpowerInMarket[nTopLevel] == 0 do
            nTopLevel = nTopLevel - 1
        end
        if nTopLevel == 0 then
            break
        end

        local nRand = math.random(nTotalWeight)
        for _, tbHireInfo in ipairs(tbUserHireInfo) do
            if tbHireInfo.nNum > 0 then
                if nRand <= tbHireInfo.nWeight then
                    tbRuntimeData.tbManpowerInMarket[nTopLevel] = tbRuntimeData.tbManpowerInMarket[nTopLevel] - 1

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
        for i = 1, tbConfig.nManpowerMaxExpLevel do
            tbUser.tbIdleManpower[i] = tbUser.tbIdleManpower[i] + tbHire.tbNewManpower[i]
            tbUser.nTotalManpower = tbUser.nTotalManpower + tbHire.tbNewManpower[i]
        end
    end

    -- TODO: tbUserHireInfo 里的数据存一下

    -- 清除招聘投标数据
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        tbUser.tbHire = nil
    end
end

function HumanResources.AddNewManpower()
    local tbRuntimeData = GetTableRuntime()
    local nCurSeason = tbRuntimeData.nCurSeason
    if nCurSeason ~= 1 and nCurSeason ~= 3 then
        return  -- 只有第一三季度，人才市场才会增加新人
    end
    print("AddNewManpower", tbRuntimeData.nCurYear, nCurSeason, #tbConfig.tbNewManpowerPerYear)
    if tbRuntimeData.nCurYear <= #tbConfig.tbNewManpowerPerYear then
        local tbNewManpower = tbConfig.tbNewManpowerPerYear[tbRuntimeData.nCurYear]
        for i = 1, tbConfig.nManpowerMaxExpLevel do
            local nNew = tbNewManpower[i]
            if nCurSeason == 1 then
                nNew = math.floor(nNew * tbConfig.fSeason1NewManpowerRatio + 0.5)
            else
                nNew = nNew - math.floor(nNew * tbConfig.fSeason1NewManpowerRatio + 0.5)
            end
            tbRuntimeData.tbManpowerInMarket[i] = tbRuntimeData.tbManpowerInMarket[i] + nNew
        end
    end
end

function HumanResources.SettleFire()
    local tbRuntimeData = GetTableRuntime()
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        for i = 1, tbConfig.nManpowerMaxExpLevel do
            if tbUser.tbFireManpower[i] ~= 0 then
                tbRuntimeData.tbManpowerInMarket[i] = tbRuntimeData.tbManpowerInMarket[i] + tbUser.tbFireManpower[i]
                tbUser.nTotalManpower = tbUser.nTotalManpower - tbUser.tbFireManpower[i]
                tbUser.tbFireManpower[i] = 0
            end
        end
    end
end

function HumanResources.SettleTrain()
    local tbRuntimeData = GetTableRuntime()
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        repeat
            if not tbUser.tbTrainManpower then
                break
            end
            for i = tbConfig.nManpowerMaxExpLevel - 1, 1, -1 do -- 从高到低遍历， 防止某级没有员工了但是设置了培训，会出现某员工连升级2次的情况
                repeat
                    if tbUser.tbTrainManpower[i] == 0 then
                        break
                    end
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
                    --若有多余，那是本季度离职的人
                until true
            end
        until true
        tbUser.tbTrainManpower = nil
    end
end

function HumanResources.UpdateAllUserManpower()
    local tbRuntimeData = GetTableRuntime()
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        HumanResources.UpdateJobManpower(tbUser)
        tbUser.nTotalManpower = 0
        for i = 1, tbConfig.nManpowerMaxExpLevel do
            tbUser.nTotalManpower = tbUser.nTotalManpower + tbUser.tbIdleManpower[i] + tbUser.tbFireManpower[i] + tbUser.tbJobManpower[i]
        end
    end
end

function HumanResources.UpdateJobManpower(tbUser)
    tbUser.tbJobManpower = {0, 0, 0, 0, 0}
    for _, tbProductInfo in pairs(tbUser.tbProduct) do
        for i = 1, #tbUser.tbJobManpower do
            tbUser.tbJobManpower[i] = tbUser.tbJobManpower[i] + tbProductInfo.tbManpower[i]
        end
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
