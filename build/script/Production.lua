local tbProductState = tbConfig.tbProductState
local nNewProductId = 0

Develop = {}       --用于包含响应客户端请求的函数
Production = {}    --研发模块的内部函数

-- 立项 {FuncName = "Develop", Operate = "NewProduct", Category="A" }
function Develop.NewProduct(tbParam, user)
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
    product.bIsPlatform = categoryConfig.bIsPlatform
    product.szName = category .. tostring(id)
    user.tbProduct[id] = product
    return id, product
end

-- 关闭产品 {FuncName = "Develop", Operate = "CloseProduct", Id=1 }
function Develop.CloseProduct(tbParam, user)
    local product = nil
    if tbParam.Id then
        product = user.tbProduct[tbParam.Id]
    end
    if product == nil then
        return "未找到欲关闭的产品：" .. tbParam.Id, false
    end
    if product.State == tbProductState.nClosed then
        return "success", true
    end

    -- 关闭翻新项目
    MarketMgr:OnCloseProduct(tbParam.Id, product)

    --该产品在岗人员全部回到空闲状态
    for i = 1, tbConfig.nManpowerMaxExpLevel do
        user.tbJobManpower[i] = user.tbJobManpower[i] - product.tbManpower[i]
        user.tbIdleManpower[i] = user.tbIdleManpower[i] + product.tbManpower[i]
        product.tbManpower[i] = 0
    end
    product.State = tbProductState.nClosed
    user.tbClosedProduct[tbParam.Id] = product
    user.tbProduct[tbParam.Id] = nil

    return "success", true
end

-- 对翻新完成的产品，执行发布操作，结束翻新

-- 开始翻新产品 {FuncName = "Develop", Operate = "Renovate", Id=1 }
function Develop.Renovate(tbParam, user)
    local product = nil
    if tbParam.Id then
        product = user.tbProduct[tbParam.Id]
    end
    if product == nil then
        return "未找到欲翻新的产品：" .. tbParam.Id, false
    end

    if product.State == tbProductState.nRenovating then
        return "success", true
    elseif product.State ~= tbProductState.nPublished then
        return "未发布的产品不能翻新：" .. tbParam.Id, false
    end
    product.State = tbProductState.nRenovating
    product.nFinishedWorkLoad = 0
    product.fFinishedQuality = 0
    return "success", true
end

function Production:Reset()
    nNewProductId = 0
end

function Production:NewProductId()
    nNewProductId = nNewProductId + 1
    return nNewProductId
end

-- 此函数用来控制季度结算时遍历产品的顺序，为了避免出现一个季度产品对质量加成不一致的问题, 对于中台产品要统一结算时机
-- 当前是方式是优先处理中台，这样后续遍历的产品就会被中台的质量分所影响
function Production:GetProductLoopSequence(tbProductList)
    local tbResult = {}
    for _, tbProduct in pairs(tbProductList) do
        local tbConfig = tbConfig.tbProductCategory[tbProduct.Category]
        if tbConfig.bIsPlatform then
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
            -- 玩家没有执行上线操作前, 都需要执行UpdateWrokload函数
            if product.State <= tbProductState.nEnabled or product.State == tbProductState.nRenovating or product.State == tbProductState.nRenovateDone then
                Production:UpdateWrokload(product, user)
            elseif Production:IsPublished(product) then
                Production:UpdatePublished(product, user)
            end
        end
    end
end

-- 首次发布和翻新发布都通过此函数设置品质与状态
function Production:Publish(product, user)
    local state = product.State
    --在Market.Publish中已对产品状态做过检查，此处略过
    --product.State == tbConfig.tbProductState.nEnabled or product.State == tbConfig.tbProductState.nRenovateDone

    local quality = math.floor(product.fFinishedQuality / product.nFinishedWorkLoad)
    product.fFinishedQuality = quality
    product.nOrigQuality= quality
    product.nQuality = quality
    product.State = tbProductState.nPublished
end

