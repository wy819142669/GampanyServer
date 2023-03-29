// 基础控件操作

using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEngine;
using UnityEngine.Networking;
using UnityEngine.Rendering;
using UnityEngine.UI;
using XLua;

//local tbCtrlDef = {
//    OBJECT              = Ui.GameObject,
//    BUTTON              = Ui.Button,
//    TEXT                = Ui.Text,
//    IMAGE               = Ui.Image,
//    INPUT_FIELD         = Ui.InputField,
//    TOGGLE              = Ui.Toggle,
//    SLIDER              = Ui.Slider,
//    SCROLL_RECT         = Ui.ScrollRect,
//    GRID_LAYOUT_GROUP   = Ui.GridLayoutGroup,
//    RECT_TRANSFORM      = Ui.RectTransform,
//    TRANSFORM           = Ui.Transform,
//    RICH_TEXT           = Ui.RichText,
//}

namespace Game.UI
{
    [XLua.LuaCallCSharp]
    public class UIPanel : MonoBehaviour
    {
        private Dictionary<string, Transform> m_ObjectList = new Dictionary<string, Transform>();
        private Dictionary<string, Button> m_ButtonList = new Dictionary<string, Button>();
        private Dictionary<string, Text> m_TextList = new Dictionary<string, Text>();
        private Dictionary<string, Image> m_ImageList = new Dictionary<string, Image>();
        private Dictionary<string, InputField> m_InputList = new Dictionary<string, InputField>();
        private Dictionary<string, PrefabAnchor> m_PrefabAnchorList = new Dictionary<string, PrefabAnchor>();

        // // Clipping rectangle
        // [HideInInspector][SerializeField] UIDrawCall.Clipping mClipping = UIDrawCall.Clipping.None;
        // [HideInInspector][SerializeField] Vector4 mClipRange = new Vector4(0f, 0f, 300f, 200f);
        // [HideInInspector][SerializeField] Vector2 mClipSoftness = new Vector2(4f, 4f);

        // 返回当前panel的画布层级，若panel没有画布，会递归查找祖先的画布
        public int GetSortingOrder(Transform trans)
        {
            if (trans == null)
            {
                trans = transform;
            }
            var canvas = trans.GetComponent<Canvas>();
            if (canvas)
            {
                return canvas.sortingOrder;
            }
            if (trans.parent)
            {
                return GetSortingOrder(trans.parent);
            }
            return 0;
        }

        public int GetMaxSortingOrderInChildren(Transform trans)
        {
            if (trans == null)
            {
                trans = transform;
            }
            var canvasList = trans.gameObject.GetComponentsInChildren<Canvas>(true);
            var sortingGroupList = trans.gameObject.GetComponentsInChildren<SortingGroup>(true);
            int maxOrder = GetSortingOrder(trans);
            foreach(var elem in canvasList)
            {
                if  (maxOrder < elem.sortingOrder)
                {
                    maxOrder = elem.sortingOrder;
                }
            }
            foreach (var elem in sortingGroupList)
            {
                if (maxOrder < elem.sortingOrder)
                {
                    maxOrder = elem.sortingOrder;
                }
            }
            return maxOrder;
        }

        private Transform FindChild(string szKey)
        {
            if (szKey == "Main")
                return transform; // 不填写子控件名字则返回根控件
            Transform ret = null;
            if (!m_ObjectList.TryGetValue(szKey, out ret))
            {
                ret = transform.Find(szKey);
                if (ret == null)
                {
                    UnityEngine.Debug.LogError(string.Format("FindChild Error ! {0} not in {1} !!", szKey, transform.name));
                    return null;
                }
                m_ObjectList.Add(szKey, ret);
            }

            return ret;
        }

        public void SetActive(string szKey, bool bVisiable)
        {
            var child = FindChild(szKey);
            if (child == null)
                return;

            var obj = child.gameObject;
            if (obj.activeSelf != bVisiable)
                obj.SetActive(bVisiable);
        }

        public bool IsActive(string szKey)
        {
            var child = FindChild(szKey);
            if (child == null)
                return false;

            return child.gameObject.activeSelf;
        }

        public string Label_GetText(string szKey)
        {
            var comp = GetText(szKey);
            if (comp == null)
                return "";

            return comp.text;
        }

        public void Label_SetText(string szKey, string szText)
        {
            var comp = GetText(szKey);
            if (comp == null)
                return;

            comp.text = szText;
        }

