package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
)

type commandSpec struct {
	context context.Context
	name    string
	args    []string
	dir     string
	env     []string
	stdin   io.Reader
	stdout  io.Writer
	stderr  io.Writer
}

type commandRunner interface {
	run(commandSpec) error
}

type execCommandRunner struct{}

func (execCommandRunner) run(spec commandSpec) error {
	ctx := spec.context
	if ctx == nil {
		ctx = context.Background()
	}
	cmd := exec.CommandContext(ctx, spec.name, spec.args...)
	cmd.Dir = spec.dir
	cmd.Env = spec.env
	cmd.Stdin = spec.stdin
	cmd.Stdout = spec.stdout
	cmd.Stderr = spec.stderr
	return cmd.Run()
}

func buildScriptCommand(
	goos string,
	bundleRoot string,
	relativePath string,
	env []string,
	stdin io.Reader,
	stdout io.Writer,
	stderr io.Writer,
) (commandSpec, error) {
	if err := validateScriptPath(relativePath, goos); err != nil {
		return commandSpec{}, err
	}
	var name string
	var args []string
	var runnerPath string

	switch goos {
	case "darwin":
		runnerPath = filepath.Join(bundleRoot, "Core", "Launcher", "run_macOS.sh")
		name = "/bin/bash"
		args = []string{runnerPath, relativePath}
	case "windows":
		runnerPath = filepath.Join(bundleRoot, "Core", "Launcher", "run_windows.ps1")
		name = "powershell.exe"
		args = []string{
			"-NoLogo",
			"-NoProfile",
			"-ExecutionPolicy", "Bypass",
			"-File", runnerPath,
			"-Script", relativePath,
		}
	default:
		return commandSpec{}, fmt.Errorf("unsupported operating system %q", goos)
	}

	info, err := os.Stat(runnerPath)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return commandSpec{}, &missingLauncherError{path: runnerPath}
		}
		return commandSpec{}, fmt.Errorf("inspect launcher %q: %w", runnerPath, err)
	}
	if !info.Mode().IsRegular() {
		return commandSpec{}, &missingLauncherError{path: runnerPath}
	}
	targetPath := filepath.Join(bundleRoot, filepath.FromSlash(relativePath))
	if targetInfo, targetErr := os.Stat(targetPath); targetErr != nil || !targetInfo.Mode().IsRegular() {
		return commandSpec{}, &missingLauncherError{path: targetPath}
	}

	return commandSpec{
		name:   name,
		args:   args,
		dir:    bundleRoot,
		env:    env,
		stdin:  stdin,
		stdout: stdout,
		stderr: stderr,
	}, nil
}

type missingLauncherError struct {
	path string
}

func (err *missingLauncherError) Error() string {
	return fmt.Sprintf("launcher not found: %s", err.path)
}
