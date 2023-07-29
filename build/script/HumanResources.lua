local tbConfig = tbConfig

HR = {}             --用于包含响应客户端请求的函数
HumanResources = {} --人力模块的内部函数

-- 调薪 {FuncName = "HR", Operate = "RaiseSalary"}
function HR.RaiseSalary(tbParam, user)
    local tbRuntimeData = GetTableRuntime()
    if user.bStepDone or tbRuntimeData.nCurSeason ~= 0 then
        return "仅在年初可以调薪", false
    end
    user.nSalaryLevel = user.nSalaryLevel + 1
    local szReturnMsg = "薪水标准提升至:" .. GameLogic:HR_GetSalary(user.nSalaryLevel)
    user.bStepDone = true  -- 调薪完自动结束当前步骤
    return szReturnMsg, true
end

-- 招聘 {FuncName = "HR", Operate = "CommitHire", nNum = 20, nExpense = 60}
-- 同一个季度，新的招聘计划会替换旧提交的计划
function HR.CommitHire(tbParam, user)
    local tbRuntimeData = GetTableRuntime()
    if tbRuntimeData.nCurSeason == 2 or tbRuntimeData.nCurSeason == 4 then
        return "只有1、3季度才可以招聘", false
    end

    if tbParam.nExpense < tbParam.nNum * tbConfig.nSalary then
        return "预算费用太低，不能低于工资", false
    end

    if user.tbHire then
        GameLogic:FIN_Unpay(user, tbConfig.tbFinClassify.HR, user.tbHire.nExpense)
        user.tbHire = nil
    end
    if tbParam.nExpense > user.nCash then
        return "没有足够的资金进行招聘", false
    end

    local szReturnMsg
    if tbParam.nExpense > 0 and tbParam.nNum > 0 then
        GameLogic:FIN_Pay(user, tbConfig.tbFinClassify.HR, tbParam.nExpense)
        user.tbHire = { nNum = tbParam.nNum, nExpense = tbParam.nExpense }
        szReturnMsg = string.format("招聘投标：%d人，花费：%d", tbParam.nNum, tbParam.nExpense)
    else
        szReturnMsg = "success"
    end
    return szReturnMsg, true
end

-- 解雇 {FuncName = "HR", Operate = "CommitFire", tbFire= {0, 0, 0, 0, 0}}
-- 传入的nNum表示把欲解雇的人数更新为nNum，而不是再增加解雇nNum人
function HR.CommitFire(tbParam, user)
    local tbRuntimeData = GetTableRuntime()
    if tbRuntimeData.nCurSeason == 0 then
        return "年初阶段不能解雇员工", false
    end
    local tbFire = tbParam.tbFire
    local finalCount = 0
    for i = 1, tbConfig.nManpowerMaxExpLevel do
        if tbFire == nil or tbFire[i] < 0 then
            return "解雇人数参数错误", false
        end
        local total = user.tbIdleManpower[i] + user.tbFireManpower[i]
        if total < tbFire[i] then
            return "人数不足够解雇", false
        end
        user.tbIdleManpower[i] = total - tbFire[i]
        user.tbFireManpower[i] = tbFire[i]
        finalCount = finalCount + tbFire[i]
    end
    local msg
    if finalCount > 0 then
        msg = string.format("被解雇的%d位员工，将于季度末离开", finalCount)
    else
        msg = "success"
    end
    return msg, true
end

