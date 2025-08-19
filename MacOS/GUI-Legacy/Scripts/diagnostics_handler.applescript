use AppleScript version "2.4"
use framework "Foundation"
use framework "AppKit"
use scripting additions

-- Diagnostics Handler for First Year Python Installer
-- Handles component-based diagnostics with progress tracking and reporting

on runComponentDiagnostics()
	-- Show initial progress dialog
	set progress description to "Initializing First Year Python Diagnostics..."
	set progress total steps to 6
	set progress completed steps to 0
	
	-- Initialize results and log
	set diagnosticResults to {}
	set fullLog to ""
	
	-- 1) System Information
	set progress completed steps to 1
	set progress description to "Checking System Information..."
	set sys to checkSystemInfo()
	set end of diagnosticResults to sys
	set fullLog to fullLog & "=== System Information ===" & return & sys's details & return & "Exit Code: 0" & return & return
	
	-- 2) Homebrew
	set progress completed steps to 2
	set progress description to "Checking Homebrew..."
	set hb to checkHomebrew()
	set end of diagnosticResults to hb
	set fullLog to fullLog & "=== Homebrew ===" & return & hb's details & return & "Exit Code: 0" & return & return
	
	-- 3) Python/Conda
	set progress completed steps to 3
	set progress description to "Checking Python/Conda..."
	set py to checkPythonConda()
	set end of diagnosticResults to py
	set fullLog to fullLog & "=== Python/Conda ===" & return & py's details & return & "Exit Code: 0" & return & return
	
	-- 4) Visual Studio Code
	set progress completed steps to 4
	set progress description to "Checking Visual Studio Code..."
	set vs to checkVSCode()
	set end of diagnosticResults to vs
	set fullLog to fullLog & "=== Visual Studio Code ===" & return & vs's details & return & "Exit Code: 0" & return & return
	
	-- 5) LaTeX
	set progress completed steps to 5
	set progress description to "Checking LaTeX..."
	set lx to checkLatex()
	set end of diagnosticResults to lx
	set fullLog to fullLog & "=== LaTeX ===" & return & lx's details & return & "Exit Code: 0" & return & return
	
	-- 6) Environment
	set progress completed steps to 6
	set progress description to "Checking Environment..."
	set env to checkEnvironment()
	set end of diagnosticResults to env
	set fullLog to fullLog & "=== Environment ===" & return & env's details & return & "Exit Code: 0" & return & return
	
	-- Summary
	set progress description to "Generating diagnostic summary..."
	set summary to createSimpleSummary(diagnosticResults)
	
	-- Show results
	set progress description to "Diagnostics completed!"
	showSimpleResults(summary, diagnosticResults, fullLog)
end runComponentDiagnostics

on checkSystemInfo()
	try
		set osVersion to do shell script "sw_vers -productVersion"
		set architecture to do shell script "uname -m"
		set hostname to do shell script "hostname"
		set details to "SYSTEM INFORMATION" & return & "------------------" & return & ¬
			"macOS Version: " & osVersion & return & ¬
			"Architecture: " & architecture & return & ¬
			"Hostname: " & hostname & return & return & ¬
			"✓ System information collected"
		set status to "✓ Passed"
		return {component:"System Information", status:status, details:details}
	on error errMsg
		return {component:"System Information", status:"✗ Failed", details:"Error: " & errMsg}
	end try
end checkSystemInfo

on checkHomebrew()
	try
		set brewPath to do shell script "command -v brew || true"
		if brewPath is not "" then
			set brewVersion to do shell script "brew --version | head -n 1"
			set details to "HOMEBREW" & return & "--------" & return & ¬
				"✓ Homebrew is installed" & return & ¬
				"  Version: " & brewVersion & return & ¬
				"  Location: " & brewPath & return & return & ¬
				"  Status: ✓ Installed (brew doctor check skipped)" & return & ¬
				"  Note: Run 'brew doctor' manually if you need detailed status"
			set status to "✓ Passed"
		else
			set details to "HOMEBREW" & return & "--------" & return & ¬
				"✗ Homebrew is not installed" & return & ¬
				"  Required for Python development setup" & return
			set status to "✗ Failed"
		end if
		return {component:"Homebrew", status:status, details:details}
	on error errMsg
		return {component:"Homebrew", status:"✗ Failed", details:"Error: " & errMsg}
	end try
