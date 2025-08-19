-- First Year Python Installer for macOS
-- Main AppleScript application for DTU Python Support tools
-- Provides a simple interface to run diagnostics and installation tools for first-year students

on run
	-- Main application entry point
	showMainDialog()
end run

on showMainDialog()
	-- Create the main dialog with vertically stacked options
	set dialogResult to display dialog "DTU First Year Python Installer" & return & return & "Welcome to the First Year Python Installer!" & return & return & "This application helps first-year students set up their Python development environment at DTU." & return & return & "Please select an option:" buttons {"Install", "Run Diagnostics", "Cancel"} default button "Install" cancel button "Cancel" with title "First Year Python Installer" with icon note
	
	if button returned of dialogResult is "Install" then
		showFirstYearSetupDialog()
	else if button returned of dialogResult is "Run Diagnostics" then
		runComponentDiagnostics()
	end if
end showMainDialog

on runComponentDiagnostics()
	-- Load diagnostics handler
	set diagnosticsScript to load script (path to resource "diagnostics_handler.scpt" in bundle (path to me))
	
	-- Run the component-based diagnostics
	diagnosticsScript's runComponentDiagnostics()
end runComponentDiagnostics

on showFirstYearSetupDialog()
	-- Load installation handler
	set installationScript to load script (path to resource "installation_handler.scpt" in bundle (path to me))
	
	-- Show installation dialog
	installationScript's showFirstYearSetupDialog()
end showFirstYearSetupDialog

-- Handle application events
on quit
	continue quit
end quit
