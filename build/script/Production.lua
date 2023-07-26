local tbProductState = tbConfig.tbProductState

Develop = {}       --用于包含响应客户端请求的函数
Production = {}    --研发模块的内部函数

-- 立项 {FuncName = "Develop", Operate = "NewProduct", Category="A" }
function Develop.NewProduct(tbParam, user)
    if user.bBankruptcy then
        return "破产状态无法立项", false
    end
    
    if tbParam.Category == nil then
        return "立项需要指明品类", false
    end
    Production:CreateUserProduct(tbParam.Category, user)
    return "success", true
end

function Production:CreateUserProduct(category, user)
    local product = Lib.copyTab(tbInitTables.tbInitNewProduct)
    local categoryConfig = tbConfig.tbProductCategory[category]
    local id = Production:NewProductId()
    product.Id = id
    product.nNeedWorkLoad = categoryConfig.nWorkLoad
    product.Category = category
    product.szName = category .. tostring(id)
    user.tbProduct[id] = product
    return id, product
end

function Production:Close(product, user)
    --该产品在岗人员全部回到空闲状态
    for i = 1, tbConfig.nManpowerMaxExpLevel do
        user.tbJobManpower[i] = user.tbJobManpower[i] - product.tbManpower[i]
        user.tbIdleManpower[i] = user.tbIdleManpower[i] + product.tbManpower[i]
        product.tbManpower[i] = 0
    end

    if GameLogic:PROD_IsInMarket(product) then
        GameLogic:OnCloseProduct(product.Id, product, false)
    end

    product.State = tbProductState.nClosed
    user.tbClosedProduct[product.Id] = product
    user.tbProduct[product.Id] = nil
end

-- 关闭产品 {FuncName = "Develop", Operate = "CloseProduct", Id=1 }
function Develop.CloseProduct(tbParam, user)
    local product = tbParam.Id and user.tbProduct[tbParam.Id] or nil
    if product == nil then
        return "未找到欲关闭的产品：" .. tbParam.Id, false
    end

    Production:Close(product, user)

    return "success", true
end

-- 开始翻新产品 {FuncName = "Develop", Operate = "Renovate", Id=1 }
function Develop.Renovate(tbParam, user)
    local product = nil
    if tbParam.Id then
        product = user.tbProduct[tbParam.Id]
    end
    if product == nil then
        return "未找到欲翻新的产品：" .. tbParam.Id, false
    end

    if product.State == tbProductState.nRenovating or product.State == tbProductState.nRenovateDone then
        return "success", true
    elseif product.State ~= tbProductState.nPublished then
        return "未发布的产品不能翻新：" .. tbParam.Id, false
    end

    local categoryConfig = tbConfig.tbProductCategory[product.Category]

    product.State = tbProductState.nRenovating
    product.nNeedWorkLoad = categoryConfig.nRenovationWorkload
    product.nFinishedWorkLoad = 0
    product.nFinishedQuality = 0
    return "success", true
end

function Production:Reset()
    local data = GetTableRuntime()
    data.nNewProductId = 0
end

function Production:NewProductId()
    local data = GetTableRuntime()
    data.nNewProductId = data.nNewProductId + 1
    return data.nNewProductId
end

-- 此函数用来控制季度结算时遍历产品的顺序，为了避免出现一个季度产品对质量加成不一致的问题, 对于中台产品要统一结算时机
-- 当前是方式是优先处理中台，这样后续遍历的产品就会被中台的质量分所影响
function Production:GetProductLoopSequence(tbProductList)
    local tbResult = {}
    for _, tbProduct in pairs(tbProductList) do
        if GameLogic:PROD_IsPlatformP(tbProduct) or GameLogic:PROD_IsPlatformPQ(tbProduct) then
            -- 优先处理
            table.insert(tbResult, 1, tbProduct)
        else
            table.insert(tbResult, tbProduct)
        end
    end

    return tbResult
end