-- 培训 {FuncName = "HR", Operate = "CommitTrain", tbTrain = { 2, 1, 1, 0, 0}}
function HR.CommitTrain(tbParam, user)
    local result = "success"

    -- 最高级别员工若设置培训人数会被直接忽略
    tbParam.tbTrain[tbConfig.nManpowerMaxExpLevel] = 0

    -- 如果有旧的提交记录，则undo
    local nTotalNum = 0
    if user.tbTrainManpower then   --user.tbTrainManpower存储时还是存五级，当最高级处理时被忽略
        for i = 1, tbConfig.nManpowerMaxExpLevel - 1 do
            nTotalNum = nTotalNum + user.tbTrainManpower[i]
        end
        GameLogic:FIN_Unpay(user, tbConfig.tbFinClassify.HR, nTotalNum * tbConfig.nSalary)
        user.tbTrainManpower = nil
        result = "成功取消培训计划"
    end

    --计算最多允许培训的人员数目
    local tbMax = Lib.copyTab(user.tbIdleManpower)
    for i = 1, tbConfig.nManpowerMaxExpLevel - 1 do
        tbMax[i] = tbMax[i] + user.tbFireManpower[i] + user.tbJobManpower[i]
        tbMax[i] = math.floor(tbMax[i] * tbConfig.fTrainMaxRatioPerLevel)
    end
    tbMax[tbConfig.nManpowerMaxExpLevel] = 0

    nTotalNum = 0
    for i = 1, tbConfig.nManpowerMaxExpLevel - 1 do
        nTotalNum = nTotalNum + tbParam.tbTrain[i]
        if tbParam.tbTrain[i] > tbMax[i] or tbParam.tbTrain[i] < 0 then
            return string.format("%d级员工最多只能培训%d个", i, tbMax[i]), false
        end
    end

    if nTotalNum > 0 then
        local nMaxTotalNum = math.floor(user.nTotalManpower * tbConfig.fTrainMaxRatioTotal)
        if nTotalNum > nMaxTotalNum then
            return string.format("最多只能培训%d人", nMaxTotalNum), false
        end
        if GameLogic:FIN_Pay(user, tbConfig.tbFinClassify.HR, nTotalNum * tbConfig.nSalary) then
            user.tbTrainManpower = tbParam.tbTrain  --user.tbTrainManpower存储时还是存五级，当最高级处理时被忽略
            result = "成功设置培训"
        else
            return "没有足够的费用进行培训", false
        end       
    end
    return result, true
end

-- 挖掘人才 {FuncName = "HR", Operate = "Poach", TargetUser = szName, nLevel = 5, nExpense = 12})
function HR.Poach(tbParam, user)
    local tbRuntimeData = GetTableRuntime()
    if user.tbPoach then
        return "本季度已经执行过挖掘", false
    end

    if user.nCash < tbParam.nExpense then
        return "没有足够的资金进行挖人", false
    end

    local tbTargetUser = tbRuntimeData.tbUser[tbParam.TargetUser]
    if not tbTargetUser then
        return "目标公司不存在", false
    end
    local lvl = tbParam.nLevel
    if not lvl or lvl < 1 or lvl > tbConfig.nManpowerMaxExpLevel then
        return "需要人才等级无效", false
    end

    if not tbParam.nExpense or tbParam.nExpense < tbConfig.tbPoachExpenseRatio[1] * tbConfig.nSalary then
        return "投入费用无效", false
    end

    local szResult
    local bSuccess = false
    local preDepartCount = tbTargetUser.tbDepartManpower and tbTargetUser.tbDepartManpower[lvl] or 0
    if tbTargetUser.tbIdleManpower[lvl] + tbTargetUser.tbFireManpower[lvl] + tbTargetUser.tbJobManpower[lvl] <= preDepartCount then
        szResult = "目标公司并没有你需要的人才"
    else
        local rand = math.random()
        local nSuccessWeight = tbParam.nExpense * tbConfig.nManpowerMaxExpLevel / lvl + tbConfig.nSalary * (1 + (user.nSalaryLevel - 1) * tbConfig.fPoachSalaryLevelRatio) * tbConfig.nPoachSalaryWeight
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
        if tbTargetUser.tbDepartManpower and tbTargetUser.tbDepartManpower[lvl] then
            tbTargetUser.tbDepartManpower[lvl] = tbTargetUser.tbDepartManpower[lvl] + 1
        else
            tbTargetUser.tbDepartManpower = tbTargetUser.tbDepartManpower or {}
            tbTargetUser.tbDepartManpower[lvl] = 1
        end
        table.insert(tbTargetUser.tbTips, string.format("你的一个%d级员工提交了离职申请，将在下个季度初离开公司。", lvl))
    else
        nCost = math.floor(tbParam.nExpense * (1 - tbConfig.fPoachFailedReturnExpenseRatio))
        nCost = math.max(nCost, 1)
    end

    GameLogic:FIN_Pay(user, tbConfig.tbFinClassify.HR, nCost)
    user.tbPoach = {
        TargetUser = tbParam.TargetUser,
        nLevel = lvl,
        nExpense = nCost,   --记录实际开销
        szResult = szResult,
        bSuccess = bSuccess
    }
    return szResult, true
end

