package main

import (
	"fmt"
	"path/filepath"
	"sort"
	"strings"
)

type actionStep struct {
	Path     string
	NonFatal bool
}

type catalogAction struct {
	ID          string
	Name        string
	Description string
	Group       string
	Order       int
	Destructive bool
	Steps       []actionStep
}

type catalogCheck struct {
	ID    string
	Order int
	Path  string
}

type scriptCatalog struct {
	Actions map[string]catalogAction
	Checks  []catalogCheck
}

func staticCatalog(goos string) (scriptCatalog, error) {
	var condaInstall, vscodeInstall, vscodeSettings, vscodeExtensions string
	var condaUninstall, vscodeUninstall string
	var checks []catalogCheck

	switch goos {
	case "darwin":
		condaInstall = "Core/Conda/install/install_macOS.sh"
		vscodeInstall = "Core/VsCode/install/install_macOS.sh"
		vscodeSettings = "Core/VsCode/config/settings_macOS.sh"
		vscodeExtensions = "Core/VsCode/config/extensions_macOS.sh"
		condaUninstall = "Utils/Conda/uninstall_macOS.sh"
		vscodeUninstall = "Utils/VsCode/uninstall_macOS.sh"
		checks = []catalogCheck{
			{ID: "miniforge", Order: 10, Path: "Core/Checks/check_miniforge_macOS.sh"},
			{ID: "vscode", Order: 20, Path: "Core/Checks/check_vscode_macOS.sh"},
			{ID: "vscode-extensions", Order: 30, Path: "Core/Checks/check_extensions_macOS.sh"},
			{ID: "vscode-settings", Order: 40, Path: "Core/Checks/check_settings_macOS.sh"},
		}
	case "windows":
		condaInstall = "Core/Conda/install/install_windows.ps1"
		vscodeInstall = "Core/VsCode/install/install_windows.ps1"
		vscodeSettings = "Core/VsCode/config/settings_windows.ps1"
		vscodeExtensions = "Core/VsCode/config/extensions_windows.ps1"
		condaUninstall = "Utils/Conda/uninstall_Windows.ps1"
		vscodeUninstall = "Utils/VsCode/uninstall_Windows.ps1"
		checks = []catalogCheck{
			{ID: "miniforge", Order: 10, Path: "Core/Checks/check_miniforge_windows.ps1"},
			{ID: "vscode", Order: 20, Path: "Core/Checks/check_vscode_windows.ps1"},
			{ID: "vscode-extensions", Order: 30, Path: "Core/Checks/check_extensions_windows.ps1"},
			{ID: "vscode-settings", Order: 40, Path: "Core/Checks/check_settings_windows.ps1"},
		}
	default:
		return scriptCatalog{}, fmt.Errorf("unsupported operating system %q", goos)
	}

	extensionStep := actionStep{Path: vscodeExtensions, NonFatal: true}
	return scriptCatalog{
		Actions: map[string]catalogAction{
			"install-all": {
				ID: "install-all", Name: "Install everything",
				Description: "Install DTU Miniforge, VS Code, settings, and extensions",
				Group:       "Install things", Order: 10,
				Steps: []actionStep{{Path: condaInstall}, {Path: vscodeInstall}, {Path: vscodeSettings}, extensionStep},
			},
			"install-conda": {
				ID: "install-conda", Name: "Install DTU Miniforge",
				Description: "Install the DTU Miniforge distribution",
				Group:       "Install things", Order: 20,
				Steps: []actionStep{{Path: condaInstall}},
			},
			"install-vscode": {
				ID: "install-vscode", Name: "Install VS Code",
				Description: "Install VS Code, DTU settings, and required extensions",
				Group:       "Install things", Order: 30,
				Steps: []actionStep{{Path: vscodeInstall}, {Path: vscodeSettings}, extensionStep},
			},
			"uninstall-all": {
				ID: "uninstall-all", Name: "Uninstall everything",
				Description: "Remove VS Code and Conda, including their user data",
				Group:       "Uninstall things", Order: 10, Destructive: true,
				Steps: []actionStep{{Path: vscodeUninstall}, {Path: condaUninstall}},
			},
			"uninstall-conda": {
				ID: "uninstall-conda", Name: "Uninstall Miniforge",
				Description: "Remove Conda distributions and their user data",
				Group:       "Uninstall things", Order: 20, Destructive: true,
				Steps: []actionStep{{Path: condaUninstall}},
			},
			"uninstall-vscode": {
				ID: "uninstall-vscode", Name: "Uninstall VS Code",
				Description: "Remove VS Code, settings, extensions, and user data",
				Group:       "Uninstall things", Order: 30, Destructive: true,
				Steps: []actionStep{{Path: vscodeUninstall}},
			},
		},
		Checks: checks,
	}, nil
}

func validateScriptPath(path, goos string) error {
	clean := filepath.ToSlash(filepath.Clean(path))
	if clean != path || strings.HasPrefix(clean, "../") || strings.Contains(clean, "/../") {
		return fmt.Errorf("unsafe script path %q", path)
	}
	if !strings.HasPrefix(clean, "Core/") && !strings.HasPrefix(clean, "Utils/") {
		return fmt.Errorf("script path outside approved roots: %q", path)
	}
	wantedExtension := ".sh"
	if goos == "windows" {
		wantedExtension = ".ps1"
	}
	if strings.ToLower(filepath.Ext(clean)) != wantedExtension {
		return fmt.Errorf("script path %q does not match platform %s", path, goos)
	}
	return nil
}

func (catalog scriptCatalog) visibleActions() []catalogAction {
	actions := make([]catalogAction, 0, len(catalog.Actions))
	for _, action := range catalog.Actions {
		actions = append(actions, action)
	}
	sort.Slice(actions, func(i, j int) bool {
		if actions[i].Group != actions[j].Group {
			return actionGroupOrder(actions[i].Group) < actionGroupOrder(actions[j].Group)
		}
		if actions[i].Order != actions[j].Order {
			return actions[i].Order < actions[j].Order
		}
		return actions[i].ID < actions[j].ID
	})
	return actions
}

func actionGroupOrder(group string) int {
	switch group {
	case "Install things":
		return 0
	case "Uninstall things":
		return 1
	default:
		return 2
	}
}

func (catalog scriptCatalog) resolveAction(id string) (catalogAction, error) {
	action, exists := catalog.Actions[id]
	if !exists {
		return catalogAction{}, fmt.Errorf("unknown action %q", id)
	}
	return action, nil
}
