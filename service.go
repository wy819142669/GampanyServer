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

	address := fmt.Sprintf(":%v", port)
	err := http.ListenAndServe(address, nil)
	if err != nil {

	}

	return err
}

func doReload(w http.ResponseWriter, r *http.Request) {
	body, _ := ioutil.ReadAll(r.Body)
	fmt.Printf("got / doReload request\n")

	ret := CallLua("Reload", string(body))
	io.WriteString(w, ret)
}

func doQuery(w http.ResponseWriter, r *http.Request) {
	body, _ := ioutil.ReadAll(r.Body)
	fmt.Printf("got / doQuery request\n")

	ret := CallLua("Query", string(body))
	io.WriteString(w, ret)
}

func doAction(w http.ResponseWriter, r *http.Request) {
	body, _ := ioutil.ReadAll(r.Body)
	fmt.Printf("got / doAction request\n")

	ret := CallLua("Action", string(body))
	io.WriteString(w, ret)
}
