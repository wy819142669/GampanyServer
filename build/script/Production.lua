local tbProductState = tbConfig.tbProductState
local nNewProductId = 0

Develop = {}       --用于包含响应客户端请求的函数
Production = {}    --研发模块的内部函数

-- 立项 {FuncName = "Develop", Operate = "NewProduct", Category="A" }
function Develop.NewProduct(tbParam, user)
    if tbParam.Category == nil then
        return "立项需要指明品类", false
    end
    local product = Lib.copyTab(tbInitTables.tbInitNewProduct)
    product.Category = tbParam.Category
    local id = Production:NewProductId()
    user.tbProduct[id] = product
    return "success", true
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
    elseif product.State ~= tbProductState.nEnabled or product.State ~= tbProductState.nPublished then
        return "未完成的产品不能翻新：" .. tbParam.Id, false
    end
    product.State = tbProductState.nRenovating

    -- 翻新时清空初始值，当翻新完成后替换当前值。
    product.nRenovatedWorkLoad = 0
    product.fRenovatedQuality = 0

    return "success", true
end

function Production:Reset()
    nNewProductId = 0
end

function Production:NewProductId()
    nNewProductId = nNewProductId + 1
    return nNewProductId
end

function Production:PostSeason()
    local tbRuntimeData = GetTableRuntime()
    for _, user in pairs(tbRuntimeData.tbUser) do
        for _, product in pairs(user.tbProduct) do
            -- 玩家没有执行上线操作前, 都需要执行UpdateWrokload函数
            if product.State <= tbProductState.nEnabled then
                Production:UpdateWrokload(product, user, {targetState = tbProductState.nEnabled})
            elseif product.State == tbProductState.nPublished then
                Production:UpdatePublished(product, user)
            elseif product.State == tbProductState.nRenovating then            
                Production:UpdateRenovating(product, user)
                Production:UpdatePublished(product, user)
            end
        end
    end
end

-- 首次发布和翻新发布都通过此函数设置品质与状态
function Production:Publish(product)
    local curQuality = product.fCurQuality
    local oldState = product.State
    if oldState == tbProductState.nEnabled then
        curQuality = product.fFinishedQuality / product.nFinishedWorkLoad
    elseif oldState == tbProductState.nRenovating then
        curQuality = product.fRenovatedQuality / product.nRenovatedWorkLoad
    end

    product.fFinishedQuality = curQuality
    product.fCurQuality = curQuality
    product.State = tbProductState.nPublished
end

-- 判断当前产品是否翻新完成
function Production:IsRenovateComplete(product)
    if product.State ~= tbProductState.nRenovating then
        return false
    end

    local category = tbConfig.tbProductCategory[product.Category]
    return product.nRenovatedWorkLoad >= math.ceil(category.nWorkLoad * tbConfig.fRenovateWorkLoadRatio)
end

function Production:GetQuality(product)
    local category = tbConfig.tbProductCategory[product.Category]
    local totalMan = 0
    local totalQuality = 0
    for i = 1, tbConfig.nManpowerMaxExpLevel do
        totalMan = totalMan + product.tbManpower[i]
        totalQuality = totalQuality + product.tbManpower[i] * i
    end
    if totalMan < category.nMinTeam then
        totalMan = totalMan * tbConfig.fSmallTeamRatio
        totalQuality = totalQuality * tbConfig.fSmallTeamRatio
    elseif totalMan > category.nIdeaTeam then
        local exceed = totalMan - category.nIdeaTeam
        totalMan = category.nIdeaTeam + exceed * tbConfig.fBigTeamRatio
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

    return totalQuality, totalMan
end

-- UpdateWrokload函数会被研发和翻新两个阶段复用, 所以有冲突的变量都需要通过options传入
-- options = {
--     workLoadKey = nil,       product中与当前阶段相关的 人力 变量的key
--     qualityKey = nil,        product中与当前阶段相关的 质量 变量的key
--     workLoadRatio = nil,     所需人力比例, 默认值为1, 翻新时通过传入参数控制比例
--     targetState = nil,       不传递targetState在工时满足后不自动切换状态
-- }
function Production:UpdateWrokload(product, user, options)
    local category = tbConfig.tbProductCategory[product.Category]
    local totalQuality, totalMan = self:GetQuality(product)
    options = options or {}
    local workLoadKey = options.workLoadKey or "nFinishedWorkLoad"
    local qualityKey = options.qualityKey or "fFinishedQuality"
    product[workLoadKey] = product[workLoadKey] + totalMan
    product[qualityKey] = product[qualityKey] + totalQuality

    -- 向上取整
    local workLoadRatio = options.workLoadRatio or 1
    if product[workLoadKey] < math.ceil(category.nWorkLoad * workLoadRatio) then
        return
    end

    --====产品研发完成, 翻新过程中人力满足后不自动切换成上线状态, 需要玩家手动执行上线操作====
    if options.targetState then
        product.State = options.targetState
    end

    --====把多余的人手（超过category.nMaintainTeam），自动释放====
    totalMan = 0
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
                product.tbManpower[i] = category.nMaintainTeam - totalMan                                           
            end
        end
    end
end

function Production:UpdatePublished(product)
    local addQuality = -1
    local category = tbConfig.tbProductCategory[product.Category]
    local totalQuality, totalMan = self:GetQuality(product)
    -- 人力投入大于理想人员规模和当前品质大于等于初始品质
    if totalMan >= category.nIdeaTeam and totalQuality >= product.fFinishedQuality then
        addQuality = 1
    end

    -- 不能超过初始品质
    product.fCurQuality = math.min(product.fCurQuality + addQuality, product.fCurQuality)
end

function Production:UpdateRenovating(product, user)
    local options = {
        workLoadKey = "nRenovatedWorkLoad",       
        qualityKey = "fRenovatedQuality",        
        workLoadRatio = tbConfig.fRenovateWorkLoadRatio,
    }
    self:UpdateWrokload(product, user, options)
end
