package main

import (
	"bytes"
	"io"
	"os"
	"path/filepath"
	"reflect"
	"runtime"
	"strings"
	"sync"
	"testing"

	"charm.land/huh/v2"
)

type recordingRunner struct {
	mu     sync.Mutex
	specs  []commandSpec
	errors []error
}

func (runner *recordingRunner) run(spec commandSpec) error {
	runner.mu.Lock()
	defer runner.mu.Unlock()
	index := len(runner.specs)
	runner.specs = append(runner.specs, spec)
	if index < len(runner.errors) {
		return runner.errors[index]
	}
	return nil
}

type writingRunner struct{ spec commandSpec }

func (runner *writingRunner) run(spec commandSpec) error {
	runner.spec = spec
	_, _ = io.WriteString(spec.stdout, "\x1b[32mnative stdout\x1b[0m\n")
	_, _ = io.WriteString(spec.stderr, "native stderr\n")
	return nil
}

type fixedChecker struct{ results []healthResult }

func (checker fixedChecker) run(scriptCatalog) []healthResult { return checker.results }

type sequenceChecker struct {
	results [][]healthResult
	called  int
}

func (checker *sequenceChecker) run(scriptCatalog) []healthResult {
	index := checker.called
	checker.called++
	if index >= len(checker.results) {
		index = len(checker.results) - 1
	}
	return checker.results[index]
}

type fixedHealthPrompter struct {
	decision workflowDecision
	err      error
}

func (prompt *fixedHealthPrompter) prompt(
	_ []healthResult, _ []catalogAction, _ bool,
	_ bool, _ bool, _ io.Reader, _ io.Writer,
) (workflowDecision, error) {
	return prompt.decision, prompt.err
}

type sequenceHealthPrompter struct {
	decisions     []workflowDecision
	finalStatuses []bool
	called        int
}

func (prompt *sequenceHealthPrompter) prompt(
	_ []healthResult, _ []catalogAction, finalStatus bool,
	_ bool, _ bool, _ io.Reader, _ io.Writer,
) (workflowDecision, error) {
	prompt.finalStatuses = append(prompt.finalStatuses, finalStatus)
	decision := prompt.decisions[prompt.called]
	prompt.called++
	return decision, nil
}

type fixedConfirmer struct {
	confirmed bool
	err       error
	called    int
}

func (confirmer *fixedConfirmer) confirm(
	_ []catalogAction, _ bool, _ bool, _ io.Reader, _ io.Writer,
) (bool, error) {
	confirmer.called++
	return confirmer.confirmed, confirmer.err
}

type fakeExitError struct{ code int }

func (err fakeExitError) Error() string { return "child failed" }
func (err fakeExitError) ExitCode() int { return err.code }

func TestParseCLI(t *testing.T) {
	config, err := parseCLI(
		[]string{"--bundle-root", "/tmp/a bundle", "--accessible", "install-vscode"},
		[]string{"PIS_ACCESSIBLE=false"},
	)
	if err != nil {
		t.Fatal(err)
	}
	if config.bundleRoot != "/tmp/a bundle" || !config.accessible || config.action != "install-vscode" {
		t.Fatalf("unexpected config: %#v", config)
	}
	config, err = parseCLI(nil, []string{"PIS_ACCESSIBLE=1"})
	if err != nil || !config.accessible {
		t.Fatalf("PIS_ACCESSIBLE=1 not honored: %#v %v", config, err)
	}
}

func TestStaticCatalogContainsExactActionsChecksAndOrder(t *testing.T) {
	for _, goos := range []string{"darwin", "windows"} {
		catalog, err := staticCatalog(goos)
		if err != nil {
			t.Fatalf("%s: %v", goos, err)
		}
		ids := make([]string, 0, 6)
		for _, action := range catalog.visibleActions() {
			ids = append(ids, action.ID)
		}
		want := []string{"install-all", "install-conda", "install-vscode", "uninstall-all", "uninstall-conda", "uninstall-vscode"}
		if !reflect.DeepEqual(ids, want) {
			t.Fatalf("%s actions = %#v, want %#v", goos, ids, want)
		}
		if len(catalog.Checks) != 4 {
			t.Fatalf("%s checks = %d", goos, len(catalog.Checks))
		}
		for _, check := range catalog.Checks {
			if err := validateScriptPath(check.Path, goos); err != nil {
				t.Fatalf("%s check path: %v", goos, err)
			}
		}
		for _, action := range catalog.Actions {
			for _, step := range action.Steps {
				if err := validateScriptPath(step.Path, goos); err != nil {
					t.Fatalf("%s action path: %v", goos, err)
				}
			}
		}
	}
}

