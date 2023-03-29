using System;
using System.IO;
using UnityEngine;

public enum LoaderMode
{
    Async,
    Sync,
}

public enum GetResourceFullPathType
{
    Invalid,
    InStreaming,
    InPersistent,
}

public delegate void OnResourceFinishEventHandler(object obj, object param);

public class ResourceResult
{
    public object objResult = null;
}

public class ResourceDef
{
    public static string ResourceDir = "Assets/Game/Artworks";
    public static string DynamicTranslateResourceDir = "Assets/Localization/{0}/{1}/Assets/Game/Artworks";
    public static readonly string CompressExt = ".CP";

#if UNITY_EDITOR_WIN || UNITY_STANDALONE
    public static string FileProtocol = "file:///";
#else
    public static string FileProtocol = "file://";
#endif

    public static string PersistentPathWithoutFileProtocol
    {
        get
        {
            return GameEnv.GetPersistent();// string.Format("{0}/.update/", GameEnv.GetPersistent()); // 各平台通用
        }
    }

    public static string PersistentPath
    {
        get
        {
            return FileProtocol + PersistentPathWithoutFileProtocol;
        }
    }

    public static readonly string StreamingResPath = Application.streamingAssetsPath + "/Res/";
    public static string PersistentResPath
    {
        get
        {
            return string.Format("{0}/Res/", GameEnv.GetPersistent());
        }
    }
    public static string PersistentBundlePath
    {
        get
        {
            return string.Format("{0}/Bundles/", GameEnv.GetPersistent());
        }
    }

    


    public static string ProductPathWithProtocol { get; private set; }
    public static string ProductPathWithoutFileProtocol { get; private set; }

    public static string BundlesPathRelative { get; private set; }

    public static bool TryGetPersistentUrl(string url, bool withFileProtocol, out string newUrl)
    {
        if (withFileProtocol)
            newUrl = Path.Combine(PersistentPath, url);
        else
            newUrl = Path.Combine(PersistentPathWithoutFileProtocol,url);

        if (File.Exists(newUrl))
            return true;

        return false;
    }

    public static bool TryGetStreamingUrl(string url, bool withFileProtocol, out string newUrl)
    {
        if (withFileProtocol)
            newUrl = ProductPathWithProtocol + url;
        else
            newUrl = ProductPathWithoutFileProtocol + url;

        // 除了Android的StreamingAssetPath以外，其它平台任何目录都可以直接用File类操作
#if !UNITY_EDITOR && UNITY_ANDROID
        if (!ResourceAndroidPlugin.IsAssetExists(url)) // StreamingAssetsPath在Android平台上是压缩在apk内jar包中的
            return false;
#else
        if (!File.Exists(newUrl))
            return false;
#endif


        return true;
    }

    public static string GetResourceFullPath(string url, bool withFileProtocol = true)
    {
        string fullPath;
        if (GetResourceFullPath(url, withFileProtocol, out fullPath) != GetResourceFullPathType.Invalid)
            return fullPath;
        return null;
    }

    public static GetResourceFullPathType GetResourceFullPath(string url, bool withFileProtocol, out string fullPath)
    {
        if (string.IsNullOrEmpty(url))
        {
            fullPath = null;
            return GetResourceFullPathType.Invalid;
        }

        string persistentUrl;
        bool hasPersistentUrl = TryGetPersistentUrl(url, withFileProtocol, out persistentUrl);
        if (hasPersistentUrl)
        {
            fullPath = persistentUrl;
            return GetResourceFullPathType.InPersistent;
        }

        string inStreamingUrl;
        bool hasInStreamingUrl = TryGetStreamingUrl(url, withFileProtocol, out inStreamingUrl);
        if (!hasInStreamingUrl)
        {
            fullPath = null;
            return GetResourceFullPathType.Invalid;
        }

        fullPath = inStreamingUrl;
        return GetResourceFullPathType.InStreaming;
    }

    public static bool IsResourceExist(string url)
    {
        string fullPath;
        var hasPersistentUrl = TryGetPersistentUrl(url, false, out fullPath);
        var hasStreamingUrl = TryGetStreamingUrl(url, false, out fullPath);
        return hasPersistentUrl || hasStreamingUrl;
    }

