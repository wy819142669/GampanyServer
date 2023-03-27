// Copyright 2015 Ginger. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package netutil

import (
	"context"
	"net"
	"time"

	"jtwsm.net/gocode/utility/chanutil"
)

// httpService is a wrapper of http.Server.
type httpService struct {
	err     error
	quitCtx context.Context
	quitF   context.CancelFunc
	stopD   chanutil.DoneChan

	l         *net.TCPListener
	tlsConfig *TlsConfig
	server    httpServer
}

type httpServer interface {
	ServeTLS(l net.Listener, certFile, keyFile string) error
	Serve(l net.Listener) error
}

type Shutdowner interface {
	Shutdown() error
}

type ShutdownWithContexter interface {
	Shutdown(ctx context.Context) error
}

func newhttpService(l *net.TCPListener, tlsConfig *TlsConfig, server httpServer) *httpService {
	s := &httpService{}

	s.quitCtx, s.quitF = context.WithCancel(context.Background())
	s.stopD = chanutil.NewDoneChan()
	s.l = l
	s.tlsConfig = tlsConfig
	s.server = server

	return s
}

func (s *httpService) Start() {
	go s.serve()
	time.Sleep(200 * time.Millisecond)
}

func (s *httpService) Stop() {
	switch srv := s.server.(type) {
	case Shutdowner:
		srv.Shutdown()
	case ShutdownWithContexter:
		srv.Shutdown(context.Background())
	default:
		panic("unsupported")
	}
	s.quitF()
}

func (s *httpService) StopD() chanutil.DoneChanR {
	return s.stopD.R()
}

func (s *httpService) Stopped() bool {
	return s.stopD.R().Done()
}

func (s *httpService) QuitCtx() context.Context {
	return s.quitCtx
}

func (s *httpService) Err() error {
	return s.err
}

// ---------------------------------------------------------------------------------------

func (s *httpService) serve() {
	if s.tlsConfig != nil {
		// HTTPS
		s.err = s.server.ServeTLS(TcpKeepAliveListener{s.l}, s.tlsConfig.CertFile, s.tlsConfig.KeyFile)
	} else {
		// HTTP
		s.err = s.server.Serve(TcpKeepAliveListener{s.l})
	}

	s.stopD.SetDone()
	s.quitF()
}
