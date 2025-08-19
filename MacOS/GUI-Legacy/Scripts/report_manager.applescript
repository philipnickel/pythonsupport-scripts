-- Report Manager for DTU Python Support Tools
-- Generates comprehensive system reports and manages export functionality

use AppleScript version "2.4"
use framework "Foundation"
use framework "AppKit"
use scripting additions

on generateFullReport()
	-- Generate comprehensive system report using diagnostic components
	set progress description to "Generating comprehensive system report..."
	set progress total steps to 4
	set progress completed steps to 0
	
	-- Load diagnostics manager to get full diagnostic data
	try
		set diagnosticsManager to load script (path to resource "diagnostics_manager.scpt" in bundle (path to me))
		
		set progress completed steps to 1
		set progress description to "Collecting system information..."
		
		-- This would collect comprehensive system information
		set systemData to collectSystemData()
		
		set progress completed steps to 2
		set progress description to "Analyzing environment..."
		
		-- Collect environment analysis
		set environmentData to collectEnvironmentData()
		
		set progress completed steps to 3
		set progress description to "Compiling report..."
		
		-- Generate report content
		set reportContent to compileFullReport(systemData, environmentData)
		
		set progress completed steps to 4
		set progress description to "Report ready!"
		
		-- Show report options
		showReportOptions(reportContent)
		
	on error errMsg
		display dialog "Error generating system report:" & return & return & errMsg ¬
			buttons {"OK"} default button "OK" with title "Report Error" with icon stop
	end try
end generateFullReport

on collectSystemData()
	-- Collect comprehensive system information
	try
		set systemInfo to {}
		
		-- Basic system info
		set osVersion to do shell script "sw_vers -productVersion"
		set architecture to do shell script "uname -m"
		set hostname to do shell script "hostname"
		set uptime to do shell script "uptime"
		set memInfo to do shell script "vm_stat | head -n 10"
		set diskInfo to do shell script "df -h /"
		
		set end of systemInfo to {category:"System Information", data:"macOS Version: " & osVersion & return & "Architecture: " & architecture & return & "Hostname: " & hostname & return & "Uptime: " & uptime & return & "Memory Info:" & return & memInfo & return & "Disk Info:" & return & diskInfo}
		
		-- Shell information
		set shellInfo to do shell script "echo $SHELL && echo $PATH"
		set end of systemInfo to {category:"Shell Environment", data:shellInfo}
		
		-- Network information
		set networkInfo to do shell script "ifconfig | grep 'inet ' | head -n 5"
		set end of systemInfo to {category:"Network Configuration", data:networkInfo}
		
		return systemInfo
		
	on error
		return {{category:"System Information", data:"Error collecting system information"}}
	end try
end collectSystemData

on collectEnvironmentData()
	-- Collect development environment information
	try
		set envData to {}
		
		-- Python environments
		try
			set pythonInfo to do shell script "python3 --version && which python3 && conda info --envs 2>/dev/null || echo 'Conda not available'"
			set end of envData to {category:"Python Environment", data:pythonInfo}
		on error
			set end of envData to {category:"Python Environment", data:"Python not found"}
		end try
		
		-- Development tools
		try
			set devTools to do shell script "git --version 2>/dev/null || echo 'Git not found'; code --version 2>/dev/null | head -n 1 || echo 'VS Code not found'; brew --version 2>/dev/null | head -n 1 || echo 'Homebrew not found'"
			set end of envData to {category:"Development Tools", data:devTools}
		end try
		
		-- Package managers
		try
			set packageManagers to do shell script "pip3 --version 2>/dev/null || echo 'pip3 not found'; conda --version 2>/dev/null || echo 'conda not found'; brew list --formula | wc -l | xargs echo 'Homebrew packages:' || echo 'Homebrew packages: 0'"
			set end of envData to {category:"Package Managers", data:packageManagers}
		end try
		
		return envData
		
	on error
		return {{category:"Environment Data", data:"Error collecting environment information"}}
	end try
end collectEnvironmentData

