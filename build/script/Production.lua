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


function Production:CreateUserProduct(category, user, workLoadRatio)
    local product = Lib.copyTab(tbInitTables.tbInitNewProduct)
    local categoryConfig = tbConfig.tbProductCategory[category]
    local id = Production:NewProductId()
    product.Id = id
    product.nNeedWorkLoad = math.ceil(categoryConfig.nWorkLoad * (workLoadRatio or 1))
    product.Category = category
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
    if product.RenovateProductId then
        Develop.CloseProduct({Id = product.RenovateProductId}, user)
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

-- 结束翻新 {FuncName = "Develop", Operate = "StopRenovate", Id=1 }
function Develop.StopRenovate(tbParam, user)
    local product
    if tbParam.Id then
        product = user.tbProduct[tbParam.Id]
    end
    if not product then
        return "未找到产品：" .. tbParam.Id, false
    end
    
    print("StopRenovate", product.State, product.State ~= tbProductState.nRenovating, product.RenovateProductId)
    if product.State ~= tbProductState.nRenovating or not product.RenovateProductId then
        return "不在翻新状态中", false
    end

    local targetProductId = product.RenovateProductId
    product.RenovateProductId = nil
    Develop.CloseProduct({Id = targetProductId}, user)

    product.State = tbProductState.nPublished

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
    elseif product.State ~= tbProductState.nPublished then
        return "未完成的产品不能翻新：" .. tbParam.Id, false
    end

    -- 新建项目并创建双方链接
    local newId, newProduct = Production:CreateUserProduct(product.Category, user, tbConfig.fRenovateWorkLoadRatio)
    product.RenovateProductId = newId
    newProduct.SourceProductId = tbParam.Id

    product.State = tbProductState.nRenovating
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
                Production:UpdateWrokload(product, user)
            elseif product.State >= tbProductState.nPublished then
                Production:UpdatePublished(product, user)
            end
        end
    end
end

-- 首次发布和翻新发布都通过此函数设置品质与状态
function Production:Publish(product, user)
    local state = product.State
    if state ~= tbProductState.nEnabled then
        return
    end

    local quality = math.floor(product.fFinishedQuality / product.nFinishedWorkLoad)
    product.fFinishedQuality = quality
    product.nQuality = quality
    product.State = tbProductState.nPublished

    -- 合并数据
    if product.SourceProductId then
        local sourceProduct = user.tbProduct[product.SourceProductId]
        sourceProduct.RenovateProductId = nil
        sourceProduct.nQuality = quality
        sourceProduct.fFinishedQuality = quality
        sourceProduct.State = tbProductState.nPublished

        Develop.CloseProduct({Id = product.Id}, user)
    end
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

    return math.floor(totalQuality + 0.5), math.floor(totalMan + 0.5)
end


function Production:UpdateWrokload(product, user)
    local totalQuality, totalMan = self:GetQuality(product)
    local newWorkLoadValue = product.nFinishedWorkLoad + totalMan
    local newQualityValue = product.fFinishedQuality + totalQuality

    product.nFinishedWorkLoad = newWorkLoadValue
    product.fFinishedQuality = newQualityValue

    if newWorkLoadValue < product.nNeedWorkLoad then
        return
    end

    if product.State ~= tbProductState.nEnabled then
        product.State = tbProductState.nEnabled
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
    product.nQuality = math.min(product.nQuality + addQuality, product.nQuality)
end

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
