package main

import (
	"fmt"
	"io"
	"io/ioutil"

	//"jtwsm.net/gocode/utility/netutil"
	//"net"
	"net/http"

	//"../netutil"
)

type service struct {
	//*netutil.HttpService
}

func Start(port int32) error {
	http.HandleFunc("/reload", doReload)
	http.HandleFunc("/query", doQuery)
	http.HandleFunc("/action", doAction)
	http.HandleFunc("/admin", doAdmin)

	address := fmt.Sprintf(":%v", port)
	err := http.ListenAndServe(address, nil)
	if err != nil {

	}

	return err
}

func doReload(w http.ResponseWriter, r *http.Request) {
	body, _ := ioutil.ReadAll(r.Body)

	bodyString := string(body)
	fmt.Printf("got / doReload request %v \n", bodyString)

	ret := CallLua("Reload", bodyString)
	io.WriteString(w, ret)
}

func doQuery(w http.ResponseWriter, r *http.Request) {
	body, _ := ioutil.ReadAll(r.Body)

	bodyString := string(body)
	fmt.Printf("got / doQuery request %v \n", bodyString)

	ret := CallLua("Query", bodyString)
	io.WriteString(w, ret)
}

func doAction(w http.ResponseWriter, r *http.Request) {
	body, _ := ioutil.ReadAll(r.Body)

	bodyString := string(body)
	fmt.Printf("got / doAction request %v \n", bodyString)

	ret := CallLua("Action", bodyString)
	io.WriteString(w, ret)
}

func doAdmin(w http.ResponseWriter, r *http.Request) {
	body, _ := ioutil.ReadAll(r.Body)

	bodyString := string(body)
	fmt.Printf("got / doAdmin request %v \n", bodyString)

	ret := CallLua("Admin", bodyString)
	io.WriteString(w, ret)
}
