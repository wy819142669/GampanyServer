using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using static UnityEngine.EventSystems.StandaloneInputModule;
using static UnityEngine.LightProbeProxyVolume;
using static UnityEngine.ParticleSystem;
using UnityEngine;
using XLua;
using XLua.LuaDLL;
using System.IO;

public class GameClient : MonoBehaviour
{
    public static bool _InitFlag { get; private set; } = false;
    public static GameClient _Instance { get; private set; } = null;
    public static int _InitPercent = 0;
    public static XLua.LuaEnv _LuaEnv = null;
    private static WebService _webservice = null;
    

    void Awake()
    {
    }

    void Start()
    {

        if (_webservice == null)
        {
            _webservice = new WebService();
        }

        if (_LuaEnv == null)
        {
            _LuaEnv = new XLua.LuaEnv();
            _LuaEnv.AddLoader(MyLoader);
        }
        
        _LuaEnv.DoString("print('Hello World')");
        _LuaEnv.DoString("require 'luascript/Client.lua'");

        CallLua("Client:OnClientStartUp", 3333);

    }

#if UNITY_EDITOR
    void Update()
    {
        CallLua("Client:OnUpdate", 5555);
    }
#endif

    void OnDestroy()
    {
        _LuaEnv.Dispose();
    }

    void OnApplicationQuit()
    {

    }
    public static void LuaGC()
    {
        var count = XLua.LuaDLL.Lua.lua_gc(_LuaEnv.L, XLua.LuaGCOptions.LUA_GCCOUNT, 0);
        UnityEngine.Debug.LogError("Lua GC count:" + count);
    }

    // 不可高频调用 GC太高
    public static object[] CallLua(string szFunction, params object[] vecParams)
    {
        if (_LuaEnv == null)
        {
            UnityEngine.Debug.LogError(string.Format("Call ERR ?? m_Lua is nil !! func={0}", szFunction));
            return null;
        }

        int nIdxOfSp = szFunction.IndexOf(":");
        if (nIdxOfSp > 0 && nIdxOfSp < szFunction.LastIndexOf("."))
        {
            UnityEngine.Debug.LogError(string.Format("Call ERR ?? func={0}", szFunction));
            return null;
        }

        XLua.LuaTable tbFirstParam = null;
        if (nIdxOfSp > 0)
        {
            tbFirstParam = _LuaEnv.Global.GetInPath<XLua.LuaTable>(szFunction.Substring(0, nIdxOfSp));
            if (tbFirstParam == null)
            {
                UnityEngine.Debug.LogError(string.Format("Call ERR ?? func={0}", szFunction));
                return null;
            }

            szFunction = szFunction.Replace(":", ".");
        }

        var func = _LuaEnv.Global.GetInPath<XLua.LuaFunction>(szFunction);
        if (func == null)
        {
            UnityEngine.Debug.LogError(string.Format("Call ERR ?? func is null, szFunction={0}", szFunction));
            return null;
        }

        List<object> lstParam = new List<object>();
        if (tbFirstParam != null)
            lstParam.Add(tbFirstParam);

        if (vecParams != null)
        {
            for (int i = 0; i < vecParams.Length; ++i)
            {
                lstParam.Add(vecParams[i]);
            }
        }

        return func.Call(lstParam.ToArray());
    }

    private byte[] MyLoader(ref string filePath)
    {
        return System.Text.Encoding.UTF8.GetBytes(File.ReadAllText(filePath));
    }


    static public int PostWebRequest(string url, string bodyjson)
    {
        UnityEngine.Debug.LogError(string.Format("PostWebRequest={0}", _webservice.GetRequestId()));
        return _webservice.WebRequest(url, bodyjson);
    }

}