    static ResourceDef()
    {
        BundlesPathRelative = string.Format("{0}/{1}/", "Bundles", GetBuildPlatformName());

        switch (Application.platform)
        {
            case RuntimePlatform.WindowsEditor:
            case RuntimePlatform.OSXEditor:
                {
                    string editorProductPath = Path.GetFullPath("./");
                    ProductPathWithProtocol = FileProtocol + editorProductPath + "/";
                    ProductPathWithoutFileProtocol = editorProductPath + "/";
                }
                break;
            case RuntimePlatform.WindowsPlayer:
            case RuntimePlatform.OSXPlayer:
                {
                    string path = Application.streamingAssetsPath.Replace('\\', '/');
                    ProductPathWithProtocol = string.Format("{0}{1}/", FileProtocol, path);
                    ProductPathWithoutFileProtocol = string.Format("{0}/", path);
                }
                break;
            case RuntimePlatform.Android:
                {
                    ProductPathWithProtocol = string.Concat("jar:", FileProtocol, Application.dataPath, "!/assets/");
                    ProductPathWithoutFileProtocol = Application.dataPath + "!assets/";
                }
                break;
            case RuntimePlatform.IPhonePlayer:
                {
                    // MacOSX下，带空格的文件夹，空格字符需要转义成%20
                    ProductPathWithProtocol = string.Format("{0}/", System.Uri.EscapeUriString(FileProtocol + Application.streamingAssetsPath));
                    ProductPathWithoutFileProtocol = Application.streamingAssetsPath + "/";
                }
                break;
            default:
                {
                    Debug.Assert(false);
                }
                break;
        }
    }

    private static string _unityEditorEditorUserBuildSettingsActiveBuildTarget;

    public static string UnityEditor_EditorUserBuildSettings_activeBuildTarget
    {
        get
        {
            if (Application.isPlaying && !string.IsNullOrEmpty(_unityEditorEditorUserBuildSettingsActiveBuildTarget))
            {
                return _unityEditorEditorUserBuildSettingsActiveBuildTarget;
            }
            var assemblies = System.AppDomain.CurrentDomain.GetAssemblies();
            foreach (var a in assemblies)
            {
                if (a.GetName().Name == "UnityEditor")
                {
                    Type lockType = a.GetType("UnityEditor.EditorUserBuildSettings");
                    var p = lockType.GetProperty("activeBuildTarget");

                    var em = p.GetGetMethod().Invoke(null, new object[] { }).ToString();
                    _unityEditorEditorUserBuildSettingsActiveBuildTarget = em;
                    return em;
                }
            }
            return null;
        }
    }
    public static string GetBuildPlatformName()
    {
        string buildPlatformName = "Windows"; // default

        if (Application.isEditor)
        {
            var buildTarget = UnityEditor_EditorUserBuildSettings_activeBuildTarget;
            //UnityEditor.EditorUserBuildSettings.activeBuildTarget;
            switch (buildTarget)
            {
                case "StandaloneOSXIntel":
                case "StandaloneOSXIntel64":
                case "StandaloneOSXUniversal":
                    buildPlatformName = "MacOS";
                    break;
                case "StandaloneWindows": // UnityEditor.BuildTarget.StandaloneWindows:
                case "StandaloneWindows64": // UnityEditor.BuildTarget.StandaloneWindows64:
                    buildPlatformName = "Windows";
                    break;
                case "Android": // UnityEditor.BuildTarget.Android:
                    buildPlatformName = "Android";
                    break;
                case "iPhone": // UnityEditor.BuildTarget.iPhone:
                case "iOS":
                    buildPlatformName = "iOS";
                    break;
                default:
                    Debug.Assert(false);
                    break;
            }
        }
        else
        {
            switch (Application.platform)
            {
                case RuntimePlatform.OSXPlayer:
                    buildPlatformName = "MacOS";
                    break;
                case RuntimePlatform.Android:
                    buildPlatformName = "Android";
                    break;
                case RuntimePlatform.IPhonePlayer:
                    buildPlatformName = "iOS";
                    break;
                case RuntimePlatform.WindowsPlayer:
                    buildPlatformName = "Windows";
                    break;
                default:
                    Debug.Assert(false);
                    break;
            }
        }

        return buildPlatformName;
    }
}