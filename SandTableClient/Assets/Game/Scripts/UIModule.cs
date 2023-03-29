//using UnityEngine;
//using System.Collections.Generic;
//using XLua;
//using System.Linq;
//using Game.UI;
//using System.Collections;
//using System;
//using ypzxAudioEditor;
//using UnityEngine.Rendering;
//using UnityEngine.UI;

//#if !UNITY_EDITOR && UNITY_IOS
//using UnityEngine.iOS;
//#endif

//[XLua.LuaCallCSharp]
//public class UIModule : MonoBehaviour
//{
//    public const string UI_VIEW_PATH = "ui/views/";
//    public const string EVENT_PREFAB = "InternalRes/EventSystem";
//    public const string UI_CAMERA_PREFAB = "InternalRes/UICamera";
//    public const string UI_LOG_VIEW = "InternalRes/UILogView";
//    public const string UI_CRASH_VIEW = "InternalRes/UICrashView";
//    public static UIModule _Instance = null;
//    private static Camera _Camera = null;
//    public static UIStartUp _StartUI = null;
//    public static GameObject _MsgBox = null;
//    private static Dictionary<string, UIView> _UIViewMap = new Dictionary<string, UIView>();
//    private static EventReference _EventReference = null;
//    private static GameObject FpsCounter = null;
//    private static Transform _UIGroup1 = null;
//    private static Transform _UIGroup2 = null;

//    // 低端机型现在会在关闭UI时开启一个协程，20S后如果没有再开启该UI，则释放掉UI资源以回收内存
//    private Dictionary<string, Coroutine> _DestroyCoroutine = new Dictionary<string, Coroutine>(); // 协程集合

//    private enum OpAfterLoaded
//    {
//        Show,
//        Hide,
//    }

//    public static Camera UICamera()
//    {
//        return _Camera;
//    }


//    public static IEnumerator Init()
//    {
//        var obj = new GameObject("UIModule");
//        obj.transform.position = new Vector3(1000, 1000, 0); // 为了在场景视图下UI不挡住场景
//        obj.layer = LayerMask.NameToLayer("UI");
//        obj.AddComponent<UIModule>();
//        GameObject.DontDestroyOnLoad(obj);
//        _EventReference = new EventReference();
//        ShowStartUI();

//        var group1 = new GameObject("Group1");
//        group1.transform.SetParent(obj.transform);
//        group1.layer = LayerMask.NameToLayer("UI");
//        group1.ResetTransform();
//        _UIGroup1 = group1.transform;

//        var group2 = new GameObject("Group2");
//        group2.transform.SetParent(obj.transform);
//        group2.layer = LayerMask.NameToLayer("UI");
//        group2.ResetTransform();
//        _UIGroup2 = group2.transform;

//        yield return null;
//    }

//    void Awake()
//    {
//        _Instance = this;

//        var eventObject = GameObject.Instantiate<GameObject>(Resources.Load<GameObject>(EVENT_PREFAB));
//        eventObject.transform.SetParent(gameObject.transform);
//        eventObject.transform.localPosition = Vector3.zero;
//        eventObject.transform.localRotation = Quaternion.identity;
//        eventObject.transform.localScale = Vector3.one;

//        var cameraGo = GameObject.Instantiate<GameObject>(Resources.Load<GameObject>(UI_CAMERA_PREFAB));
//        cameraGo.transform.SetParent(gameObject.transform);
//        cameraGo.transform.localPosition = Vector3.zero;
//        cameraGo.transform.localRotation = Quaternion.identity;
//        cameraGo.transform.localScale = Vector3.one;
//        _Camera = cameraGo.GetComponent<Camera>();

//        if (GameEnv.bHasDebugParam && GameEnv.bDebugOpenLogView)
//        {
//            var UILogView = GameObject.Instantiate<GameObject>(Resources.Load<GameObject>(UI_LOG_VIEW));
//            UILogView.transform.SetParent(gameObject.transform);
//            UILogView.layer = LayerMask.NameToLayer("UI");
//            var canvas = UILogView.GetComponent<Canvas>();
//            if (canvas != null)
//            {
//                canvas.worldCamera = _Camera;
//                canvas.sortingLayerName = "UI";
//                canvas.planeDistance = 8.66f;
//            }
//        }

