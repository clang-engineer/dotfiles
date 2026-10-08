package main

import (
	"fmt"
	"os"

	"github.com/clang-engineer/dotfiles/tools/db/internal/app"
)

func main() {
	code, err := app.Run(os.Args[1:])
	if err != nil {
		fmt.Fprintf(os.Stderr, "db: %v\n", err)
		os.Exit(1)
	}
	os.Exit(code)
}
