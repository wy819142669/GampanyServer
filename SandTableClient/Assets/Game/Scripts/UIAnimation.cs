using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UIAnimation : MonoBehaviour
{
    public List<Sprite> _Sprites = new List<Sprite>();
    private Image _Render = null;
    public float _Interval = 0.05f; // 播放间隔时间（秒）
    public bool _Loop = true;
    private bool _IsPlaying = false;
    private float _IntervalDelta = 1; // 累积间隔时间（秒），控制播放速度，设为1是为了让第一帧不需要等待就播放
    private int _NextFrameIndex = 0; // 当前正在播第几帧，从0开始

    void Awake()
    {
        _Render = GetComponent<Image>();
        Play();
    }

    public void Play(int startFrame=0)
    {
        gameObject.SetActive(true);
        _NextFrameIndex = startFrame;
        _IsPlaying = true;
    }

    public void Stop()
    {
        _IsPlaying = false;
    }

    void Update()
    {
        if (!_IsPlaying || _Sprites == null || _Sprites.Count <= 0)
            return;

        _IntervalDelta += Time.deltaTime;
        if (_IntervalDelta < _Interval)
            return;

        _IntervalDelta = 0;
        _Render.sprite = _Sprites[_NextFrameIndex];
        _Render.SetNativeSize();

        _NextFrameIndex = (_NextFrameIndex + 1) % _Sprites.Count;

        // 最后一帧且动画不是循环播放，就结束播放
        if (_NextFrameIndex == _Sprites.Count - 1 && !_Loop)
        {
            _NextFrameIndex = 0;
            _IsPlaying = false;
            gameObject.SetActive(false);
            return;
        }
    }
}

