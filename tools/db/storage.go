package main

import (
	"bytes"
	"os"
	"path/filepath"

	"github.com/BurntSushi/toml"
)

func encodeTOML(v any) ([]byte, error) {
	var b bytes.Buffer
	err := toml.NewEncoder(&b).Encode(v)
	return b.Bytes(), err
}

// Atomic replacement never follows an existing file symlink into a source repository.
func writePrivate(path string, data []byte) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	f, err := os.CreateTemp(filepath.Dir(path), ".db-*")
	if err != nil {
		return err
	}
	defer os.Remove(f.Name())
	if _, err := f.Write(data); err != nil {
		f.Close()
		return err
	}
	if err := f.Close(); err != nil {
		return err
	}
	return os.Rename(f.Name(), path)
}
