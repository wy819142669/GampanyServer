local ProductState = tbConfig.tbProductState
---@class ProductMeta
local ProductMeta = {}

function ProductMeta:Init(tbParams)

end


-- 更新人力
function ProductMeta:UpdatePeaple()

end

-- 更新品质
function ProductMeta:UpdateQuality()
    -- 获取当前人数
end

-- 季度更新
function ProductMeta:UpdateSeason()
    self:UpdateQuality()
end

-- 上线
function ProductMeta:Publish()
    -- TODO 检查各种

    -- TODO 设置各种

    self.nState = ProductState.nPublished
    return true
end

function ProductMeta:SetState(nState)
    self.nState = nState
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
        nState = ProductState.nBuilding,    -- 当前状态
        nTotalSeason = 0,                   -- 总季度
        nRunningSeason = 0,                 -- 上线季度
        tbPeoples = {}                      -- 人员table, key为等级, value为数量
    }

    if not nSpecifiedId then
        self.nId = self.nId + 1
    end
    
    local tbObj = setmetatable(tbContext, {__index = ProductMeta})
    self.tbProducts[nId] = tbObj

    -- 产品初始化
    tbObj:Init(tbParams)

    -- 返回产品id
    return nId
end

-- 设置上线
function ProductionMgr:Publish(tbParams)
    local tbObj = self:GetOne(tbParams.nId)
    return tbObj and tbObj:Publish()
end