        public void Label_SetChildText(string szKey, string szChildKey, string szText)
        {
            var comp = GetText(szKey + "/" + szChildKey);
            if (comp == null)
                return;

            comp.text = szText;
        }


        public void Label_SetColor(string szKey, float r, float g, float b)
        {
            var comp = GetText(szKey);
            if (comp == null)
                return;
            comp.color = new Color(r, g, b);
        }

        //public void Label_SetGradientColor(string szKey, string szColor)
        //{
        //    var comp = GetText(szKey);
        //    if (comp == null)
        //        return;

        //    string ct = szColor + "Top";
        //    string cb = szColor + "Bottom";
        //    comp.color = Color.white;
        //    comp.getco
        //    Label.applyGradient = true;
        //    Label.gradientTop = UiLoadSetting.m_ColorDefine[ct];
        //    Label.gradientBottom = UiLoadSetting.m_ColorDefine[cb];
        //}

        public void Emoji_SetText(string szKey, string szChildKey, string szText)
        {
            var comp = GetEmojiText(szKey + "/" + szChildKey);
            if (comp == null)
                return;

            comp.text = szText;
        }

        public string Input_GetText(string szKey)
        {
            var comp = GetInput(szKey);
            if (comp == null)
                return "";

            return comp.text;
        }

        public void Input_SetText(string szKey, string szText)
        {
            var comp = GetInput(szKey);
            if (comp == null)
                return;

            comp.text = szText;
        }

        public void Input_SetPlaceHolderText(string szKey, string szText)
        {
            var comp = GetText(szKey + "/Placeholder");
            if (comp == null)
                return;

            comp.text = szText;
        }

        public void Input_SetEnable(string szKey, bool bEnable)
        {
            var comp = GetInput(szKey);
            if (comp == null)
                return;
            comp.interactable = bEnable;
        }

        public void Toggle_SetChecked(string szKey, bool bChecked)
        {
            var comp = GetToggle(szKey);
            if (comp == null)
                return;

            comp.isOn = bChecked;
        }

        public bool Toggle_GetChecked(string szKey)
        {
            var comp = GetToggle(szKey);
            if (comp == null)
                return false;

            return comp.isOn;
        }

        public void Toggle_SetEnable(string szKey, bool bEnable)
        {
            var comp = GetToggle(szKey);
            if (comp == null)
                return;
            comp.interactable = bEnable;
        }

        public void Sprite_SetEnable(string szKey, bool bEnable)
        {
            var comp = GetImage(szKey);
            if (comp == null)
            {
                return;
            }

            comp.enabled = bEnable;
        }

