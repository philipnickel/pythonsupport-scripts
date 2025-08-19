-- Diagnostics Manager for DTU Python Support Tools
-- Manages all diagnostic operations and integrates with existing shell components
-- Provides different levels of diagnostic checking with proper progress tracking

use AppleScript version "2.4"
use framework "Foundation"
use framework "AppKit"
use scripting additions

property componentScriptsPath : ""

on initializePaths()
	-- Get the path to diagnostic component scripts
	set resourcesPath to path to resource "" in bundle (path to me)
	set componentScriptsPath to (resourcesPath as string) & "diagnostics_components:"
end initializePaths

on runQuickCheck()
	initializePaths()
	
	-- Quick system overview - just basic checks
	set progress description to "Running Quick System Check..."
	set progress total steps to 3
	set progress completed steps to 0
	
	-- System info
	set progress completed steps to 1
	set progress description to "Checking system..."
	set sysCheck to runComponentScript("system_info.sh")
	
	-- Homebrew
	set progress completed steps to 2
	set progress description to "Checking Homebrew..."
	set brewCheck to runComponentScript("homebrew_check.sh")
	
	-- Python
	set progress completed steps to 3
	set progress description to "Checking Python..."
	set pythonCheck to runComponentScript("python_conda_check.sh")
	
	-- Show quick summary
	set progress description to "Analysis complete!"
	showQuickResults({sysCheck, brewCheck, pythonCheck})
end runQuickCheck

