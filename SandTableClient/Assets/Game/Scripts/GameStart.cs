using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameStart : MonoBehaviour
{
    void Awake()
    {
        UnityEngine.Debug.LogError("Awake");
    }
    // Start is called before the first frame update
    void Start()
    {
        UnityEngine.Debug.LogError("Start");
        GameObject clientObject = new GameObject("GameClient");
        GameObject.DontDestroyOnLoad(clientObject);
        var web = clientObject.AddComponent<WebService>();
        var game = clientObject.AddComponent<GameClient>();
        GameClient.webservice = web;
    }

    // Update is called once per frame
    void Update()
    {
        //UnityEngine.Debug.LogError("Update");
    }
}
