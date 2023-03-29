using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

[XLua.LuaCallCSharp]
[ExecuteInEditMode]
public class PrefabAnchor : MonoBehaviour
{   
    public GameObject m_Prefab;
    GameObject m_Inst;

    #if UNITY_EDITOR
    GameObject m_Preview;
    GameObject m_PreviewPrefab;

    void OnDisable()
    {
        DestoryPreview();
    }

    void OnEnable()
    {
        CreatePreview();
    }

    void CreatePreview()
    {
        if (Application.isPlaying)
        {
            return;
        }
        DestoryPreview();
        if (m_Prefab != null && m_Preview == null)
        {
            m_Preview = Instantiate(m_Prefab, transform, false);
            m_PreviewPrefab = m_Prefab;
            RecursiveSetFlag(m_Preview, HideFlags.HideAndDontSave | HideFlags.NotEditable);
        }
    }

    void DestoryPreview()
    {
        if (Application.isPlaying)
        {
            return;
        }
        if (m_Preview != null)
        {
            DestroyImmediate(m_Preview);
            m_Preview = null;
        }
    }

    void RecursiveSetFlag(GameObject go, HideFlags flags)
    {
        go.hideFlags = flags;
        foreach(Transform child in go.transform)
        {
            RecursiveSetFlag(child.gameObject, flags);
        }
    }
    #endif

    void Awake ()
    {
        #if UNITY_EDITOR
        CreatePreview();
        if (!Application.isPlaying)
        {
            return;
        }
        #endif
        Create();
    }

    void Update()
    {       
        if (Application.isPlaying)
        {
            if (m_Inst == null)
            {
                DestroyImmediate(gameObject);
            }
        }

        #if UNITY_EDITOR
        if (Application.isPlaying)
        {
            return;
        }

        if (m_Prefab != m_PreviewPrefab)
        {
            CreatePreview();
        }
        #endif
    }

    public void Create()
    {
        if (m_Prefab != null && m_Inst == null)
        {
            m_Inst = Instantiate(m_Prefab, transform, false);
            m_Inst.name = m_Prefab.name;
        }
    }
}