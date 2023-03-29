// Copyright 2015 SEASUN. All rights reserved.

// Package idgener can generate pid file.
package main

import (
	"os"
	"strconv"
)

type PidFile struct {
	path string
	Pid  int
}

func NewPidF(path string) *PidFile {
	t := &PidFile{path, os.Getpid()}

	f, err := os.OpenFile(path,
		os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0644)
	if err != nil {
		return t
	}
	defer f.Close()

	_, err = f.WriteString(strconv.Itoa(t.Pid))

	return t
}

func (pf *PidFile) Close() error {
	return os.Remove(pf.path)
}
