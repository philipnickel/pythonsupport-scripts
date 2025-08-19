-- DTU Python Support - Full GUI Application
-- Complete Python development support tool for DTU students
-- Modular architecture with comprehensive installation and diagnostic capabilities

on run
	-- Main application entry point
	showWelcomeScreen()
end run

on showWelcomeScreen()
	-- Main menu with the three primary options
	try
		set welcomeResult to display dialog "DTU Python Support" & return & return & ¬
			"🐍 Python Development Support for DTU Students" & return & return & ¬
			"Choose what you need:" & return & return & ¬
			"• First Year Students Installation - Complete setup for new students" & return & ¬
			"• Custom Installation - Choose specific components" & return & ¬
			"• Troubleshooting/Verification - Diagnose and fix issues" ¬
			buttons {"First Year", "Custom", "Troubleshooting"} ¬
			default button "First Year" ¬
			cancel button "Troubleshooting" ¬
			with title "DTU Python Support" ¬
			with icon note
		
		set buttonPressed to button returned of welcomeResult
		
		if buttonPressed is "First Year" then
			runFirstYearInstallation()
		else if buttonPressed is "Custom" then
			showCustomInstallationMenu()
		else if buttonPressed is "Troubleshooting" then
			showTroubleshootingMenu()
		end if
	on error number -128
		-- User cancelled, quit the application
		return
	end try
end showWelcomeScreen


on showAboutDialog()
	-- About dialog with version and contact information
	display dialog "DTU Python Support - Full Edition" & return & return & ¬
		"Version: 2.0.0 (Full GUI)" & return & ¬
		"Architecture: Modular Components" & return & return & ¬
		"Developed by DTU Python Support Team" & return & ¬
		"Contact: pythonsupport@dtu.dk" & return & return & ¬
		"Features:" & return & ¬
		"• Modular diagnostic system" & return & ¬
		"• Multiple installation workflows" & return & ¬
		"• Post-installation verification" & return & ¬
		"• Environment repair tools" & return & ¬
		"• Comprehensive reporting" & return & return & ¬
		"© 2024 Technical University of Denmark" ¬
		buttons {"Visit Support Site", "OK"} ¬
		default button "OK" ¬
		with title "About DTU Python Support" ¬
		with icon note
	
	if button returned of result is "Visit Support Site" then
		do shell script "open 'https://pythonsupport.dtu.dk'"
	end if
	
	showWelcomeScreen()
end showAboutDialog

-- Main action handlers
on runFirstYearInstallation()
	try
		set installationManager to load script (path to resource "installation_manager.scpt" in bundle (path to me))
		installationManager's runFirstYearSetup()
	on error number -128
		-- User cancelled
		return
	on error errMsg
		display dialog "Error running first year installation:" & return & return & errMsg ¬
			buttons {"OK"} default button "OK" with title "Installation Error" with icon stop
	end try
	showWelcomeScreen()
end runFirstYearInstallation

on showCustomInstallationMenu()
	try
		set installationManager to load script (path to resource "installation_manager.scpt" in bundle (path to me))
		installationManager's runCustomSetup()
	on error number -128
		-- User cancelled
		return
	on error errMsg
		display dialog "Error running custom installation:" & return & return & errMsg ¬
			buttons {"OK"} default button "OK" with title "Installation Error" with icon stop
	end try
	showWelcomeScreen()
end showCustomInstallationMenu

on showTroubleshootingMenu()
	-- Troubleshooting submenu with diagnostics and repair options
	try
		set troubleResult to display dialog "Troubleshooting & Verification" & return & return & ¬
			"Select the type of troubleshooting:" & return & return & ¬
			"• Quick Check - Fast system overview" & return & ¬
			"• Full Diagnostics - Comprehensive system analysis" & return & ¬
			"• Environment Repair - Fix common configuration issues" ¬
			buttons {"Quick Check", "Full Diagnostics", "Back"} ¬
			default button "Quick Check" ¬
			cancel button "Back" ¬
			with title "Troubleshooting" ¬
			with icon note
		
		set buttonPressed to button returned of troubleResult
		
		if buttonPressed is "Quick Check" then
			set diagnosticsManager to load script (path to resource "diagnostics_manager.scpt" in bundle (path to me))
			diagnosticsManager's runQuickCheck()
		else if buttonPressed is "Full Diagnostics" then
			set diagnosticsManager to load script (path to resource "diagnostics_manager.scpt" in bundle (path to me))
			diagnosticsManager's runFullCheck()
		end if
		showWelcomeScreen()
	on error number -128
		-- User cancelled, go back to main menu
		showWelcomeScreen()
	on error errMsg
		display dialog "Error running troubleshooting:" & return & return & errMsg ¬
			buttons {"OK"} default button "OK" with title "Troubleshooting Error" with icon stop
		showWelcomeScreen()
	end try
end showTroubleshootingMenu

-- Application lifecycle handlers
on quit
	-- Clean shutdown
	continue quit
end quit

on reopen
	-- Handle reopening the application
	showWelcomeScreen()
end reopen