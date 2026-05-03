        # SCRIPT RUN AS ADMIN
        if ($env:BWO_UNATTENDED -ne '1') {
        If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
        {Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        Exit}
        }
        $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + " (Administrator)"
        $Host.UI.RawUI.BackgroundColor = "Black"
        $Host.PrivateData.ProgressBackgroundColor = "Black"
        $Host.PrivateData.ProgressForegroundColor = "White"
        Clear-Host

        # FUNCTION GET FILE FROM WEB
        function Get-FileFromWeb {
        param ([Parameter(Mandatory)][string]$URL, [Parameter(Mandatory)][string]$File)
        function Show-Progress {
        param ([Parameter(Mandatory)][Single]$TotalValue, [Parameter(Mandatory)][Single]$CurrentValue, [Parameter(Mandatory)][string]$ProgressText, [Parameter()][int]$BarSize = 10, [Parameter()][switch]$Complete)
        $percent = $CurrentValue / $TotalValue
        $percentComplete = $percent * 100
        if ($psISE) { Write-Progress "$ProgressText" -id 0 -percentComplete $percentComplete }
        else { Write-Host -NoNewLine "`r$ProgressText $(''.PadRight($BarSize * $percent, [char]9608).PadRight($BarSize, [char]9617)) $($percentComplete.ToString('##0.00').PadLeft(6)) % " }
        }
        try {
        $request = [System.Net.HttpWebRequest]::Create($URL)
        $response = $request.GetResponse()
        if ($response.StatusCode -eq 401 -or $response.StatusCode -eq 403 -or $response.StatusCode -eq 404) { throw "Remote file either doesn't exist, is unauthorized, or is forbidden for '$URL'." }
        if ($File -match '^\.\\') { $File = Join-Path (Get-Location -PSProvider 'FileSystem') ($File -Split '^\.')[1] }
        if ($File -and !(Split-Path $File)) { $File = Join-Path (Get-Location -PSProvider 'FileSystem') $File }
        if ($File) { $fileDirectory = $([System.IO.Path]::GetDirectoryName($File)); if (!(Test-Path($fileDirectory))) { [System.IO.Directory]::CreateDirectory($fileDirectory) | Out-Null } }
        [long]$fullSize = $response.ContentLength
        [byte[]]$buffer = new-object byte[] 1048576
        [long]$total = [long]$count = 0
        $reader = $response.GetResponseStream()
        $writer = new-object System.IO.FileStream $File, 'Create'
        do {
        $count = $reader.Read($buffer, 0, $buffer.Length)
        $writer.Write($buffer, 0, $count)
        $total += $count
        if ($fullSize -gt 0) { Show-Progress -TotalValue $fullSize -CurrentValue $total -ProgressText " $([System.IO.Path]::GetFileName($File))" }
        } while ($count -gt 0)
        }
        finally {
        if ($null -ne $reader) { $reader.Close() }
        if ($null -ne $writer) { $writer.Close() }
        if ($null -ne $response) { $response.Close() }
        }
        }

        # FUNCTION SHOW MODERN FILE PICKER
        function Show-ModernFilePicker {
        param(
        [ValidateSet('Folder', 'File')]
        $Mode,
        [string]$fileType
        )
        if ($Mode -eq 'Folder') {
        $Title = 'Select Folder'
        $modeOption = $false
        $Filter = "Folders|`n"
        }
        else {
        $Title = 'Select File'
        $modeOption = $true
        if ($fileType) {
        $Filter = "$fileType Files (*.$fileType) | *.$fileType|All files (*.*)|*.*"
        }
        else {
        $Filter = 'All Files (*.*)|*.*'
        }
        }
        $AssemblyFullName = 'System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'
        $Assembly = [System.Reflection.Assembly]::Load($AssemblyFullName)
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.AddExtension = $modeOption
        $OpenFileDialog.CheckFileExists = $modeOption
        $OpenFileDialog.DereferenceLinks = $true
        $OpenFileDialog.Filter = $Filter
        $OpenFileDialog.Multiselect = $false
        $OpenFileDialog.Title = $Title
        $OpenFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
        $OpenFileDialogType = $OpenFileDialog.GetType()
        $FileDialogInterfaceType = $Assembly.GetType('System.Windows.Forms.FileDialogNative+IFileDialog')
        $IFileDialog = $OpenFileDialogType.GetMethod('CreateVistaDialog', @('NonPublic', 'Public', 'Static', 'Instance')).Invoke($OpenFileDialog, $null)
        $null = $OpenFileDialogType.GetMethod('OnBeforeVistaDialog', @('NonPublic', 'Public', 'Static', 'Instance')).Invoke($OpenFileDialog, $IFileDialog)
        if ($Mode -eq 'Folder') {
        [uint32]$PickFoldersOption = $Assembly.GetType('System.Windows.Forms.FileDialogNative+FOS').GetField('FOS_PICKFOLDERS').GetValue($null)
        $FolderOptions = $OpenFileDialogType.GetMethod('get_Options', @('NonPublic', 'Public', 'Static', 'Instance')).Invoke($OpenFileDialog, $null) -bor $PickFoldersOption
        $null = $FileDialogInterfaceType.GetMethod('SetOptions', @('NonPublic', 'Public', 'Static', 'Instance')).Invoke($IFileDialog, $FolderOptions)
        }
       $VistaDialogEvent = [System.Activator]::CreateInstance($AssemblyFullName, 'System.Windows.Forms.FileDialog+VistaDialogEvents', $false, 0, $null, $OpenFileDialog, $null, $null).Unwrap()
        [uint32]$AdviceCookie = 0
        $AdvisoryParameters = @($VistaDialogEvent, $AdviceCookie)
        $AdviseResult = $FileDialogInterfaceType.GetMethod('Advise', @('NonPublic', 'Public', 'Static', 'Instance')).Invoke($IFileDialog, $AdvisoryParameters)
        $AdviceCookie = $AdvisoryParameters[1]
        $Result = $FileDialogInterfaceType.GetMethod('Show', @('NonPublic', 'Public', 'Static', 'Instance')).Invoke($IFileDialog, [System.IntPtr]::Zero)
        $null = $FileDialogInterfaceType.GetMethod('Unadvise', @('NonPublic', 'Public', 'Static', 'Instance')).Invoke($IFileDialog, $AdviceCookie)
        if ($Result -eq [System.Windows.Forms.DialogResult]::OK) {
        $FileDialogInterfaceType.GetMethod('GetResult', @('NonPublic', 'Public', 'Static', 'Instance')).Invoke($IFileDialog, $null)
        }
        return $OpenFileDialog.FileName
        }