//    }

//    public static void ShowStartUI()
//    {
//        UnityEngine.Object go = Resources.Load("InternalRes/UIStartUp", typeof(UnityEngine.GameObject));
//        GameObject uiObj = Instantiate(go) as GameObject;
//        GameObject.DontDestroyOnLoad(uiObj);
//        uiObj.transform.localScale = Vector3.one;
//        uiObj.transform.localRotation = Quaternion.identity;
//        uiObj.transform.localPosition = Vector3.zero;
//        _StartUI = uiObj.GetComponent<UIStartUp>();
//        uiObj.SetActive(true);
//    }

//    public static void CloseStartUI()
//    {
//        if (_StartUI == null)
//            return;
//        GameObject.DestroyImmediate(_StartUI.gameObject);
//        _StartUI = null;
//    }

//    public static void SetResolution(int width, int height, bool fullscreen)
//    {
//        Screen.SetResolution(width, height, fullscreen);
//    }

//    public static void ShowMsgBox(string szMsg, string szCenterText, Action fnCenter)
//    {
//        if (_MsgBox == null)
//        {
//            UnityEngine.Object go = Resources.Load("InternalRes/UISysMessageBox", typeof(UnityEngine.GameObject));
//            _MsgBox = Instantiate(go) as GameObject;
//            GameObject.DontDestroyOnLoad(_MsgBox);
//        }
        
//        var msgBox = _MsgBox.GetComponent<UISysMessageBox>();
//        msgBox.Reset();
//        msgBox.btnList[(int)UISysMessageBox.BtnType.OK].gameObject.SetActive(false);
//        msgBox.btnList[(int)UISysMessageBox.BtnType.Cancer].gameObject.SetActive(false);
//        msgBox.btnList[(int)UISysMessageBox.BtnType.Center].gameObject.SetActive(true);
//        msgBox.SetBtnAction(null, null, fnCenter);
//        msgBox.SetBtnLabel("", "", szCenterText);
//        msgBox.SetMsg(szMsg);
//        _MsgBox.SetActive(true);
//    }

//    public static void ShowMsgBox2(string szMsg, string szOKText, string szCancerText, Action fnOK, Action fnCancer)
//    {
//        if (_MsgBox == null)
//        {
//            UnityEngine.Object go = Resources.Load("InternalRes/UISysMessageBox", typeof(UnityEngine.GameObject));
//            _MsgBox = Instantiate(go) as GameObject;
//            GameObject.DontDestroyOnLoad(_MsgBox);
//        }
//        var msgBox = _MsgBox.GetComponent<UISysMessageBox>();
//        msgBox.Reset();
//        msgBox.btnList[(int)UISysMessageBox.BtnType.OK].gameObject.SetActive(true);
//        msgBox.btnList[(int)UISysMessageBox.BtnType.Cancer].gameObject.SetActive(true);
//        msgBox.btnList[(int)UISysMessageBox.BtnType.Center].gameObject.SetActive(false);
//        msgBox.SetBtnAction(fnOK, fnCancer, null);
//        msgBox.SetBtnLabel(szOKText, szCancerText, "");
//        msgBox.SetMsg(szMsg);
//        _MsgBox.SetActive(true);
//    }

//    public static void CloseMsgBox()
//    {
//        if (_MsgBox == null)
//        {
//            return;
//        }
//        _MsgBox.SetActive(false);
//    }

//    public static bool IsMsgBoxShow()
//    {
//        if (_MsgBox != null)
//            return _MsgBox.activeSelf;
//        return false;
//    }

//    public static void OnStartUILoadingProgress(int nProgress)
//    {
//        _StartUI.OnLoadingProgress(nProgress);
//    }
//    public static void OnStartUILoadingProgress(float fProgress)
//    {
//        _StartUI.SetLoadingProgress(fProgress);
//    }

//    public static void OnStartUILoadingFinished()
//    {
//        _StartUI.OnLoadingFinished();
//    }

//    private static UIView GetUI(string uiName)
//    {
//        if (_UIViewMap.ContainsKey(uiName))
//        {
//            return _UIViewMap[uiName];
//        }
//        return null;
//    }

