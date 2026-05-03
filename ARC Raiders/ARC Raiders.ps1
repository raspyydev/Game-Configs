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
        try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }
        if ($File -match '^\.\\') { $File = Join-Path (Get-Location -PSProvider 'FileSystem') ($File -Split '^\.')[1] }
        if ($File -and !(Split-Path $File)) { $File = Join-Path (Get-Location -PSProvider 'FileSystem') $File }
        if ($File) { $fileDirectory = $([System.IO.Path]::GetDirectoryName($File)); if (!(Test-Path($fileDirectory))) { [System.IO.Directory]::CreateDirectory($fileDirectory) | Out-Null } }

        # GitHub raw often resets connections without a real browser User-Agent; retry helps flaky networks.
        $ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        $response = $null
        $reader = $null
        $writer = $null
        $useStream = $false
        for ($attempt = 1; $attempt -le 3; $attempt++) {
            try {
                $request = [System.Net.HttpWebRequest]::Create($URL)
                $request.UserAgent = $ua
                $request.Timeout = 180000
                $request.ReadWriteTimeout = 300000
                $request.AllowAutoRedirect = $true
                $response = $request.GetResponse()
                $code = [int]$response.StatusCode
                if ($code -eq 401 -or $code -eq 403 -or $code -eq 404) {
                    $response.Close()
                    $response = $null
                    throw "Remote file either doesn't exist, is unauthorized, or is forbidden for '$URL'."
                }
                $useStream = $true
                break
            } catch {
                if ($null -ne $response) { try { $response.Close() } catch { } ; $response = $null }
                if ($attempt -ge 3) { break }
                Start-Sleep -Seconds (2 * $attempt)
            }
        }
        if ($useStream) {
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
        } else {
            try {
                $wc = New-Object System.Net.WebClient
                $wc.Headers.Add('User-Agent', $ua)
                $wc.DownloadFile($URL, $File)
            } catch {
                Invoke-WebRequest -Uri $URL -OutFile $File -UseBasicParsing -UserAgent $ua -TimeoutSec 180
            }
        }
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

# message
if ($env:BWO_UNATTENDED -ne '1') {
    Write-Host "Run game once to generate config location"
    Write-Host ""
    Pause
}
Clear-Host

# Config archive: prefer zip next to this script (bundled / import), else download from Game-Configs repo.
# Embedded BWO / dot-source: MyCommand.Path and PSScriptRoot are often empty—use env + cwd fallbacks (no Join-Path on null).
$arcZipName = 'ARC Raiders.zip'
$tempZip = Join-Path $env:SystemRoot 'Temp\ARC Raiders.zip'
$tempDir = Join-Path $env:SystemRoot 'Temp\ARC Raiders'
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
        $scriptDir = [System.IO.Path]::Combine($gr, 'ARC Raiders')
    }
}
if ([string]::IsNullOrWhiteSpace("$scriptDir") -and -not [string]::IsNullOrWhiteSpace($env:BWO_GAME_CONFIG_SCRIPT_DIR)) {
    $scriptDir = $env:BWO_GAME_CONFIG_SCRIPT_DIR.TrimEnd('\', '/')
}
if ([string]::IsNullOrWhiteSpace("$scriptDir") -and $PSScriptRoot) { $scriptDir = [string]$PSScriptRoot }
if ([string]::IsNullOrWhiteSpace("$scriptDir")) {
    foreach ($_try in @($PWD.Path, [Environment]::CurrentDirectory)) {
        if (-not [string]::IsNullOrWhiteSpace($_try)) {
            $scriptDir = $_try.TrimEnd('\', '/')
            break
        }
    }
}
$localZip = $null
$_sdFinal = "$scriptDir".Trim().TrimEnd('\', '/')
if ($_sdFinal.Length -gt 0 -and -not [string]::IsNullOrWhiteSpace($arcZipName)) {
    $localZip = [System.IO.Path]::Combine($_sdFinal, $arcZipName)
}

try {
    if ($localZip -and (Test-Path -LiteralPath $localZip)) {
        Copy-Item -LiteralPath $localZip -Destination $tempZip -Force
    } else {
        # Prefer bundled ZIP next to script; otherwise download from raspyydev/Game-Configs (two URL shapes).
        $mirrorUrls = @(
            'https://github.com/raspyydev/Game-Configs/raw/refs/heads/main/ARC%20Raiders/ARC%20Raiders.zip',
            'https://raw.githubusercontent.com/raspyydev/Game-Configs/main/ARC%20Raiders/ARC%20Raiders.zip'
        )
        $downloadOk = $false
        foreach ($u in $mirrorUrls) {
            try {
                Get-FileFromWeb -URL $u -File $tempZip
                if ((Test-Path -LiteralPath $tempZip) -and ((Get-Item -LiteralPath $tempZip).Length -ge 64)) {
                    $downloadOk = $true
                    break
                }
            } catch {
                continue
            }
        }
        if (-not $downloadOk) {
            throw 'ARC Raiders: could not download config archive from any mirror (bundle ZIP next to this script should be used).'
        }
    }
} catch {
    Write-Host "ARC Raiders download failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Clear-Host

if (-not (Test-Path -LiteralPath $tempZip) -or ((Get-Item -LiteralPath $tempZip).Length -lt 64)) {
    Write-Host 'ARC Raiders config archive missing or empty.' -ForegroundColor Red
    exit 1
}

Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
try {
    Expand-Archive -LiteralPath $tempZip -DestinationPath $tempDir -Force
} catch {
    Write-Host "ARC Raiders extract failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$extracted = @(Get-ChildItem -LiteralPath $tempDir -Force -ErrorAction SilentlyContinue)
if ($extracted.Count -eq 0) {
    Write-Host 'ARC Raiders archive expanded to an empty folder.' -ForegroundColor Red
    exit 1
}

$destRoot = Join-Path $env:LOCALAPPDATA 'PioneerGame\Saved\Config\WindowsClient'
if (-not (Test-Path -LiteralPath $destRoot)) {
    Write-Host "ARC Raiders config folder not found: $destRoot (run the game once)." -ForegroundColor Red
    exit 1
}

try {
    Copy-Item -Path (Join-Path $tempDir '*') -Destination $destRoot -Recurse -Force
} catch {
    Write-Host "ARC Raiders install copy failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Clear-Host

Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $tempZip -Force -ErrorAction SilentlyContinue
Clear-Host

# message
Write-Host "ARC Raiders config applied . . ." -ForegroundColor Green
if ($env:BWO_UNATTENDED -ne '1') { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
