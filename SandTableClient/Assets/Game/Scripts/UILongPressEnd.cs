using System.Linq;
using UnityEngine;
using UnityEngine.EventSystems;
using XLua;

namespace Game.UI
{
    public class UILongPressEnd : MonoBehaviour, IPointerDownHandler, IPointerUpHandler
    {
        // 按住多久进入长按，默认1秒
        // 这种实现方式的触发时长不精确，数值设定为1时等待时间过长，目前改成0.25
        public float EnterTime = 0.25f;

        // 按下瞬时的时间
        private float _beginTime = 0f;

        // 当前的时间
        private float _curTime = 0f;

        // 长按结束回调函数
        private LuaFunction _luaEndCallback;

        // 结束回调参数
        private object[] _endParams;

        // 抬起手指回调
        private LuaFunction _luaUpCallback;

        // 抬起手指回调参数
        private object[] _upParams;

        // 是否按下
        private bool _isPress = false;

        // 是否进入过长按逻辑
        private bool _isEnteredLongPress = false;


        private void Awake()
        {
        }

        public void BindLongPressUp(LuaFunction funcCall, params object[] vevParams)
        {
            _luaUpCallback = funcCall;
            _upParams = vevParams;
        }

        public void BindLongPressEnd(LuaFunction funcCall, params object[] vevParams)
        {
            _luaEndCallback = funcCall;
            _endParams = vevParams;
        }

        public void SetLongPressEndTime(float enterTime)
        {
            EnterTime = enterTime;
        }

        public void ClearLongPressEnd()
        {
            Clear();
        }

        public void OnPointerDown(PointerEventData eventData)
        {
            StartCount();
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            EndCount();
            if (_isEnteredLongPress)
            {
                _luaUpCallback?.Call(_upParams.ToArray());
            }
            _isEnteredLongPress = false;
        }

        private void CheckLongPress()
        {
            if (_isPress && null != _luaEndCallback)
            {
                if (_curTime >= _beginTime + EnterTime)
                {
                    _luaEndCallback?.Call(_endParams.ToArray());
                    ResetEvent();
                    _isEnteredLongPress = true;
                    return;
                }

                _curTime = Time.time;
            }
        }

        private void StartCount()
        {
            _isPress = true;
            _beginTime = Time.time;
            _curTime = 0;
        }

        private void EndCount()
        {
            ResetEvent();
        }

        public void ResetEvent()
        {
            _isPress = false;
            _beginTime = 0;
            _curTime = 0;
        }

        private void Clear()
        {
            ResetEvent();
            _isEnteredLongPress = false;
            _luaEndCallback = null;
            _endParams = null;
            _luaUpCallback = null;
            _upParams = null;
        }

        private void FixedUpdate()
        {
            CheckLongPress();
        }

        private void OnDisable()
        {
            ResetEvent();
        }

        private void OnDestroy()
        {
            Clear();
        }
    }
}