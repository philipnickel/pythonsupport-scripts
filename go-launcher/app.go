package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/signal"
	"path/filepath"
	"strconv"
	"strings"

	tea "charm.land/bubbletea/v2"
	"charm.land/huh/v2"
)

const (
	exitOK              = 0
	exitFailure         = 1
	exitUsage           = 2
	exitMissingLauncher = 3
	exitCancelled       = 130
)

type app struct {
	goos             string
	executablePath   string
	env              []string
	stdin            io.Reader
	stdout           io.Writer
	stderr           io.Writer
	runner           commandRunner
	healthPrompter   healthPrompter
	confirmer        actionConfirmer
	checker          healthChecker
	terminal         bool
	dtuRelease       string
	miniforgeVersion string
}

type actionConfirmer interface {
	confirm([]catalogAction, bool, bool, io.Reader, io.Writer) (bool, error)
}

type defaultActionConfirmer struct{}

func (defaultActionConfirmer) confirm(
	actions []catalogAction,
	accessible bool,
	fullScreen bool,
	stdin io.Reader,
	stdout io.Writer,
) (bool, error) {
	return confirmActions(actions, accessible, fullScreen, stdin, stdout)
}

type cliConfig struct {
	bundleRoot string
	accessible bool
	action     string
}

func (application app) run(args []string) int {
	config, err := parseCLI(args, application.env)
	if err != nil {
		if errors.Is(err, flag.ErrHelp) {
			printUsage(application.stdout)
			if catalog, catalogErr := staticCatalog(application.goos); catalogErr == nil {
				printCatalogActions(application.stdout, catalog)
			}
			return exitOK
		}
		fmt.Fprintf(application.stderr, "pis-launcher: %v\n", err)
		printUsage(application.stderr)
		return exitUsage
	}

	bundleRoot, err := resolveBundleRoot(config.bundleRoot, application.executablePath)
	if err != nil {
		fmt.Fprintf(application.stderr, "pis-launcher: %v\n", err)
		return exitFailure
	}
	catalog, err := staticCatalog(application.goos)
	if err != nil {
		fmt.Fprintf(application.stderr, "pis-launcher: %v\n", err)
		return exitFailure
	}

	if config.action != "" {
		action, resolveErr := catalog.resolveAction(config.action)
		if resolveErr != nil {
			fmt.Fprintf(application.stderr, "pis-launcher: %v\n", resolveErr)
			printCatalogActions(application.stderr, catalog)
			return exitUsage
		}
		return application.executeActions(bundleRoot, []catalogAction{action})
	}

	fullScreen := !config.accessible && application.terminal
	checker := application.checker
	if checker == nil {
		checker = scriptHealthChecker{
			goos: application.goos, bundleRoot: bundleRoot, env: application.env,
			runner: application.runner,
		}
	}
	prompter := application.healthPrompter
	if prompter == nil {
		prompter = defaultHealthPrompter{}
	}
	confirmer := application.confirmer
	if confirmer == nil {
		confirmer = defaultActionConfirmer{}
	}

	finalStatus := false

checkLoop:
	for {
		results, checkErr := runHealthChecks(checker, catalog, fullScreen, application.stdin, application.stdout)
		if checkErr != nil {
			if errors.Is(checkErr, tea.ErrInterrupted) {
				return exitCancelled
			}
			fmt.Fprintf(application.stderr, "pis-launcher: health display failed: %v\n", checkErr)
			return exitFailure
		}
		for {
			decision, promptErr := prompter.prompt(
				results, catalog.visibleActions(), finalStatus, config.accessible,
				fullScreen, application.stdin, application.stdout,
			)
			if promptErr != nil {
				if errors.Is(promptErr, huh.ErrUserAborted) {
					return exitCancelled
				}
				fmt.Fprintf(application.stderr, "pis-launcher: prompt failed: %v\n", promptErr)
				return exitFailure
			}
			switch decision.mode {
			case workflowClose:
				return exitOK
			case workflowRecheck:
				finalStatus = false
				continue checkLoop
			case workflowExecute:
				// The selection came from either the fresh screen or the overview.
				// If confirmation is declined, return there instead of reopening a
				// previous final-status screen.
				finalStatus = false
				if len(decision.actionIDs) != 1 {
					fmt.Fprintln(application.stderr, "pis-launcher: invalid action selection")
					return exitFailure
				}
				action, resolveErr := catalog.resolveAction(decision.actionIDs[0])
				if resolveErr != nil {
					fmt.Fprintf(application.stderr, "pis-launcher: could not resolve selection: %v\n", resolveErr)
					return exitFailure
				}
				actions := []catalogAction{action}
				confirmed, confirmErr := confirmer.confirm(
					actions, config.accessible, fullScreen, application.stdin, application.stdout,
				)
				if confirmErr != nil {
					if errors.Is(confirmErr, huh.ErrUserAborted) {
						return exitCancelled
					}
					fmt.Fprintf(application.stderr, "pis-launcher: confirmation failed: %v\n", confirmErr)
					return exitFailure
				}
				if !confirmed {
					continue
				}
				if code := application.executeActions(bundleRoot, actions); code != exitOK {
					return code
				}
				finalStatus = true
				continue checkLoop
			}
		}
	}
}

