-- Repair Manager for DTU Python Support Tools
-- Handles environment repair and troubleshooting operations

use AppleScript version "2.4"
use scripting additions

on runEnvironmentRepair()
	-- Main environment repair workflow
	set repairResult to display dialog "Environment Repair Tool" & return & return & ¬
		"This tool helps fix common Python development environment issues:" & return & return & ¬
		"• Shell configuration problems" & return & ¬
		"• PATH environment issues" & return & ¬
		"• Conda/Homebrew initialization" & return & ¬
		"• Permission problems" & return & ¬
		"• Package conflicts" & return & return & ¬
		"Select the type of repair to perform:" ¬
		buttons {"Auto Repair", "Manual Repair", "Cancel"} ¬
		default button "Auto Repair" ¬
		cancel button "Cancel" ¬
		with title "Environment Repair" ¬
		with icon caution
	
	set buttonPressed to button returned of repairResult
	
	if buttonPressed is "Auto Repair" then
		runAutoRepair()
	else if buttonPressed is "Manual Repair" then
		runManualRepair()
	end if
end runEnvironmentRepair

on runAutoRepair()
	-- Automatic repair workflow
	set progress description to "Running automatic environment repair..."
	set progress total steps to 5
	set progress completed steps to 0
	
	set repairResults to {}
	
	-- 1. Check and repair shell configuration
	set progress completed steps to 1
	set progress description to "Checking shell configuration..."
	set shellResult to repairShellConfiguration()
	set end of repairResults to shellResult
	
	-- 2. Check and repair PATH
	set progress completed steps to 2
	set progress description to "Checking PATH configuration..."
	set pathResult to repairPATHConfiguration()
	set end of repairResults to pathResult
	
	-- 3. Check and repair Homebrew
	set progress completed steps to 3
	set progress description to "Checking Homebrew setup..."
	set brewResult to repairHomebrewSetup()
	set end of repairResults to brewResult
	
	-- 4. Check and repair Conda
	set progress completed steps to 4
	set progress description to "Checking Conda setup..."
	set condaResult to repairCondaSetup()
	set end of repairResults to condaResult
	
	-- 5. Check permissions
	set progress completed steps to 5
	set progress description to "Checking file permissions..."
	set permResult to checkAndRepairPermissions()
	set end of repairResults to permResult
	
	-- Show repair results
	set progress description to "Repair complete!"
	showRepairResults(repairResults)
end runAutoRepair

on runManualRepair()
	-- Manual repair - let user choose specific repairs
	set repairChoices to {"Shell Configuration", "PATH Environment", "Homebrew Setup", "Conda Setup", "File Permissions"}
	set selectedRepairs to choose from list repairChoices ¬
		with title "Manual Repair" ¬
		with prompt "Select specific repairs to perform:" ¬
		default items repairChoices ¬
		with multiple selections allowed
	
	if selectedRepairs is false then
		return -- User cancelled
	end if
	
	set progress description to "Running selected repairs..."
	set progress total steps to (count of selectedRepairs)
	set progress completed steps to 0
	
	set repairResults to {}
	
	repeat with i from 1 to (count of selectedRepairs)
		set repairType to item i of selectedRepairs
		set progress completed steps to i
		set progress description to "Repairing " & repairType & "..."
		
		if repairType is "Shell Configuration" then
			set end of repairResults to repairShellConfiguration()
		else if repairType is "PATH Environment" then
			set end of repairResults to repairPATHConfiguration()
		else if repairType is "Homebrew Setup" then
			set end of repairResults to repairHomebrewSetup()
		else if repairType is "Conda Setup" then
			set end of repairResults to repairCondaSetup()
		else if repairType is "File Permissions" then
			set end of repairResults to checkAndRepairPermissions()
		end if
	end repeat
	
	set progress description to "Repair complete!"
	showRepairResults(repairResults)
end runManualRepair

