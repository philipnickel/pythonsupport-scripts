# @doc
# @name: Windows GUI Dialog System
# @description: Native Windows dialogs using PowerShell Windows.Forms for better user experience
# @category: GUI
# @usage: . .\gui_dialogs.ps1
# @requirements: Windows PowerShell, .NET Framework
# @notes: Provides native Windows dialogs without terminal dependency
# @/doc

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to show confirmation dialog
function Show-ConfirmationDialog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [string]$DefaultButton = "Yes"
    )
    
    $result = [System.Windows.Forms.MessageBox]::Show(
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question,
        [System.Windows.Forms.MessageBoxDefaultButton]::Button1
    )
    
    return $result -eq [System.Windows.Forms.DialogResult]::Yes
}

# Function to show information dialog
function Show-InfoDialog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    [System.Windows.Forms.MessageBox]::Show(
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}

# Function to show error dialog
function Show-ErrorDialog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    [System.Windows.Forms.MessageBox]::Show(
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
}

# Function to show installation progress dialog
function Show-ProgressDialog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [string]$InitialMessage,
        
        [Parameter(Mandatory=$true)]
        [scriptblock]$InstallScript
    )
    
    # Create form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(400, 150)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true
    
    # Create label
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(350, 40)
    $label.Text = $InitialMessage
    $label.TextAlign = "MiddleLeft"
    $form.Controls.Add($label)
    
    # Create progress bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(20, 70)
    $progressBar.Size = New-Object System.Drawing.Size(350, 20)
    $progressBar.Style = "Marquee"
    $progressBar.MarqueeAnimationSpeed = 30
    $form.Controls.Add($progressBar)
    
    # Show form
    $form.Show()
    $form.Refresh()
    
    try {
        # Execute the installation script
        $global:ProgressLabel = $label
        $global:ProgressForm = $form
        & $InstallScript
        return $true
    }
    catch {
        Show-ErrorDialog -Title "Installation Error" -Message "Installation failed: $($_.Exception.Message)"
        return $false
    }
    finally {
        $form.Close()
        $form.Dispose()
    }
}

# Function to update progress dialog
function Update-ProgressDialog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    if ($global:ProgressLabel -and $global:ProgressForm) {
        $global:ProgressLabel.Text = $Message
        $global:ProgressForm.Refresh()
        Start-Sleep -Milliseconds 100
    }
}

# Function to show installation summary
function Show-InstallationSummary {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Results
    )
    
    $summary = "Installation Summary:`n`n"
    
    foreach ($component in $Results.Keys) {
        $status = if ($Results[$component]) { "[OK] Success" } else { "[FAIL] Failed" }
        $summary += "$component : $status`n"
    }
    
    $summary += "`nNext steps:`n"
    $summary += "1. Restart your terminal/PowerShell`n"
    $summary += "2. Open VSCode and start coding!`n"
    $summary += "3. Use 'conda activate first_year' to activate Python environment`n"
    $summary += "4. Visit https://pythonsupport.dtu.dk for resources"
    
    $allSuccessful = ($Results.Values | Where-Object { $_ -eq $false }).Count -eq 0
    $icon = if ($allSuccessful) { [System.Windows.Forms.MessageBoxIcon]::Information } else { [System.Windows.Forms.MessageBoxIcon]::Warning }
    $title = if ($allSuccessful) { "Installation Completed Successfully!" } else { "Installation Completed with Issues" }
    
    [System.Windows.Forms.MessageBox]::Show(
        $summary,
        $title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $icon
    )
}

# Export functions
Export-ModuleMember -Function Show-ConfirmationDialog, Show-InfoDialog, Show-ErrorDialog, Show-ProgressDialog, Update-ProgressDialog, Show-InstallationSummary