function Production:PostSeason()
    local tbRuntimeData = GetTableRuntime()
    for _, user in pairs(tbRuntimeData.tbUser) do
        for _, product in pairs(self:GetProductLoopSequence(user.tbProduct)) do
            -- 研发/翻新中都需要执行UpdateWorkload函数
            if GameLogic:PROD_IsDeveloping(product) then
                Production:UpdateWorkload(product, user)
            end
            -- 发布后都需要团队维持质量
            if GameLogic:PROD_IsPublished(product) then
                Production:UpdatePublished(product, user)
            end
        end
    end
end

-- 首次发布和翻新发布都通过此函数设置品质与状态
function Production:Publish(product, user)
    --在Market.Publish中已对产品状态做过检查，此处略过
    --product.State == tbConfig.tbProductState.nEnabled or product.State == tbConfig.tbProductState.nRenovateDone
    local quality = math.floor(product.nFinishedQuality / product.nFinishedWorkLoad * 10)
    quality = math.min(quality, tbConfig.nManpowerMaxExpLevel * 10)
    product.nFinishedQuality = 0
    product.State = tbProductState.nPublished
    return quality
end

function Production:GetTeamScaleQuality(product)
    local totalMan = 0
    local totalQuality = 0
    for i = 1, tbConfig.nManpowerMaxExpLevel do
        totalMan = totalMan + product.tbManpower[i]
        totalQuality = totalQuality + product.tbManpower[i] * i
    end
    return totalMan, totalQuality
end

function Production:GetDevelopingQuality(product, user)
    local category = tbConfig.tbProductCategory[product.Category]
    local bInRenovate = product.State == tbConfig.tbProductState.nRenovating or product.State == tbConfig.tbProductState.nRenovateDone
    local nMinTeam = bInRenovate and category.nRenovateMinTeam or category.nMinTeam
    local nIdeaTeam = bInRenovate and category.nRenovateIdeaTeam or category.nIdeaTeam
    local totalMan, totalQuality = Production:GetTeamScaleQuality(product)

    if totalMan < nMinTeam then
        totalMan = totalMan * tbConfig.fSmallTeamRatio
        totalQuality = totalQuality * tbConfig.fSmallTeamRatio
    elseif totalMan > nIdeaTeam then
        local exceed = totalMan - nIdeaTeam
        totalMan = nIdeaTeam + exceed * tbConfig.fBigTeamRatio
        --团队超出理想规模时，优先保留级别高员工贡献的质量
        for i = 1, tbConfig.nManpowerMaxExpLevel do
            if product.tbManpower[i] > 0 then
                local num = math.min(exceed, product.tbManpower[i])
                totalQuality = totalQuality - num * i * (1 - tbConfig.fBigTeamRatio)
                exceed = exceed - num
                if exceed == 0 then
                    break
                end
            end
        end
    end

    totalQuality = totalQuality * tbConfig.fQualityPerManpowerLevel

    -- 非中台部门要计算中台加成
    if not GameLogic:PROD_IsPlatformP(product) and not GameLogic:PROD_IsPlatformPQ(product) then
        local fManPowerRate, fQualityRate = self:GetPlatformEffect(user)
        totalQuality, totalMan = totalQuality * fQualityRate, totalMan * fManPowerRate
    end

    -- 四舍五入
    return math.floor(totalQuality + 0.5), math.floor(totalMan + 0.5)
end

