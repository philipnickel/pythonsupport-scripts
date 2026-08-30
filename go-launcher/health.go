package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"sort"
	"strings"
	"sync"
	"time"
)

type healthStatus string

const (
	healthReady    healthStatus = "ready"
	healthMissing  healthStatus = "missing"
	healthOutdated healthStatus = "outdated"
	healthUnknown  healthStatus = "unknown"
	healthBlocked  healthStatus = "blocked"
	healthError    healthStatus = "error"
)

type healthResult struct {
	Schema           int          `json:"schema"`
	ID               string       `json:"id"`
	Status           healthStatus `json:"status"`
	Summary          string       `json:"summary"`
	InstalledVersion string       `json:"installedVersion"`
	LatestVersion    string       `json:"latestVersion"`
	Details          []string     `json:"details"`
	Order            int          `json:"-"`
}

type healthChecker interface {
	run(scriptCatalog) []healthResult
}

type scriptHealthChecker struct {
	goos       string
	bundleRoot string
	env        []string
	runner     commandRunner
	timeout    time.Duration
}

func (checker scriptHealthChecker) run(catalog scriptCatalog) []healthResult {
	results := make([]healthResult, len(catalog.Checks))
	var group sync.WaitGroup
	for index, check := range catalog.Checks {
		index, check := index, check
		group.Add(1)
		go func() {
			defer group.Done()
			results[index] = checker.runOne(check)
		}()
	}
	group.Wait()
	sort.Slice(results, func(i, j int) bool {
		if results[i].Order == results[j].Order {
			return results[i].ID < results[j].ID
		}
		return results[i].Order < results[j].Order
	})
	return results
}

func (checker scriptHealthChecker) runOne(check catalogCheck) healthResult {
	result := healthResult{
		Schema: 1, ID: check.ID, Status: healthError, Order: check.Order,
	}
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	spec, err := buildScriptCommand(
		checker.goos, checker.bundleRoot, check.Path, checker.env,
		nil, &stdout, &stderr,
	)
	if err != nil {
		result.Summary = "Check could not start"
		result.Details = []string{err.Error()}
		return result
	}
	timeout := checker.timeout
	if timeout <= 0 {
		timeout = 8 * time.Second
	}
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	spec.context = ctx
	err = checker.runner.run(spec)
	if err != nil {
		if ctx.Err() == context.DeadlineExceeded {
			result.Status = healthUnknown
			result.Summary = "Check timed out"
		} else {
			result.Summary = "Check failed"
		}
		detail := strings.TrimSpace(stderr.String())
		if detail == "" {
			detail = err.Error()
		}
		result.Details = []string{detail}
		return result
	}
	parsed, parseErr := parseHealthResult(stdout.Bytes(), check)
	if parseErr != nil {
		result.Summary = "Check returned invalid data"
		result.Details = []string{parseErr.Error()}
		return result
	}
	return parsed
}

func parseHealthResult(data []byte, check catalogCheck) (healthResult, error) {
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	var result healthResult
	if err := decoder.Decode(&result); err != nil {
		return healthResult{}, err
	}
	var extra any
	if err := decoder.Decode(&extra); err != io.EOF {
		return healthResult{}, fmt.Errorf("expected exactly one JSON object")
	}
	if result.Schema != 1 {
		return healthResult{}, fmt.Errorf("unsupported check schema %d", result.Schema)
	}
	if result.ID != check.ID {
		return healthResult{}, fmt.Errorf("check id %q does not match expected id %q", result.ID, check.ID)
	}
	switch result.Status {
	case healthReady, healthMissing, healthOutdated, healthUnknown, healthBlocked, healthError:
	default:
		return healthResult{}, fmt.Errorf("invalid health status %q", result.Status)
	}
	if strings.TrimSpace(result.Summary) == "" {
		return healthResult{}, fmt.Errorf("check summary is empty")
	}
	result.Order = check.Order
	return result, nil
}

func isFreshSetup(results []healthResult) bool {
	miniforgeMissing := false
	vsCodeMissing := false
	for _, result := range results {
		switch result.ID {
		case "miniforge":
			miniforgeMissing = result.Status == healthMissing
		case "vscode":
			vsCodeMissing = result.Status == healthMissing
		}
	}
	return miniforgeMissing && vsCodeMissing
}

func healthSummary(results []healthResult) string {
	var builder strings.Builder
	for _, result := range results {
		fmt.Fprintf(&builder, "%s  %s\n", statusSymbol(result.Status), result.Summary)
		if result.Status == healthOutdated || result.Status == healthUnknown || result.Status == healthError {
			for _, detail := range result.Details {
				fmt.Fprintf(&builder, "   %s\n", detail)
			}
		}
	}
	return strings.TrimSpace(builder.String())
}

func statusSymbol(status healthStatus) string {
	switch status {
	case healthReady:
		return "✓"
	case healthMissing:
		return "○"
	case healthOutdated:
		return "!"
	case healthBlocked:
		return "·"
	case healthUnknown:
		return "?"
	default:
		return "×"
	}
}