        public void Sprite_SetSprite(string szKey, string szPath, bool bOverride)
        {
            var comp = GetImage(szKey);
            if (comp == null)
                return;

            if (string.IsNullOrEmpty(szPath))
            {
                return;
            }
            Sprite s = LoadSprite(szPath);
            _SetSprite(comp, bOverride, s);
        }
        private static Sprite LoadSprite(string path)
        {
            var texture = LoadTexture2D(path);
            var sprite = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), new Vector2(0.5f, 0.5f));
            return sprite;
        }

        private static Texture2D LoadTexture2D(string path)
        {
            var bytes = File.ReadAllBytes(path);
            Texture2D texture = null;
            texture = new Texture2D((int)100, (int)100);
            texture.LoadImage(bytes);
            return texture;
        }


        private void _SetSprite(Image c, bool o, Sprite s)
        {
            if (c == null || s == null)
                return;

            if (o)
                c.overrideSprite = s;
            else
                c.sprite = s;
        }

        public void Sprite_SetSpriteAnimation(string szKey, string szPathPrefix, int nPathPostfixLength,
            int nStartNum, int nEndNum, string szType, float fInterval = 0.05f, bool bLoop = true)
        {
            GameObject go = GetObject(szKey);
            if (go == null || string.IsNullOrEmpty(szPathPrefix) || string.IsNullOrEmpty(szType) || nStartNum > nEndNum)
                return;

            UIAnimation ani = go.GetComponent<UIAnimation>();
            if (ani == null)
                ani = go.AddComponent<UIAnimation>();
            else
                ani._Sprites.Clear();

            int nLength = nEndNum - nStartNum + 1;
            for (int i = 0; i < nLength; i++)
            {
                int nIndex = nStartNum + i;
                string szPath = szPathPrefix + nIndex.ToString().PadLeft(nPathPostfixLength, '0') + "." + szType;
                var s = LoadSprite(szPath);
                _AddAnimationSprite(s, ani);
            }
            ani._Interval = fInterval;
            ani._Loop = bLoop;
        }

        private void _AddAnimationSprite(Sprite s, UIAnimation ani)
        {
            if (ani == null || s == null)
                return;
            ani._Sprites.Add(s);
        }

        public void Sprite_SetSpriteImage(string szKey, Sprite sprite, bool bOverride)
        {
            var comp = GetImage(szKey);
            if (comp == null)
                return;

            if (bOverride)
                comp.overrideSprite = sprite;
            else
                comp.sprite = sprite;
        }

        public void Sprite_SetFill(string szKey, float fValue)
        {
            var comp = GetImage(szKey);
            if (comp == null)
                return;

            comp.fillAmount = fValue;
        }

        public void Sprite_SetNativeSize(string szKey)
        {
            var comp = GetImage(szKey);
            if (comp == null)
                return;

            comp.SetNativeSize();
        }

        public void Sprite_SetSize(string szKey, float fWidth, float fHeight)
        {
            var comp = GetImage(szKey);
            if (comp == null)
                return;

            comp.rectTransform.sizeDelta = new Vector2(fWidth, fHeight);
        }

        public void RawImage_SetImage(string szKey, Texture tex)
        {
            var comp = GetRawImage(szKey);
            if (comp == null)
                return;

            comp.texture = tex;
        }

        public void Object_SetSize(string szKey, float fWidth, float fHeight)
        {
            var rectTransform = GetRectTransform(szKey);
            if (rectTransform == null)
                return;

            rectTransform.sizeDelta = new Vector2(fWidth, fHeight);
        }

        public void Sprite_SetColor(string szKey, float nR, float nG, float nB, float nA)
        {
            var comp = GetImage(szKey);
            if (comp == null)
                return;

            comp.color = new Color(nR / 255f, nG / 255f, nB / 255f, nA / 255f);
        }


        public void Sprite_SetAlphaAnimation(string szKey, float nStart, float nEnd, float nDuration)
        {
            var comp = GetImage(szKey);
            if (comp == null)
                return;

            comp.CrossFadeAlpha(nEnd / 255f, nDuration, false);
        }

        public void Sprite_SetAlpha(string szKey, float fAlpha)
        {
            var comp = GetImage(szKey);
            if (comp == null)
                return;

            var alphaColor = Color.white;
            alphaColor.a = fAlpha;
            comp.color = alphaColor;
        }

        public void Button_SetText(string szKey, string szText, string szTextPath)
        {
            var comp = GetButton(szKey);
            if (comp == null)
                return;

            var txtTransform = comp.transform.Find(szTextPath);
            if (txtTransform == null)
            {
                UnityEngine.Debug.LogError(string.Format("Button_SetText Error ! Button={0} szTextPath={1} is not exist !!", szKey, szTextPath));
                return;
            }

            var txt = txtTransform.GetComponent<Text>();
            if (txt == null)
            {
                UnityEngine.Debug.LogError(string.Format("Button_SetText Error ! Button={0} szTextPath={1} is not Text !!", szKey, szTextPath));
                return;
            }

            txt.text = szText;
        }

        public void Button_SetEnable(string szKey, bool bEnable)
        {
            var comp = GetButton(szKey);
            if (comp == null)
                return;
            comp.interactable = bEnable;
        }

        public void Button_BindEvent(string szKey, LuaFunction funcCall, params object[] vecParams)
        {
            var comp = GetButton(szKey);
            if (comp == null)
                return;

            comp.onClick.RemoveAllListeners();
            comp.onClick.AddListener(
                delegate ()
                {
                    funcCall.Call(vecParams.ToArray());
                }
            );
        }

        public void Button_BindLongPressUp(string szKey, LuaFunction funcCall, params object[] vevParams)
        {
            GameObject go = GetObject(szKey);
            UILongPressEnd comp = go.GetComponent<UILongPressEnd>();
            if (comp == null)
            {
                comp = go.AddComponent<UILongPressEnd>();
            }
            comp.BindLongPressUp(funcCall, vevParams);
        }

        public void Button_BindLongPressEnd(string szKey, LuaFunction funcCall, params object[] vevParams)
        {
            GameObject go = GetObject(szKey);
            UILongPressEnd comp = go.GetComponent<UILongPressEnd>();
            if (comp == null)
            {
                comp = go.AddComponent<UILongPressEnd>();
            }
            comp.BindLongPressEnd(funcCall, vevParams);
        }



        public void SetLongPressEndTime(string szKey, float enterTime)
        {
            UILongPressEnd comp = TryGetComponent<UILongPressEnd>(szKey);
            comp.SetLongPressEndTime(enterTime);
        }


        public void SetDoubleClick(string szKey, LuaFunction funcCall, params object[] vevParams)
        {    
            GameObject go = GetObject(szKey);
            UIDoubleClick comp = go.GetComponent<UIDoubleClick>();
            if (comp == null)
            {
                comp = go.AddComponent<UIDoubleClick>();
            }
            
            comp.BindDoubleClick(funcCall, vevParams);
        }

        public void Scroll_BindEvent(string szKey, LuaFunction funcCall)
        {
        }

        public void Slider_BindEvent(string szKey, LuaFunction funcCall, params object[] vecParams)
        {
            var comp = GetSlider(szKey);
            if (comp == null)
            {
                return;
            }

            comp.onValueChanged.RemoveAllListeners();
            comp.onValueChanged.AddListener(
                f =>
                {
                    funcCall.Call(f, vecParams.ToArray());
                }
            );
        }

        //public void Toggle_BindEvent(string szKey, LuaFunction funcCall, params object[] vecParams)
        //{
        //    var comp = GetToggle(szKey);
        //    if (comp == null)
        //        return;

        //    comp.onValueChanged.RemoveAllListeners();

        //    var toggleRepresent = comp.GetComponent<ToggleRepresent>();
        //    if (toggleRepresent != null)
        //    {
        //        toggleRepresent.BindDefaultListener();
        //    }

        //    comp.onValueChanged.AddListener(
        //        (isOn) =>
        //        {
        //            var trans = comp.GetComponent<ButtonGroupTransition>();
        //            if (isOn == true)
        //            {
        //                //var soundCfg = comp.GetComponent<UIButtonSound>();
        //                //if (soundCfg != null && soundCfg.ClickID > 0)
        //                //{
        //                //    UIModule.PlaySound(soundCfg.ClickID);
        //                //}
        //                UIModule.PlaySound(1195);
        //                if (trans != null)
        //                {
        //                    trans.OnSelected();
        //                }
        //            }
        //            else if (trans != null)
        //            {
        //                trans.OnUnSelected();
        //            }
        //            funcCall.Call(isOn, vecParams.ToArray());
        //        }
        //    );
        //}

        public void Input_BindEvent(string szKey, LuaFunction funcCall, params object[] vecParams)
        {
            var comp = GetInput(szKey);
            if (comp == null)
                return;

            comp.onValueChanged.RemoveAllListeners();
            comp.onValueChanged.AddListener(
                (str) =>
                {
                    funcCall.Call(str, vecParams.ToArray());
                }
            );
        }

        public void Input_OnEndEdit(string szKey, LuaFunction funcCall, params object[] vecParams)
        {
            var comp = GetInput(szKey);
            if (comp == null)
                return;

            comp.onEndEdit.RemoveAllListeners();
            comp.onEndEdit.AddListener(
                (str) =>
                {
                    funcCall.Call(str, vecParams.ToArray());
                }
            );
        }

        public void Button_ClearEvent(string szKey)
        {
            var comp = GetButton(szKey);
            if (comp == null)
                return;

            comp.onClick.RemoveAllListeners();
        }

        public void ScrollRect_SetVerticalNormalizedPosition(string szKey, float fValue)
        {
            var comp = GetScrollRect(szKey);
            comp.verticalNormalizedPosition = fValue;
        }

        public float ScrollRect_GetVerticalNormalizedPosition(string szKey)
        {
            var comp = GetScrollRect(szKey);
            return comp.verticalNormalizedPosition;
        }

        public void Object_SetPosition(string szKey, Vector3 pos)
        {
            var comp = GetObject(szKey);
            comp.transform.localPosition = pos;
        }

        public float Slider_GetValue(string szKey)
        {
            var comp = GetSlider(szKey);
            if (comp == null)
                return 0;
            return comp.value;
        }

        public void Slider_SetValue(string szKey, float fValue)
        {
            var comp = GetSlider(szKey);
            if (comp == null)
                return;
            comp.value = fValue;
        }

        public void Slider_SetEnable(string szKey, bool bEnable)
        {
            var comp = GetSlider(szKey);
            if (comp == null)
                return;
            comp.interactable = bEnable;
        }

        public void Dropdown_BindEvent(string szKey, LuaFunction[] funcCall)
        {
            var comp = GetDropdown(szKey);
            if (comp == null)
                return;

            comp.onValueChanged.AddListener(
                (value) =>
                {
                    funcCall[value].Call(value);

                }
            );
        }

        public void Dropdown_AddOption(string szKey, string option)
        {
            var comp = GetDropdown(szKey);
            if (comp == null)
                return;
            if (comp.options == null)
            {
                comp.AddOptions(new List<Dropdown.OptionData>() { new Dropdown.OptionData(option) });
                return;
            }
            comp.options.Add(new Dropdown.OptionData(option));
        }

        public void Dropdown_ClearOption(string szKey)
        {
            var comp = GetDropdown(szKey);
            if (comp == null)
                return;
            comp.ClearOptions();
        }

        public void Dropdown_SetValue(string szKey, int nValue)
        {
            var comp = GetDropdown(szKey);
            if (comp == null)
                return;
            comp.value = nValue;
        }

        public void AddObject(string szKey, GameObject obj)
        {
            if (m_ObjectList.ContainsKey(szKey))
                UnityEngine.Debug.LogError(string.Format("AddObject {0} already exist in {1} replace it !!", szKey, transform.name));

            m_ObjectList[szKey] = obj.transform;
        }

        private bool CheckContain(string str1, string str2)
        {
            if (!str1.StartsWith(str2))
            {
                return false;
            }
            return (str1.Equals(str2) || str1.StartsWith(str2 + "/"));
        }

        public void DeleteObject(string szKey)
        {
            foreach (var item in m_ButtonList.ToList())
            {
                if (CheckContain(item.Key, szKey))
                {
                    m_ButtonList.Remove(item.Key);
                }
            }
            foreach (var item in m_TextList.ToList())
            {
                if (CheckContain(item.Key, szKey))
                {
                    m_TextList.Remove(item.Key);
                }
            }
            foreach (var item in m_ImageList.ToList())
            {
                if (CheckContain(item.Key, szKey))
                {
                    m_ImageList.Remove(item.Key);
                }
            }
            if (m_ObjectList.ContainsKey(szKey))
            {
                m_ObjectList[szKey].SetParent(null);
                GameObject.Destroy(m_ObjectList[szKey].gameObject);
                m_ObjectList.Remove(szKey);
            }
            foreach (var item in m_ObjectList.ToList())
            {
                if (CheckContain(item.Key, szKey))
                {
                    m_ObjectList.Remove(item.Key);
                }
            }
            foreach (var item in m_InputList.ToList())
            {
                if (CheckContain(item.Key, szKey))
                {
                    m_InputList.Remove(item.Key);
                }
            }
        }

        //只用于循环滚动列表的Clear功能，功能是删除Object的path但是不Destroy（因为Object重利用）
        public void DeleteObjectListPath(string szKey)
        {
            foreach (var item in m_ButtonList.ToList())
            {
                if (CheckContain(item.Key, szKey))
                {
                    m_ButtonList.Remove(item.Key);
                }
            }
            foreach (var item in m_TextList.ToList())
            {
                if (CheckContain(item.Key, szKey))
                {
                    m_TextList.Remove(item.Key);
                }
            }
            foreach (var item in m_ImageList.ToList())
            {
                if (CheckContain(item.Key, szKey))
                {
                    m_ImageList.Remove(item.Key);
                }
            }
            if (m_ObjectList.ContainsKey(szKey))
            {
                m_ObjectList.Remove(szKey);
            }
            foreach (var item in m_ObjectList.ToList())
            {
                if (CheckContain(item.Key, szKey))
                {
                    m_ObjectList.Remove(item.Key);
                }
            }
            foreach (var item in m_InputList.ToList())
            {
                if (CheckContain(item.Key, szKey))
                {
                    m_InputList.Remove(item.Key);
                }
            }
        }

        public bool IsObjectExist(string szKey)
        {
            if (szKey == "Main")
            {
                return true;
            }

            if (!m_ObjectList.TryGetValue(szKey, out var ret))
            {
                ret = transform.Find(szKey);
                if (ret == null)
                {
                    return false;
                }
            }

            return true;
        }

        public GameObject GetObject(string szKey)
        {
            var child = FindChild(szKey);
            if (child == null)
                return null;

            return child.gameObject;
        }

        public string CloneObject(string szKey, string szName)
        {
            var template = FindChild(szKey);
            if (template == null)
                return null;

            var obj = GameObject.Instantiate(template.gameObject, template.parent);
            obj.transform.localScale = Vector3.one;
            obj.transform.localPosition = Vector3.zero;
            obj.SetActive(true);

            if (!string.IsNullOrEmpty(szName))
                obj.name = szName;
            else
                obj.name = obj.GetInstanceID().ToString();

            string szNewKey = szKey.Replace(template.gameObject.name, obj.name);
            AddObject(szNewKey, obj);

            //UnityEngine.Debug.LogError("CloneObject Template={0} New={1}", szKey, szNewKey);

            return szNewKey;
        }

        public string CloneObjectAsSamePosition(string szKey, string szName)
        {
            var template = FindChild(szKey);
            if (template == null)
                return null;

            var obj = GameObject.Instantiate(template.gameObject, template.parent);
            obj.transform.localScale = Vector3.one;
            obj.transform.position = template.position;
            obj.SetActive(true);

            if (!string.IsNullOrEmpty(szName))
                obj.name = szName;
            else
                obj.name = obj.GetInstanceID().ToString();

            string szNewKey = szKey.Replace(template.gameObject.name, obj.name);
            AddObject(szNewKey, obj);

            //UnityEngine.Debug.LogError("CloneObject Template={0} New={1}", szKey, szNewKey);

            return szNewKey;
        }

        public RectTransform GetRectTransform(string szKey)
        {
            return TryGetComponent<RectTransform>(szKey);
        }

        public Transform GetTransform(string szKey)
        {
            var child = FindChild(szKey);
            if (child == null)
                return null;

            return child.transform;
        }

        public Button GetButton(string szKey)
        {
            if (szKey == "Main")
            {
                var c = transform.GetComponent<Button>();
                if (c == null)
                {
                    UnityEngine.Debug.LogError(string.Format("FindButton Error ! {0} is not Button !!", transform.name));
                    return null;
                }
                return c;
            }

            Button ret = null;
            if (!m_ButtonList.TryGetValue(szKey, out ret))
            {
                var t = transform.Find(szKey);
                if (t == null)
                {
                    UnityEngine.Debug.LogError(string.Format("FindButton Error ! {0} not in {1} !!", szKey, transform.name));
                    return null;
                }
                var comp = t.GetComponent<Button>();
                if (comp == null)
                {
                    UnityEngine.Debug.LogError(string.Format("FindButton Error ! {0} not Button in {1} !!", szKey, transform.name));
                    return null;
                }
                m_ButtonList.Add(szKey, comp);
                return comp;
            }
            return ret;
        }

        public Text GetText(string szKey)
        {
            if (szKey == "Main")
            {
                var c = transform.GetComponent<Text>();
                if (c == null)
                {
                    UnityEngine.Debug.LogError(string.Format("FindText Error ! {0} is not Text !!", transform.name));
                    return null;
                }
                return c;
            }

            Text ret = null;
            if (!m_TextList.TryGetValue(szKey, out ret))
            {
                var t = transform.Find(szKey);
                if (t == null)
                {
                    UnityEngine.Debug.LogError(string.Format("FindText Error ! {0} not in {1} !!", szKey, transform.name));
                    return null;
                }
                var comp = t.GetComponent<Text>();
                if (comp == null)
                {
                    UnityEngine.Debug.LogError(string.Format("FindText Error ! {0} not Text in {1} !!", szKey, transform.name));
                    return null;
                }
                m_TextList.Add(szKey, comp);
                return comp;
            }
            return ret;
        }

        public EmojiText GetEmojiText(string szKey)
        {
            return TryGetComponent<EmojiText>(szKey);
        }

        public Image GetImage(string szKey)
        {
            if (szKey == "Main")
            {
                var c = transform.GetComponent<Image>();
                if (c == null)
                {
                    UnityEngine.Debug.LogError(string.Format("FindImage Error ! {0} is not Image !!", transform.name));
                    return null;
                }
                return c;
            }

            Image ret = null;
            if (!m_ImageList.TryGetValue(szKey, out ret))
            {
                var t = transform.Find(szKey);
                if (t == null)
                {
                    UnityEngine.Debug.LogError(string.Format("FindImage Error ! {0} not in {1} !!", szKey, transform.name));
                    return null;
                }
                var comp = t.GetComponent<Image>();
                if (comp == null)
                {
                    UnityEngine.Debug.LogError(string.Format("FindImage Error ! {0} not Image in {1} !!", szKey, transform.name));
                    return null;
                }
                m_ImageList.Add(szKey, comp);
                return comp;
            }
            return ret;
        }

        public InputField GetInput(string szKey)
        {
            if (szKey == "Main")
            {
                var c = transform.GetComponent<InputField>();
                if (c == null)
                {
                    UnityEngine.Debug.LogError(string.Format("FindInputField Error ! {0} is not InputField !!", transform.name));
                    return null;
                }
                return c;
            }

            InputField ret = null;
            if (!m_InputList.TryGetValue(szKey, out ret))
            {
                var t = transform.Find(szKey);
                if (t == null)
                {
                    UnityEngine.Debug.LogError(string.Format("FindInputField Error ! {0} not in {1} !!", szKey, transform.name));
                    return null;
                }
                var comp = t.GetComponent<InputField>();
                if (comp == null)
                {
                    UnityEngine.Debug.LogError(string.Format("FindInputField Error ! {0} not InputField in {1} !!", szKey, transform.name));
                    return null;
                }
                m_InputList.Add(szKey, comp);
                return comp;
            }
            return ret;
        }

        public Toggle GetToggle(string szKey)
        {
            if (szKey == "Main")
            {
                var c = transform.GetComponent<Toggle>();
                if (c == null)
                {
                    UnityEngine.Debug.LogError(string.Format("FindToggle Error ! {0} is not Toggle !!", transform.name));
                    return null;
                }
                return c;
            }
            return TryGetComponent<Toggle>(szKey);
        }

        public RawImage GetRawImage(string szKey)
        {
            if (szKey == "Main")
            {
                var c = transform.GetComponent<RawImage>();
                if (c == null)
                {
                    UnityEngine.Debug.LogError(string.Format("FindRawImage Error ! {0} is not Toggle !!", transform.name));
                    return null;
                }
                return c;
            }
            return TryGetComponent<RawImage>(szKey);
        }

        public Slider GetSlider(string szKey)
        {
            return TryGetComponent<Slider>(szKey);
        }

        public ScrollRect GetScrollRect(string szKey)
        {
            return TryGetComponent<ScrollRect>(szKey);
        }

        public GridLayoutGroup GetGridLayoutGroup(string szKey)
        {
            return TryGetComponent<GridLayoutGroup>(szKey);
        }

        public UILongPressEnd GetLongPressEnd(string szKey)
        {
            return TryGetComponent<UILongPressEnd>(szKey);
        }

        public Dropdown GetDropdown(string szKey)
        {
            return TryGetComponent<Dropdown>(szKey);
        }

        public UIDoubleClick GetDoubleClick(string szKey)
        {
            return TryGetComponent<UIDoubleClick>(szKey);
        }
        
        private T TryGetComponent<T>(string szKey)
        {
            var child = FindChild(szKey);
            if (null == child)
            {
                return default;
            }

            var comp = child.GetComponent<T>();
            if (null == comp)
            {
                UnityEngine.Debug.LogError(string.Format("Find {0} Error ! {1} not {2} !!", typeof(T).Name, szKey, typeof(T).Name));
                return default;
            }

            return comp;
        }

        public void SetScale(string szKey, float fScale)
        {
            var child = FindChild(szKey);
            if (child == null)
                return;

            child.localScale = Vector3.one * fScale;
        }

        public void ContentSizeFitter_Refresh(string szKey)
        {
            var child = FindChild(szKey);
            if (child == null)
                return;

            var fitter = child.GetComponent<ContentSizeFitter>();
            if (fitter != null)
            {
                RectTransform comp = child.GetComponent<RectTransform>();
                LayoutRebuilder.ForceRebuildLayoutImmediate(comp);
            }
        }

        public int GetPanelSortingOrder()
        {
            var obj = gameObject;
            if (obj == null)
                return 0;
            var canvas = obj.GetComponent<Canvas>();
            if (canvas != null)
            {
                return canvas.sortingOrder;
            }
            return 0;
        }

        public void SetPanelSortingOrder(int nOrder)
        {
            var obj = gameObject;
            if (obj == null)
                return;
            var canvas = obj.GetComponent<Canvas>();
            if (canvas != null)
            {
                canvas.sortingOrder = nOrder;
            }
        }

        //public void SetDealEmojiInputLimit(string szKey, int nLimitNum)
        //{
        //    var obj = transform;
        //    UIDealEmojiInput comp = null;
        //    if (szKey == "Main")
        //    {
        //        comp = obj.GetComponent<UIDealEmojiInput>();
        //        if (null == comp)
        //        {
        //            UnityEngine.Debug.LogError(string.Format("{0} Find UIDealEmojiInput Error !!!", transform.name));
        //            return;
        //        }

        //        comp.characterLimit = nLimitNum;
        //        return;
        //    }

        //    comp = TryGetComponent<UIDealEmojiInput>(szKey);
        //    comp.characterLimit = nLimitNum;
        //}

        public PrefabAnchor GetPrefabAnchor(string szKey)
        {
            if (szKey == "Main")
            {
                var c = transform.GetComponent<PrefabAnchor>();
                if (c == null)
                {
                    UnityEngine.Debug.LogError(string.Format("Find PrefabAnchor Error ! {0} is not PrefabAnchor !!", transform.name));
                    return null;
                }
                return c;
            }

            PrefabAnchor ret = null;
            if (!m_PrefabAnchorList.TryGetValue(szKey, out ret))
            {
                var t = transform.Find(szKey);
                if (t == null)
                {
                    UnityEngine.Debug.LogError(string.Format("Find PrefabAnchor Error ! {0} not in {1} !!", szKey, transform.name));
                    return null;
                }
                var comp = t.GetComponent<PrefabAnchor>();
                if (comp == null)
                {
                    UnityEngine.Debug.LogError(string.Format("Find PrefabAnchor Error ! {0} not Image in {1} !!", szKey, transform.name));
                    return null;
                }
                m_PrefabAnchorList.Add(szKey, comp);
                return comp;
            }
            return ret;
        }

        public void CreatePrefabByAnchor(string szKey)
        {
            PrefabAnchor anchor = GetPrefabAnchor(szKey);
            anchor.Create();
        }

        //private void InitChildWnd(Transform child)
        //{
        //    //// 如果这个窗口是组件的根，则初始化这个组件，组件下的窗口不予管理
        //    //WndCom WndCom = child.GetComponent<WndCom>();
        //    //if (WndCom != null)
        //    //{
        //    //    WndCom.Init(child.name, this, szExtName);
        //    //}
        //    //else
        //    //{
        //    //    foreach (Transform t in child)
        //    //    {
        //    //        InitChildWnd(t, szExtName);
        //    //    }
        //    //}

        //    //if (!m_WndList.ContainsKey(child.name))
        //    //    m_WndList[child.name] = child;

        //    if (!m_WndList.ContainsKey(child.name))
        //    {
        //        DebugEx.LogError(child.name);
        //        m_WndList[child.name] = child;
        //    }
        //}

        //         public UIDrawCall.Clipping clipping
        //         {
        //             get
        //             {
        //                 return mClipping;
        //             }
        //             set
        //             {
        //                 if (mClipping != value)
        //                 {
        //                     mResized = true;
        //                     mClipping = value;
        //                     mMatrixFrame = -1;
        // #if UNITY_EDITOR
        //                     if (!Application.isPlaying) UpdateDrawCalls();
        // #endif
        //                 }
        //             }
        //         }
        
        //在UI上显示网页
        //param:
        //    key : 该网页UI对象的路径
        //    url : 网址
        //    pageIndex: 分页值,填0~n, 不同分页之间可以切换
        //    type: 0-默认值,代表该url为一般网址,可以直接加载;  1-代表该url是小青sdk生成的数据,需要解析后取出html content来显示
        public void ShowUrl(string key, string url, int pageIndex, int type)
        {
            //UniWebViewProxy webView = TryGetComponent<UniWebViewProxy>(key);
            //if (webView == null)
            //{
            //    Debug.LogError("Can not find comp uniwebviewproxy in " + key);
            //    return;
            //}

            //switch (type)
            //{
            //    case 0:
            //        webView.SetUrl(url, pageIndex);
            //        break;
            //    case 1:
            //        //小青SDK,该网址对应的是一段json格式的数据,需要读取出来抽取html信息再显示
            //        CoroutineManager.StartCor(SetXiaoQingHtmlContent(webView, url, pageIndex));
            //        break;
            //}
        }

        //小青web的内容格式定义
        [System.Serializable]
        private class XiaoQingWebDef
        {
            [System.Serializable]
            public class Data
            {
                public int id;
                public int catid;
                public string title;
                public string style;
                public string thumb;
                public string keywords;
                public string description;
                public string url;
                public int listorder;
                public int islink;
                public long inputTime;
                public long updateTime;
                public string content;
            }

            public int code;
            public string msg;
            public Data[] data;
        }


        public void SetAsLastSibling(string key)
        {
            Transform trns = GetTransform(key);
            trns.SetAsLastSibling();
        }

        private void OnDestroy()
        {
            Image[] sprs = GetComponentsInChildren<Image>(true);
            if (sprs != null)
            {
                //设置为null以释放关联的sprite类AB
                foreach (var sprRender in sprs)
                {
                    sprRender.sprite = null;
                }
            }
        }
    }
}