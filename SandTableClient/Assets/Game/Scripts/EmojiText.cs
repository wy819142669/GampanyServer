using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;


public interface ClickableText
{
    void OnClick(PointerEventData e);
}

public class EmojiText : Text, ClickableText
{
    private class HrefInfo
    {
        public int startIndex;

        public int endIndex;

        public string name;

        public readonly List<Rect> boxes = new List<Rect>();
    }

    public struct EmojiInfo
    {
        public float x;
        public float y;
        public float size;
    }
    // group0：整体
    // group1：<a href=[^>\n\s]+>或<color=#.+?>，这一组是需要被排除的
    // group2：#[0-9]+或#v7u2ic5e，这一组是需要被匹配的
    private static Regex regex = new Regex(@"(<a href=[^>\n\s]+>|<color=#.+?>)|(#[0-9]+|#v7u2ic5e)");    //#v7u2ic5e为特定语音图标
    private static readonly Regex s_HrefRegex = new Regex(@"<a href=([^>\n\s]+)>(.*?)(</a>)", RegexOptions.Singleline);

    protected static readonly StringBuilder s_buffer = new StringBuilder();
    private static Dictionary<string, EmojiInfo> EmojiIndex = null;

    protected float _iconScaleOfDoubleSymbole = 0.5f;
    protected string parsedText;

    private float _customScaleRate = 1.1f; //现在表情默认Mesh用的是‘口’字的Mesh，这里可以对Mesh进行放大
    private float customScaleWidthOffset = 0.0f;
    private float customScaleHeightOffset = 0.0f;

    public delegate void ClickLinkAction(string param);

    public ClickLinkAction onClickLink;

    private readonly List<HrefInfo> m_HrefInfos = new List<HrefInfo>();

    public override float preferredWidth =>
        cachedTextGeneratorForLayout.GetPreferredWidth(parsedText, GetGenerationSettings(rectTransform.rect.size)) /
        pixelsPerUnit;

    public override float preferredHeight =>
        cachedTextGeneratorForLayout.GetPreferredHeight(parsedText, GetGenerationSettings(rectTransform.rect.size)) /
        pixelsPerUnit;

    public override string text {
        get => this.m_Text;
        set
        {
            if (string.IsNullOrEmpty(value))
            {
                if (string.IsNullOrEmpty(this.m_Text))
                    return;
                this.m_Text = "";
                this.SetVerticesDirty();
            }
            else
            {
                if (this.m_Text == value)
                    return;

                if (supportRichText)
                {
                    loadConfig();
                }
                
                this.m_Text = value;
                parsedText = ParseHref(this.m_Text);
                parsedText = ParseEmoji(parsedText);
                
                this.SetVerticesDirty();
                this.SetLayoutDirty();
            }
        }
    }
    protected readonly Dictionary<int, EmojiInfo> m_emojiDic = new Dictionary<int, EmojiInfo>();

    protected readonly UIVertex[] m_TempVerts = new UIVertex[4];
    private List<RaycastResult> results;
    private string current;

    public static Dictionary<string, EmojiInfo> GetConfig()
    {
        loadConfig();
        return EmojiIndex;
    }

    protected static void loadConfig()
    {
        if (EmojiIndex == null)
        {
            EmojiIndex = new Dictionary<string, EmojiInfo>();

            //load emoji data, and you can overwrite this segment code base on your project.
            TextAsset emojiContent = Resources.Load<TextAsset>("InternalRes/Emoji/emoji");

            string[] lines = emojiContent.text.Split('\n');
            for (int i = 1; i < lines.Length; i++)
            {
                if (!string.IsNullOrEmpty(lines[i]))
                {
                    string[] strs = lines[i].Split('\t');
                    EmojiInfo info;
                    info.x = float.Parse(strs[3]);
                    info.y = float.Parse(strs[4]);
                    info.size = float.Parse(strs[5]);
                    EmojiIndex.Add(strs[1], info);
                }
            }

            Resources.UnloadAsset(emojiContent);
        }
    }

    /// <summary>
    /// 换掉富文本
    /// </summary>
    private string ReplaceRichText(string str)
    {
        str = Regex.Replace(str, @"<color=(.+?)>", "");
        str = str.Replace("</color>", "");
        str = Regex.Replace(str, @"<a href=(.+?)>", "");
        str = str.Replace("</a>", "");
        str = str.Replace("<b>", "");
        str = str.Replace("</b>", "");
        str = str.Replace("<i>", "");
        str = str.Replace("</i>", "");
        str = str.Replace("\n", "");
        str = str.Replace("\t", "");
        str = str.Replace("\r", "");
        str = str.Replace(" ", "");

        return str;
    }

