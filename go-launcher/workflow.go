package main

import (
	"io"

	"charm.land/bubbles/v2/key"
	tea "charm.land/bubbletea/v2"
	"charm.land/huh/v2"
	huhspinner "charm.land/huh/v2/spinner"
)

type workflowMode int

const (
	workflowClose workflowMode = iota
	workflowExecute
	workflowRecheck
)

type workflowDecision struct {
	mode      workflowMode
	actionIDs []string
}

type healthPrompter interface {
	prompt([]healthResult, []catalogAction, bool, bool, bool, io.Reader, io.Writer) (workflowDecision, error)
}

type defaultHealthPrompter struct{}

func (defaultHealthPrompter) prompt(
	results []healthResult,
	visible []catalogAction,
	finalStatus bool,
	accessible bool,
	fullScreen bool,
	stdin io.Reader,
	stdout io.Writer,
) (workflowDecision, error) {
	plain := accessible || !fullScreen
	if finalStatus {
		choice := "close"
		form := huh.NewForm(huh.NewGroup(
			huh.NewNote().
				Title("Setup check complete").
				Description(healthSummary(results)),
			huh.NewSelect[string]().Title("What next?").Options(
				huh.NewOption("Close", "close").Selected(true),
				huh.NewOption("Return to overview", "overview"),
			).Value(&choice),
		))
		if err := runLauncherForm(form, plain, fullScreen, stdin, stdout); err != nil {
			return workflowDecision{}, err
		}
		if choice == "close" {
			return workflowDecision{mode: workflowClose}, nil
		}
	}

	if !finalStatus && isFreshSetup(results) {
		choice := "install-all"
		form := huh.NewForm(huh.NewGroup(
			huh.NewNote().
				Title("DTU Python Support").
				Description("No DTU Python setup was found."),
			huh.NewSelect[string]().Title("Get started").Options(
				huh.NewOption("Install everything", "install-all").Selected(true),
				huh.NewOption("See more options", "overview"),
			).Value(&choice),
		))
		if err := runLauncherForm(form, plain, fullScreen, stdin, stdout); err != nil {
			return workflowDecision{}, err
		}
		if choice == "install-all" {
			return workflowDecision{mode: workflowExecute, actionIDs: []string{"install-all"}}, nil
		}
	}

	return promptOverview(results, visible, plain, fullScreen, stdin, stdout)
}

func promptOverview(
	results []healthResult,
	visible []catalogAction,
	plain bool,
	fullScreen bool,
	stdin io.Reader,
	stdout io.Writer,
) (workflowDecision, error) {
	selected := "__recheck__"
	options := make([]huh.Option[string], 0, len(visible)+1)
	for index, action := range visible {
		option := huh.NewOption(action.Name, action.ID)
		if index == 0 {
			option = option.Selected(true)
			selected = action.ID
		}
		options = append(options, option)
	}
	options = append(options, huh.NewOption("Check again", "__recheck__"))

	form := huh.NewForm(huh.NewGroup(
		huh.NewNote().
			Title("DTU Python Support — Your setup").
			Description(healthSummary(results)),
		huh.NewSelect[string]().
			Title("What would you like to do?").
			Filtering(false).
			Options(options...).
			Value(&selected),
	))
	if err := runLauncherForm(form, plain, fullScreen, stdin, stdout); err != nil {
		return workflowDecision{}, err
	}
	if selected == "__recheck__" {
		return workflowDecision{mode: workflowRecheck}, nil
	}
	return workflowDecision{mode: workflowExecute, actionIDs: []string{selected}}, nil
}

func runLauncherForm(
	form *huh.Form,
	plain bool,
	fullScreen bool,
	stdin io.Reader,
	stdout io.Writer,
) error {
	keymap := huh.NewDefaultKeyMap()
	keymap.Quit = key.NewBinding(
		key.WithKeys("ctrl+c", "esc"),
		key.WithHelp("esc", "cancel"),
	)
	form.WithKeyMap(keymap).WithAccessible(plain).WithInput(stdin).WithOutput(stdout)
	if fullScreen {
		form.WithViewHook(launcherViewHook)
	}
	return form.Run()
}

func launcherViewHook(view tea.View) tea.View {
	view.AltScreen = true
	view.WindowTitle = "DTU Python Support"
	return view
}

func runHealthChecks(
	checker healthChecker,
	catalog scriptCatalog,
	fullScreen bool,
	stdin io.Reader,
	stdout io.Writer,
) ([]healthResult, error) {
	var results []healthResult
	activity := huhspinner.New().
		Title("Checking your setup…").
		WithAccessible(!fullScreen).
		WithInput(stdin).
		WithOutput(stdout).
		Action(func() { results = checker.run(catalog) })
	if fullScreen {
		activity.WithViewHook(launcherViewHook)
	}
	if err := activity.Run(); err != nil {
		return nil, err
	}
	return results, nil
}
