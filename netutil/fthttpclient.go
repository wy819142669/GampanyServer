// Copyright 2015 Ginger. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package netutil

import (
	"context"
	"fmt"
	"jx3m/pkg/consistent_hash"
	"log"
	"net"
	. "net/http"
	liburl "net/url"
	"runtime"
	"seasun/trace"
	"sync"
	"sync/atomic"
	"time"

	"jtwsm.net/gocode/utility/chanutil"
)

// FailoverHttpClient is a contexted http client.
type FailoverHttpClient struct {
	concur chanutil.Semaphore
	ts     *Transport
	hc     *Client

	updateMutex sync.Mutex
	//consHash      *consistent_hash.ConsistentHash
	consHash      atomic.Value
	allHosts      []string
	aliveHosts    map[string]struct{}
	keepAliveFunc func(hc *Client, backendAddr string) bool
	maxTry        int
	index         int64
}

func NewFailoverHttpClient(maxConcurrent, timeout int, hosts []string, keepAliveFunc func(hc *Client, addr string) bool) (*FailoverHttpClient, error) {
	mi := maxConcurrent / 5
	if mi <= 0 {
		mi = DefaultMaxIdleConnsPerHost
	}
	ts := &Transport{
		Proxy: ProxyFromEnvironment,
		Dial: (&net.Dialer{
			Timeout:   10 * time.Second,
			KeepAlive: 60 * time.Second,
		}).Dial,
		TLSHandshakeTimeout: 10 * time.Second,
		MaxIdleConnsPerHost: mi,
	}
	hc := &Client{
		Transport: ts,
		Timeout:   time.Duration(timeout) * time.Second,
	}
	c := &FailoverHttpClient{
		concur:        chanutil.NewSemaphore(maxConcurrent),
		ts:            ts,
		hc:            hc,
		maxTry:        1,
		keepAliveFunc: keepAliveFunc,
	}
	if len(hosts) != 0 {
		c.UpdateLoadBalanceHosts(hosts)
	}
	if keepAliveFunc != nil {
		go c.keepaliveRoutine()
	}
	return c, nil
}

func (c *FailoverHttpClient) SetMaxAutoRetry(maxTry int) {
	c.maxTry = maxTry
	if c.maxTry <= 0 {
		c.maxTry = 1
	}
}

func (c *FailoverHttpClient) keepaliveRoutine() {
	defer func() {
		if err := recover(); err != nil {
			const size = 16 << 10
			buf := make([]byte, size)
			buf = buf[:runtime.Stack(buf, false)]
			log.Printf("FailoverHttpClient keepaliveRoutine panic %v\n%s\n",
				err, buf)
		}
	}()
	ticker := time.Tick(10 * time.Second)
	for {
		select {
		case <-ticker:
			c.checkOnce()
		}
	}
}
func (c *FailoverHttpClient) checkOnce() {
	if c.keepAliveFunc == nil {
		return
	}
	c.updateMutex.Lock()
	defer c.updateMutex.Unlock()
	allHosts := c.allHosts
	var change = false
	var newDead []string
	var newAlive []string
	for _, addr := range allHosts {
		if alive := c.keepAliveFunc(c.hc, addr); alive {
			if _, wasAlive := c.aliveHosts[addr]; !wasAlive {
				change = true
				newAlive = append(newAlive, addr)
			}
		} else {
			if _, wasAlive := c.aliveHosts[addr]; wasAlive {
				change = true
				newDead = append(newDead, addr)
			}
		}
	}
	if change {
		consHash := c.consHash.Load().(*consistent_hash.ConsistentHash)
		for _, addr := range newAlive {
			consHash.Set([]byte(addr), addr)
			c.aliveHosts[addr] = struct{}{}
		}
		for _, addr := range newDead {
			consHash.Del([]byte(addr))
			delete(c.aliveHosts, addr)
		}
	}

}

func (c *FailoverHttpClient) UpdateLoadBalanceHosts(hosts []string) error {
	c.updateMutex.Lock()
	defer c.updateMutex.Unlock()
	var (
		aliveHosts map[string]struct{} = make(map[string]struct{})
		allHosts   []string
	)
	for _, addr := range hosts {
		allHosts = append(allHosts, addr)
		if c.keepAliveFunc != nil {
			if alive := c.keepAliveFunc(c.hc, addr); alive {
				aliveHosts[addr] = struct{}{}
			}
		} else {
			aliveHosts[addr] = struct{}{}
		}
	}
	consHash := consistent_hash.NewConsistentHash()

	for addr, _ := range aliveHosts {
		consHash.Set([]byte(addr), addr)
	}
	c.allHosts = allHosts
	c.aliveHosts = aliveHosts
	c.consHash.Store(consHash)
	return nil
}

func (c *FailoverHttpClient) acquireConn(ctx context.Context) error {
	if trace.FromContext(ctx) != nil {
		_, span := trace.StartSpan(ctx, "acquireConn")
		span.Annotatef(nil, "start acquireConn, poolStatus=%v/%v", cap(c.concur)-len(c.concur), cap(c.concur))
		defer span.End()
	}

	select {
	case <-ctx.Done():
		return ctx.Err()
	// Acquire
	case c.concur <- struct{}{}:
		return nil
	}
}

func (c *FailoverHttpClient) releaseConn() {
	<-c.concur
}

func (c *FailoverHttpClient) Do(ctx context.Context,
	req *Request, key []byte) (resp *Response, err error) {

	err = c.acquireConn(ctx)
	if err != nil {
		return
	}
	defer c.releaseConn()

	hosts := c.selectHost(key, c.maxTry)
	if len(hosts) == 0 {
		return nil, fmt.Errorf("no alive host")
	}

	for i, _ := range hosts {
		req.Host = hosts[i]
		req.URL.Host = hosts[i]
		resp, err = c.hc.Do(req)
		if err == nil {
			return resp, nil
		}
	}
	return resp, err
}

func (c *FailoverHttpClient) Get(ctx context.Context,
	path string, value liburl.Values, key []byte) (resp *Response, err error) {

	err = c.acquireConn(ctx)
	if err != nil {
		return
	}
	defer c.releaseConn()
	hosts := c.selectHost(key, c.maxTry)
	if len(hosts) == 0 {
		return nil, fmt.Errorf("no alive host")
	}

	for i, _ := range hosts {
		urlStr := fmt.Sprintf("http://%s%s?%s", hosts[i], path, value.Encode())
		resp, err = c.hc.Get(urlStr)
		if err == nil {
			return resp, nil
		}
	}
	return resp, err
}

func (c *FailoverHttpClient) Close() error {
	c.ts.CloseIdleConnections()
	return nil
}

func (c *FailoverHttpClient) selectHost(key []byte, n int) (addr []string) {
	consHash := c.consHash.Load().(*consistent_hash.ConsistentHash)
	addr = consHash.GetN(key, n)
	if len(addr) == 0 {
		c.checkOnce()
		consHash = c.consHash.Load().(*consistent_hash.ConsistentHash)
		addr = consHash.GetN(key, n)
	}
	return addr
}
