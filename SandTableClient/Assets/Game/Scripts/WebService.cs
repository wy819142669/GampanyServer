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

    public int GetRequestId()
    { 
        return _requestID;
    }


    public int WebRequest(string url, string body)
    {
        asycWebRequet(url, body, _requestID);
        return _requestID++;
    }

    public void asycWebRequet(string url, string param, int requestID)
    {
        WWW www = new WWW(url, Encoding.UTF8.GetBytes(param));
        //yield return www;
        if (!String.IsNullOrEmpty(www.error))
        {
            Debug.LogErrorFormat("asycWebRequet failed: network error {0}", www.error);
            //yield break;
        }
        System.Threading.Thread.Sleep(1000);    
        string body = www.text;
        www.Dispose();

        // Debug.Log(body);
        GameClient.CallLua("Client:OnWebRespond", body);
    }
}
