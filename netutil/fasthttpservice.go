// Copyright 2015 Ginger. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package netutil

import (
	"net"
	"net/http"
	"time"

	"github.com/valyala/fasthttp"
	"github.com/valyala/fasthttp/fasthttpadaptor"
)

// FastHttpService is a wrapper of fastfasthttp.Server.
type FastHttpService struct {
	*httpService
	srv *fasthttp.Server
}

func NewFastHttpService(l *net.TCPListener, h fasthttp.RequestHandler, tlsConfig *TlsConfig) *FastHttpService {
	s := &FastHttpService{}

	s.srv = &fasthttp.Server{
		Handler:      h,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}
	s.httpService = newhttpService(l, tlsConfig, s.srv)

	return s
}

// 用于快速切换为fasthttp，无需修改原有的handler，但因为转换，性能会有所下降，建议仅用作测试用
func NewFastHttpServiceWithHttpHandler(l *net.TCPListener, h http.Handler, tlsConfig *TlsConfig) *FastHttpService {
	fasthttpHandler := fasthttpadaptor.NewFastHTTPHandler(h)
	return NewFastHttpService(l, fasthttpHandler, tlsConfig)
}

func (s *FastHttpService) ListenAddr() string {
	return s.l.Addr().String()
}

func (s *FastHttpService) SetReadTimeout(second int64) {
	s.srv.ReadTimeout = time.Duration(second) * time.Second
}

func (s *FastHttpService) SetWriteTimeout(second int64) {
	s.srv.WriteTimeout = time.Duration(second) * time.Second
}

func (s *FastHttpService) SetKeepAlivesEnabled(v bool) {
	s.srv.DisableKeepalive = !v
}

func (s *FastHttpService) GetCurrentConcurrency() uint32 {
	return s.srv.GetCurrentConcurrency()
}

func (s *FastHttpService) GetOpenConnectionsCount() int32 {
	return s.srv.GetOpenConnectionsCount()
}
