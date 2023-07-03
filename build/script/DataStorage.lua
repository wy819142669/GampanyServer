require("Json")
require("Lib")
require("Config")

DataStorage = {}
local szDataPath = "DataStorage/"

function DataStorage:Save(tbRuntimeData)
    local szFileName = string.format("%s_Year%d_Season%d.std", os.date("%Y%m%d%H%M%S"), tbRuntimeData.nCurYear, tbRuntimeData.nCurSeason)
    local file = io.open(szDataPath .. szFileName, "w+")
    if not file then
        print(string.format("Error: Save data to [%s] failed", szFileName))
        return
    end

    local szJson = JsonEncode(tbRuntimeData)
    file:write(szJson)
    file:close()
end

function DataStorage:Load()
    local szFileName = tbConfig.szRecoverDataFile
    if szFileName == "" then
        return nil, "未配置加载的文件名"
    end

    local file = io.open(szDataPath .. szFileName, "r")
    if not file then
        return nil, "文件不存在"
    end

    local tbData
    local szJson = file:read("*a")
    if szJson then
        tbData = JsonDecode(szJson)
    end

    file:close()
    return tbData
end