func (application app) executeActions(bundleRoot string, actions []catalogAction) int {
	for _, selected := range actions {
		fmt.Fprintf(application.stdout, "\n── %s ──\n\n", selected.Name)
		for _, step := range selected.Steps {
			spec, err := buildScriptCommand(
				application.goos, bundleRoot, step.Path, application.childEnvironment(),
				application.stdin, application.stdout, application.stderr,
			)
			if err != nil {
				fmt.Fprintf(application.stderr, "pis-launcher: %v\n", err)
				var missing *missingLauncherError
				if errors.As(err, &missing) {
					return exitMissingLauncher
				}
				return exitFailure
			}
			ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
			spec.context = ctx
			err = application.runner.run(spec)
			interrupted := errors.Is(ctx.Err(), context.Canceled)
			stop()
			if err == nil {
				continue
			}
			if interrupted {
				return exitCancelled
			}
			if step.NonFatal {
				fmt.Fprintln(application.stderr, "\nWarning: VS Code extensions could not be installed. Connect to the internet and run the VS Code setup again.")
				continue
			}
			var exitCoder interface{ ExitCode() int }
			if errors.As(err, &exitCoder) && exitCoder.ExitCode() >= 0 {
				return exitCoder.ExitCode()
			}
			fmt.Fprintf(application.stderr, "pis-launcher: could not run action %s: %v\n", selected.ID, err)
			return exitFailure
		}
	}
	return exitOK
}

func (application app) childEnvironment() []string {
	env := setEnvironmentValue(application.env, "PS_DTU_RELEASE", application.dtuRelease)
	return setEnvironmentValue(env, "PS_MINIFORGE_VERSION", application.miniforgeVersion)
}

func setEnvironmentValue(env []string, name, value string) []string {
	prefix := name + "="
	result := make([]string, 0, len(env)+1)
	for _, entry := range env {
		if !strings.HasPrefix(entry, prefix) {
			result = append(result, entry)
		}
	}
	return append(result, prefix+value)
}

func confirmActions(actions []catalogAction, accessible, fullScreen bool, stdin io.Reader, stdout io.Writer) (bool, error) {
	confirmed := true
	destructive := false
	names := make([]string, 0, len(actions))
	for _, action := range actions {
		names = append(names, action.Name)
		destructive = destructive || action.Destructive
	}
	title := "Continue with this setup?"
	description := strings.Join(names, "\n")
	if destructive {
		title = "Remove the selected software and user data?"
		description = "This action is destructive and cannot be undone.\n" + description
	}
	field := huh.NewConfirm().Title(title).Description(description).
		Affirmative("Continue").Negative("Go back").Value(&confirmed)
	form := huh.NewForm(huh.NewGroup(field))
	if err := runLauncherForm(form, accessible || !fullScreen, fullScreen, stdin, stdout); err != nil {
		return false, err
	}
	return confirmed, nil
}

func parseCLI(args []string, env []string) (cliConfig, error) {
	config := cliConfig{accessible: environmentBool(env, "PIS_ACCESSIBLE")}
	flags := flag.NewFlagSet("pis-launcher", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	flags.StringVar(&config.bundleRoot, "bundle-root", "", "directory containing the script bundle")
	flags.BoolVar(&config.accessible, "accessible", config.accessible, "use plain accessible prompts")
	if err := flags.Parse(args); err != nil {
		return config, err
	}
	positionals := flags.Args()
	if len(positionals) > 1 {
		return cliConfig{}, fmt.Errorf("expected at most one action")
	}
	if len(positionals) == 1 {
		config.action = positionals[0]
	}
	return config, nil
}

func environmentBool(env []string, name string) bool {
	prefix := name + "="
	for index := len(env) - 1; index >= 0; index-- {
		if !strings.HasPrefix(env[index], prefix) {
			continue
		}
		value := strings.TrimPrefix(env[index], prefix)
		parsed, err := strconv.ParseBool(value)
		return err == nil && parsed
	}
	return false
}

func resolveBundleRoot(explicitRoot string, executablePath string) (string, error) {
	root := explicitRoot
	if root == "" {
		if executablePath == "" {
			return "", errors.New("cannot determine executable location; use --bundle-root")
		}
		root = filepath.Dir(executablePath)
		// Release images keep the executable visible at the volume root while
		// scripts and payloads live in a hidden adjacent resource directory.
		resourceRoot := filepath.Join(root, ".dtu-python-support")
		if info, err := os.Stat(resourceRoot); err == nil && info.IsDir() {
			root = resourceRoot
		}
	}
	absoluteRoot, err := filepath.Abs(root)
	if err != nil {
		return "", fmt.Errorf("resolve bundle root %q: %w", root, err)
	}
	return filepath.Clean(absoluteRoot), nil
}

func printUsage(output io.Writer) {
	fmt.Fprintln(output, "usage: pis-launcher [--accessible] [--bundle-root PATH] [ACTION]")
	fmt.Fprintln(output, "run without ACTION to check the system and open the interactive setup")
	fmt.Fprintln(output, "ACTION selects one of the built-in setup or removal operations")
}

func printCatalogActions(output io.Writer, catalog scriptCatalog) {
	fmt.Fprintln(output, "available actions:")
	for _, action := range catalog.visibleActions() {
		fmt.Fprintf(output, "  %-20s %s\n", action.ID, action.Name)
	}
}

func isTerminal(file *os.File) bool {
	info, err := file.Stat()
	return err == nil && info.Mode()&os.ModeCharDevice != 0
}

func newApp() (app, error) {
	executablePath, err := os.Executable()
	if err != nil {
		return app{}, fmt.Errorf("locate executable: %w", err)
	}
	runner := execCommandRunner{}
	return app{
		goos: runtimeGOOS, executablePath: executablePath, env: os.Environ(),
		stdin: os.Stdin, stdout: os.Stdout, stderr: os.Stderr,
		runner:           runner,
		healthPrompter:   defaultHealthPrompter{},
		confirmer:        defaultActionConfirmer{},
		terminal:         isTerminal(os.Stdin) && isTerminal(os.Stdout),
		dtuRelease:       bundleRelease,
		miniforgeVersion: bundledMiniforgeVersion,
	}, nil
}