-- 调配调动人员 {FuncName = "HR", Operate = "Reassign", tbReassign = { [ProductId] = {0,0,0,0,0} }} {0,0,0,0,0}中的数值表示目标人数，而不是变动人数
function HR.Reassign(tbParam, user)
    if tbParam.tbReassign == nil then
        return "调配调动人员参数有误", false
    end

    for id, _ in pairs(tbParam.tbReassign) do
        local product = user.tbProduct[id]
        if product == nil then
            return "未找到产品：" .. tbParam.ProductId, false
        end
    end

    for id, _ in pairs(tbParam.tbReassign) do
        local product = user.tbProduct[id]
        for i = 1, tbConfig.nManpowerMaxExpLevel do
            user.tbIdleManpower[i] = user.tbIdleManpower[i] + product.tbManpower[i]
            product.tbManpower[i] = 0
        end
    end

    for id, reassign in pairs(tbParam.tbReassign) do
        local product = user.tbProduct[id]
        for i = 1, tbConfig.nManpowerMaxExpLevel do
            if user.tbIdleManpower[i] >= reassign[i] then
                user.tbIdleManpower[i] = user.tbIdleManpower[i] - reassign[i]
                product.tbManpower[i] = reassign[i]
            end
        end
    end
    HumanResources:UpdateJobManpower(user)
    return "success", true
end

function HumanResources:SettleDepart()
    local tbRuntimeData = GetTableRuntime()
    for _, user in pairs(tbRuntimeData.tbUser) do
        if user.tbDepartManpower then
            for i = 1, tbConfig.nManpowerMaxExpLevel do -- #user.tbDepartManpower
                if user.tbDepartManpower[i] then
                    local nNum = user.tbDepartManpower[i]
                    if nNum > 0 then
                        local nCount = math.min(nNum, user.tbFireManpower[i])
                        if nCount > 0 then
                            nNum = nNum - nCount
                            user.tbFireManpower[i] = user.tbFireManpower[i] - nCount
                            table.insert(user.tbSysMsg, string.format("公司的即将解雇员工中%d名%d级员工辞职离开了公司", nCount, i))
                        end

                        nCount = math.min(nNum, user.tbIdleManpower[i])
                        if nCount > 0 then
                            nNum = nNum - nCount
                            user.tbIdleManpower[i] = user.tbIdleManpower[i] - nCount
                            table.insert(user.tbSysMsg, string.format("公司的待岗员工中%d名%d级员工辞职离开了公司", nCount, i))
                        end

                        for id, product in pairs(user.tbProduct) do
                            nCount = math.min(nNum, product.tbManpower[i])
                            if nCount > 0 then
                                nNum = nNum - nCount
                                product.tbManpower[i] = product.tbManpower[i] - nCount
                                local info = string.format("公司的%s%d项目的员工中%d名%d级员工辞职离开了公司", product.Category, id, nCount, i)
                                table.insert(user.tbSysMsg, info)
                            end
                            if nNum == 0 then
                                break
                            end
                        end
                        assert(nNum == 0)
                    end
                    user.nTotalManpower = user.nTotalManpower - user.tbDepartManpower[i]
                    user.tbDepartManpower[i] = 0
                end
            end
            HumanResources:UpdateJobManpower(user)
        end
    end
end

function HumanResources:SettlePoach()
    local tbRuntimeData = GetTableRuntime()
    for _, user in pairs(tbRuntimeData.tbUser) do
        if user.tbPoach and user.tbPoach.bSuccess then
            user.tbIdleManpower[user.tbPoach.nLevel] = user.tbIdleManpower[user.tbPoach.nLevel] + 1
            user.nTotalManpower = user.nTotalManpower + 1
            table.insert(user.tbSysMsg, string.format("被挖掘来的1名%d级员工已经入职，处于待岗状态", user.tbPoach.nLevel))
        end
        user.tbPoach = nil
    end
end

