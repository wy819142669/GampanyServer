-- local cjson = require "luascript/cjson"

require("luascript/Ui.lua")
require("luascript/Json.lua")
require("luascript/lib.lua")
Log=print
LogErr=print
LogWarn=print


Client = {}
Client.GameClient = CS.GameClient
function Client:OnClientStartUp(nParam)
    print("Client:OnClientStartUp()!!", nParam)
    self:DoRequestWeb("http://8.219.208.117:13134/reload", {a = 1, b = 2})
end

function Client:OnUpdate(nParam)
    -- print("Client:OnUpdate()!!", nParam)
end


function Client:DoRequestWeb(szUrl, tbBody)
    local szBody = JsonEncode(tbBody)
    local nRequestId = self.GameClient.PostWebRequest(szUrl, szBody)
    print("Client:DoRequestWeb()!!", szUrl, szBody, nRequestId)
end

function Client:OnWebRespond(szBody)
    local tbBody = JsonDecode(szBody)
    Lib:ShowTB(tbBody)
    print("Client:OnWebRespond()!!", szBody)
end

