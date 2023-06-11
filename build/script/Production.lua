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
    local product = tbInitTables.tbInitNewProduct[tbParam.Category]
    if product == nil then
        return "立项产品的品类有误", false
    end
    local id = Production:NewProductId()
    tbUser.tbProduct[id] = Lib.copyTab(product)
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

---@class ProductMeta
local ProductMeta = {}

local function GetRuntiimeTable(szCompany, nId)
    local tbRuntimeData = GetTableRuntime()
    local tbUser = tbRuntimeData.tbUser[szCompany]
    return tbUser and tbUser.tbProduct[nId]
end

local function SetMetaData(self, key, value)
    self._value[key] = value
    -- 通过szCompany和nId获取到tbRuntimeData中的具体对象。
    local tbData = GetRuntiimeTable(self.szCompany, self.nId)
    if tbData then
        tbData[key] = value
    end
end

local function GetMetaData(self, key)
    if ProductMeta[key] then
        return ProductMeta[key]
    end
    return self._value[key]
end

-- 创建项目时执行的初始化操作
function ProductMeta:Init()
    local productValue = {
        nState = tbProductState.nBuilding,  -- 当前状态
        nTotalSeason = 0,                   -- 总季度
        nPublishSeason = 0,                 -- 上线季度
        tbPeoples = {},                     -- 人员table, key为等级, value为数量
        nQuality = 0,
    }

    self._value = productValue
end

-- 更新品质
function ProductMeta:UpdateQuality()
    local nQuality = self.nQuality
    for nLevel, nCount in pairs(self:GetPeaple()) do
        if nLevel > 0 and nCount > 0 then
            nQuality = nQuality + nLevel * nCount
        end
    end

    self.nQuality = nQuality
end

-- 季度更新
function ProductMeta:UpdateSeason()
    self.nTotalSeason = self.nTotalSeason + 1
    if self.nState > tbProductState.nEnabled then
        self.nPublishSeason = self.nPublishSeason + 1
    end
    self:UpdateQuality()
end

-- 上线
function ProductMeta:Publish(tbParams)
    -- TODO 检查各种

    -- 设置状态
    self.nState = tbProductState.nPublished
    return true
end

-- 设置员工
function ProductMeta:SetPeaple(tbParams)
    self.tbPeoples = Lib.copyTab(tbParams.tbPeaples) or {}
end

-- 获取员工
function ProductMeta:GetPeaple()
    return self.tbPeaples
end

-- 是否可上线
function ProductMeta:CanPublish()
    return self.nState == tbProductState.nEnabled
end

-- 设置状态变更
function ProductMeta:SetState(nState)
    self.nState = nState
end

-- 获取品质 = 总质量 / 总季度
function ProductMeta:GetQuality()
    return self.nQuality / self.nTotalSeason
end

----------------------------------------------------------

---@class ProductionMgr
ProductionMgr = {
    tbProducts = {},
    nId = 1,
}

function ProductionMgr:Init(tbParams)
    for _, tbInfo in ipairs(tbParams.Products or {}) do
        self:Create(tbInfo, tbInfo.Id)
    end

    self.nId = tbParams.Products and #tbParams.Products + 1
end

-- 一个季度结束，更新所有产品信息
function ProductionMgr:UpdateSeason()
    for _, tbObj in pairs(self:GetAll()) do
        tbObj:UpdateSeason()
    end
end

-- 获取当前所有产品
function ProductionMgr:GetAll()
    return self.tbProducts
end

function ProductionMgr:GetByKey(key, value)
    local tbResult = {}
    for _, tbInfo in pairs(self:GetAll()) do
        if tbInfo[key] == value then
            tbResult[#tbResult+1] = tbInfo
        end
    end

    return tbResult
end

-- 获取所有指定类型的产品
function ProductionMgr:GetByType(szType)
    return self:GetByKey("szType", szType)
end

-- 获取指定公司的所有产品
function ProductionMgr:GetByCompany(szCompany)
    return self:GetByKey("szCompany", szCompany)
end

-- 获取单个产品
---@return ProductMeta
function ProductionMgr:GetOne(nId)
    return self.tbProducts[nId]
end

-- 获取一组产品
function ProductionMgr:GetMany(tbIds)
    local tbResult = {}
    for _, nId in ipairs(tbIds) do
        tbResult[#tbResult+1] = self:GetOne(nId)
    end

    return tbResult
end

-- 新建产品
function ProductionMgr:Create(tbParams, nSpecifiedId)
    -- 传入公司、产品类型、初始数据
    local nId = nSpecifiedId or self.nId
    local tbContext = {
        nId = nId,                          -- 产品Id
        szCompany = tbParams.szCompany,     -- 公司名字
        szType = tbParams.szType,           -- 产品类型
        _value = {},
    }

    if not nSpecifiedId then
        self.nId = self.nId + 1
    end
    
    local tbProduct = setmetatable(tbContext, {__index = GetMetaData, __newindex = SetMetaData})
    self.tbProducts[nId] = tbProduct

    -- 产品初始化
    tbProduct:Init(tbParams)

    -- 返回产品id
    return nId
end

-- 是否可以上线
function ProductionMgr:CanPublish(nId)
    local tbProduct = self:GetOne(nId)
    if not tbProduct then
        return false
    end

    return tbProduct:CanPublish()
end

-- 设置上线
function ProductionMgr:Publish(tbParams)
    local tbProduct = self:GetOne(tbParams.nId)
    return tbProduct and tbProduct:Publish(tbParams)
end

-- 设置员工
function ProductionMgr:SetPeaple(tbParams)
    local tbProduct = self:GetOne(tbParams.nId)
    return tbProduct and tbProduct:SetPeaple(tbParams)
end

-- 获取指定等级员工数量
function ProductionMgr:GetPeapleCountByLevel(tbParams)

end

-- 扣除指定等级的员工
function ProductionMgr:ReducePeapleByLevel(tbParams)

end

-- 增加指定等级的员工
function ProductionMgr:AddPeapleByLevel(tbParams)
    -- 判断是否总人数超出上限
end