if ($env:BWO_UNATTENDED -ne '1') {
    $BwoCfgBundleRoot = $null
    if (-not [string]::IsNullOrWhiteSpace($env:BWO_GAME_CONFIGS_ROOT)) {
        $BwoCfgBundleRoot = ([string]$env:BWO_GAME_CONFIGS_ROOT).TrimEnd('\', '/')
    }
    if ([string]::IsNullOrWhiteSpace([string]$BwoCfgBundleRoot) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $p0 = Split-Path -Parent -LiteralPath $PSCommandPath
        if (-not [string]::IsNullOrWhiteSpace([string]$p0)) {
            $p1 = Split-Path -Parent -LiteralPath $p0
            if (-not [string]::IsNullOrWhiteSpace([string]$p1)) { $BwoCfgBundleRoot = $p1 }
        }
    }
    if ([string]::IsNullOrWhiteSpace([string]$BwoCfgBundleRoot) -and -not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $spr = Split-Path -Parent -LiteralPath $PSScriptRoot
        if (-not [string]::IsNullOrWhiteSpace([string]$spr)) { $BwoCfgBundleRoot = $spr }
    }
    $__bwoInstallCheckPath = $null
    if (-not [string]::IsNullOrWhiteSpace([string]$BwoCfgBundleRoot)) {
        $__bwoInstallCheckPath = Join-Path -Path $BwoCfgBundleRoot -ChildPath 'BwoGameInstallCheck.ps1'
    }
    if ($null -ne $__bwoInstallCheckPath -and (Test-Path -LiteralPath $__bwoInstallCheckPath)) {
        $BwoCfgRelKey = 'unknown/unknown.ps1'
        if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
            $rk0 = Split-Path -Parent -LiteralPath $PSCommandPath
            if (-not [string]::IsNullOrWhiteSpace([string]$rk0)) {
                $BwoCfgRelKey = "$(Split-Path -Leaf -LiteralPath $rk0)/$(Split-Path -Leaf -LiteralPath $PSCommandPath)"
            }
        } elseif (-not [string]::IsNullOrWhiteSpace($PSScriptRoot) -and $MyInvocation.MyCommand.Name) {
            $BwoCfgRelKey = "$(Split-Path -Leaf -LiteralPath $PSScriptRoot)/$($MyInvocation.MyCommand.Name)"
        }
        . (Join-Path -Path $BwoCfgBundleRoot -ChildPath 'BwoGameInstallCheck.ps1')
        Assert-BwoGameInstalled -BundleRoot $BwoCfgBundleRoot -ScriptRelativeKey $BwoCfgRelKey
    }
}
# create config folders
New-Item -Path "$env:LOCALAPPDATA\FragPunk\A50\Saved\Config" -Name "WindowsClient" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$env:LOCALAPPDATA\FragPunk\Epic\Saved\Config" -Name "WindowsClient" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$env:LOCALAPPDATA\FragPunk\Steam\Saved\Config" -Name "WindowsClient" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
Clear-Host