func TestAggregateActionUsesLeafStepsAndIgnoresExtensionFailure(t *testing.T) {
	root := t.TempDir()
	writeStaticBundle(t, root, "darwin")
	runner := &recordingRunner{errors: []error{nil, nil, nil, fakeExitError{code: 9}}}
	application := testApp(root, runner)
	if code := application.run([]string{"install-all"}); code != exitOK {
		t.Fatalf("exit code = %d", code)
	}
	if len(runner.specs) != 4 {
		t.Fatalf("steps run = %d, want 4", len(runner.specs))
	}
	wantSuffixes := []string{
		"Core/Conda/install/install_macOS.sh",
		"Core/VsCode/install/install_macOS.sh",
		"Core/VsCode/config/settings_macOS.sh",
		"Core/VsCode/config/extensions_macOS.sh",
	}
	for index, suffix := range wantSuffixes {
		if !strings.HasSuffix(filepath.ToSlash(strings.Join(runner.specs[index].args, " ")), suffix) {
			t.Fatalf("step %d = %#v", index, runner.specs[index].args)
		}
	}
}

func TestAggregateActionStopsOnFatalStep(t *testing.T) {
	root := t.TempDir()
	writeStaticBundle(t, root, "darwin")
	runner := &recordingRunner{errors: []error{nil, fakeExitError{code: 17}}}
	application := testApp(root, runner)
	if code := application.run([]string{"install-all"}); code != 17 {
		t.Fatalf("exit code = %d", code)
	}
	if len(runner.specs) != 2 {
		t.Fatalf("steps run = %d, want 2", len(runner.specs))
	}
}

func TestBuildScriptCommandPreservesEnvironment(t *testing.T) {
	root := t.TempDir()
	writeStaticBundle(t, root, "darwin")
	env := []string{"PS_ENV=offline"}
	spec, err := buildScriptCommand(
		"darwin", root, "Core/Conda/install/install_macOS.sh", env, nil, nil, nil,
	)
	if err != nil {
		t.Fatal(err)
	}
	runnerPath := filepath.Join(root, "Core", "Launcher", "run_macOS.sh")
	if spec.name != "/bin/bash" || !reflect.DeepEqual(spec.args, []string{runnerPath, "Core/Conda/install/install_macOS.sh"}) {
		t.Fatalf("unexpected command: %#v", spec)
	}
	if !reflect.DeepEqual(spec.env, env) {
		t.Fatal("environment was not preserved")
	}
}

func TestBuildMetadataIsForwardedWithoutDuplicatingEnvironment(t *testing.T) {
	application := app{
		env:        []string{"A=1", "PS_DTU_RELEASE=old", "PS_MINIFORGE_VERSION=old"},
		dtuRelease: "2026.2.3-0", miniforgeVersion: "26.3.2-3",
	}
	env := application.childEnvironment()
	if !reflect.DeepEqual(env, []string{"A=1", "PS_DTU_RELEASE=2026.2.3-0", "PS_MINIFORGE_VERSION=26.3.2-3"}) {
		t.Fatalf("environment = %#v", env)
	}
}

func TestHealthResultValidationAndFreshRouting(t *testing.T) {
	check := catalogCheck{ID: "miniforge", Order: 10}
	result, err := parseHealthResult([]byte(`{"schema":1,"id":"miniforge","status":"missing","summary":"Not installed","installedVersion":"","latestVersion":"2026.2.3-0","details":[]}`), check)
	if err != nil {
		t.Fatal(err)
	}
	if isFreshSetup([]healthResult{result}) {
		t.Fatal("one missing primary component was treated as fresh")
	}
	results := []healthResult{result, {ID: "vscode", Status: healthMissing}}
	if !isFreshSetup(results) {
		t.Fatal("two explicitly missing primary components were not treated as fresh")
	}
	for _, status := range []healthStatus{healthReady, healthOutdated, healthUnknown, healthBlocked, healthError} {
		results[0].Status = status
		if isFreshSetup(results) {
			t.Fatalf("primary status %q was treated as fresh", status)
		}
	}
}

