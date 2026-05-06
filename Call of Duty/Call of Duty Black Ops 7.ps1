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

# BwoGameInstallCheck needs a stable bundle root; embedded BWO console (BWO_UNATTENDED=1) often has no PSCommandPath/PSScriptRoot — skip probe there (no red errors).
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
    if ([string]::IsNullOrWhiteSpace([string]$BwoCfgBundleRoot) -and -not [string]::IsNullOrWhiteSpace($env:BWO_GAME_CONFIG_SCRIPT_DIR)) {
        $_gscd = $env:BWO_GAME_CONFIG_SCRIPT_DIR.TrimEnd('\','/')
        $_bp = Split-Path -Parent -LiteralPath $_gscd
        if (-not [string]::IsNullOrWhiteSpace($_bp)) { $BwoCfgBundleRoot = $_bp }
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$BwoCfgBundleRoot)) {
        $BwoCfgBundleRoot = ([string]$BwoCfgBundleRoot).TrimEnd('\','/')
    }
    if ([string]::IsNullOrWhiteSpace([string]$BwoCfgBundleRoot)) {
        $_cwdBundle = $PWD.Path
        if ([string]::IsNullOrWhiteSpace($_cwdBundle)) { $_cwdBundle = [Environment]::CurrentDirectory }
        if (-not [string]::IsNullOrWhiteSpace($_cwdBundle)) {
            $_parentBundle = Split-Path -Parent -LiteralPath $_cwdBundle
            if (-not [string]::IsNullOrWhiteSpace($_parentBundle)) {
                $BwoCfgBundleRoot = $_parentBundle.TrimEnd('\','/')
            }
        }
    }
    $__bwoInstallCheckPath = $null
    if ((-not [string]::IsNullOrWhiteSpace([string]$BwoCfgBundleRoot)) -and ($BwoCfgBundleRoot.Trim().Length -gt 0)) {
        $__bwoInstallCheckPath = [System.IO.Path]::Combine($BwoCfgBundleRoot.TrimEnd('\','/'), 'BwoGameInstallCheck.ps1')
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
        . ([System.IO.Path]::Combine($BwoCfgBundleRoot.TrimEnd('\','/'), 'BwoGameInstallCheck.ps1'))
        Assert-BwoGameInstalled -BundleRoot $BwoCfgBundleRoot -ScriptRelativeKey $BwoCfgRelKey
    }
}

# message
if ($env:BWO_UNATTENDED -ne '1') {
    Write-Host "Run game once to generate config location"
    Write-Host ""
    Pause
}
Clear-Host

# Config archive: prefer zip next to this script (bundled / import), else download from Game-Configs repo.
$bo7ZipName = "Call of Duty Black Ops 7/Warzone.zip"
$tempZip = "$env:SystemRoot\Temp\BO7.zip"
$tempDir = "$env:SystemRoot\Temp\BO7"
$scriptPath = $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($scriptPath) -and $PSCommandPath) { $scriptPath = $PSCommandPath }
$scriptDir = $null
if (-not [string]::IsNullOrWhiteSpace($scriptPath)) {
    $gd = [System.IO.Path]::GetDirectoryName($scriptPath)
    if (-not [string]::IsNullOrWhiteSpace($gd)) { $scriptDir = $gd }
}
if ([string]::IsNullOrWhiteSpace("$scriptDir") -and -not [string]::IsNullOrWhiteSpace($env:BWO_GAME_CONFIGS_ROOT)) {
    $gr = ([string]$env:BWO_GAME_CONFIGS_ROOT).TrimEnd('\', '/')
    if ($gr.Length -gt 0) {
        $scriptDir = [System.IO.Path]::Combine($gr, 'Call of Duty')
    }
}
if ([string]::IsNullOrWhiteSpace("$scriptDir") -and -not [string]::IsNullOrWhiteSpace($env:BWO_GAME_CONFIG_SCRIPT_DIR)) {
    $scriptDir = $env:BWO_GAME_CONFIG_SCRIPT_DIR.TrimEnd('\','/')
}
if ([string]::IsNullOrWhiteSpace("$scriptDir") -and $PSScriptRoot) { $scriptDir = [string]$PSScriptRoot }
if ([string]::IsNullOrWhiteSpace("$scriptDir")) {
    foreach ($_tryZip in @($PWD.Path, [Environment]::CurrentDirectory)) {
        if (-not [string]::IsNullOrWhiteSpace($_tryZip)) {
            $scriptDir = $_tryZip.TrimEnd('\','/')
            break
        }
    }
}
$localZip = $null
$_sdFinal = "$scriptDir".Trim().TrimEnd('\','/')
if ($_sdFinal.Length -gt 0 -and -not [string]::IsNullOrWhiteSpace($bo7ZipName)) {
    $localZip = [System.IO.Path]::Combine($_sdFinal, $bo7ZipName)
}

if ($localZip -and (Test-Path -LiteralPath $localZip)) {
    Copy-Item -LiteralPath $localZip -Destination $tempZip -Force
} else {
    Get-FileFromWeb -URL "https://github.com/raspyydev/Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Black%20Ops%207.zip" -File $tempZip
}
Clear-Host

if (-not (Test-Path -LiteralPath $tempZip) -or ((Get-Item -LiteralPath $tempZip).Length -lt 64)) {
    Write-Host "Black Ops 7/Warzone config archive missing or empty." -ForegroundColor Red
    Write-Host "Add '$bo7ZipName' next to this script, or publish it at:" -ForegroundColor Yellow
    Write-Host "https://github.com/raspyydev/Game-Configs/tree/main/Call%20of%20Duty" -ForegroundColor Yellow
    exit 1
}

Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive -LiteralPath $tempZip -DestinationPath $tempDir -Force
Clear-Host

$cfg0 = "$tempDir\players\s.1.0.cod25.txt0"
$cfg1 = "$tempDir\players\s.1.0.cod25.txt1"
if (-not ((Test-Path -LiteralPath $cfg0) -and (Test-Path -LiteralPath $cfg1))) {
    Write-Host "Archive did not contain expected players\s.1.0.cod25.txt0 and .txt1 (corrupt zip or wrong archive)." -ForegroundColor Red
    exit 1
}

# edit config files
$s10cod25txt0 = "$env:SystemRoot\Temp\BO7\players\s.1.0.cod25.txt0"
$s10cod25txt1 = "$env:SystemRoot\Temp\BO7\players\s.1.0.cod25.txt1"

# user input change rendererworkercount in config files
Write-Host "Set RendererWorkerCount to cpu cores -1"
Write-Host ""
do {
$input = Read-Host -Prompt "RendererWorkerCount"
} while ([string]::IsNullOrWhiteSpace($input))
(Get-Content $s10cod25txt0) -replace "\$", $input | Out-File $s10cod25txt0
(Get-Content $s10cod25txt1) -replace "\$", $input | Out-File $s10cod25txt1

# convert s.1.0.cod25.txt0 to utf8
$content = Get-Content -Path "$env:SystemRoot\Temp\BO7\players\s.1.0.cod25.txt0" -Raw
$filePath = "$env:SystemRoot\Temp\BO7\players\s.1.0.cod25.txt0"
$encoding = New-Object System.Text.UTF8Encoding $false
$writer = [System.IO.StreamWriter]::new($filePath, $false, $encoding)
$writer.Write($content)
$writer.Close()

# convert s.1.0.cod25.txt1 to utf8
$content = Get-Content -Path "$env:SystemRoot\Temp\BO7\players\s.1.0.cod25.txt1" -Raw
$filePath = "$env:SystemRoot\Temp\BO7\players\s.1.0.cod25.txt1"
$encoding = New-Object System.Text.UTF8Encoding $false
$writer = [System.IO.StreamWriter]::new($filePath, $false, $encoding)
$writer.Write($content)
$writer.Close()

# install config files
$destPlayers = Join-Path $env:LocalAppData "Activision\Call of Duty\players"
if (-not (Test-Path -LiteralPath $destPlayers)) {
    New-Item -ItemType Directory -Path $destPlayers -Force | Out-Null
}
Copy-Item -Path "$env:SystemRoot\Temp\BO7\players\*" -Destination $destPlayers -Recurse -Force
Clear-Host

# cleanup
Remove-Item "$env:SystemRoot\Temp\BO7" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$env:SystemRoot\Temp\BO7.zip" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

# message
Write-Host "Call of Duty Black Ops 7/Warzone config applied . . ."
Write-Host ""
Write-Host "Always select 'no' for 'Set Optimal Settings & Run In Safe Mode'"
Write-Host ""
Write-Host "Open game, in GRAPHICS select Restart Shaders Pre-Loading then reboot game"
if ($env:BWO_UNATTENDED -ne '1') { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }