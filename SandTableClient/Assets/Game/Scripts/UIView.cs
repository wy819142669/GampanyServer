//using UnityEngine;
//using System;
//using XLua;
//using DG.Tweening;
//using System.Linq;
//using UnityEngine.UI;

//namespace Game.UI
//{
//    [XLua.LuaCallCSharp]
//    public class UIView : MonoBehaviour
//    {
//        public string m_luaClassName;

//        private LuaEnv m_luaState;
//        private LuaTable m_luaObj;
//        private LuaFunction m_funcOnAwake;
//        private LuaFunction m_funcOnStart;
//        private LuaFunction m_funcOnUpdate;
//        private LuaFunction m_funcOnLateUpdate;
//        private LuaFunction m_funcOnFixedUpdate;
//        private LuaFunction m_funcOnDestroy;
//        private LuaFunction m_funcOnWillRenderCanvas;
//        private LuaFunction m_funcOnEnable;
//        private LuaFunction m_funcOnDisable;
//        private LuaFunction m_funcOnPause;
//        private LuaFunction m_funcDoDestroy;

//        private UIViewAnimationScale m_ScaleAnim = null;
//        private UIViewAnimationController m_animCtrl = null;
//       // private UIViewSound m_Sound = null;

//        private bool m_Opening = false;
//        private bool m_Closing = false;

//        public LuaFunction FuncDoDestroy { get => m_funcDoDestroy; set => m_funcDoDestroy = value; }

//        void Awake()
//        {
//            m_ScaleAnim = GetComponent<UIViewAnimationScale>();
//            m_animCtrl = GetComponent<UIViewAnimationController>();
//            if (!string.IsNullOrEmpty(m_luaClassName))
//            {
//                m_luaState = CppModule._LuaEnv;
//                bool ret = Init(m_luaClassName);
//                if (!ret)
//                {
//                    LogHelper.ERROR("UIView", "Init error, luaClassname: {0}", m_luaClassName);
//                }
//                else
//                {
//                    LanguageModule.TranslatePrefab(gameObject);

//                    if (m_funcOnAwake != null)
//                        m_funcOnAwake.Call(m_luaObj, this);
//                }
//            }

//           // m_Sound = GetComponent<UIViewSound>();
//        }

//        void Start()
//        {
//            if (m_funcOnStart != null)
//                m_funcOnStart.Call(m_luaObj);
//        }

//        void Update()
//        {
//            if (m_funcOnUpdate != null)
//                m_funcOnUpdate.Call(m_luaObj);
//        }

//        private void LateUpdate()
//        {
//            if (m_funcOnLateUpdate != null)
//                m_funcOnLateUpdate.Call(m_luaObj);
//        }

//        void FixedUpdate()
//        {
//            if (m_funcOnFixedUpdate != null)
//                m_funcOnFixedUpdate.Call(m_luaObj);
//        }

//        void OnDestroy()
//        {
//            if (m_funcOnDestroy != null)
//                m_funcOnDestroy.Call(m_luaObj);
//        }

//        void OnEnable()
//        {
//            if (m_funcOnWillRenderCanvas != null)
//                Canvas.willRenderCanvases += OnWillRenderCanvas;

//            if (m_funcOnEnable != null)
//                m_funcOnEnable.Call(m_luaObj);
//        }

//        void OnDisable()
//        {
//            if (m_funcOnWillRenderCanvas != null)
//                Canvas.willRenderCanvases -= OnWillRenderCanvas;

//            if (m_funcOnDisable != null)
//                m_funcOnDisable.Call(m_luaObj);
//        }

//        private void OnApplicationPause(bool pause)
//        {
//            if (m_funcOnPause != null)
//                m_funcOnPause.Call(m_luaObj, pause);
//        }

//        private bool Init(string luaClassName)
//        {
//            // 从Ui:GetClass()中获取LuaTable
//            var tableUI = CppModule.GetGlobalTable("Ui");
//            var funcGetClass = tableUI.Get<LuaFunction>("GetClass");
//            m_luaObj = (LuaTable)(funcGetClass.Call(tableUI, luaClassName)[0]);