func TestFreshPromptAndGroupedOverview(t *testing.T) {
	catalog, _ := staticCatalog("darwin")
	results := []healthResult{{ID: "miniforge", Status: healthMissing}, {ID: "vscode", Status: healthMissing}}
	prompter := defaultHealthPrompter{}
	output := &bytes.Buffer{}
	decision, err := prompter.prompt(results, catalog.visibleActions(), false, true, false, strings.NewReader("\n"), output)
	if err != nil {
		t.Fatal(err)
	}
	if decision.mode != workflowExecute || !reflect.DeepEqual(decision.actionIDs, []string{"install-all"}) {
		t.Fatalf("default fresh decision = %#v", decision)
	}
	output.Reset()
	decision, err = prompter.prompt(results, catalog.visibleActions(), false, true, false, strings.NewReader("2\n1\n"), output)
	if err != nil {
		t.Fatal(err)
	}
	if decision.mode != workflowExecute || decision.actionIDs[0] != "install-all" {
		t.Fatalf("overview decision = %#v", decision)
	}
	text := output.String()
	for _, expected := range []string{"What would you like to do?", "Install everything", "Uninstall everything", "Check again"} {
		if !strings.Contains(text, expected) {
			t.Fatalf("overview missing %q:\n%s", expected, text)
		}
	}
	if strings.Contains(text, "Install things —") || strings.Contains(text, "/ filter") {
		t.Fatalf("overview contains redundant category or filter controls:\n%s", text)
	}
}

func TestNamedActionStreamsWithoutLogs(t *testing.T) {
	root := t.TempDir()
	writeStaticBundle(t, root, "darwin")
	runner := &writingRunner{}
	output, errorsOutput := &bytes.Buffer{}, &bytes.Buffer{}
	input := strings.NewReader("child input")
	application := testApp(root, runner)
	application.stdin, application.stdout, application.stderr = input, output, errorsOutput
	if code := application.run([]string{"install-conda"}); code != exitOK {
		t.Fatalf("exit code = %d", code)
	}
	if !strings.Contains(output.String(), "native stdout") || !strings.Contains(errorsOutput.String(), "native stderr") {
		t.Fatalf("output not forwarded: stdout=%q stderr=%q", output, errorsOutput)
	}
	if runner.spec.stdin != input {
		t.Fatal("child stdin was not attached directly")
	}
	if _, err := os.Stat(filepath.Join(root, "logs")); !os.IsNotExist(err) {
		t.Fatalf("logs directory should not exist: %v", err)
	}
}

func TestUnknownActionAndMissingRunner(t *testing.T) {
	root := t.TempDir()
	writeStaticBundle(t, root, "darwin")
	application := testApp(root, &recordingRunner{})
	if code := application.run([]string{"not-an-action"}); code != exitUsage {
		t.Fatalf("unknown action exit = %d", code)
	}
	if err := os.Remove(filepath.Join(root, "Core", "Launcher", "run_macOS.sh")); err != nil {
		t.Fatal(err)
	}
	if code := application.run([]string{"install-conda"}); code != exitMissingLauncher {
		t.Fatalf("missing runner exit = %d", code)
	}
}

func TestInteractiveCancellation(t *testing.T) {
	root := t.TempDir()
	writeStaticBundle(t, root, "darwin")
	application := testApp(root, &recordingRunner{})
	application.checker = fixedChecker{results: []healthResult{{ID: "miniforge", Status: healthReady}}}
	application.healthPrompter = &fixedHealthPrompter{err: huh.ErrUserAborted}
	if code := application.run(nil); code != exitCancelled {
		t.Fatalf("exit code = %d", code)
	}
}

func TestSuccessfulActionRechecksAndShowsFinalStatus(t *testing.T) {
	root := t.TempDir()
	writeStaticBundle(t, root, "darwin")
	checker := &sequenceChecker{results: [][]healthResult{
		{{ID: "miniforge", Status: healthMissing}, {ID: "vscode", Status: healthMissing}},
		{{ID: "miniforge", Status: healthReady}, {ID: "vscode", Status: healthReady}},
	}}
	prompt := &sequenceHealthPrompter{decisions: []workflowDecision{
		{mode: workflowExecute, actionIDs: []string{"install-conda"}},
		{mode: workflowClose},
	}}
	confirmer := &fixedConfirmer{confirmed: true}
	runner := &recordingRunner{}
	application := testApp(root, runner)
	application.checker, application.healthPrompter, application.confirmer = checker, prompt, confirmer
	if code := application.run(nil); code != exitOK {
		t.Fatalf("exit code = %d", code)
	}
	if checker.called != 2 || len(runner.specs) != 1 || confirmer.called != 1 {
		t.Fatalf("calls: checks=%d actions=%d confirmations=%d", checker.called, len(runner.specs), confirmer.called)
	}
	if !reflect.DeepEqual(prompt.finalStatuses, []bool{false, true}) {
		t.Fatalf("final statuses = %#v", prompt.finalStatuses)
	}
}