function Production:UpdateWorkload(product, user)
    local totalQuality, totalMan = self:GetDevelopingQuality(product, user)
    product.nFinishedWorkLoad = product.nFinishedWorkLoad + totalMan
    product.nFinishedQuality = product.nFinishedQuality + totalQuality

    if product.nFinishedWorkLoad < product.nNeedWorkLoad then
        return
    end

    local szMsg = ""
    if product.State == tbProductState.nBuilding then 
        product.State = tbProductState.nEnabled
        szMsg = "产品%s研发完成，多余的%d人手已经释放到待岗区"
    elseif product.State == tbProductState.nRenovating then
        product.State = tbProductState.nRenovateDone
        szMsg = "产品%s翻新完成，多余的%d人手已经释放到待岗区"
    else
        return --之前就已经完成了，还重新配上多余人手，则保持不做释放多余人手
    end

    --====把多余的人手（超过category.nMaintainIdeaTeam），自动释放====
    totalMan = 0
    local category = tbConfig.tbProductCategory[product.Category]
    for i = tbConfig.nManpowerMaxExpLevel, 1, -1 do --优先保留高等级的，释放低等级的
        local num = product.tbManpower[i]
        if num > 0 then
            if totalMan >= category.nMaintainIdeaTeam then
                user.tbIdleManpower[i] = user.tbIdleManpower[i] + num
                user.tbJobManpower[i] = user.tbJobManpower[i] - num
                totalMan = totalMan + num
                product.tbManpower[i] = 0
            elseif totalMan + num <= category.nMaintainIdeaTeam then
                totalMan = totalMan + num
            else
                local exceed = totalMan + num - category.nMaintainIdeaTeam
                user.tbIdleManpower[i] = user.tbIdleManpower[i] + exceed
                user.tbJobManpower[i] = user.tbJobManpower[i] - exceed
                totalMan = totalMan + num
                product.tbManpower[i] = num - exceed
            end
        end
    end


    if totalMan > category.nMaintainIdeaTeam and szMsg ~= "" then
        table.insert(user.tbSysMsg, string.format(szMsg, product.szName, totalMan - category.nMaintainIdeaTeam))
    end
end

function Production:UpdatePublished(product, user)
    local addQuality = -tbConfig.fQualityDelta
    local nLastQuality10 = product.nQuality10
    local category = tbConfig.tbProductCategory[product.Category]
    local totalMan, totalQuality = Production:GetTeamScaleQuality(product)
    local szReason

    if totalMan >= category.nMaintainIdeaTeam then
        if totalQuality / totalMan * 10 >= product.nOrigQuality10 / tbConfig.fQualityPerManpowerLevel then
            if product.nQuality10 == product.nOrigQuality10 then
                return
            end
            addQuality = tbConfig.fQualityDelta  --维护团队的等级不低于原始质量等级，则恢复质量
            szReason = "维护团队规模和品质优秀"
        elseif totalQuality / totalMan * 10 >= product.nQuality10 / tbConfig.fQualityPerManpowerLevel then
            return
        else
            szReason = string.format("维护团队平均等级不足%.1f", product.nOrigQuality10 / 10 / tbConfig.fQualityPerManpowerLevel)
        end
    else
        szReason = string.format("维护人数不足%d人", category.nMaintainIdeaTeam)
    end

    product.nQuality10 = math.min(product.nQuality10 + addQuality, product.nOrigQuality10)    -- 不能超过初始品质
    product.nQuality10 = math.max(1, product.nQuality10)

    if product.nQuality10 ~= nLastQuality10 then
        if GameLogic:PROD_IsPlatformP(product) then
            user.nPlatformPQuality10 = product.nQuality10
        elseif GameLogic:PROD_IsPlatformPQ(product) then
            user.nPlatformPQQuality10 = product.nQuality10
        end
        table.insert(user.tbSysMsg, string.format("已发布产品%s由于%s品质由%.1f变更为%.1f", product.szName, szReason, nLastQuality10 / 10, product.nQuality10 / 10))
    end
end

function Production:IsPublished(product)
    return table.contain_value(tbConfig.tbPublishedState, product.State)
end

function Production:GetPlatformEffect(user)
    local manpowerRate = 1 + tbConfig.fPlatformManPowerRate * user.nPlatformPQuality10 * tbConfig.fQualityRatio
    local qualityRate =  (1 + tbConfig.fPlatformQualityRate * user.nPlatformPQuality10 * tbConfig.fQualityRatio) * (1 + tbConfig.fPlatformQualityRate * user.nPlatformPQQuality10 * tbConfig.fQualityRatio)

    return manpowerRate, qualityRate
end
