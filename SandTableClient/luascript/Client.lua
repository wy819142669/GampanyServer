-- local cjson = require "luascript/cjson"

require("luascript/Ui.lua")


Client = {}
Client.GameClient = CS.GameClient
function Client:OnClientStartUp(nParam)
    print("Client:OnClientStartUp()!!", nParam)
    -- self:DoRequestWeb("http://8.219.208.117:13134/reload", {a = 1, b = 2})
    self:DoRequestWeb("http://8.219.208.117:13134/reload", "{\"aaa\":1111, \"bbb\":222}")
end

function Client:OnUpdate(nParam)
    -- print("Client:OnUpdate()!!", nParam)
end


function Client:DoRequestWeb(szUrl, tbBody)
    local szBody = ""
    -- local szBody = cjson.encode(tbBody)
    local nRequestId = self.GameClient.PostWebRequest(szUrl, tbBody)
    print("Client:DoRequestWeb()!!", szUrl, szBody, nRequestId)
end

function Client:OnWebRespond(szBody)
    -- local tbBody = cjson.decode(szBody)
    print("Client:OnWebRespond()!!", szBody)
end