end checkHomebrew

on checkPythonConda()
	try
		set condaPath to do shell script "command -v conda || true"
		if condaPath is not "" then
			set condaVersion to do shell script "conda --version 2>&1"
			set condaBase to do shell script "conda info --base 2>&1"
			set packages to do shell script "conda list 2>&1 | egrep '^(dtumathtools|pandas|scipy|statsmodels|uncertainties)\\s' || true"
			set details to "PYTHON/CONDA" & return & "-------------" & return & ¬
				"✓ Conda is installed" & return & ¬
				"  " & condaVersion & return & ¬
				"  Base environment: " & condaBase & return & ¬
				"  Key packages:" & return & packages
			set status to "✓ Passed"
		else
			set py3Path to do shell script "command -v python3 || true"
			if py3Path is not "" then
				set py3Version to do shell script "python3 --version 2>&1"
				set details to "PYTHON/CONDA" & return & "-------------" & return & ¬
					"⚠ Conda not installed" & return & ¬
					"  System Python3: " & py3Version & return & ¬
					"  Location: " & py3Path & return & ¬
					"  Note: Conda recommended for DTU courses"
				set status to "⚠ Warning"
			else
				set details to "PYTHON/CONDA" & return & "-------------" & return & ¬
					"✗ No Python installation found" & return & ¬
					"  Required for Python development"
				set status to "✗ Failed"
			end if
		end if
		return {component:"Python/Conda", status:status, details:details}
	on error errMsg
		return {component:"Python/Conda", status:"✗ Failed", details:"Error: " & errMsg}
	end try
end checkPythonConda

on checkVSCode()
	try
		set codePath to do shell script "command -v code || true"
		if codePath is not "" then
			set codeVersion to do shell script "code --version | head -n 1 2>&1"
			set extList to do shell script "code --list-extensions 2>&1 | head -n 50 || true"
			set details to "VISUAL STUDIO CODE" & return & "------------------" & return & ¬
				"✓ Visual Studio Code is installed" & return & ¬
				"  Version: " & codeVersion & return & ¬
				"  Location: " & codePath & return & ¬
				"  Extensions (first 50):" & return & extList
			set status to "✓ Passed"
		else
			-- Check Applications fallback
			set appExists to do shell script "[ -d '/Applications/Visual Studio Code.app' ] && echo yes || echo no"
			if appExists = "yes" then
				set details to "VISUAL STUDIO CODE" & return & "------------------" & return & ¬
					"⚠ Found in Applications but not in PATH" & return & ¬
					"  Consider adding 'code' to PATH or reinstalling"
				set status to "⚠ Warning"
			else
				set details to "VISUAL STUDIO CODE" & return & "------------------" & return & ¬
					"✗ Visual Studio Code is not installed"
				set status to "✗ Failed"
			end if
		end if
		return {component:"Visual Studio Code", status:status, details:details}
	on error errMsg
		return {component:"Visual Studio Code", status:"✗ Failed", details:"Error: " & errMsg}
	end try
end checkVSCode

