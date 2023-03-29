
using System.IO;
using System;
using UnityEngine;

[XLua.LuaCallCSharp]
public class GameEnv
{
    public static bool IsUseAB = false;                      // 是否用编辑器接口加载资源 -> (true==AssetDatabase) (false==AssetBundle)
    public static bool IsUsePack = false;                   // 是否使用pack名资源（配置文件和Lua）
    public static bool IsDevMode = true;                    // 是否是开发模式
    public static bool EnableSDK = true;                    // 是否启用登录SDK
    public static bool IsInternal = false;                  // 是否内网版本
    public static string AppVersionStr = "";                // 版本号
    public static int AppNum = 1;                           // App编号（正式换包时+1）
    public static string Language = "chs";                  // 语言
    public static string Area = "CN";                       // 地区
    public static int TranslateMode = 0;                    // 翻译模式 0静态 1动态 仅对越南版本生效
    public static bool AllSameAsLastTime = false;           // 账号/区服/选角色 都跟上次一样自动选择进入游戏，用于unity环境自动进入场景
    public static string Tag = "";                          // 标签用于特殊处理
    public static bool EnableAutoTest = false;              // 启用自动化测试
    //public static bool BuildDlc = false;                    // 是否开启DLC功能 已废弃

    public static string InternalCDN = "";                  // 内网CDN地址
    public static string ExternalCDN = "";                  // 外网CDN地址
    public static string InternalBackupCDN = "";            // 内网备用CDN地址
    public static string ExternalBackupCDN = "";            // 外网备用CDN地址

    public static string VersionGetUrl = "";        // 外网版本信息获取地址
    public static string VersionGetBackupUrl = "";  // 外网备用版本信息获取地址
    public static string CdnMain = "";               // 外网CDN地址
    public static string CdnBackupMain = "";         // 外网备用CDN地址

    //public static string InternalVersionGetUrl = "";        // 内网版本信息获取地址
    //public static string InternalVersionGetBackupUrl = "";  // 内网备用版本信息获取地址
    //public static string InternalCdnUrl = "";               // 内网CDN地址
    //public static string InternalCdnBackupUrl = "";         // 内网备用CDN地址

    public static string AnnouncementGetUrl = "";      // 外网公告信息获取地址
    //public static string InternalAnnouncementUrl = "";      // 内网公告信息获取地址

    public static string BannerGetUrl = "";            // 外网Banner信息获取地址
    //public static string InternalBannerUrl = "";            // 内网Banner信息获取地址

    public static string MusicSettingGetUrl = "";            // 外网MusicSetting信息获取地址
    //public static string InternalMusicSettingUrl = "";            // 内网MusicSetting信息获取地址

    public static string ApkDownloadUrl = "";               // APK下载地址
    public static bool IsOpenUpdate = false;                // 是否开启更新
    public static bool IsShenHe = false;  // 是否为IOS审核版本

    public static RuntimePlatform Platform { get; private set; }
    public static bool InPlatform_Android { get; private set; }
    public static bool InPlatform_Iphone { get; private set; }
    public static bool InPlatform_PC { get; private set; }


    public static string _UserPath = "";

    public static string ZoneId = "trunk";
    public static bool CanRespondBackCmd = true;
    public static float GyroRate = 1.0f;

    public static string GetPersistent()
    {
#if !UNITY_EDITOR && UNITY_STANDALONE_WIN
        var windowsPersistent = Path.Combine(Application.streamingAssetsPath, "../PersistentData");
        if (!Directory.Exists(windowsPersistent))
        {
            Directory.CreateDirectory(windowsPersistent);
        }
        return windowsPersistent;
#endif
        return Application.persistentDataPath;
    }

