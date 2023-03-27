print(package.path)

package.path = ".\\script\\?.lua;" .. package.path
--print(package.path)
require("Json")

function Reload(jsonParam)
    print("[lua] reload")

    print(jsonParam)
    --jsonParam = '{"x":1, "y":2}'
    local tbParam = JsonDecode(jsonParam)
    print(type(tbParam))
    print(JsonEncode(tbParam))
    return "reload success!" .. JsonEncode(tbParam)
end

function Action(jsonParam)
    print("[lua] action")

    local tbParam = JsonDecode(jsonParam)
end

function Query(jsonParam)
    print("[lua] query")

    local tbParam = JsonDecode(jsonParam)
end

print("load success")
