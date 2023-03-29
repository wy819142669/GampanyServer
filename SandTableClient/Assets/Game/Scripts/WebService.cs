using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using UnityEngine;

public class WebService : MonoBehaviour
{
    int _requestID = 1;

    // Start is called before the first frame update
    void Start()
    {
        //WebRequest("http://8.219.208.117:13134/reload", "{\"a\":1, \"b\":2}");
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public int GetCurRequestId()
    { 
        return _requestID;
    }


    public int WebRequest(string url, string body)
    {
        Debug.Log("WebRequest" + 0);
        asycWebRequet(url, body, _requestID);
        Debug.Log("WebRequest" + 1);
        return _requestID++;
    }

    IEnumerator asycWebRequet(string url, string param, int requestID)
    {
        Debug.Log("asycWebRequet" + 0);
        WWW www = new WWW(url, Encoding.UTF8.GetBytes(param));
        Debug.Log("asycWebRequet"+1);
        yield return www;
        Debug.Log("asycWebRequet" + 2);
        if (!String.IsNullOrEmpty(www.error))
        {
            Debug.LogErrorFormat("asycWebRequet failed: network error {0}", www.error);
            yield break;
        }
        Debug.Log("asycWebRequet" + 3);
        string body = www.text;
        Debug.Log("asycWebRequet" + 4);
        www.Dispose();

        Debug.Log("asycWebRequet" + 5);
        // Debug.Log(body);
        GameClient.CallLua("Client:OnWebRespond", body);
    }
}
