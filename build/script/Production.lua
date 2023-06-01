local tbConfig = tbConfig
local tbProductState = tbConfig.tbProductState

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