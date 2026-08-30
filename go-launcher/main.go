package main

import (
	"fmt"
	"os"
	"runtime"
)

var runtimeGOOS = runtime.GOOS
var bundleRelease = "development"
var bundledMiniforgeVersion = "unknown"

func main() {
	application, err := newApp()
	if err != nil {
		fmt.Fprintf(os.Stderr, "pis-launcher: %v\n", err)
		os.Exit(exitFailure)
	}
	os.Exit(application.run(os.Args[1:]))
}
