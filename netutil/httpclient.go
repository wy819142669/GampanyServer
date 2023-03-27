// Copyright 2015 Ginger. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package netutil

import (
	"context"
	"crypto/tls"
	"io"
	"net"
	. "net/http"
	"net/url"
	"seasun/trace"
	"time"

	"jtwsm.net/gocode/utility/chanutil"
)

// HttpClient is a contexted http client.
type HttpClient struct {
	concur chanutil.Semaphore
	ts     *Transport
	hc     *Client
}

func NewHttpClient(maxConcurrent, timeout int) *HttpClient {
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
		TLSClientConfig:     &tls.Config{InsecureSkipVerify: true},
	}
	hc := &Client{
		Transport: ts,
		Timeout:   time.Duration(timeout) * time.Second,
	}
	return &HttpClient{
		concur: chanutil.NewSemaphore(maxConcurrent),
		ts:     ts,
		hc:     hc,
	}
}

func (c *HttpClient) acquireConn(ctx context.Context) error {
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

func (c *HttpClient) releaseConn() {
	<-c.concur
}

func (c *HttpClient) Do(ctx context.Context,
	req *Request) (resp *Response, err error) {

	err = c.acquireConn(ctx)
	if err != nil {
		return
	}
	defer c.releaseConn()

	req = req.WithContext(ctx)
	return c.hc.Do(req)
}

func (c *HttpClient) Get(ctx context.Context,
	url string) (resp *Response, err error) {

	err = c.acquireConn(ctx)
	if err != nil {
		return
	}
	defer c.releaseConn()

	return c.hc.Get(url)
}

func (c *HttpClient) Head(ctx context.Context,
	url string) (resp *Response, err error) {

	err = c.acquireConn(ctx)
	if err != nil {
		return
	}
	defer c.releaseConn()

	return c.hc.Head(url)
}

func (c *HttpClient) Post(ctx context.Context,
	url string, bodyType string, body io.Reader) (resp *Response, err error) {

	err = c.acquireConn(ctx)
	if err != nil {
		return
	}
	defer c.releaseConn()

	return c.hc.Post(url, bodyType, body)
}

func (c *HttpClient) PostForm(ctx context.Context,
	url string, data url.Values) (resp *Response, err error) {

	err = c.acquireConn(ctx)
	if err != nil {
		return
	}
	defer c.releaseConn()

	return c.hc.PostForm(url, data)
}

func (c *HttpClient) Close() error {
	c.ts.CloseIdleConnections()
	return nil
}