# download config files
Get-FileFromWeb -URL "https://github.com/raspyydev/Game-Configs/raw/refs/heads/main/Frag%20Punk/Frag%20Punk.zip" -File "$env:SystemRoot\Temp\Frag Punk.zip"
Clear-Host

# extract config files
Expand-Archive "$env:SystemRoot\Temp\Frag Punk.zip" -DestinationPath "$env:SystemRoot\Temp\FragPunk" -ErrorAction SilentlyContinue | Out-Null
Clear-Host

# download inspector
Get-FileFromWeb -URL "https://github.com/raspyydev/Better-Ressourcen/releases/download/downloads/inspector.exe" -File "$env:SystemRoot\Temp\FragPunk\RebarOffInspector\inspector.exe"
Clear-Host

# message
Write-Host "Importing Frag Punk Inspector Profile: Rebar Off. Please wait . . ."
Write-Host ""
Write-Host "AMD GPU users, ignore error & press 'OK'"
Write-Host ""
# unblock drs files
$path = "C:\ProgramData\NVIDIA Corporation\Drs"
Get-ChildItem -Path $path -Recurse | Unblock-File
# import inspector profile
Start-Process -wait "$env:SystemRoot\Temp\FragPunk\RebarOffInspector\inspector.exe" -args "$env:SystemRoot\Temp\FragPunk\RebarOffInspector\FragPunk.nip -silent"
Timeout /T 3 | Out-Null
Clear-Host

# install config files
Copy-Item -Path "$env:SystemRoot\Temp\FragPunk\Engine.ini" -Destination "$env:LOCALAPPDATA\FragPunk\A50\Saved\Config\WindowsClient" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "$env:SystemRoot\Temp\FragPunk\GameUserSettings.ini" -Destination "$env:LOCALAPPDATA\FragPunk\A50\Saved\Config\WindowsClient" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "$env:SystemRoot\Temp\FragPunk\Engine.ini" -Destination "$env:LOCALAPPDATA\FragPunk\Epic\Saved\Config\WindowsClient" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "$env:SystemRoot\Temp\FragPunk\GameUserSettings.ini" -Destination "$env:LOCALAPPDATA\FragPunk\Epic\Saved\Config\WindowsClient" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "$env:SystemRoot\Temp\FragPunk\Engine.ini" -Destination "$env:LOCALAPPDATA\FragPunk\Steam\Saved\Config\WindowsClient" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item -Path "$env:SystemRoot\Temp\FragPunk\GameUserSettings.ini" -Destination "$env:LOCALAPPDATA\FragPunk\Steam\Saved\Config\WindowsClient" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
Clear-Host

# cleanup
Remove-Item "$env:SystemRoot\Temp\FragPunk" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$env:SystemRoot\Temp\Frag Punk.zip" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
Clear-Host

# message
Write-Host "Frag Punk config applied . . ."
if ($env:BWO_UNATTENDED -ne '1') { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
