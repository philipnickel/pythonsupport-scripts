-- First Year Python Installer for macOS
-- AppleScript application for DTU Python Support tools
-- Provides a simple interface to run diagnostics and installation tools for first-year students

on run
	-- Main application entry point
	showMainDialog()
end run

on showMainDialog()
	-- Create the main dialog with options
	set dialogResult to display dialog "DTU First Year Python Installer" & return & return & "Welcome to the First Year Python Installer!" & return & return & "This application helps first-year students set up their Python development environment at DTU." & return & return & "Please select an option:" buttons {"Run Diagnostics", "First Year Setup", "Cancel"} default button "Run Diagnostics" cancel button "Cancel" with title "First Year Python Installer" with icon note
	
	if button returned of dialogResult is "Run Diagnostics" then
		runDiagnostics()
	else if button returned of dialogResult is "First Year Setup" then
		showFirstYearSetupDialog()
	end if
end showMainDialog

on runDiagnostics()
	-- Show progress dialog
	set progress description to "Running First Year Python Diagnostics..."
	set progress total steps to 3
	set progress completed steps to 0
	
	-- Step 1: Prepare diagnostics
	set progress completed steps to 1
	set progress description to "Preparing diagnostics..."
	
	-- Step 2: Run diagnostics script
	set progress completed steps to 2
	set progress description to "Running system diagnostics..."
	
	-- Execute the diagnostics script
	set diagnosticsScript to "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Diagnostics/run.sh)\""
	
	try
		do shell script diagnosticsScript
		set progress completed steps to 3
		set progress description to "Diagnostics completed!"
		
		-- Show results dialog
		display dialog "First Year Python Diagnostics completed successfully!" & return & return & "The system diagnostics have been run and results are shown in the terminal." & return & return & "Check the terminal output for detailed information about your system setup." buttons {"OK"} default button "OK" with title "First Year Python Diagnostics Complete" with icon note
		
	on error errorMessage
		-- Show error dialog
		display dialog "Error running First Year Python diagnostics:" & return & return & errorMessage & return & return & "Please try again or contact Python Support if the problem persists." buttons {"OK"} default button "OK" with title "First Year Python Diagnostics Error" with icon stop
	end try
end runDiagnostics

on showFirstYearSetupDialog()
	-- Show warning dialog for first year setup
	set setupResult to display dialog "First Year Student Setup" & return & return & "This will install a complete Python development environment including:" & return & "• Homebrew package manager" & return & "• Python with Miniconda" & return & "• Visual Studio Code" & return & "• Essential Python packages" & return & return & "This process may take 10-15 minutes and requires administrator privileges." & return & return & "Do you want to proceed?" buttons {"Run Setup", "Cancel"} default button "Run Setup" cancel button "Cancel" with title "First Year Setup" with icon caution
	
	if button returned of setupResult is "Run Setup" then
		-- For now, just show a message that this feature is not yet implemented
		display dialog "First Year Setup" & return & return & "This feature is currently under development." & return & return & "For now, please use the diagnostics tool to check your system, or run the setup manually using the command line tools." buttons {"OK"} default button "OK" with title "Setup Not Available" with icon note
	end if
end showFirstYearSetupDialog

-- Handle application events
on quit
	continue quit
end quit