on checkLatex()
	try
		set tlmgrPath to do shell script "command -v tlmgr || true"
		if tlmgrPath is not "" then
			set tlmgrVer to do shell script "tlmgr --version | head -n 1 2>&1"
			set havePandoc to do shell script "command -v pandoc >/dev/null 2>&1 && echo yes || echo no"
			set pandocLine to "✗ Pandoc is not installed"
			if havePandoc = "yes" then set pandocLine to "✓ Pandoc: " & (do shell script "pandoc --version | head -n 1 2>&1")
			set haveNbconvert to do shell script "python3 -c 'import nbconvert' 2>/dev/null && echo yes || echo no"
			set nbLine to "✗ nbconvert is not available"
			if haveNbconvert = "yes" then set nbLine to "✓ nbconvert is available"
			set details to "LATEX" & return & "-----" & return & ¬
				"✓ TeX Live is installed" & return & ¬
				"  Location: " & tlmgrPath & return & ¬
				"  " & tlmgrVer & return & ¬
				pandocLine & return & nbLine
			set status to "✓ Passed"
		else
			set details to "LATEX" & return & "-----" & return & ¬
				"✗ TeX Live is not installed" & return & ¬
				"  Required for PDF export from Jupyter notebooks"
			set status to "✗ Failed"
		end if
		return {component:"LaTeX", status:status, details:details}
	on error errMsg
		return {component:"LaTeX", status:"✗ Failed", details:"Error: " & errMsg}
	end try
end checkLatex

on checkEnvironment()
	try
		set shellPath to do shell script "echo $SHELL"
		set condaInPath to do shell script "echo $PATH | grep -q conda && echo yes || echo no"
		set hasZshrc to do shell script "[ -f ~/.zshrc ] && echo yes || echo no"
		set hasZprofile to do shell script "[ -f ~/.zprofile ] && echo yes || echo no"
		set condaLine to "⚠ Conda not found in PATH"
		if condaInPath = "yes" then set condaLine to "✓ Conda found in PATH"
		set zshrcLine to "missing"
		if hasZshrc = "yes" then set zshrcLine to "present"
		set zprofileLine to "missing"
		if hasZprofile = "yes" then set zprofileLine to "present"
		set details to "SHELL CONFIGURATION" & return & "-------------------" & return & ¬
			"Current shell: " & shellPath & return & ¬
			condaLine & return & ¬
			"~/.zshrc: " & zshrcLine & return & ¬
			"~/.zprofile: " & zprofileLine
		set status to "✓ Passed"
		if condaInPath is "no" then set status to "⚠ Warning"
		return {component:"Environment", status:status, details:details}
	on error errMsg
		return {component:"Environment", status:"✗ Failed", details:"Error: " & errMsg}
	end try
end checkEnvironment

on createSimpleSummary(diagnosticResults)
	set totalItems to (count of diagnosticResults)
	set passedItems to 0
	set warningItems to 0
	set failedItems to 0
	repeat with r in diagnosticResults
		set s to r's status as text
		if s starts with "✓" then
			set passedItems to passedItems + 1
		else if s starts with "⚠" then
			set warningItems to warningItems + 1
		else if s starts with "✗" then
			set failedItems to failedItems + 1
		end if
	end repeat
	set summary to "First Year Python Diagnostics Summary" & return & return & ¬
		"Total Components Checked: " & totalItems & return & ¬
		"✓ Passed: " & passedItems & return & ¬
		"⚠ Warnings: " & warningItems & return & ¬
		"✗ Failed: " & failedItems & return & return
	if failedItems = 0 and warningItems = 0 then
		set summary to summary & "🎉 Your system is ready for Python development!"
	else if failedItems = 0 then
		set summary to summary & "⚠ Your system is mostly ready, but some improvements are recommended."
	else
		set summary to summary & "❌ Your system needs setup before Python development."
	end if
	return summary
end createSimpleSummary

on showSimpleResults(summary, diagnosticResults, fullLog)
	-- Show simple results dialog
	set resultText to summary & return & return & "Component Checklist:" & return & return
	repeat with r in diagnosticResults
		set resultText to resultText & r's status & " " & r's component & return
	end repeat
	
	set result to display dialog resultText buttons {"View Details", "OK"} default button "OK" with title "First Year Python Diagnostics Complete" with icon note
	if button returned of result is "View Details" then
		showDetailedResults(summary, diagnosticResults, fullLog)
	end if
end showSimpleResults