    private string ParseHref(string content)
    {
        s_buffer.Length = 0;
        m_HrefInfos.Clear();
        var indexText = 0;
        foreach (Match match in s_HrefRegex.Matches(content))
        {
            string subStr = content.Substring(indexText, match.Index - indexText);
            s_buffer.Append(subStr);
            //s_buffer.Append("<color=blue>");
            var group = match.Groups[1];


#if UNITY_2019_1_OR_NEWER
            int startIdx = ReplaceRichText(subStr).Length * 4; // 超链接里的文本起始顶点索引
            int endIdx = (ReplaceRichText(subStr).Length + match.Groups[2].Length - 1) * 4 + 3;
#else
            int startIdx = s_buffer.Length * 4; // 超链接里的文本起始顶点索引
            int endIdx = (s_buffer.Length + match.Groups[2].Length - 1) * 4 + 3;
#endif

            var hrefInfo = new HrefInfo
            {
                startIndex = startIdx,
                endIndex = endIdx,
                name = group.Value
            };
            m_HrefInfos.Add(hrefInfo);

            s_buffer.Append(match.Groups[2].Value);
            indexText = match.Index + match.Length;
        }

        s_buffer.Append(content.Substring(indexText, content.Length - indexText));
        return s_buffer.ToString();
    }

    protected string ParseEmoji(string content)
    {
        m_emojiDic.Clear();
        s_buffer.Length = 0;
        int nParcedCount = 0;
        int nOffset = 0;
        int indexText = 0;
        
        foreach (Match match in regex.Matches(content))
        {
            var group = match.Groups[2];
            if (!group.Success)
            {
                continue;
            }
            
            EmojiInfo info;
            if (EmojiIndex != null && EmojiIndex.TryGetValue(group.Value, out info))
            {
                string subStr = content.Substring(indexText, match.Index - indexText);
                s_buffer.Append(subStr);
                s_buffer.Append("口");
#if UNITY_2019_1_OR_NEWER
                int index = ReplaceRichText(s_buffer.ToString()).Length - 1;
#else
                int index = match.Index - nOffset;
#endif
                m_emojiDic.Add(index, info);
                nOffset += match.Length - 1;
                nParcedCount++;
                indexText = match.Index + match.Length;
            }
        }
        s_buffer.Append(content.Substring(indexText, content.Length - indexText));
        return s_buffer.ToString();
    }

