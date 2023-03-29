using System;
using System.Collections.Generic;

public class LoaderManager
{
    private static readonly Dictionary<Type, Dictionary<string, BaseLoader>> _LoaderPool =
        new Dictionary<Type, Dictionary<string, BaseLoader>>();

   
    public static T GetLoader<T>(string url, BaseLoader.LoaderCallBack loaderCallBack, LoaderMode loaderMode,
        params object[] initArgs) where T : BaseLoader, new()
    {
        var t = typeof(T);
        Dictionary<string, BaseLoader> loaderPool = null;
        if (!_LoaderPool.TryGetValue(t, out loaderPool))
        {
            loaderPool = new Dictionary<string, BaseLoader>();
            _LoaderPool[t] = loaderPool;
        }

        BaseLoader loader = null;
        if (!loaderPool.TryGetValue(url, out loader))
        {
            loader = new T();
            loaderPool[url] = loader;

            loader.RefCount++;
            loader.AddCallback(loaderCallBack);
            loader.Init(url, loaderMode, initArgs);
        }
        else
        {
            if (loader.RefCount < 0)
            {
                UnityEngine.Debug.LogError(string.Format("LoaderManager", "URL[{0}] Error RefCount[{1}]!", url, loader.RefCount));
                loader.RefCount = 0;
            }
            loader.RefCount++;

            if (loader.IsCompleted)
            {
                loaderCallBack?.Invoke(loader.ResultObject);
            }
            else
            {
                loader.AddCallback(loaderCallBack);

                if (loader.IsLoading)
                {
                    // 正在异步加载（绝对不可能正在同步加载）
                    if (loaderMode == LoaderMode.Sync)
                    {
                        loader.DoDispose();
                        loader.ReInit(loaderMode, initArgs);
                    }
                }
                else
                {
                    // 已经Release掉的，要重新Init
                    loader.ReInit(loaderMode, initArgs);
                }
            }            
        }

        return loader as T;
    }

    public static void ReleaseLoader(BaseLoader loader)
    {
        // 只卸载，保留loader本身在pool里，不要每次都new
        loader?.DoDispose();
    }
}
