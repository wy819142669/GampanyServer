// Copyright 2015 Ginger. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package netutil

import (
	"net"
	"net/http"
	"time"
)

// HttpService is a wrapper of http.Server.
type HttpService struct {
	*httpService
	srv *http.Server
}

func NewHttpService(l *net.TCPListener, h http.Handler, tlsConfig *TlsConfig) *HttpService {
	s := &HttpService{}

	s.srv = &http.Server{
		Addr:           l.Addr().String(),
		Handler:        h,
		ReadTimeout:    10 * time.Second,
		WriteTimeout:   10 * time.Second,
		MaxHeaderBytes: 1 << 20,
	}
	s.httpService = newhttpService(l, tlsConfig, s.srv)

	return s
}

func (s *HttpService) ListenAddr() string {
	return s.srv.Addr
}

func (s *HttpService) SetReadTimeout(second int64) {
	s.srv.ReadTimeout = time.Duration(second) * time.Second
}

func (s *HttpService) SetWriteTimeout(second int64) {
	s.srv.WriteTimeout = time.Duration(second) * time.Second
}

func (s *HttpService) SetKeepAlivesEnabled(v bool) {
	s.srv.SetKeepAlivesEnabled(v)
}
