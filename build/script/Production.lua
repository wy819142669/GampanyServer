local tbConfig = tbConfig
local tbProductState = tbConfig.tbProductState
local nNewProductId = 0

Develop = {}       --用于包含响应客户端请求的函数
Production = {}    --研发模块的内部函数

-- 立项 {FuncName = "Develop", Operate = "NewProduct", Category="A" }
function Develop.NewProduct(tbParam, tbUser)
    if tbParam.Category == nil then
        return "立项需要指明品类", false
    end
    local product = Lib.copyTab(tbInitTables.tbInitNewProduct)
    product.Category = tbParam.Category
    local id = Production:NewProductId()
    tbUser.tbProduct[id] = product
    return "success", true
end

-- 关闭产品 {FuncName = "Develop", Operate = "CloseProduct", Id=1 }
function Develop.CloseProduct(tbParam, tbUser)
    if tbParam.Id == nil then
        return "关闭产品需要指明id", false
    end
    local product = tbUser.tbProduct[tbParam.Id]
    if product == nil then
        return "未找到产品：" .. Id, false
    end
    if product.State == tbProductState.nClosed then
        return "success", true
    end

    --该产品在岗人员全部回到空闲状态
    for i = 1, tbConfig.nManpowerMaxExpLevel do
        tbUser.tbJobManpower[i] = tbUser.tbJobManpower[i] - product.tbManpower[i]
        tbUser.tbIdleManpower[i] = tbUser.tbIdleManpower[i] + product.tbManpower[i]
        product.tbManpower[i] = 0
    end
    product.State = tbProductState.nClosed
    tbUser.tbClosedProduct[tbParam.Id] = product
    tbUser.tbProduct[tbParam.Id] = nil
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
    for _, tbUser in pairs(tbRuntimeData.tbUser) do
        for _, product in pairs(tbUser.tbProduct) do
            if product.Sate == tbProductState.nBuilding then
                Production:UpdateWrokload(product, tbUser)
            end
        end
    end
end

function Production:UpdateWrokload(product, tbUser)
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
    product.nFinishedWorkLoad = product.nFinishedWorkLoad + totalMan
    product.fFinishedQuality = product.fFinishedQuality + totalQuality

    if product.nFinishedWorkLoad < category.nWorkLoad then
        return
    end

    --====产品研发完成====
    product.State = tbProductState.nEnabled
    product.fFinishedQuality = fFinishedQuality / product.nFinishedWorkLoad
    --====把多余的人手（超过category.nMaintainTeam），自动释放====
    totalMan = 0
    for i = tbConfig.nManpowerMaxExpLevel, 1, -1 do
        if product.tbManpower[i] > 0 then
            if totalMan >= category.nMaintainTeam then
                tbUser.tbIdleManpower[i] = tbUser.tbIdleManpower[i] + product.tbManpower[i]
                tbUser.tbJobManpower[i] = tbUser.tbJobManpower[i] - product.tbManpower[i]
                totalMan = totalMan + product.tbManpower[i]
                product.tbManpower[i] = 0
            elseif totalMan + product.tbManpower[i] <= category.nMaintainTeam then
                totalMan = totalMan + product.tbManpower[i]
            else
                local exceed = totalMan + product.tbManpower[i] - category.nMaintainTeam
                tbUser.tbIdleManpower[i] = tbUser.tbIdleManpower[i] + exceed
                tbUser.tbJobManpower[i] = tbUser.tbJobManpower[i] - exceed
                totalMan = totalMan + product.tbManpower[i]
                product.tbManpower[i] = category.nMaintainTeam - totalMan                                           
            end
        end
    end
end
