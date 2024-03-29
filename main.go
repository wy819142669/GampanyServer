package main

import (
	//"fmt"
	"github.com/yuin/gopher-lua"
	"io/ioutil"
	"log"
	"os"
	"os/signal"
	"path"
	"sync"

	//"runtime"
	"syscall"
)

var g_L *lua.LState
var mutex sync.Mutex

func main() {
	LoadLua()
	defer g_L.Close()

    if (len(os.Args) > 1) {
        CallLua("AdminLoadSavedFile", os.Args[1])
    }

	pidF := NewPidF("SandTableServer.pid")
	defer pidF.Close()

	g_L.SetGlobal("RemoteToClient", g_L.NewFunction(RemoteToClient))

	go func() {
		Start(13135)
	}()

	waitQuit()
}

func LoadLua()  {
	g_L = lua.NewState()
	//defer L.Close()

	if err := g_L.DoFile(getSandTableScriptPath()); err != nil {
		panic(err)
	}
}

func CallLua(funcName, params string) string {
	mutex.Lock()
	defer mutex.Unlock()

	top := g_L.GetTop()
	defer g_L.SetTop(top)

	fn := g_L.GetGlobal(funcName)
	if err := g_L.CallByParam(lua.P{
		Fn: fn,
		NRet: 1,
		Protect: true,
	}, lua.LString(params)); err != nil {
		panic(err)
	}
	//这里获取函数返回值
	ret := g_L.Get(-1)

	return lua.LVAsString(ret)
}

func RemoteToClient(l *lua.LState) int {

	return 1
}

func readContent(path string) ([]byte, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}

	content, err := ioutil.ReadAll(f)
	if err != nil {
		return nil, err
	}
	f.Close()
	if string(content[0:3]) == "\xef\xbb\xbf" {
		content = content[3:] // skip BOM
	}
	return content, nil
}

func getSriptPath()string {
	//_, mainFile, _, ok := runtime.Caller(0)
	//if !ok {
	//	fmt.Errorf("Get main file path failed")
	//	return ""
	//}
	exefile := os.Args[0]
	dir := path.Dir(exefile)
	return path.Join(dir, "script")
}

func getSandTableScriptPath() string {
	return  path.Join(getSriptPath(), "SandTable.lua")
}

func waitQuit() {
	qc := make(chan os.Signal, 1)
	signal.Notify(qc, syscall.SIGINT, syscall.SIGTERM)
	select {
	case s := <-qc:
		log.Printf("Caught signal %v to quit", s)
	}
}
