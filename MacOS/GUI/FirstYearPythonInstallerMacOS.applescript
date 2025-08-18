-- First Year Python Installer for macOS
-- AppleScript application for DTU Python Support tools
-- Provides a simple interface to run diagnostics and installation tools for first-year students

on run
	-- Main application entry point
	showMainDialog()
end run

on showMainDialog()
	-- Create the main dialog with options
	set dialogResult to display dialog "DTU First Year Python Installer" & return & return & "Welcome to the First Year Python Installer!" & return & return & "This application helps first-year students set up their Python development environment at DTU." & return & return & "Please select an option:" buttons {"Install", "Run Diagnostics", "Cancel"} default button "Install" cancel button "Cancel" with title "First Year Python Installer" with icon note
	
	if button returned of dialogResult is "Install" then
		showFirstYearSetupDialog()
	else if button returned of dialogResult is "Run Diagnostics" then
		runDiagnostics()
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
	
	-- Execute the diagnostics script and capture output
	set diagnosticsScript to "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/dtudk/pythonsupport-scripts/main/MacOS/Components/Diagnostics/run.sh)\""
	
	try
		set diagnosticsOutput to do shell script diagnosticsScript
		set progress completed steps to 3
		set progress description to "Diagnostics completed!"
		
		-- Show results dialog with captured output
		set resultText to "First Year Python Diagnostics completed successfully!" & return & return & "System diagnostics results:" & return & return
		
		-- Truncate output if too long (AppleScript dialog has limits)
		if length of diagnosticsOutput > 1000 then
			set resultText to resultText & "Output is too long to display here. Check the terminal for full results." & return & return & "Summary: Diagnostics completed successfully."
		else
			set resultText to resultText & diagnosticsOutput
		end if
		
		set result to display dialog resultText buttons {"OK", "Show in Terminal"} default button "OK" with title "First Year Python Diagnostics Complete" with icon note
		
		-- If user wants to see in terminal, open terminal and show results
		if button returned of result is "Show in Terminal" then
			do shell script "open -a Terminal"
			delay 1
			do shell script "osascript -e 'tell application \"Terminal\" to do script \"echo \\\"=== First Year Python Diagnostics Results ===\\\" && " & diagnosticsScript & "\"'"
		end if
		
	on error errorMessage
		-- Show error dialog
		display dialog "Error running First Year Python diagnostics:" & return & return & errorMessage & return & return & "Please try again or contact Python Support if the problem persists." buttons {"OK"} default button "OK" with title "First Year Python Diagnostics Error" with icon stop
	end try
end runDiagnostics

on showFirstYearSetupDialog()
	-- Show warning dialog for first year setup
	set setupResult to display dialog "First Year Python Installation" & return & return & "This will install a complete Python development environment including:" & return & "• Homebrew package manager" & return & "• Python with Miniconda" & return & "• Visual Studio Code" & return & "• Essential Python packages for DTU courses" & return & return & "This process may take 10-15 minutes and requires administrator privileges." & return & return & "Do you want to proceed with the installation?" buttons {"Install", "Cancel"} default button "Install" cancel button "Cancel" with title "First Year Python Installation" with icon caution
	
	if button returned of setupResult is "Install" then
		-- For now, just show a message that this feature is not yet implemented
		display dialog "Installation Coming Soon" & return & return & "The automated installation feature is currently under development." & return & return & "For now, please:" & return & "1. Use the diagnostics tool to check your system" & return & "2. Run the installation manually using the command line tools" & return & return & "Contact Python Support if you need assistance: pythonsupport@dtu.dk" buttons {"OK"} default button "OK" with title "Installation Not Available" with icon note
	end if
end showFirstYearSetupDialog

-- Handle application events
on quit
	continue quit
end quit