function Production:GetQuality(product, user)
    local category = tbConfig.tbProductCategory[product.Category]
    local totalMan = 0
    local totalQuality = 0

    local bInRenovate = product.State == tbConfig.tbProductState.nRenovating
    local nMinTeam = bInRenovate and category.nRenovateMinTeam or category.nMinTeam
    local nIdeaTeam = bInRenovate and category.nRenovateIdeaTeam or category.nIdeaTeam

    for i = 1, tbConfig.nManpowerMaxExpLevel do
        totalMan = totalMan + product.tbManpower[i]
        totalQuality = totalQuality + product.tbManpower[i] * i
    end
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
    
    totalQuality, totalMan = totalQuality * tbConfig.fQualityPerManpowerLevel, totalMan

    -- 非中台部门要计算中台加成
    if not category.bIsPlatform then
        local fQualityRate, fManPowerRate = self:MiddlePlatformQuality(user)
        totalQuality, totalMan = totalQuality * (1 + fQualityRate), totalMan * (1 + fManPowerRate)
    end

    -- 四舍五入
    return math.floor(totalQuality + 0.5), math.floor(totalMan + 0.5)
end

function Production:UpdateWrokload(product, user)
    local totalQuality, totalMan = self:GetQuality(product, user)
    local newWorkLoadValue = product.nFinishedWorkLoad + totalMan
    local newQualityValue = product.fFinishedQuality + totalQuality

    product.nFinishedWorkLoad = newWorkLoadValue
    product.fFinishedQuality = newQualityValue

    if newWorkLoadValue < product.nNeedWorkLoad then
        return
    end

    local szMsg = ""
    if product.State == tbProductState.nBuilding then 
        product.State = tbProductState.nEnabled
        szMsg = "产品%s研发完成，多余的%d人手已经释放到待岗区"
    elseif product.State == tbProductState.nRenovating then
        product.State = tbProductState.nRenovateDone
        szMsg = "产品%s翻新完成，多余的%d人手已经释放到待岗区"
    end

    --====把多余的人手（超过category.nMaintainTeam），自动释放====
    totalMan = 0
    local category = tbConfig.tbProductCategory[product.Category]
    for i = tbConfig.nManpowerMaxExpLevel, 1, -1 do
        if product.tbManpower[i] > 0 then
            if totalMan >= category.nMaintainTeam then
                user.tbIdleManpower[i] = user.tbIdleManpower[i] + product.tbManpower[i]
                user.tbJobManpower[i] = user.tbJobManpower[i] - product.tbManpower[i]
                totalMan = totalMan + product.tbManpower[i]
                product.tbManpower[i] = 0
            elseif totalMan + product.tbManpower[i] <= category.nMaintainTeam then
                totalMan = totalMan + product.tbManpower[i]
            else
                local exceed = totalMan + product.tbManpower[i] - category.nMaintainTeam
                user.tbIdleManpower[i] = user.tbIdleManpower[i] + exceed
                user.tbJobManpower[i] = user.tbJobManpower[i] - exceed
                totalMan = totalMan + product.tbManpower[i]
                product.tbManpower[i] = product.tbManpower[i] - exceed
            end
        end
    end

    if szMsg ~= "" then
        table.insert(user.tbSysMsg, string.format(szMsg, product.szName, totalMan - category.nMaintainTeam))
    end
end

function Production:UpdatePublished(product, user)
    local addQuality = -1
    local nLastQuality = product.nQuality
    local category = tbConfig.tbProductCategory[product.Category]
    local totalQuality, totalMan = self:GetQuality(product, user)

    -- 人力投入大于理想人员规模和当前品质大于等于初始品质
    if totalMan >= category.nMaintainTeam and totalQuality / totalMan >= product.nOrigQuality then
        addQuality = 1
    end

    -- 不能超过初始品质
    product.nQuality = math.min(product.nQuality + addQuality, product.nOrigQuality)
    product.nQuality = math.max(1, product.nQuality)

    if product.nQuality ~= nLastQuality then
        table.insert(user.tbSysMsg, string.format("已发布产品%s品质由%d变更为%d", product.szName, nLastQuality, product.nQuality))
    end
end

function Production:IsPublished(product)
    return table.contain_value(tbConfig.tbPublishedState, product.State)
end

function Production:MiddlePlatformQuality(user)
    for _, product in pairs(user.tbProduct) do
        local config = tbConfig.tbProductCategory[product.Category]
        if config.bIsPlatform and self:IsPublished(product) then
            return config.fQualityRate * product.nQuality, config.fManPowerRate * product.nQuality
        end
    end
    
    return 0, 0
end

--[[
function Production:RecordProductState()
    local tbRuntimeData = GetTableRuntime()
    for _, user in pairs(tbRuntimeData.tbUser) do
        for _, product in pairs(user.tbProduct) do
            product.OriginalState = product.State
        end
        for _, product in pairs(user.tbClosedProduct) do
            product.OriginalState = product.State
        end
    end
end
--]]