on runFullCheck()
	initializePaths()
	
	-- Comprehensive analysis using all components
	set progress description to "Running Comprehensive System Analysis..."
	set progress total steps to 6
	set progress completed steps to 0
	
	set componentResults to {}
	set fullLog to "DTU Python Support - Full Diagnostic Report" & return & ¬
		"Generated: " & (current date as string) & return & ¬
		"==========================================" & return & return
	
	-- Define components in order
	set components to {¬
		{name:"System Information", script:"system_info.sh"}, ¬
		{name:"Homebrew", script:"homebrew_check.sh"}, ¬
		{name:"Python/Conda", script:"python_conda_check.sh"}, ¬
		{name:"Visual Studio Code", script:"vscode_check.sh"}, ¬
		{name:"LaTeX", script:"latex_check.sh"}, ¬
		{name:"Environment", script:"environment_check.sh"}}
	
	-- Run each component
	repeat with i from 1 to (count of components)
		set currentComponent to item i of components
		set progress completed steps to i
		set progress description to "Checking " & (currentComponent's name) & "..."
		
		set componentResult to runComponentScript(currentComponent's script)
		set end of componentResults to {¬
			component:(currentComponent's name), ¬
			status:(componentResult's status), ¬
			details:(componentResult's output)}
		
		-- Add to full log
		set fullLog to fullLog & "=== " & (currentComponent's name) & " ===" & return & ¬
			(componentResult's output) & return & ¬
			"Exit Code: " & (componentResult's exitCode) & return & return
	end repeat
	
	-- Generate comprehensive summary
	set progress description to "Generating comprehensive report..."
	set summary to createFullSummary(componentResults)
	
	set progress description to "Analysis complete!"
	showFullResults(summary, componentResults, fullLog)
end runFullCheck

on runComponentCheck()
	initializePaths()
	
	-- Let user select which components to check
	set componentChoices to {"System Information", "Homebrew", "Python/Conda", "Visual Studio Code", "LaTeX", "Environment"}
	set selectedComponents to choose from list componentChoices with title "Select Components" with prompt "Choose which components to check:" default items componentChoices with multiple selections allowed
	
	if selectedComponents is false then
		return -- User cancelled
	end if
	
	set progress description to "Running Selected Component Checks..."
	set progress total steps to (count of selectedComponents)
	set progress completed steps to 0
	
	set componentResults to {}
	
	-- Run selected components
	repeat with i from 1 to (count of selectedComponents)
		set componentName to item i of selectedComponents
		set progress completed steps to i
		set progress description to "Checking " & componentName & "..."
		
		-- Map component names to script files
		set scriptName to ""
		if componentName is "System Information" then
			set scriptName to "system_info.sh"
		else if componentName is "Homebrew" then
			set scriptName to "homebrew_check.sh"
		else if componentName is "Python/Conda" then
			set scriptName to "python_conda_check.sh"
		else if componentName is "Visual Studio Code" then
			set scriptName to "vscode_check.sh"
		else if componentName is "LaTeX" then
			set scriptName to "latex_check.sh"
		else if componentName is "Environment" then
			set scriptName to "environment_check.sh"
		end if
		
		if scriptName is not "" then
			set componentResult to runComponentScript(scriptName)
			set end of componentResults to {¬
				component:componentName, ¬
				status:(componentResult's status), ¬
				details:(componentResult's output)}
		end if
	end repeat
	
	set progress description to "Analysis complete!"
	set summary to createComponentSummary(componentResults)
	showComponentResults(summary, componentResults)
end runComponentCheck

on runComponentScript(scriptName)
	-- Execute a diagnostic component script and parse results
	try
		-- Construct path to the script
		set scriptPath to (componentScriptsPath as string) & scriptName
		set scriptPosixPath to POSIX path of scriptPath
		
		-- Make script executable and run it
		set shellCommand to "chmod +x " & quoted form of scriptPosixPath & " && " & quoted form of scriptPosixPath
		set scriptOutput to do shell script shellCommand
		
		-- Determine status based on output
		set componentStatus to "✓ Passed"
		if scriptOutput contains "✗" then
			set componentStatus to "✗ Failed"
		else if scriptOutput contains "⚠" then
			set componentStatus to "⚠ Warning"
		end if
		
		return {status:componentStatus, output:scriptOutput, exitCode:0}
		
	on error errMsg
		return {status:"✗ Error", output:"Error running component: " & errMsg, exitCode:1}
	end try
end runComponentScript

on createFullSummary(componentResults)
	set totalItems to (count of componentResults)
	set passedItems to 0
	set warningItems to 0
	set failedItems to 0
	
	repeat with result in componentResults
		set status to result's status
		if status starts with "✓" then
			set passedItems to passedItems + 1
		else if status starts with "⚠" then
			set warningItems to warningItems + 1
		else if status starts with "✗" then
			set failedItems to failedItems + 1
		end if
	end repeat
	
	set summary to "DTU Python Support - Comprehensive Analysis" & return & return & ¬
		"Total Components Analyzed: " & totalItems & return & ¬
		"✓ Passed: " & passedItems & return & ¬
		"⚠ Warnings: " & warningItems & return & ¬
		"✗ Failed: " & failedItems & return & return
	
	if failedItems = 0 and warningItems = 0 then
		set summary to summary & "🎉 Your system is fully ready for Python development at DTU!"
	else if failedItems = 0 then
		set summary to summary & "⚠ Your system is mostly ready. Review warnings for optimal setup."
	else
		set summary to summary & "❌ Your system requires setup before Python development."
	end if
	
	return summary
end createFullSummary

on createComponentSummary(componentResults)
	return createFullSummary(componentResults)
end createComponentSummary

on showQuickResults(results)
	-- Show abbreviated results for quick check
	set resultText to "Quick System Check Results" & return & return
	repeat with result in results
		set resultText to resultText & result's status & " " & result's component & return
	end repeat
	
	set quickResult to display dialog resultText ¬
		buttons {"Run Full Check", "OK"} ¬
		default button "OK" ¬
		with title "Quick Check Complete" ¬
		with icon note
	
	if button returned of quickResult is "Run Full Check" then
		runFullCheck()
	end if
end showQuickResults

on showFullResults(summary, componentResults, fullLog)
	-- Show comprehensive results with detailed options
	set resultText to summary & return & return & "Component Status:" & return & return
	repeat with result in componentResults
		set resultText to resultText & result's status & " " & result's component & return
	end repeat
	
	set fullResult to display dialog resultText ¬
		buttons {"View Details", "Email Report", "OK"} ¬
		default button "OK" ¬
		with title "Comprehensive Analysis Complete" ¬
		with icon note
	
	set buttonPressed to button returned of fullResult
	
	if buttonPressed is "View Details" then
		showDetailedResults(summary, componentResults, fullLog)
	else if buttonPressed is "Email Report" then
		emailDiagnosticReport(summary, componentResults, fullLog)
	end if
end showFullResults

on showComponentResults(summary, componentResults)
	-- Show results for selected components
	set resultText to summary & return & return & "Component Status:" & return & return
	repeat with result in componentResults
		set resultText to resultText & result's status & " " & result's component & return
	end repeat
	
	display dialog resultText ¬
		buttons {"OK"} ¬
		default button "OK" ¬
		with title "Component Check Complete" ¬
		with icon note
end showComponentResults

on showDetailedResults(summary, componentResults, fullLog)
	-- Show detailed results in scrollable window
	try
		set outputContent to fullLog & return & return & ¬
			"==========================================" & return & ¬
			"End of Diagnostic Report" & return & ¬
			"For support, contact: pythonsupport@dtu.dk"
		
		set alert to current application's NSAlert's alloc()'s init()
		alert's setMessageText:"Detailed Diagnostic Results"
		alert's setInformativeText:""
		alert's addButtonWithTitle:"Email Report"
		alert's addButtonWithTitle:"Save Report"
		alert's addButtonWithTitle:"Close"
		
		set frame to current application's NSMakeRect(0, 0, 700, 420)
		set scrollView to current application's NSScrollView's alloc()'s initWithFrame:frame
		scrollView's setHasVerticalScroller:true
		scrollView's setHasHorizontalScroller:true
		scrollView's setBorderType:(current application's NSBezelBorder)
		
		set textView to current application's NSTextView's alloc()'s initWithFrame:frame
		textView's setEditable:false
		textView's setSelectable:true
		textView's setDrawsBackground:true
		textView's setBackgroundColor:(current application's NSColor's blackColor())
		
		set attrDict to current application's NSMutableDictionary's dictionary()
		attrDict's setValue:(current application's NSColor's whiteColor()) forKey:(current application's NSForegroundColorAttributeName)
		attrDict's setValue:((current application's NSFont's userFixedPitchFontOfSize:12)) forKey:(current application's NSFontAttributeName)
		set attributed to (current application's NSAttributedString's alloc()'s initWithString:outputContent attributes:attrDict)
		(textView's textStorage()'s setAttributedString:attributed)
		
		scrollView's setDocumentView:textView
		alert's setAccessoryView:scrollView
		
		(current application's NSApp's activateIgnoringOtherApps:true)
		set modalResult to alert's runModal()
		
		if modalResult = (current application's NSAlertFirstButtonReturn) then
			emailDiagnosticReport(summary, componentResults, fullLog)
		else if modalResult = (current application's NSAlertSecondButtonReturn) then
			saveDiagnosticReport(summary, componentResults, fullLog)
		end if
		
	on error errorMessage
		display dialog "Failed to show detailed results:" & return & return & errorMessage ¬
			buttons {"OK"} default button "OK" with title "Error" with icon stop
	end try
end showDetailedResults

on emailDiagnosticReport(summary, componentResults, fullLog)
	-- Generate and email diagnostic report
	try
		set reportContent to "DTU Python Support - Diagnostic Report" & return & return & ¬
			"Generated: " & (current date as string) & return & return & ¬
			summary & return & return & ¬
			fullLog & return & ¬
			"For support, contact: pythonsupport@dtu.dk"
		
		set emailSubject to "DTU Python Support Diagnostic Report"
		do shell script "open 'mailto:pythonsupport@dtu.dk?subject=" & emailSubject & "&body=" & reportContent & "'"
		
		display dialog "Email client opened with diagnostic report." ¬
			buttons {"OK"} default button "OK" with title "Email Report" with icon note
			
	on error errorMessage
		display dialog "Failed to open email:" & return & return & errorMessage ¬
			buttons {"OK"} default button "OK" with title "Email Error" with icon stop
	end try
end emailDiagnosticReport

on saveDiagnosticReport(summary, componentResults, fullLog)
	-- Save diagnostic report to desktop
	try
		set reportContent to "DTU Python Support - Diagnostic Report" & return & return & ¬
			"Generated: " & (current date as string) & return & return & ¬
			summary & return & return & ¬
			fullLog
		
		set desktopPath to (path to desktop as string)
		set reportPath to desktopPath & "DTU_Python_Diagnostics_" & (do shell script "date +%Y%m%d_%H%M%S") & ".txt"
		
		set reportFile to open for access file reportPath with write permission
		write reportContent to reportFile
		close access reportFile
		
		display dialog "Diagnostic report saved to Desktop." ¬
			buttons {"OK"} default button "OK" with title "Report Saved" with icon note
			
	on error errorMessage
		display dialog "Failed to save report:" & return & return & errorMessage ¬
			buttons {"OK"} default button "OK" with title "Save Error" with icon stop
	end try
end saveDiagnosticReport