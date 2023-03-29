using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using XLua;


public class UIDoubleClick : MonoBehaviour, IPointerDownHandler, IDragHandler, IBeginDragHandler, IEndDragHandler
{
    // 双击间隔时长
    public float Interval = 0.2f;

    // 已点击次数
    private int _clickedCount = 0;

    // 最大点击数
    private int _maxClickCount = 2;

    // 最后一次点击的时间
    private float _lastClickTime = 0f;

    // Button组件
    private Button _button = null;

    // button是否有值
    private bool _isButtonNotNull = false;

    // 是否在拖动中
    private bool _isDragging = false;

    // 滚动视图
    public ScrollRect ScrollView = null;

    // Lua回调
    private LuaFunction _callback = null;

    // 回调参数
    private object[] _args = null;
    

    public void BindDoubleClick(LuaFunction callback, object[] args)
    {
        _callback = callback;
        _args = args;
    }

    private void OnEnable()
    {
        // 如果有button组件先把它关掉，以免响应两次单击
        if (_button == null)
        {
            _button = this.gameObject.GetComponent<Button>();
        }
        
        if (ScrollView == null)
        {
            GetScrollRect(this.transform, ref ScrollView);
        }

        _isButtonNotNull = _button != null;
        SetButtonEnable(false);
    }

    private void OnDisable()
    {
        SetButtonEnable(true);
    }

    private void Update()
    {
        // 点击了一下，且不在滚动中
        if (_clickedCount == 1 && !_isDragging)
        {
            // 计算时间差
            float intervalTime = Time.realtimeSinceStartup - _lastClickTime;
            // 如果有button组件，且下次点击时间已经超过了时间差
            if (_isButtonNotNull && intervalTime > Interval)
            {
                // 响应单击
                _button.onClick?.Invoke();
                // 重置
                _clickedCount = 0;
            }
        }
    }

    private void SetButtonEnable(bool isEnable)
    {
        if (_isButtonNotNull)
        {
            _button.enabled = isEnable;
        }
    }

    public void OnPointerDown(PointerEventData eventData)
    {
        // 计算时间差
        float intervalTime = Time.realtimeSinceStartup - _lastClickTime;
        // 记录点击次数
        _clickedCount++;
        // 如果时间差在间隔时长内，且点击了两次以上
        if (intervalTime <= Interval && _clickedCount >= _maxClickCount)
        {
            // 重置
            _clickedCount = 0;
            // 执行
            _callback?.Call(_args);
        }

        // 更新最后点击时间
        _lastClickTime = Time.realtimeSinceStartup;
    }


    public void ResetDoubleClick()
    {
        _clickedCount = 0;
        _lastClickTime = 0;
    }

    public void OnBeginDrag(PointerEventData eventData)
    {
        _isDragging = true;
        if (ScrollView != null) ScrollView.OnBeginDrag(eventData);
    }

    public void OnDrag(PointerEventData eventData)
    {
        _isDragging = true;
        if (ScrollView != null) ScrollView.OnDrag(eventData);
    }
    
    public void OnEndDrag(PointerEventData eventData)
    {
        _isDragging = false;
        ResetDoubleClick();
        if (ScrollView != null) ScrollView.OnEndDrag(eventData);
    }

    // 找滚动视图（如果有的话）
    private void GetScrollRect(Transform trans, ref ScrollRect scroll)
    {
        scroll = trans.GetComponent<ScrollRect>();
        if (scroll != null)
        {
            return;
        }
        
        if (trans.parent != null)
        {
            GetScrollRect(trans.parent, ref scroll);
        }
    }
}