on showDetailedResults(summary, diagnosticResults, fullLog)
	-- Show detailed results in an embedded, scrollable window using AppleScriptObjC
	try
		-- Build the complete output with full log
		set outputContent to "DTU First Year Python Diagnostics - Complete Log" & return & return & ¬
			"Generated: " & (current date as string) & return & return & ¬
			"==========================================" & return & return & ¬
			fullLog & return & return & ¬
			"==========================================" & return & ¬
			"End of Diagnostic Results" & return & ¬
			"For support, contact: pythonsupport@dtu.dk" & return
		
		-- Prepare a scrollable text view
		set alert to current application's NSAlert's alloc()'s init()
		alert's setMessageText:"Detailed Diagnostic Results"
		alert's setInformativeText:""
		-- Buttons: Email Report (default) and Close
		alert's addButtonWithTitle:"Email Report"
		alert's addButtonWithTitle:"Close"
		
		set frame to current application's NSMakeRect(0, 0, 700, 420)
		set scrollView to current application's NSScrollView's alloc()'s initWithFrame:frame
		scrollView's setHasVerticalScroller:true
		scrollView's setHasHorizontalScroller:true
		scrollView's setBorderType:(current application's NSBezelBorder)
		
		set textView to current application's NSTextView's alloc()'s initWithFrame:frame
		textView's setEditable:false
		textView's setSelectable:true
		-- Dark background + white monospaced text
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
		-- If first button pressed (Email Report), send email with full output
		if modalResult = (current application's NSAlertFirstButtonReturn) then
			my emailDiagnosticReport(summary, diagnosticResults, fullLog)
		end if
		
	on error errorMessage
		display dialog "Failed to render detailed results:" & return & return & errorMessage buttons {"OK"} default button "OK" with title "Error" with icon stop
	end try
end showDetailedResults

on downloadSimpleReport(summary)
	-- Generate and download simple report
	try
		set reportContent to "DTU First Year Python Diagnostics Report" & return & return
		set reportContent to reportContent & "Generated: " & (current date as string) & return & return
		set reportContent to reportContent & summary & return & return
		set reportContent to reportContent & "For detailed component results, run the command line diagnostics."
		
		-- Save to desktop
		set desktopPath to (path to desktop as string)
		set reportPath to desktopPath & "DTU_Python_Diagnostics_Report.txt"
		
		set reportFile to open for access file reportPath with write permission
		write reportContent to reportFile
		close access reportFile
		
		display dialog "Diagnostic report saved to Desktop:" & return & return & "DTU_Python_Diagnostics_Report.txt" buttons {"OK"} default button "OK" with title "Report Downloaded" with icon note
		
	on error errorMessage
		display dialog "Failed to download report:" & return & return & errorMessage buttons {"OK"} default button "OK" with title "Download Error" with icon stop
	end try
end downloadSimpleReport

on emailDiagnosticReport(summary, diagnosticResults, fullLog)
	-- Generate and email diagnostic report with full terminal output
	try
		set reportContent to "DTU First Year Python Diagnostics Report" & return & return
		set reportContent to reportContent & "Generated: " & (current date as string) & return & return
		set reportContent to reportContent & summary & return & return
		
		set reportContent to reportContent & "Complete Diagnostic Log:" & return & return
		set reportContent to reportContent & "==========================================" & return & return
		set reportContent to reportContent & fullLog & return & return
		set reportContent to reportContent & "==========================================" & return & return
		
		set reportContent to reportContent & return & "End of Diagnostic Report" & return
		set reportContent to reportContent & "For support, contact: pythonsupport@dtu.dk"
		
		-- Open default email client with report
		set emailSubject to "DTU First Year Python Diagnostics Report"
		set emailBody to reportContent
		
		do shell script "open 'mailto:pythonsupport@dtu.dk?subject=" & emailSubject & "&body=" & emailBody & "'"
		
		display dialog "Email client opened with complete diagnostic report." & return & return & "The report includes all terminal output from each diagnostic component." & return & return & "Please review and send to pythonsupport@dtu.dk" buttons {"OK"} default button "OK" with title "Email Report" with icon note
		
	on error errorMessage
		display dialog "Failed to open email:" & return & return & errorMessage buttons {"OK"} default button "OK" with title "Email Error" with icon stop
	end try
end emailDiagnosticReport