//    private Coroutine GetDestoryCoroutine(string uiName)
//    {
//        if (_DestroyCoroutine.ContainsKey(uiName))
//        {
//            return _DestroyCoroutine[uiName];
//        }
//        return null;
//    }

//    public static void PreloadUIAsync(string uiName, LuaFunction funcCall, params object[] vecParams)
//    {
//        UnRegisteAutoDestroy(uiName);

//        var ui = GetUI(uiName);
//        if (ui != null)
//        {
            
//            ui.Show(funcCall, vecParams);
//            return;
//        }

//        LoadResourceAsync(uiName, funcCall, vecParams);
//    }

//    public static void PreloadUI(string uiName, LuaFunction funcCall, params object[] vecParams)
//    {
//        UnRegisteAutoDestroy(uiName);

//        var ui = GetUI(uiName);
//        if (ui != null)
//        {
//            ui.Show(funcCall, vecParams);
//            return;
//        }
//        LoadResource(uiName, funcCall, vecParams);
//        if (funcCall != null)
//            funcCall.Dispose();
//    }

//    private static void UnRegisteAutoDestroy(string uiName)
//    {
//        var destroyCoroutine = _Instance.GetDestoryCoroutine(uiName);
//        if (destroyCoroutine != null)
//        {
//            _Instance.StopCoroutine(destroyCoroutine);
//            _Instance._DestroyCoroutine.Remove(uiName);
//        }
//    }

//    public void OnCloseUI(string uiName)
//    {
//        if (QualityModule.CheckUseAutoDestroyUI() && UISetting.EnableAutoDeleteOnLowPreset(uiName))
//        {
//            UnRegisteAutoDestroy(uiName);
//            _DestroyCoroutine[uiName] = StartCoroutine(DestroyByTime(uiName));
//        }
//    }

//    private IEnumerator DestroyByTime(string uiName)
//    {
//        yield return new WaitForSeconds(QualityModule.GetUseAutoDestroyUIDelay());
//        if (QualityModule.CheckUseAutoDestroyUI())
//        {
//            DebugEx.Log("<color=#D00000>Destroy(" + uiName + ")</color>");
//            // 这里通过lua调用销毁，因为要同时销毁lua里面的对象
//            var ui = GetUI(uiName);
//            if (ui != null)
//            {
//                ui.CallLuaDestroyUI(uiName);
//            }
//            _DestroyCoroutine.Remove(uiName);
//        }
//    }

//    public static void DestroyUI(string uiName)
//    {
//        DebugEx.Log("<color=#D0D000>DestroyUI(" + uiName + ")</color>");
//        UnRegisteAutoDestroy(uiName);
//        var ui = GetUI(uiName);
//        if (ui != null)
//        {
//            ui.gameObject.transform.SetParent(null);
//            GameObject.Destroy(ui.gameObject);
//            _UIViewMap.Remove(uiName);
//            return;
//        }
//    }

//    public void Clear()
//    {
//        StopAllCoroutines();
//        _DestroyCoroutine.Clear();

//        foreach (var pair in _UIViewMap)
//        {
//            try
//            {
//                GameObject.Destroy(pair.Value.gameObject);
//            }
//            catch (System.Exception e)
//            {
//                LogHelper.ERROR("UIModule", "Failed to clear ui: " + e.ToString());
//            }
//        }
//        _UIViewMap.Clear();
//    }

//    private static void LoadResourceAsync(string uiName, LuaFunction funcCall, params object[] vecParams)
//    {
//        string path = UI_VIEW_PATH + uiName + ".prefab";

//        ResourceModule.LoadResourceAsync(true, path, (obj, param) =>
//        {
//            if (obj == null)
//            {
//                LogHelper.ERROR("UIModule", "{0} LoadResource Failed!", path);
//                return;
//            }

//            var prefab = obj as GameObject;
//            if (prefab == null)
//            {
//                LogHelper.ERROR("UIModule", "Failed to load ui prefab:" + uiName);
//                return;
//            }