func TestHelpDoesNotRequireBundle(t *testing.T) {
	output := &bytes.Buffer{}
	application := app{goos: "darwin", stdout: output, stderr: io.Discard}
	if code := application.run([]string{"--help"}); code != exitOK {
		t.Fatalf("exit code = %d", code)
	}
	if !strings.Contains(output.String(), "install-all") {
		t.Fatalf("help output = %q", output.String())
	}
}

func TestMacOSLeafRunnerIntegration(t *testing.T) {
	if runtime.GOOS != "darwin" {
		t.Skip("macOS integration test")
	}
	root := filepath.Join(t.TempDir(), "offline bundle")
	copyTestFile(t, filepath.Join("..", "Core", "Launcher", "run_macOS.sh"), filepath.Join(root, "Core", "Launcher", "run_macOS.sh"))
	copyTestFile(t, filepath.Join("..", "Core", "env.sh"), filepath.Join(root, "Core", "env.sh"))
	marker := filepath.Join(root, "ran.txt")
	actionPath := filepath.Join(root, "Core", "Conda", "install", "install_macOS.sh")
	writeTestFile(t, actionPath, "#!/bin/bash\nprintf '%s' \"$PS_ENV|$PS_BUNDLE_ROOT|$PS_DTU_RELEASE\" > "+shellQuote(marker)+"\n")
	application := app{
		goos: "darwin", executablePath: filepath.Join(root, "pis-launcher"),
		env:   []string{"PATH=" + os.Getenv("PATH"), "HOME=" + t.TempDir()},
		stdin: strings.NewReader(""), stdout: io.Discard, stderr: io.Discard,
		runner: execCommandRunner{}, dtuRelease: "2026.2.3-0", miniforgeVersion: "26.3.2-3",
	}
	if code := application.run([]string{"install-conda"}); code != exitOK {
		t.Fatalf("exit code = %d", code)
	}
	contents, err := os.ReadFile(marker)
	if err != nil {
		t.Fatal(err)
	}
	if got := string(contents); got != "offline|"+root+"|2026.2.3-0" {
		t.Fatalf("forwarded environment = %q", got)
	}
}

func testApp(root string, runner commandRunner) app {
	return app{
		goos: "darwin", executablePath: filepath.Join(root, "pis-launcher"), env: []string{},
		stdin: strings.NewReader(""), stdout: io.Discard, stderr: io.Discard,
		runner: runner, terminal: false, dtuRelease: "development", miniforgeVersion: "unknown",
	}
}

func writeStaticBundle(t *testing.T, root, goos string) {
	t.Helper()
	catalog, err := staticCatalog(goos)
	if err != nil {
		t.Fatal(err)
	}
	runner := "Core/Launcher/run_macOS.sh"
	if goos == "windows" {
		runner = "Core/Launcher/run_windows.ps1"
	}
	writeTestFile(t, filepath.Join(root, filepath.FromSlash(runner)), "test runner\n")
	for _, check := range catalog.Checks {
		writeTestFile(t, filepath.Join(root, filepath.FromSlash(check.Path)), "test check\n")
	}
	for _, action := range catalog.Actions {
		for _, step := range action.Steps {
			writeTestFile(t, filepath.Join(root, filepath.FromSlash(step.Path)), "test action\n")
		}
	}
}

func writeTestFile(t *testing.T, path, contents string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(contents), 0o755); err != nil {
		t.Fatal(err)
	}
}

func copyTestFile(t *testing.T, source, destination string) {
	t.Helper()
	contents, err := os.ReadFile(source)
	if err != nil {
		t.Fatal(err)
	}
	writeTestFile(t, destination, string(contents))
}

func shellQuote(value string) string { return "'" + strings.ReplaceAll(value, "'", "'\\''") + "'" }