//            // 全局唯一LuaTable，需要解禁创建全局对象
//            //m_luaObj = m_luaState.Global.Get<LuaTable>(luaClassName);

//            if (m_luaObj == null)
//                return false;

//            m_funcOnAwake = m_luaObj.Get<LuaFunction>("OnAwake");
//            m_funcOnStart = m_luaObj.Get<LuaFunction>("OnStart");
//            m_funcOnUpdate = m_luaObj.Get<LuaFunction>("OnUpdate");
//            m_funcOnLateUpdate = m_luaObj.Get<LuaFunction>("OnLateUpdate");
//            m_funcOnFixedUpdate = m_luaObj.Get<LuaFunction>("OnFixedUpdate");
//            m_funcOnDestroy = m_luaObj.Get<LuaFunction>("OnDestroyed");
//            m_funcOnWillRenderCanvas = m_luaObj.Get<LuaFunction>("OnWillRenderCanvas");
//            m_funcOnEnable = m_luaObj.Get<LuaFunction>("OnEnable");
//            m_funcOnDisable = m_luaObj.Get<LuaFunction>("OnDisable");
//            m_funcOnPause = m_luaObj.Get<LuaFunction>("OnApplicationPause");
//            FuncDoDestroy = m_luaObj.Get<LuaFunction>("DestroyWindow");
//            return true;
//        }

//        public LuaTable GetScriptObject()
//        {
//            return m_luaObj;
//        }

//        private void OnWillRenderCanvas()
//        {
//            if (m_funcOnWillRenderCanvas != null)
//                m_funcOnWillRenderCanvas.Call(m_luaObj);
//        }

//        public void ShowAtOnce(LuaFunction funcCall, params object[] vecParams)
//        {
//            gameObject.SetActive(true);
//            funcCall?.Call(vecParams.ToArray());
//        }

//        public void Show(LuaFunction funcCall, params object[] vecParams)
//        {
//            if (m_animCtrl != null)
//            {
//                gameObject.SetActive(true);
//                m_animCtrl.PlayShow(() => { funcCall?.Call(vecParams.ToArray()); });
//            }
//            else if (m_ScaleAnim != null)
//            {
//                if (m_Closing)
//                    m_ScaleAnim.FinishHideNow();

//                m_Opening = true;
//                m_ScaleAnim.PlayShow(()=> { m_Opening = false;  gameObject.SetActive(true); funcCall?.Call(vecParams.ToArray()); });
//            }
//            else
//            {
//                gameObject.SetActive(true);
//                funcCall?.Call(vecParams.ToArray());
//            }

//            //if (m_Sound != null && m_Sound.OpenID > 0)
//            //{
//            //    UIModule.PlaySound(m_Sound.OpenID);
//            //}
//        }

//        public void HideAtOnce()
//        {
//            gameObject.SetActive(false);
//            UIModule._Instance.OnCloseUI(m_luaClassName);
//        }

//        public void Hide()
//        {
//            if (m_animCtrl != null)
//            {
//                m_animCtrl.PlayHide(() => { gameObject.SetActive(false);});
//            }
//            else if (m_ScaleAnim != null)
//            {
//                m_Closing = true;
//                m_ScaleAnim.PlayHide(() => { gameObject.SetActive(false); m_Closing = false; });
//            }
//            else
//            {
//                gameObject.SetActive(false);
//            }

//            //if (m_Sound != null && m_Sound.CloseID> 0)
//            //{
//            //    UIModule.PlaySound(m_Sound.CloseID);
//            //}

//            UIModule._Instance.OnCloseUI(m_luaClassName);
//        }

//        public void CallLuaDestroyUI(string uiName)
//        {
//            FuncDoDestroy.Call(m_luaObj, uiName);
//        }

//        public void SetGroup(int nGroup)
//        {
//            UIModule.SetGroup(gameObject, nGroup);
//        }
//    }
//}