-- 人才市场予以处理各企业的招聘计划
function HumanResources:SettleHire()
    -- tbManpowerInMarket = { 0, 0, 0, 0, 0 } -- 人才市场各等级人数，元素个数需要等于tbConfig.nManpowerMaxExpLevel
    -- tbUser.tbHire = { nNum = tbParam.nNum, nExpense = tbParam.nExpense }
    local tbRuntimeData = GetTableRuntime()

    -- 计算权重
    local tbUserHireInfo = {}
    local nTotalWeight = 0
    local nTotalNeed = 0
    for userName, user in pairs(tbRuntimeData.tbUser) do
        if user.tbHire and user.tbHire.nNum and user.tbHire.nNum  > 0 then
            local nWeight = math.floor(user.tbHire.nExpense / user.tbHire.nNum * (1 + (user.nSalaryLevel - 1) * tbConfig.fHireWeightRatioPerLevel) * 1000 + 0.5)
            table.insert(tbUserHireInfo, {
                userName = userName,
                nNum = user.tbHire.nNum,
                nWeight = nWeight,
                tbNewManpower = {0, 0, 0, 0, 0} --元素个数需要等于tbConfig.nManpowerMaxExpLevel
            })

            nTotalWeight = nTotalWeight + nWeight
            nTotalNeed = nTotalNeed + user.tbHire.nNum
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
        local user = tbRuntimeData.tbUser[tbHire.userName]
        local tbNewManpowerInfo = {}
        local nSumLevel = 0
        local nCount = 0
        for i = 1, tbConfig.nManpowerMaxExpLevel do
            if tbHire.tbNewManpower[i] > 0 then
                user.tbIdleManpower[i] = user.tbIdleManpower[i] + tbHire.tbNewManpower[i]
                user.nTotalManpower = user.nTotalManpower + tbHire.tbNewManpower[i]
                nCount = nCount + tbHire.tbNewManpower[i]
                nSumLevel = nSumLevel + tbHire.tbNewManpower[i] * i
                table.insert(tbNewManpowerInfo, string.format("%d名%d级员工", tbHire.tbNewManpower[i], i))
            end
        end

        local szMsg = "人才市场招聘结果：当前薪水%d级,计划招聘%d人,花费费用%d,实际招募到%s人%s,新入职员工平均等级%.2f"
        table.insert(user.tbSysMsg, string.format(szMsg, user.nSalaryLevel, user.tbHire.nNum, user.tbHire.nExpense,
            nCount, #tbNewManpowerInfo > 0 and "," .. table.concat(tbNewManpowerInfo, "、")  or "", nSumLevel / nCount
        ))
    end

    -- TODO: tbUserHireInfo 里的数据存一下

    -- 清除招聘投标数据
    for _, user in pairs(tbRuntimeData.tbUser) do
        user.tbHire = nil
    end
end

function HumanResources:AddNewManpower()
    local tbRuntimeData = GetTableRuntime()
    local nCurSeason = tbRuntimeData.nCurSeason
    if nCurSeason ~= 1 and nCurSeason ~= 3 then
        return  -- 只有第一三季度，人才市场才会增加新人
    end
    if tbRuntimeData.nCurYear <= #tbConfig.tbNewManpowerPerYear then
        local tbNewManpower = tbConfig.tbNewManpowerPerYear[tbRuntimeData.nCurYear]
        for i = 1, tbConfig.nManpowerMaxExpLevel do
            local nNew = math.floor(tbNewManpower[i] * tbRuntimeData.nGamerCount / tbConfig.nStandardPlayerCount + 0.5)
            if nCurSeason == 1 then
                nNew = math.floor(nNew * tbConfig.fSeason1NewManpowerRatio + 0.5)
            else
                nNew = nNew - math.floor(nNew * tbConfig.fSeason1NewManpowerRatio + 0.5)
            end
            tbRuntimeData.tbManpowerInMarket[i] = tbRuntimeData.tbManpowerInMarket[i] + nNew
        end
    end
end

function HumanResources:SettleFire()
    local tbRuntimeData = GetTableRuntime()
    for _, user in pairs(tbRuntimeData.tbUser) do
        for i = 1, tbConfig.nManpowerMaxExpLevel do
            if user.tbFireManpower[i] > 0 then
                tbRuntimeData.tbManpowerInMarket[i] = tbRuntimeData.tbManpowerInMarket[i] + user.tbFireManpower[i]
                user.nTotalManpower = user.nTotalManpower - user.tbFireManpower[i]

                table.insert(user.tbSysMsg, string.format("%d名%d级员工已被解雇离开公司", user.tbFireManpower[i], i))
                user.tbFireManpower[i] = 0
            end
        end
    end
end

function HumanResources:SettleTrain()
    local tbRuntimeData = GetTableRuntime()
    for name, user in pairs(tbRuntimeData.tbUser) do
        if user.tbTrainManpower then
            for i = tbConfig.nManpowerMaxExpLevel - 1, 1, -1 do -- 从高到低遍历， 防止某级没有员工了但是设置了培训，会出现某员工连升级2次的情况
                if user.tbTrainManpower[i] > 0 then
                    for id, product in pairs(user.tbProduct) do -- TODO：改成按照产品优先级排序
                        if product.tbManpower[i] > 0 and user.tbTrainManpower[i] > 0 then
                            local nLevelUpCount = math.min(product.tbManpower[i], user.tbTrainManpower[i])
                            if nLevelUpCount > 0 then
                                user.tbTrainManpower[i] = user.tbTrainManpower[i] - nLevelUpCount
                                product.tbManpower[i] = product.tbManpower[i] - nLevelUpCount
                                product.tbManpower[i + 1] = product.tbManpower[i + 1] + nLevelUpCount
                                table.insert(user.tbSysMsg, string.format("%s项目的%d名%d级员工晋升到%d级", product.szName, nLevelUpCount, i, i + 1))
                            end
                        end
                    end
                    if user.tbTrainManpower[i] > 0 then
                        local nLevelUpCount = math.min(user.tbIdleManpower[i], user.tbTrainManpower[i])
                        if nLevelUpCount > 0 then
                            user.tbTrainManpower[i] = user.tbTrainManpower[i] - nLevelUpCount
                            user.tbIdleManpower[i] = user.tbIdleManpower[i] - nLevelUpCount
                            user.tbIdleManpower[i + 1] = user.tbIdleManpower[i + 1] + nLevelUpCount
                            table.insert(user.tbSysMsg, string.format("待岗的%d名%d级员工晋升到%d级", nLevelUpCount, i, i + 1))
                        end
                    end
                    --若有多余，那是本季度离职的人
                end
            end
            HumanResources:UpdateJobManpower(user)
        end
        user.tbTrainManpower = nil
    end
