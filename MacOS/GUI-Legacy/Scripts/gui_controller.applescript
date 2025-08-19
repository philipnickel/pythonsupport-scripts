-- GUI Controller for DTU Python Support Tools
-- Central controller that manages all GUI interactions and workflows
-- Provides routing between different installation and diagnostic options

property appName : "DTU Python Support"

on showMainMenu()
	-- Main menu with full range of options
	set dialogText to appName & return & return & ¬
		"Welcome to the DTU Python Support Tools!" & return & return & ¬
		"This application provides comprehensive Python development setup and diagnostics for DTU students." & return & return & ¬
		"Please select an option:"
	
	set mainResult to display dialog dialogText ¬
		buttons {"Diagnostics", "Install", "Advanced"} ¬
		default button "Diagnostics" ¬
		with title appName ¬
		with icon note
	
	set buttonPressed to button returned of mainResult
	
	if buttonPressed is "Diagnostics" then
		showDiagnosticsMenu()
	else if buttonPressed is "Install" then
		showInstallationMenu()
	else if buttonPressed is "Advanced" then
		showAdvancedMenu()
	end if
end showMainMenu

on showDiagnosticsMenu()
	-- Diagnostics options submenu
	set dialogText to "Diagnostics Options" & return & return & ¬
		"Choose the type of diagnostic check to run:" & return & return & ¬
		"• Quick Check: Fast overview of system status" & return & ¬
		"• Full Check: Comprehensive analysis with detailed reporting" & return & ¬
		"• Component Check: Individual component analysis"
	
	set diagResult to display dialog dialogText ¬
		buttons {"Quick Check", "Full Check", "Component Check", "Back"} ¬
		default button "Full Check" ¬
		cancel button "Back" ¬
		with title "Diagnostics Menu" ¬
		with icon note
	
	set buttonPressed to button returned of diagResult
	
	if buttonPressed is "Quick Check" then
		runQuickDiagnostics()
	else if buttonPressed is "Full Check" then
		runFullDiagnostics()
	else if buttonPressed is "Component Check" then
		runComponentDiagnostics()
	else if buttonPressed is "Back" then
		showMainMenu()
	end if
end showDiagnosticsMenu

on showInstallationMenu()
	-- Installation options submenu
	set dialogText to "Installation Options" & return & return & ¬
		"Choose your installation type:" & return & return & ¬
		"• First Year: Basic setup for new students" & return & ¬
		"• Advanced: Full development environment" & return & ¬
		"• Custom: Select specific components" & return & ¬
		"• Repair: Fix existing installation issues"
	
	set installResult to display dialog dialogText ¬
		buttons {"First Year", "Advanced", "Custom", "Back"} ¬
		default button "First Year" ¬
		cancel button "Back" ¬
		with title "Installation Menu" ¬
		with icon note
	
	set buttonPressed to button returned of installResult
	
	if buttonPressed is "First Year" then
		runFirstYearInstallation()
	else if buttonPressed is "Advanced" then
		runAdvancedInstallation()
	else if buttonPressed is "Custom" then
		runCustomInstallation()
	else if buttonPressed is "Back" then
		showMainMenu()
	end if
end showInstallationMenu

on showAdvancedMenu()
	-- Advanced options submenu
	set dialogText to "Advanced Options" & return & return & ¬
		"Advanced tools and utilities:" & return & return & ¬
		"• System Report: Generate detailed system report" & return & ¬
		"• Environment Repair: Fix common configuration issues" & return & ¬
		"• Package Management: Manage Python packages" & return & ¬
		"• Settings: Configure application preferences"
	
	set advResult to display dialog dialogText ¬
		buttons {"System Report", "Environment Repair", "Settings", "Back"} ¬
		default button "System Report" ¬
		cancel button "Back" ¬
		with title "Advanced Menu" ¬
		with icon note
	
	set buttonPressed to button returned of advResult
	
	if buttonPressed is "System Report" then
		generateSystemReport()
	else if buttonPressed is "Environment Repair" then
		runEnvironmentRepair()
	else if buttonPressed is "Settings" then
		showSettings()
	else if buttonPressed is "Back" then
		showMainMenu()
	end if
end showAdvancedMenu

-- Diagnostics handlers
on runQuickDiagnostics()
	set diagnosticsHandler to load script (path to resource "diagnostics_manager.scpt" in bundle (path to me))
	diagnosticsHandler's runQuickCheck()
	showMainMenu()
end runQuickDiagnostics

on runFullDiagnostics()
	set diagnosticsHandler to load script (path to resource "diagnostics_manager.scpt" in bundle (path to me))
	diagnosticsHandler's runFullCheck()
	showMainMenu()
end runFullDiagnostics

on runComponentDiagnostics()
	set diagnosticsHandler to load script (path to resource "diagnostics_manager.scpt" in bundle (path to me))
	diagnosticsHandler's runComponentCheck()
	showMainMenu()
end runComponentDiagnostics

-- Installation handlers
on runFirstYearInstallation()
	set installationHandler to load script (path to resource "installation_manager.scpt" in bundle (path to me))
	installationHandler's runFirstYearSetup()
	showMainMenu()
end runFirstYearInstallation

on runAdvancedInstallation()
	set installationHandler to load script (path to resource "installation_manager.scpt" in bundle (path to me))
	installationHandler's runAdvancedSetup()
	showMainMenu()
end runAdvancedInstallation

on runCustomInstallation()
	set installationHandler to load script (path to resource "installation_manager.scpt" in bundle (path to me))
	installationHandler's runCustomSetup()
	showMainMenu()
end runCustomInstallation

-- Advanced handlers
on generateSystemReport()
	set reportHandler to load script (path to resource "report_manager.scpt" in bundle (path to me))
	reportHandler's generateFullReport()
	showMainMenu()
end generateSystemReport

on runEnvironmentRepair()
	set repairHandler to load script (path to resource "repair_manager.scpt" in bundle (path to me))
	repairHandler's runEnvironmentRepair()
	showMainMenu()
end runEnvironmentRepair

on showSettings()
	set settingsHandler to load script (path to resource "settings_manager.scpt" in bundle (path to me))
	settingsHandler's showSettingsDialog()
	showMainMenu()
end showSettings