    static GameEnv()
    {
        _UserPath = GameEnv.GetPersistent() + "/";
#if UNITY_EDITOR
        _UserPath = Application.dataPath.Replace('\\', '/');
        _UserPath = _UserPath.Substring(0, _UserPath.LastIndexOf('/')) + "/";
#endif

        Platform = Application.platform;
        InPlatform_Android = Platform == RuntimePlatform.Android;
        InPlatform_Iphone = Platform == RuntimePlatform.IPhonePlayer;
#if UNITY_EDITOR || UNITY_STANDALONE_WIN || UNITY_STANDALONE_OSX
        InPlatform_PC = true;
#else
        InPlatform_PC = false;
#endif
    }

    public static void LoadConfig()
    {
        var fileName = "AppConfig";
#if UNITY_EDITOR && JX_EDITOR_DEBUG
        fileName = "AppConfig_editor";
#endif

#if UNITY_EDITOR
        IsUseAB = (int.Parse(GetConfig("Global", "IsUseAB")) == 1);
        IsUsePack = (int.Parse(GetConfig("Global", "IsUsePack")) == 1);
#else
        IsUseAB = true;
        IsUsePack = true;
#endif
        IsDevMode = (int.Parse(GetConfig("Global", "IsDevMode")) == 1);
        EnableSDK = (int.Parse(GetConfig("Global", "EnableSDK")) == 1);
        IsInternal = (int.Parse(GetConfig("Global", "IsInternal")) == 1);
        AppVersionStr = GetConfig("Global", "AppVersion");
        AppNum = int.Parse(GetConfig("Global", "AppNum"));
        Language = GetConfig("Global", "Language");
        Area = GetConfig("Global", "Area");
        Tag = GetConfig("Global", "Tag");
        EnableAutoTest = (int.Parse(GetConfig("Global", "EnableAutoTest")) == 1);
        //BuildDlc = (int.Parse(GetConfig("Global", "BuildDlc")) == 1);
        IsOpenUpdate = (int.Parse(GetConfig("Global", "IsOpenUpdate")) == 1);
        ApkDownloadUrl = GetConfig("Global", "ApkDownloadUrl");
        IsShenHe = (int.Parse(GetConfig("Global", "IsShenHe")) == 1);

        InternalCDN = GetConfig("Global", "InternalCDN");
        ExternalCDN = GetConfig("Global", "ExternalCDN");

        InternalBackupCDN = GetConfig("Global", "InternalBackupCDN");
        ExternalBackupCDN = GetConfig("Global", "ExternalBackupCDN");

#if !UNITY_EDITOR
        LoadDebugParam();
#endif

        if (bHasDebugParam && !string.IsNullOrEmpty(szDebugRemoteUpdateUrl))
        {
            InternalCDN = szDebugRemoteUpdateUrl;
            ExternalCDN = szDebugRemoteUpdateUrl;
            InternalBackupCDN = szDebugRemoteUpdateUrl;
            ExternalBackupCDN = szDebugRemoteUpdateUrl;
        }

        if (bHasDebugParam && EnableSDK == true)
        {
            EnableSDK = !bDebugSkipSDK;
        }

        var validCDN = IsInternal ? InternalCDN : ExternalCDN;
        var validBackupCDN = IsInternal ? InternalBackupCDN : ExternalBackupCDN;

        if (validCDN != "")
        {
            VersionGetUrl = GetConfig("Global", "VersionUrl").Replace("$(CDN)", validCDN);
            VersionGetBackupUrl = GetConfig("Global", "VersionBackupUrl").Replace("$(BackupCDN)", validBackupCDN);

            CdnMain = GetConfig("Global", "MainUrl").Replace("$(CDN)", validCDN);
            CdnBackupMain = GetConfig("Global", "BackupMainUrl").Replace("$(BackupCDN)", validBackupCDN);

            AnnouncementGetUrl = GetConfig("Global", "AnnouncementUrl").Replace("$(CDN)", validCDN);

            BannerGetUrl = GetConfig("Global", "BannerUrl").Replace("$(CDN)", validCDN);

            MusicSettingGetUrl = GetConfig("Global", "MusicSettingUrl").Replace("$(CDN)", validCDN);
        }
        

        //LogHelper.INFO("GameEnv", "IsUseAB={0}", IsUseAB);
        //LogHelper.INFO("GameEnv", "IsUsePack={0}", IsUsePack);
        //LogHelper.INFO("GameEnv", "IsDevMode={0}", IsDevMode);
        //LogHelper.INFO("GameEnv", "EnableSDK={0}", EnableSDK);
        //LogHelper.INFO("GameEnv", "IsInternal={0}", IsInternal);
        //LogHelper.INFO("GameEnv", "AppVersion={0}", AppVersion);
        //LogHelper.INFO("GameEnv", "AppNum={0}", AppNum);
        //LogHelper.INFO("GameEnv", "Language={0}", Language);
        //LogHelper.INFO("GameEnv", "TranslateMode={0}", TranslateMode);
        //LogHelper.INFO("GameEnv", "Tag={0}", Tag);
        //LogHelper.INFO("GameEnv", "ExternalVersionGetUrl={0}", ExternalVersionGetUrl);
        //LogHelper.INFO("GameEnv", "ExternalVersionGetBackupUrl={0}", ExternalVersionGetBackupUrl);
        //LogHelper.INFO("GameEnv", "ExternalCdnUrl={0}", ExternalCdnUrl);
        //LogHelper.INFO("GameEnv", "ExternalCdnBackupUrl={0}", ExternalCdnBackupUrl);
        //LogHelper.INFO("GameEnv", "InternalVersionGetUrl={0}", InternalVersionGetUrl);
        //LogHelper.INFO("GameEnv", "InternalVersionGetBackupUrl={0}", InternalVersionGetBackupUrl);
        //LogHelper.INFO("GameEnv", "InternalCdnUrl={0}", InternalCdnUrl);
        //LogHelper.INFO("GameEnv", "InternalCdnBackupUrl={0}", InternalCdnBackupUrl);
        //LogHelper.INFO("GameEnv", "ApkDownloadUrl={0}", ApkDownloadUrl);
        //LogHelper.INFO("GameEnv", "IsOpenUpdate={0}", IsOpenUpdate);
        //LogHelper.INFO("GameEnv", "EnableAutoTest={0}", EnableAutoTest);
        //LogHelper.INFO("GameEnv", "ExternalAnnouncementUrl={0}", ExternalAnnouncementUrl);
        //LogHelper.INFO("GameEnv", "InternalAnnouncementUrl={0}", InternalAnnouncementUrl);
        //LogHelper.INFO("GameEnv", "ExternalMusicSettingUrl={0}", ExternalMusicSettingUrl);
        //LogHelper.INFO("GameEnv", "InternalMusicSettingUrl={0}", InternalMusicSettingUrl);
    }

    public static string GetConfig(string szSection, string szKey, bool throwError = true)
    {
        return "";
    }

    public static void SetConfig(string section, string key, string value, bool throwError = true)
    {
    }

    public static string GetText()
    {
        var textAsset = Resources.Load<TextAsset>("AppConfig");
        return textAsset.text;
    }

    public static int GetUpdateVersion()
    {
        return 0;
    }
    public static void SetPlatform(int nPlatform)
    {
#if UNITY_EDITOR
        Debug.LogFormat("SetPlatform={0}", nPlatform);
#endif
    }

    public static bool bHasDebugParam = false;
    public static string szDebugRemoteUpdateUrl;
    public static string szDebugGatewayAddr;
    public static bool bDebugSkipSDK = false;
    public static bool bDebugOpenLogView = false;
    public static bool bDebugFPS = false;
    public static bool bDlcDebug = false;
    public static int nDlcDownloaderThread = 3;
    public static string szAppPath = GameEnv.GetPersistent();

    public static void LoadDebugParam()
    {
    }
}