//            var go = GameObject.Instantiate(prefab, _Instance.gameObject.transform) as GameObject;
//            if (go == null)
//            {
//                LogHelper.ERROR("UIModule", "Failed to Instantiate prefab:" + uiName);
//                return;
//            }
//            if (ResourceModule._ManualRefUI)
//            {
//                go.AddComponent<ResourceInfo>().SetInfo(uiName, prefab);
//            }

//            go.name = uiName;
//            go.transform.rectTransform();

//            var ui = go.GetComponent<UIView>();
//            if (ui == null)
//            {
//                LogHelper.ERROR("UIModule", "Failed to find an ui component derived from UILuaView at the root node of prefab:" + uiName);
//                return;
//            }

//            var canvas = go.GetComponent<Canvas>();
//            if (canvas != null)
//            {
//                canvas.worldCamera = _Camera;
//                canvas.sortingLayerName = "UI";
//                canvas.planeDistance = 8.66f;
//            }

//            _UIViewMap[uiName] = ui;

//            ui.Show(funcCall, vecParams);
//        }, null);
//    }

//    private static void LoadResource(string uiName, LuaFunction funcCall, params object[] vecParams)
//    {
//        string path = UI_VIEW_PATH + uiName + ".prefab";

//        var obj = ResourceModule.LoadResourceSync(path);
//        if (obj == null)
//        {
//            LogHelper.ERROR("UIModule", "{0} LoadResourceSync Failed!", path);
//            return;
//        }

//        var prefab = obj as GameObject;
//        if (prefab == null)
//        {
//            LogHelper.ERROR("UIModule", "Failed to load ui prefab:" + uiName);
//            return;
//        }

//        var go = GameObject.Instantiate(prefab, _Instance.gameObject.transform) as GameObject;
//        if (go == null)
//        {
//            LogHelper.ERROR("UIModule", "Failed to Instantiate prefab:" + uiName);
//            return;
//        }
//        if (ResourceModule._ManualRefUI)
//        {
//            go.AddComponent<ResourceInfo>().SetInfo(uiName, prefab);
//        }

//        go.name = uiName;
//        go.ResetTransform();

//        var ui = go.GetComponent<UIView>();
//        if (ui == null)
//        {
//            LogHelper.ERROR("UIModule", "Failed to find an ui component derived from UILuaView at the root node of prefab:" + uiName);
//            return;
//        }

//        var canvas = go.GetComponent<Canvas>();
//        if (canvas != null)
//        {
//            canvas.worldCamera = _Camera;
//            canvas.sortingLayerName = "UI";
//            canvas.planeDistance = 8.66f;

//            int nOldSortOrder = canvas.sortingOrder;
//            int nNewSortOrder = UISetting.GetUISortingOrder(obj.name);
//            if (nNewSortOrder != -100 && nOldSortOrder != nNewSortOrder)
//            {
//                Canvas[] allCanvasChild = go.GetComponentsInChildren<Canvas>(true);
//                foreach (Canvas child in allCanvasChild)
//                {
//                    int nDiff = child.sortingOrder - nOldSortOrder;
//                    child.sortingOrder = nDiff + nNewSortOrder;
//                }

//                SortingGroup[] allSortingGroupChild = go.GetComponentsInChildren<SortingGroup>(true);
//                foreach (SortingGroup child in allSortingGroupChild)
//                {
//                    int nDiff = child.sortingOrder - nOldSortOrder;
//                    child.sortingOrder = nDiff + nNewSortOrder;
//                }

//                Renderer[] allSpriteRendererChild = go.GetComponentsInChildren<Renderer>(true);
//                foreach (Renderer child in allSpriteRendererChild)
//                {
//                    int nDiff = child.sortingOrder - nOldSortOrder;
//                    child.sortingOrder = nDiff + nNewSortOrder;
//                }

//                SpriteMask[] allSpriteMaskChild = go.GetComponentsInChildren<SpriteMask>(true);
//                foreach (SpriteMask child in allSpriteMaskChild)
//                {
//                    int nFrontDiff = child.frontSortingOrder - nOldSortOrder;
//                    int nBackDiff  = child.backSortingOrder  - nOldSortOrder;
//                    child.frontSortingOrder = nFrontDiff + nNewSortOrder;
//                    child.backSortingOrder  = nBackDiff  + nNewSortOrder;
//                }
//            }
//        }