    protected override void OnPopulateMesh(VertexHelper toFill)
    {
        if (font == null)
        {
            return;
        }

        // We don't care if we the font Texture changes while we are doing our Update.
        // The end result of cachedTextGenerator will be valid for this instance.
        // Otherwise we can get issues like Case 619238.
        m_DisableFontTextureRebuiltCallback = true;

        Vector2 extents = rectTransform.rect.size;

        var settings = GetGenerationSettings(extents);
        cachedTextGenerator.Populate(parsedText, settings);

        Rect inputRect = rectTransform.rect;

        // get the text alignment anchor point for the text in local space
        Vector2 textAnchorPivot = GetTextAnchorPivot(alignment);
        Vector2 refPoint = Vector2.zero;
        refPoint.x = Mathf.Lerp(inputRect.xMin, inputRect.xMax, textAnchorPivot.x);
        refPoint.y = Mathf.Lerp(inputRect.yMin, inputRect.yMax, textAnchorPivot.y);

        // Determine fraction of pixel to offset text mesh.
        Vector2 roundingOffset = PixelAdjustPoint(refPoint) - refPoint;

        // Apply the offset to the vertices
        IList<UIVertex> verts = cachedTextGenerator.verts;
        float unitsPerPixel = 1 / pixelsPerUnit;
#if UNITY_2019_1_OR_NEWER
        // 2019.1以上版本不再计算换行符、富文本等标签的顶点 wtf
        int vertCount = verts.Count;
#else
        //Last 4 verts are always a new line...
        int vertCount = verts.Count - 4;
#endif

        toFill.Clear();
        if (roundingOffset != Vector2.zero)
        {
            for (int i = 0; i < vertCount; ++i)
            {
                int tempVertsIndex = i & 3;
                m_TempVerts[tempVertsIndex] = verts[i];
                m_TempVerts[tempVertsIndex].position *= unitsPerPixel;
                m_TempVerts[tempVertsIndex].position.x += roundingOffset.x;
                m_TempVerts[tempVertsIndex].position.y += roundingOffset.y;
                if (tempVertsIndex == 3)
                    toFill.AddUIVertexQuad(m_TempVerts);
            }
        }
        else
        {
            for (int i = 0; i < vertCount; ++i)
            {
                EmojiInfo info;
                int index = i / 4;
                if (m_emojiDic.TryGetValue(index, out info))
                {
                    // 计算一下原Mesh的长和宽，现在为了保证表情是正方形，不用高了
                    //float fCharHeight = verts[i + 1].position.y - verts[i + 2].position.y;
                    float fCharWidth = verts[i + 1].position.x - verts[i].position.x;

                    // 计算放大后表情Mesh的偏移量
                    customScaleWidthOffset = 0.5f * (_customScaleRate - 1.0f) * fCharWidth;
                    customScaleHeightOffset = 0.5f * (_customScaleRate - 1.0f) * fCharWidth;

                    m_TempVerts[3] = verts[i]; //1
                    m_TempVerts[2] = verts[i + 1]; //2
                    m_TempVerts[1] = verts[i + 2]; //3
                    m_TempVerts[0] = verts[i + 3]; //4

                    // 确定左下角0号点为Base,并依次重拼出Mesh
                    //     3------2  <---- 顶点位置示意图
                    //     |      |
                    //     |      |
                    //     0------1
                    var basePoint = m_TempVerts[0].position + new Vector3(-customScaleWidthOffset, -customScaleHeightOffset, 0);
                    m_TempVerts[0].position = basePoint;
                    m_TempVerts[1].position = basePoint + new Vector3(fCharWidth * _customScaleRate, 0, 0);
                    m_TempVerts[2].position = basePoint + new Vector3(fCharWidth * _customScaleRate, fCharWidth * _customScaleRate, 0);
                    m_TempVerts[3].position = basePoint + new Vector3(0, fCharWidth * _customScaleRate, 0);

                    m_TempVerts[0].position *= unitsPerPixel;
                    m_TempVerts[1].position *= unitsPerPixel;
                    m_TempVerts[2].position *= unitsPerPixel;
                    m_TempVerts[3].position *= unitsPerPixel;

                    float pixelOffset = m_emojiDic[index].size / 32 / 2;
                    m_TempVerts[0].uv1 = new Vector2(m_emojiDic[index].x + pixelOffset, m_emojiDic[index].y + pixelOffset);
                    m_TempVerts[1].uv1 = new Vector2(m_emojiDic[index].x - pixelOffset + m_emojiDic[index].size, m_emojiDic[index].y + pixelOffset);
                    m_TempVerts[2].uv1 = new Vector2(m_emojiDic[index].x - pixelOffset + m_emojiDic[index].size, m_emojiDic[index].y - pixelOffset + m_emojiDic[index].size);
                    m_TempVerts[3].uv1 = new Vector2(m_emojiDic[index].x + pixelOffset, m_emojiDic[index].y - pixelOffset + m_emojiDic[index].size);

                    toFill.AddUIVertexQuad(m_TempVerts);

                    i += 4 - 1; //3;//4 * info.len - 1;
                }
                else
                {
                    int tempVertsIndex = i & 3;
                    m_TempVerts[tempVertsIndex] = verts[i];
                    m_TempVerts[tempVertsIndex].position *= unitsPerPixel;
                    if (tempVertsIndex == 3)
                        toFill.AddUIVertexQuad(m_TempVerts);
                }
            }
        }

        UIVertex vert = new UIVertex();
        foreach (var hrefInfo in m_HrefInfos)
        {
            hrefInfo.boxes.Clear();
            if (hrefInfo.startIndex >= toFill.currentVertCount)
            {
                continue;
            }

            // 将超链接里面的文本顶点索引坐标加入到包围框
            toFill.PopulateUIVertex(ref vert, hrefInfo.startIndex);
            var pos = vert.position;
            var bounds = new Bounds(pos, Vector3.zero);
            for (int i = hrefInfo.startIndex, m = hrefInfo.endIndex; i < m; i++)
            {
                if (i >= toFill.currentVertCount)
                {
                    break;
                }

                toFill.PopulateUIVertex(ref vert, i);
                pos = vert.position;
                if (pos.x <= bounds.min.x) // 换行重新添加包围框
                {
                    hrefInfo.boxes.Add(new Rect(bounds.min, bounds.size));
                    bounds = new Bounds(pos, Vector3.zero);
                }
                else
                {
                    bounds.Encapsulate(pos); // 扩展包围框
                }
            }

            hrefInfo.boxes.Add(new Rect(bounds.min, bounds.size));
        }

        m_DisableFontTextureRebuiltCallback = false;
    }

    public void OnClick(PointerEventData e)
    {
        if (onClickLink == null)
        {
            return;
        }

        Vector2 lp;
        RectTransformUtility.ScreenPointToLocalPointInRectangle(rectTransform, e.position, e.pressEventCamera, out lp);

        for (int idx = 0; idx < m_HrefInfos.Count; idx++)
        {
            var hrefInfo = m_HrefInfos[idx];
            var boxes = hrefInfo.boxes;
            for (var i = 0; i < boxes.Count; ++i)
            {
                if (boxes[i].Contains(lp))
                {
                    onClickLink(hrefInfo.name);
                    return;
                }
            }
        }

        // 点到超链接以外的地方需要把事件穿透到下一层
        results = new List<RaycastResult>();
        EventSystem.current.RaycastAll(e, results);
        current = e.pointerCurrentRaycast.gameObject.name;
        for (int j = 0; j < results.Count; j++)
        {
            if (current != results[j].gameObject.name)
            {
                ExecuteEvents.Execute(results[j].gameObject, e, ExecuteEvents.pointerClickHandler);
                break;
            }
        }
    }
}