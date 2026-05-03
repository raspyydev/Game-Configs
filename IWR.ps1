        # SCRIPT RUN AS ADMIN
        If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
        {Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
        Exit}
        $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + " (Administrator)"
        $Host.UI.RawUI.BackgroundColor = "Black"
        $Host.PrivateData.ProgressBackgroundColor = "Black"
        $Host.PrivateData.ProgressForegroundColor = "White"
        Clear-Host

        # SCRIPT CHECK INTERNET
        if (!(Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
        Write-Host "Internet Connection Required`n" -ForegroundColor Red
        Pause
        exit
        }

        # SCRIPT SILENT
        $progresspreference = 'silentlycontinue'

        # FUNCTION SHOW MENU
        function show-menu {
	    Clear-Host
	    Write-Host ""
	    Write-Host "GITHUB GAME CONFIGS"
	    Write-Host ""
        Write-Host " 1.  Exit"
        Write-Host " 2.  ARC Raiders"
        Write-Host " 3.  Battlefield"
        Write-Host " 4.  Call of Duty"
        Write-Host " 5.  Counter Strike 2"
        Write-Host " 6.  Delta Force"
        Write-Host " 7.  Frag Punk"
        Write-Host " 8.  Marvel Rivals"
        Write-Host " 9.  PUBG BATTLEGROUNDS"
        Write-Host " 10. Splitgate"
        Write-Host " 11. STAR WARS Battlefront"
        Write-Host " 12. The Finals"
	    Write-Host ""
	                  }
	    show-menu
        while ($true) {
        $choice = Read-Host " "
        if ($choice -match '^(12|11|10|[1-9])$') {
        switch ($choice) {
        1 {

Clear-Host
exit

          }
        2 {

Clear-Host
irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/ARC%20Raiders/ARC%20Raiders.ps1 | iex
show-menu

          }
        3 {

Clear-Host
# show list
Write-Host "1. Battlefield 6"
Write-Host "2. Battlefield 2042"
Write-Host "3. Battlefield V"
Write-Host "4. Battlefield 1"
Write-Host "5. Battlefield Hardline"
Write-Host "6. Battlefield 4"
Write-Host "7. Battlefield 3"
Write-Host "8. Battlefield Bad Company 2"
Write-Host ""
# select game
$game = Read-Host -Prompt " "
Clear-Host
# map choice game
switch ($game) {
"1" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Battlefield/Battlefield%206.ps1 | iex}
"2" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Battlefield/Battlefield%202042.ps1 | iex}
"3" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Battlefield/Battlefield%20V.ps1 | iex}
"4" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Battlefield/Battlefield%201.ps1 | iex}
"5" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Battlefield/Battlefield%20Hardline.ps1 | iex}
"6" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Battlefield/Battlefield%204.ps1 | iex}
"7" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Battlefield/Battlefield%203.ps1 | iex}
"8" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Battlefield/Battlefield%20Bad%20Company%202.ps1 | iex}
default {
Write-Host "Invalid input . . ." -ForegroundColor Red
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit
}
}
show-menu

          }
        4 {

Clear-Host
# show list
Write-Host "1. Call of Duty Black Ops 7"
Write-Host "2. Call of Duty Black Ops 6 & WZ"
Write-Host "3. Call of Duty Modern Warfare 3 2023"
Write-Host "4. Call of Duty Modern Warfare 2 2022"
Write-Host "5. Call of Duty Black Ops Cold War"
Write-Host "6. Call of Duty Vanguard"
Write-Host "7. Call of Duty Modern Warfare 2019"
Write-Host "8. Call of Duty Black Ops 4"
Write-Host ""
# select game
$game = Read-Host -Prompt " "
Clear-Host
# map choice game
switch ($game) {
"1" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Black%20Ops%207.ps1 | iex}
"2" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Black%20Ops%206.ps1 | iex}
"3" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Modern%20Warfare%203%202023.ps1 | iex}
"4" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Modern%20Warfare%202%202022.ps1 | iex}
"5" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Black%20Ops%20Cold%20War.ps1 | iex}
"6" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Vanguard.ps1 | iex}
"7" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Modern%20Warfare%202019.ps1 | iex}
"8" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Call%20of%20Duty/Call%20of%20Duty%20Black%20Ops%204.ps1 | iex}
default {
Write-Host "Invalid input . . ." -ForegroundColor Red
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit
}
}
show-menu

          }
        5 {

Clear-Host
irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Counter%20Strike%202/Counter%20Strike%202.ps1 | iex
show-menu

          }
        6 {

Clear-Host
irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Delta%20Force/Delta%20Force.ps1 | iex
show-menu

          }
        7 {

Clear-Host
irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Frag%20Punk/Frag%20Punk.ps1 | iex
show-menu

          }
        8 {

Clear-Host
irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Marvel%20Rivals/Marvel%20Rivals.ps1 | iex
show-menu

          }
        9 {

Clear-Host
irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/PUBG%20BATTLEGROUNDS/PUBG%20BATTLEGROUNDS.ps1 | iex
show-menu

           }
        10 {

Clear-Host
# show list
Write-Host "1. Splitgate 1"
Write-Host "2. Splitgate 2"
Write-Host ""
# select game
$game = Read-Host -Prompt " "
Clear-Host
# map choice game
switch ($game) {
"1" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Splitgate/Splitgate%201.ps1 | iex}
"2" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/Splitgate/Splitgate%202.ps1 | iex}
default {
Write-Host "Invalid input . . ." -ForegroundColor Red
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit
}
}
show-menu

           }
        11 {

Clear-Host
# show list
Write-Host "1. STAR WARS Battlefront I 2015"
Write-Host "2. STAR WARS Battlefront II 2017"
Write-Host ""
# select game
$game = Read-Host -Prompt " "
Clear-Host
# map choice game
switch ($game) {
"1" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/STAR%20WARS%20Battlefront/STAR%20WARS%20Battlefront%20I%202015.ps1 | iex}
"2" {irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/STAR%20WARS%20Battlefront/STAR%20WARS%20Battlefront%20II%202017.ps1 | iex}
default {
Write-Host "Invalid input . . ." -ForegroundColor Red
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit
}
}
show-menu

           }
        12 {

Clear-Host
irm https://github.com/FR33THYFR33THY/Github-Game-Configs/raw/refs/heads/main/The%20Finals/The%20Finals.ps1 | iex
show-menu

          }
        } } else { Write-Host "Invalid input. Please select a valid option (1-12)." } }