//#if UNITY_EDITOR || UNITY_STANDALONE
//        var buttonList = go.GetComponentsInChildren<Button>(true);
//        var nav = new UnityEngine.UI.Navigation();
//        nav.mode = UnityEngine.UI.Navigation.Mode.None;
//        foreach (var btn in buttonList)
//        {
//            btn.navigation = nav;
//        }
//#endif

//        _UIViewMap[uiName] = ui;

//        ui.Show(funcCall, vecParams);
//    }

//    public static Vector2 ScreenPointToLocalPointInRectangle(RectTransform trans, Vector2 screenPoint)
//    {
//        Vector2 ret = Vector2.zero;
//        RectTransformUtility.ScreenPointToLocalPointInRectangle(trans, screenPoint, _Camera, out ret);
//        return ret;
//    }

//    public static void PlaySound(int nSoundID)
//    {
//        _EventReference.targetEventId = nSoundID;
//        AudioModule.PlaySound(_Instance.gameObject, _EventReference);
//    }

//    public static void StopSound(int nSoundID)
//    {
//        _EventReference.targetEventId = nSoundID;
//        AudioModule.StopSound(_Instance.gameObject, _EventReference);
//    }

//    public static void SetGroup(GameObject obj, int nGroup)
//    {
//        if (nGroup == 1)
//        {
//            obj.transform.SetParent(_UIGroup1);
//            obj.ResetTransform();
//        }
//        else if (nGroup == 2)
//        {
//            obj.transform.SetParent(_UIGroup2);
//            obj.ResetTransform();
//        }
//    }

//    public static void SetGroupActive(int nGroup, bool bActive)
//    {
//        if (nGroup == 1)
//        {
//            _UIGroup1.gameObject.SetActive(bActive);
//        }
//        else if (nGroup == 2)
//        {
//            _UIGroup2.gameObject.SetActive(bActive);
//        }
//    }
//    public static UIDlcDebug CreateDlcDebugUI()
//    {
//        UnityEngine.Object go = Resources.Load("InternalRes/UIDlcDebug", typeof(UnityEngine.GameObject));
//        var dlcGO = Instantiate(go) as GameObject;
//        GameObject.DontDestroyOnLoad(dlcGO);
//        return dlcGO.GetComponent<UIDlcDebug>();
//    }




//    public static void ShowMsgBox_BeforeStart(Action fnOK, Action fnCancer)
//    {
//        if (_MsgBox == null)
//        {
//            UnityEngine.Object go = Resources.Load("InternalRes/UISysMessageBox_BeforeStart", typeof(UnityEngine.GameObject));
//            _MsgBox = Instantiate(go) as GameObject;
//            GameObject.DontDestroyOnLoad(_MsgBox);
//        }
//        var msgBox = _MsgBox.GetComponent<UISysMessageBox>();
//        msgBox.Reset();
//        msgBox.btnList[(int)UISysMessageBox.BtnType.OK].gameObject.SetActive(true);
//        msgBox.btnList[(int)UISysMessageBox.BtnType.Cancer].gameObject.SetActive(true);
//        msgBox.btnList[(int)UISysMessageBox.BtnType.Center].gameObject.SetActive(false);
//        msgBox.SetBtnAction(fnOK, fnCancer, null);
//        _MsgBox.SetActive(true);
//    }

//    public static bool _isShowBeforeBox = false;
//    public static IEnumerator WarnningDialogBeforeStart()
//    {
//        _isShowBeforeBox = true;
//        ShowMsgBox_BeforeStart(
//            () =>
//            {
//                _isShowBeforeBox = false;
//            },
//            () =>
//            {
//#if UNITY_EDITOR
//                UnityEditor.EditorApplication.isPlaying = false;
//                Application.Quit();
//#endif
//                Application.Quit();
//            });

//        while (_isShowBeforeBox)
//            yield return null;
//    }

//    public static void DestroyMsgBoxBeforeStart()
//    {
//        if (_MsgBox == null)
//        {
//            return;
//        }
//        _MsgBox.SetActive(false);
//        DestroyImmediate(_MsgBox);
//        _MsgBox = null;
//    }
//}