on compileFullReport(systemData, environmentData)
	-- Compile comprehensive report
	set reportHeader to "DTU Python Support - Comprehensive System Report" & return & ¬
		"Generated: " & (current date as string) & return & ¬
		"Report Type: Full System Analysis" & return & ¬
		"==========================================" & return & return
	
	set reportContent to reportHeader
	
	-- Add system data
	set reportContent to reportContent & "SYSTEM INFORMATION" & return & ¬
		"==================" & return & return
	
	repeat with dataItem in systemData
		set reportContent to reportContent & dataItem's category & return & ¬
			(my makeUnderline(length of (dataItem's category))) & return & ¬
			dataItem's data & return & return
	end repeat
	
	-- Add environment data
	set reportContent to reportContent & "DEVELOPMENT ENVIRONMENT" & return & ¬
		"=======================" & return & return
	
	repeat with dataItem in environmentData
		set reportContent to reportContent & dataItem's category & return & ¬
			(my makeUnderline(length of (dataItem's category))) & return & ¬
			dataItem's data & return & return
	end repeat
	
	-- Add footer
	set reportContent to reportContent & "==========================================" & return & ¬
		"End of System Report" & return & ¬
		"For support, contact: pythonsupport@dtu.dk" & return
	
	return reportContent
end compileFullReport

on makeUnderline(textLength)
	-- Create underline of dashes for headers
	set underlineText to ""
	repeat with i from 1 to textLength
		set underlineText to underlineText & "-"
	end repeat
	return underlineText
end makeUnderline

on showReportOptions(reportContent)
	-- Show report with export options
	try
		set alert to current application's NSAlert's alloc()'s init()
		alert's setMessageText:"System Report Generated"
		alert's setInformativeText:"Comprehensive system report has been generated. Choose an option:"
		alert's addButtonWithTitle:"View Report"
		alert's addButtonWithTitle:"Save to Desktop"
		alert's addButtonWithTitle:"Email Report"
		alert's addButtonWithTitle:"Close"
		
		(current application's NSApp's activateIgnoringOtherApps:true)
		set modalResult to alert's runModal()
		
		if modalResult = (current application's NSAlertFirstButtonReturn) then
			showReportInWindow(reportContent)
		else if modalResult = (current application's NSAlertSecondButtonReturn) then
			saveReportToDesktop(reportContent)
		else if modalResult = (current application's NSAlertThirdButtonReturn) then
			emailReport(reportContent)
		end if
		
	on error errorMessage
		display dialog "Error showing report options:" & return & return & errorMessage ¬
			buttons {"OK"} default button "OK" with title "Error" with icon stop
	end try
end showReportOptions

on showReportInWindow(reportContent)
	-- Display report in scrollable window
	try
		set alert to current application's NSAlert's alloc()'s init()
		alert's setMessageText:"DTU Python Support - System Report"
		alert's setInformativeText:""
		alert's addButtonWithTitle:"Save Report"
		alert's addButtonWithTitle:"Email Report"
		alert's addButtonWithTitle:"Close"
		
		set frame to current application's NSMakeRect(0, 0, 700, 500)
		set scrollView to current application's NSScrollView's alloc()'s initWithFrame:frame
		scrollView's setHasVerticalScroller:true
		scrollView's setHasHorizontalScroller:true
		scrollView's setBorderType:(current application's NSBezelBorder)
		
		set textView to current application's NSTextView's alloc()'s initWithFrame:frame
		textView's setEditable:false
		textView's setSelectable:true
		textView's setDrawsBackground:true
		textView's setBackgroundColor:(current application's NSColor's whiteColor())
		
		set attrDict to current application's NSMutableDictionary's dictionary()
		attrDict's setValue:(current application's NSColor's blackColor()) forKey:(current application's NSForegroundColorAttributeName)
		attrDict's setValue:((current application's NSFont's userFixedPitchFontOfSize:11)) forKey:(current application's NSFontAttributeName)
		set attributed to (current application's NSAttributedString's alloc()'s initWithString:reportContent attributes:attrDict)
		(textView's textStorage()'s setAttributedString:attributed)
		
		scrollView's setDocumentView:textView
		alert's setAccessoryView:scrollView
		
		(current application's NSApp's activateIgnoringOtherApps:true)
		set modalResult to alert's runModal()
		
		if modalResult = (current application's NSAlertFirstButtonReturn) then
			saveReportToDesktop(reportContent)
		else if modalResult = (current application's NSAlertSecondButtonReturn) then
			emailReport(reportContent)
		end if
		
	on error errorMessage
		display dialog "Failed to display report:" & return & return & errorMessage ¬
			buttons {"OK"} default button "OK" with title "Display Error" with icon stop
	end try
end showReportInWindow

on saveReportToDesktop(reportContent)
	-- Save report to desktop
	try
		set desktopPath to (path to desktop as string)
		set timestamp to do shell script "date +%Y%m%d_%H%M%S"
		set reportPath to desktopPath & "DTU_Python_System_Report_" & timestamp & ".txt"
		
		set reportFile to open for access file reportPath with write permission
		write reportContent to reportFile
		close access reportFile
		
		display dialog "System report saved to Desktop:" & return & return & ¬
			"DTU_Python_System_Report_" & timestamp & ".txt" ¬
			buttons {"OK"} default button "OK" with title "Report Saved" with icon note
			
	on error errorMessage
		display dialog "Failed to save report:" & return & return & errorMessage ¬
			buttons {"OK"} default button "OK" with title "Save Error" with icon stop
	end try
end saveReportToDesktop

on emailReport(reportContent)
	-- Email report
	try
		set emailSubject to "DTU Python Support System Report"
		
		-- URL encode the content for mailto
		set encodedContent to do shell script "python3 -c \"import urllib.parse; print(urllib.parse.quote_plus('''\" & reportContent & \"'''))\""
		
		do shell script "open 'mailto:pythonsupport@dtu.dk?subject=" & emailSubject & "&body=" & encodedContent & "'"
		
		display dialog "Email client opened with system report." & return & return & ¬
			"The comprehensive system report has been prepared for sending to pythonsupport@dtu.dk" ¬
			buttons {"OK"} default button "OK" with title "Email Report" with icon note
			
	on error errorMessage
		display dialog "Failed to open email:" & return & return & errorMessage ¬
			buttons {"OK"} default button "OK" with title "Email Error" with icon stop
	end try
end emailReport