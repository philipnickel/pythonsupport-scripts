Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$global:StudentNumber = ""
$global:InstallPython = $true
$global:InstallVsc = $false     # Visual Studio Code
$global:InstallVscJupyter = $false

$form = New-Object System.Windows.Forms.Form
$form.Text = "Python Installation"
$form.Size = New-Object System.Drawing.Size(420, 280)
$form.StartPosition = "CenterScreen"

$panel = New-Object System.Windows.Forms.Panel
$panel.Location = New-Object System.Drawing.Point(0, 0)
$panel.Size = New-Object System.Drawing.Size(400, 180)
$form.Controls.Add($panel)

$backButton = New-Object System.Windows.Forms.Button
$backButton.Text = "< Back"
$backButton.Location = New-Object System.Drawing.Point(200, 200)
$backButton.Enabled = $false
$form.Controls.Add($backButton)

$nextButton = New-Object System.Windows.Forms.Button
$nextButton.Text = "Next >"
$nextButton.Location = New-Object System.Drawing.Point(300, 200)
$form.Controls.Add($nextButton)

$nextButton.Add_Click({ if ($nextButton.Tag) { & $nextButton.Tag } })
$backButton.Add_Click({ if ($backButton.Tag) { & $backButton.Tag } })

function Show-StudentNumber {
    $panel.Controls.Clear()
    $form.Text = "Python Installation - Step 1"

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Enter your student number (e.g. s123456):"
    $label.Location = New-Object System.Drawing.Point(20, 30)
    $label.Size = New-Object System.Drawing.Size(300, 20)
    $panel.Controls.Add($label)

    # store control in script-scope so click handlers can read it later
    $script:StudentTextBox = New-Object System.Windows.Forms.TextBox
    $script:StudentTextBox.Location = New-Object System.Drawing.Point(20, 60)
    $script:StudentTextBox.Size = New-Object System.Drawing.Size(340, 20)
    $script:StudentTextBox.Text = $global:StudentNumber
    $panel.Controls.Add($script:StudentTextBox)

    $nextButton.Text = "Next >"
    $backButton.Enabled = $false
    $backButton.Tag = $null
    $nextButton.Tag = {
        $global:StudentNumber = $script:StudentTextBox.Text
        Show-Software
    }
}

function Show-Software {
    $panel.Controls.Clear()
    $form.Text = "Python Installation - Step 2"

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Select software to install:"
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(350, 20)
    $panel.Controls.Add($label)

    $script:ChkPython = New-Object System.Windows.Forms.CheckBox
    $script:ChkPython.Text = "Python and essential libraries (recommended)"
    $script:ChkPython.Location = New-Object System.Drawing.Point(20, 50)
    $script:ChkPython.Size = New-Object System.Drawing.Size(350, 20)
    $script:ChkPython.Checked = $global:InstallPython
    $panel.Controls.Add($script:ChkPython)

    $script:ChkVsc = New-Object System.Windows.Forms.CheckBox
    $script:ChkVsc.Text = "Visual Studio Code"
    $script:ChkVsc.Location = New-Object System.Drawing.Point(20, 80)
    $script:ChkVsc.Size = New-Object System.Drawing.Size(350, 20)
    $script:ChkVsc.Checked = $global:InstallVsc
    $script:ChkVsc.Add_Click({
        # Uncheck all child checkboxes along with the parent.
        if (-Not $script:ChkVsc.Checked) {
            $script:ChkVscJupyter.Checked = $false
        }
    })
    $panel.Controls.Add($script:ChkVsc)

    $script:ChkVscJupyter = New-Object System.Windows.Forms.CheckBox
    $script:ChkVscJupyter.Text = "Jupyter notebook extensions"
    $script:ChkVscJupyter.Location = New-Object System.Drawing.Point(40, 110)
    $script:ChkVscJupyter.Size = New-Object System.Drawing.Size(350, 20)
    $script:ChkVscJupyter.Checked = $global:InstallVscJupyter
    $script:ChkVscJupyter.Add_Click({
        $script:ChkVsc.Checked = $true       # Child checkbox of Vsc.
    })
    $panel.Controls.Add($script:ChkVscJupyter)

    $nextButton.Text = "Next >"
    $backButton.Enabled = $true

    $nextButton.Tag = {
        $global:InstallPython = $script:ChkPython.Checked
        $global:InstallVsc = $script:ChkVsc.Checked
        $global:InstallVscJupyter = $script:ChkVscJupyter.Checked
        Show-Summary
    }
    $backButton.Tag = { Show-StudentNumber }
}

function Show-Summary {
    $panel.Controls.Clear()
    $form.Text = "Python Installation - Step 3"

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Review your selections:"
    $label.Size = New-Object System.Drawing.Size(350, 20)
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $panel.Controls.Add($label)

    $summaryBox = New-Object System.Windows.Forms.TextBox
    $summaryBox.Multiline = $true
    $summaryBox.ReadOnly = $true
    $summaryBox.Text = Summary
    $summaryBox.Location = New-Object System.Drawing.Point(20, 50)
    $summaryBox.Size = New-Object System.Drawing.Size(340, 100)
    $panel.Controls.Add($summaryBox)

    $nextButton.Text = "Install"
    $backButton.Enabled = $true
    $nextButton.Tag = { Log-Summary }
    $backButton.Tag = { Show-Software }
}

function Log-Summary {
    Write-Host Summary
    $form.Close()
}

function Summary {
    @"
- Student number: $global:StudentNumber
- Install Python: $global:InstallPython
- Install Visual Studio Code: $global:InstallVsc
   > Install Jupyter notebook extensions: $global:InstallVscJupyter
"@
}

Show-StudentNumber
[void]$form.ShowDialog()

# Installation animation
# function Show-Animation {
#     $installForm = New-Object System.Windows.Forms.Form
#     $installForm.Text = "Installing..."
#     $installForm.Size = New-Object System.Drawing.Size(300, 120)
#     $installForm.StartPosition = "CenterScreen"
#     $installForm.ControlBox = $false
#
#     $label = New-Object System.Windows.Forms.Label
#     $label.Text = "Installing"
#     $label.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
#     $label.Location = New-Object System.Drawing.Point(20, 20)
#     $label.Size = New-Object System.Drawing.Size(250, 30)
#     $installForm.Controls.Add($label)
#
#     $timer = New-Object System.Windows.Forms.Timer
#     $timer.Interval = 500
#     $dots = 0
#     $timer.Add_Tick({
#         $dots = ($dots + 1) % 4
#         $label.Text = "Installing" + ('.' * $dots)
#     })
#     $timer.Start()
#
#     Start-Sleep -Seconds 3
#     $timer.Stop()
#     $installForm.Close()
#
#     Write-Host "=== Installation Summary ==="
#     Write-Host "Student Number: $global:StudentNumber"
#     Write-Host "Install Python: $global:InstallPython"
#     Write-Host "Install Visual Studio Code: $global:InstallVSCode"
#     Write-Host "Install Math Libraries: $global:InstallMathLibs"
#     Write-Host "============================"
# }