end

function HumanResources:UpdateAllUserManpower()
    local tbRuntimeData = GetTableRuntime()
    for _, user in pairs(tbRuntimeData.tbUser) do
        HumanResources:UpdateJobManpower(user)
        user.nTotalManpower = 0
        for i = 1, tbConfig.nManpowerMaxExpLevel do
            user.nTotalManpower = user.nTotalManpower + user.tbIdleManpower[i] + user.tbFireManpower[i] + user.tbJobManpower[i]
        end
    end
end

function HumanResources:GetManByPositon(user)
    local dev = 0
    local pub = 0
    for _, product in pairs(user.tbProduct) do
        local num = 0
        for i = 1, tbConfig.nManpowerMaxExpLevel do
            num = num + product.tbManpower[i]
        end
        if GameLogic:PROD_IsInMarket(product) then
            pub = pub + num
        else
            dev = dev + num
        end
    end
    return dev, pub, (user.nTotalManpower - dev - pub)
end

function HumanResources:UpdateJobManpower(user)
    user.tbJobManpower = {0, 0, 0, 0, 0}
    for _, product in pairs(user.tbProduct) do
        for i = 1, tbConfig.nManpowerMaxExpLevel do
            user.tbJobManpower[i] = user.tbJobManpower[i] + product.tbManpower[i]
        end
    end
end

function HumanResources:RecordProductManpower()
    local tbRuntimeData = GetTableRuntime()
    for _, user in pairs(tbRuntimeData.tbUser) do
        for _, product in pairs(user.tbProduct) do
            product.tbOriginalManpower = Lib.copyTab(product.tbManpower)
        end
        for _, product in pairs(user.tbClosedProduct) do
            product.tbOriginalManpower = Lib.copyTab(product.tbManpower)
        end
    end
end

function HumanResources:SalaryByPosition(user, amount)
    local dev, pub, idle = HumanResources:GetManByPositon(user)
    local total = user.nTotalManpower
    return (amount * dev / total), (amount * pub / total), (amount * idle / total)
end

function HumanResources:PayOffSalary()
    local tbRuntimeData = GetTableRuntime()
    for _, user in pairs(tbRuntimeData.tbUser) do
        local nCost = user.nTotalManpower * GameLogic:HR_GetSalary(user.nSalaryLevel)
        nCost = math.floor(nCost + 0.5)
        if nCost > 0 then
            if GameLogic:FIN_Pay(user, nil, nCost) then
                table.insert(user.tbSysMsg, string.format("支付薪水：%d", nCost))
                -- 分类记账
                local dev, pub, idle = HumanResources:SalaryByPosition(user, nCost)
                GameLogic:FIN_ModifyReport(user.tbYearReport, tbConfig.tbFinClassify.Salary_Dev, dev)
                GameLogic:FIN_ModifyReport(user.tbYearReport, tbConfig.tbFinClassify.Salary_Pub, pub)
                GameLogic:FIN_ModifyReport(user.tbYearReport, tbConfig.tbFinClassify.HR, idle)
            else
                if not user.bBankruptcy then
                    GameLogic:Bankruptcy(user)
                end
            end
        end
    end
end

-- 统计所有正常经营玩家的人力
function HumanResources:UpdateTotalManpower()
    local data = GetTableRuntime()
    data.tbTotalManpower = {0, 0, 0, 0, 0}
    data.nTotalManpower = 0
    for _, user in pairs(data.tbUser) do
        if not user.bBankruptcy then
            for i = 1, tbConfig.nManpowerMaxExpLevel do
                local total = user.tbIdleManpower[i] + user.tbJobManpower[i] + user.tbFireManpower[i]
                data.tbTotalManpower[i] = data.tbTotalManpower[i] + total
                data.nTotalManpower = data.nTotalManpower + total
            end
        end
    end
end
