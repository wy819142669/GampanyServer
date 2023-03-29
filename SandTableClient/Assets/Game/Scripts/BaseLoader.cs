using System.Collections.Generic;

public abstract class BaseLoader
{
    public delegate void LoaderCallBack(object resultObject);
    private readonly List<LoaderCallBack> _FinishCallBacks;
    protected LoaderMode _LoaderMode;
    public int RefCount { get; set; }
    public string Url { get; protected set; }
    public object ResultObject { get; protected set; }
    public bool IsCompleted { get; protected set; }
    public bool IsLoading { get; protected set; }
    public virtual float Progress { get; protected set; } // 0~1

    protected BaseLoader()
    {
        RefCount = 0;
        _LoaderMode = LoaderMode.Async;
        _FinishCallBacks = new List<LoaderCallBack>();
    }

    public virtual void Init(string url, LoaderMode loaderMode, params object[] args)
    {
        Url = url;
        _LoaderMode = loaderMode;
        ResultObject = null;
        IsCompleted = false;
        IsLoading = true;
        Progress = 0;
    }

    public virtual void ReInit(LoaderMode loaderMode, params object[] args)
    {
        _LoaderMode = loaderMode;
        IsLoading = true;
    }

    public void AddCallback(LoaderCallBack callback)
    {
        if (callback != null)
            _FinishCallBacks.Add(callback);
    }

    public virtual void Release()
    {
        RefCount--;
        if (RefCount <= 0 && NeedUnload())
            LoaderManager.ReleaseLoader(this);
    }

    protected void DoCallback(object resultObj)
    {
        for (int i = 0; i < _FinishCallBacks.Count; ++i)
            _FinishCallBacks[i](resultObj);
        _FinishCallBacks.Clear();
    }

    protected virtual void OnFinish(object resultObj)
    {
        ResultObject = resultObj;
        IsCompleted = true;
        IsLoading = false;
        Progress = 1f;

        DoCallback(resultObj);
    }

    public virtual void DoDispose()
    {
        ResultObject = null;
        IsCompleted = false;
        IsLoading = false;
        Progress = 0f;
    }

    public void Dispose()
    {
        DoDispose();
    }

    // 是否需要常驻内存
    public virtual bool NeedUnload()
    {
        return true;
    }
}