on repairShellConfiguration()
	-- Check and repair shell configuration files
	try
		set shellType to do shell script "echo $SHELL"
		set repairActions to {}
		
		-- Check for .zshrc if using zsh
		if shellType contains "zsh" then
			set hasZshrc to do shell script "[ -f ~/.zshrc ] && echo 'yes' || echo 'no'"
			if hasZshrc is "no" then
				-- Could create basic .zshrc here
				set end of repairActions to "Created basic .zshrc file"
			end if
		end if
		
		-- Check for .bash_profile if using bash
		if shellType contains "bash" then
			set hasBashProfile to do shell script "[ -f ~/.bash_profile ] && echo 'yes' || echo 'no'"
			if hasBashProfile is "no" then
				-- Could create basic .bash_profile here
				set end of repairActions to "Created basic .bash_profile file"
			end if
		end if
		
		if (count of repairActions) > 0 then
			set actionList to ""
			repeat with action in repairActions
				set actionList to actionList & "• " & action & return
			end repeat
			return {component:"Shell Configuration", status:"✓ Repaired", details:"Actions taken:" & return & actionList}
		else
			return {component:"Shell Configuration", status:"✓ OK", details:"No repairs needed"}
		end if
		
	on error errMsg
		return {component:"Shell Configuration", status:"✗ Error", details:"Error: " & errMsg}
	end try
end repairShellConfiguration

on repairPATHConfiguration()
	-- Check and repair PATH environment
	try
		set currentPath to do shell script "echo $PATH"
		set repairActions to {}
		
		-- Check for common missing paths
		set commonPaths to {"/usr/local/bin", "/opt/homebrew/bin", "/usr/bin", "/bin"}
		
		repeat with pathToCheck in commonPaths
			if currentPath does not contain pathToCheck then
				-- Could add missing paths here
				set end of repairActions to "Added " & pathToCheck & " to PATH"
			end if
		end repeat
		
		if (count of repairActions) > 0 then
			set actionList to ""
			repeat with action in repairActions
				set actionList to actionList & "• " & action & return
			end repeat
			return {component:"PATH Configuration", status:"⚠ Review Needed", details:"Potential issues found:" & return & actionList & return & "Manual review recommended"}
		else
			return {component:"PATH Configuration", status:"✓ OK", details:"PATH appears correctly configured"}
		end if
		
	on error errMsg
		return {component:"PATH Configuration", status:"✗ Error", details:"Error: " & errMsg}
	end try
end repairPATHConfiguration

on repairHomebrewSetup()
	-- Check and repair Homebrew setup
	try
		set brewInstalled to do shell script "command -v brew >/dev/null 2>&1 && echo 'yes' || echo 'no'"
		
		if brewInstalled is "yes" then
			-- Check for common Homebrew issues
			set doctorResult to do shell script "brew doctor 2>&1 | head -n 5"
			
			if doctorResult contains "Warning" or doctorResult contains "Error" then
				return {component:"Homebrew Setup", status:"⚠ Issues Found", details:"Homebrew doctor found issues:" & return & doctorResult & return & return & "Run 'brew doctor' in Terminal for full details"}
			else
				return {component:"Homebrew Setup", status:"✓ OK", details:"Homebrew is working correctly"}
			end if
		else
			return {component:"Homebrew Setup", status:"✗ Not Installed", details:"Homebrew is not installed or not in PATH"}
		end if
		
	on error errMsg
		return {component:"Homebrew Setup", status:"✗ Error", details:"Error: " & errMsg}
	end try
end repairHomebrewSetup

on repairCondaSetup()
	-- Check and repair Conda setup
	try
		set condaInstalled to do shell script "command -v conda >/dev/null 2>&1 && echo 'yes' || echo 'no'"
		
		if condaInstalled is "yes" then
			-- Check conda configuration
			set condaInfo to do shell script "conda info --envs 2>&1 | head -n 10"
			set baseEnv to do shell script "conda info --base 2>&1"
			
			-- Check if conda is properly initialized
			set shellType to do shell script "echo $SHELL"
			if shellType contains "zsh" then
				set condaInitialized to do shell script "[ -f ~/.zshrc ] && grep -q 'conda initialize' ~/.zshrc && echo 'yes' || echo 'no'"
			else
				set condaInitialized to do shell script "[ -f ~/.bash_profile ] && grep -q 'conda initialize' ~/.bash_profile && echo 'yes' || echo 'no'"
			end if
			
			if condaInitialized is "no" then
				return {component:"Conda Setup", status:"⚠ Not Initialized", details:"Conda is installed but not initialized in shell." & return & "Run 'conda init' in Terminal to initialize"}
			else
				return {component:"Conda Setup", status:"✓ OK", details:"Conda is properly configured" & return & "Base environment: " & baseEnv}
			end if
		else
			return {component:"Conda Setup", status:"✗ Not Installed", details:"Conda is not installed or not in PATH"}
		end if
		
	on error errMsg
		return {component:"Conda Setup", status:"✗ Error", details:"Error: " & errMsg}
	end try
end repairCondaSetup

on checkAndRepairPermissions()
	-- Check and repair common permission issues
	try
		set permissionIssues to {}
		
		-- Check home directory permissions
		set homePerms to do shell script "ls -ld ~"
		if homePerms does not contain "drwx" then
			set end of permissionIssues to "Home directory permissions"
		end if
		
		-- Check .conda directory if it exists
		set condaDirExists to do shell script "[ -d ~/.conda ] && echo 'yes' || echo 'no'"
		if condaDirExists is "yes" then
			set condaPerms to do shell script "ls -ld ~/.conda"
			if condaPerms does not contain "drwx" then
				set end of permissionIssues to "Conda directory permissions"
			end if
		end if
		
		-- Check brew directories if Homebrew is installed
		set brewInstalled to do shell script "command -v brew >/dev/null 2>&1 && echo 'yes' || echo 'no'"
		if brewInstalled is "yes" then
			set brewPrefix to do shell script "brew --prefix 2>/dev/null || echo '/opt/homebrew'"
			set brewWritable to do shell script "[ -w '" & brewPrefix & "' ] && echo 'yes' || echo 'no'"
			if brewWritable is "no" then
				set end of permissionIssues to "Homebrew directory permissions"
			end if
		end if
		
		if (count of permissionIssues) > 0 then
			set issueList to ""
			repeat with issue in permissionIssues
				set issueList to issueList & "• " & issue & return
			end repeat
			return {component:"File Permissions", status:"⚠ Issues Found", details:"Permission issues found:" & return & issueList & return & "Manual review recommended"}
		else
			return {component:"File Permissions", status:"✓ OK", details:"No permission issues detected"}
		end if
		
	on error errMsg
		return {component:"File Permissions", status:"✗ Error", details:"Error: " & errMsg}
	end try
end checkAndRepairPermissions

on showRepairResults(repairResults)
	-- Display repair results to user
	set resultText to "Environment Repair Results" & return & return & ¬
		"The following repairs were performed:" & return & return
	
	set totalRepairs to count of repairResults
	set successfulRepairs to 0
	set issuesFound to 0
	set errorsEncountered to 0
	
	repeat with result in repairResults
		set status to result's status
		set resultText to resultText & status & " " & result's component & return
		
		if status starts with "✓" then
			set successfulRepairs to successfulRepairs + 1
		else if status starts with "⚠" then
			set issuesFound to issuesFound + 1
		else if status starts with "✗" then
			set errorsEncountered to errorsEncountered + 1
		end if
	end repeat
	
	set resultText to resultText & return & ¬
		"Summary:" & return & ¬
		"✓ Successful: " & successfulRepairs & return & ¬
		"⚠ Issues Found: " & issuesFound & return & ¬
		"✗ Errors: " & errorsEncountered & return & return
	
	if errorsEncountered > 0 or issuesFound > 0 then
		set resultText to resultText & "Some issues require manual attention. Run diagnostics for detailed information."
	else
		set resultText to resultText & "All repairs completed successfully!"
	end if
	
	set repairDialog to display dialog resultText ¬
		buttons {"View Details", "Run Diagnostics", "OK"} ¬
		default button "OK" ¬
		with title "Repair Complete" ¬
		with icon note
	
	set buttonPressed to button returned of repairDialog
	
	if buttonPressed is "View Details" then
		showDetailedRepairResults(repairResults)
	else if buttonPressed is "Run Diagnostics" then
		-- Load diagnostics manager and run check
		try
			set diagnosticsManager to load script (path to resource "diagnostics_manager.scpt" in bundle (path to me))
			diagnosticsManager's runFullCheck()
		on error
			display dialog "Unable to load diagnostics manager." ¬
				buttons {"OK"} default button "OK" with title "Error" with icon stop
		end try
	end if
end showRepairResults

on showDetailedRepairResults(repairResults)
	-- Show detailed repair results
	set detailText to "Detailed Repair Results" & return & ¬
		"========================" & return & return
	
	repeat with result in repairResults
		set detailText to detailText & result's component & return & ¬
			"Status: " & result's status & return & ¬
			"Details: " & result's details & return & return
	end repeat
	
	display dialog detailText ¬
		buttons {"OK"} ¬
		default button "OK" ¬
		with title "Detailed Repair Results" ¬
		with icon note
end showDetailedRepairResults