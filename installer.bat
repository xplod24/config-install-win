@echo off
chcp 1250>NUL
setlocal enabledelayedexpansion

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo BD: Ten skrypt musi by uruchomiony jako administrator!
    pause
    exit /b 0
)

:: Color definitions
set RED=0C
set BLUE=09
set YELLOW=0E
set GREEN=0A
set DEFAULT=07

:: Main menu function
:menu
cls
echo.
color %BLUE%
echo #################################
echo #          CHOCO MANAGER        #
echo #################################
color %YELLOW%
echo.
echo 1. Zainstaluj Chocolatey
echo 2. Zainstaluj Narzedzia
echo 3. Aktualizuj Pakiety
echo 4. Zainstaluj aplikacje NVIDIA
echo 5. Wyjscie
echo.
color %RED%
set /p choice=Wybierz opcje [1-5]: 
color %DEFAULT%

:: Process menu choice
if "%choice%"=="1" goto install_choco
if "%choice%"=="2" goto install_tools
if "%choice%"=="3" goto upgrade_packages
if "%choice%"=="4" goto install_nvidia_app
if "%choice%"=="5" goto exit_script

:: Invalid choice
color %RED%
echo.
echo Nieprawidlowy wybor! Sprobuj ponownie.
pause
goto menu

:install_choco
:: Check if Chocolatey is already installed
where choco >nul 2>&1
if %errorLevel% equ 0 (
    color %RED%
    echo.
    echo Chocolatey jest juz zainstalowany!
    pause
    goto menu
)

color %YELLOW%
echo.
echo Instalowanie Chocolatey...
pause

:: Install Chocolatey
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

color %YELLOW%
echo.
echo Chocolatey zainstalowano pomyslnie!
pause
goto menu

:install_tools
:: Check if Chocolatey is installed
where choco >nul 2>&1
if %errorLevel% neq 0 (
    color %RED%
    echo.
    echo Chocolatey nie jest zainstalowany! Zainstaluj go najpierw.
    pause
    goto menu
)

color %YELLOW%
echo.
echo ================================
echo Instalator rozpoczyna prac...
echo ================================
echo Pierwszy etap to launchery gier, steam, gog galaxy oraz epic games launcher, mona pomin
echo Drugi etap to wybr przegldarki, mona pomin
echo Ostatni etap to instalacja narzdzi oraz podstawowych sterownikw do windowsa, nie mona pomin
echo Narzedzia zawieraja: GIT, Visual Studio Code, 7ZIP, Directx, Wszystkie srodowiska DotNET
echo Biblioteki Visual C++ Redistributable, Java Runtime, Open Java Development Kit, SSH, SSL/TLS
echo.
pause
color %DEFAULT%

:: Check for game launchers first
goto check_launchers

:check_launchers
:: Initialize launcher variables
set STEAM_INSTALLED=0
set GOG_INSTALLED=0
set EPIC_INSTALLED=0

:: Check Chocolatey package list for launchers
for /f "delims=" %%a in ('choco list --local-only --limitoutput') do (
    set "pkg=%%a"
    set "pkg=!pkg:~0,-10!"  :: Remove version info
    if "!pkg!"=="steam" (
        set STEAM_INSTALLED=1
    )
    if "!pkg!"=="goggalaxy" (
        set GOG_INSTALLED=1
    )
    if "!pkg!"=="epicgameslauncher" (
        set EPIC_INSTALLED=1
    )
)

:: Steam detection in registry
if %STEAM_INSTALLED% equ 0 (
    reg query "HKLM\SOFTWARE\Valve\Steam" >nul 2>&1 || reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" >nul 2>&1
    if %errorlevel% equ 0 (
        set STEAM_INSTALLED=1
    )
)

:: GOG Galaxy detection in registry
if %GOG_INSTALLED% equ 0 (
    reg query "HKLM\SOFTWARE\GOG.com\GalaxyClient" >nul 2>&1 || reg query "HKLM\SOFTWARE\WOW6432Node\GOG.com\GalaxyClient" >nul 2>&1
    if %errorlevel% equ 0 (
        set GOG_INSTALLED=1
    )
)

:: Epic Games Launcher detection in registry
if %EPIC_INSTALLED% equ 0 (
    reg query "HKLM\SOFTWARE\EpicGames\Unreal Engine" >nul 2>&1 || reg query "HKLM\SOFTWARE\WOW6432Node\EpicGames\Unreal Engine" >nul 2>&1
    if %errorlevel% equ 0 (
        set EPIC_INSTALLED=1
    )
)

goto launcher_menu

:launcher_menu
cls
echo.
color %BLUE%
echo #################################
echo #   INSTALACJA LAUNCHEROW GIER  #
echo #################################
color %YELLOW%
echo.

:: Display launcher options with installation status
if %STEAM_INSTALLED% equ 1 (
    echo 1. Steam jest ju zainstalowany
) else (
    echo 1. Zainstaluj Steam
)

if %GOG_INSTALLED% equ 1 (
    echo 2. GOG Galaxy jest ju zainstalowany
) else (
    echo 2. Zainstaluj GOG Galaxy
)

if %EPIC_INSTALLED% equ 1 (
    echo 3. Epic Games Launcher jest ju zainstalowany
) else (
    echo 3. Zainstaluj Epic Games Launcher
)

echo 4. Zainstaluj wszystkie launchery
echo 5. Zainstaluj wybrane launchery
echo 6. Pomin instalacje launcherow
echo.
color %RED%
set /p launcher_choice=Wybierz opcje [1-6]: 
color %DEFAULT%

if "%launcher_choice%"=="1" (
    if %STEAM_INSTALLED% equ 1 (
        color %RED%
        echo.
        echo Steam jest juz zainstalowany!
        echo.
        pause
        goto launcher_menu
    )
    color %YELLOW%
    echo Instalowanie Steam...
    choco install steam -y
    set STEAM_INSTALLED=1
    pause
    goto launcher_menu
)

if "%launcher_choice%"=="2" (
    if %GOG_INSTALLED% equ 1 (
        color %RED%
        echo.
        echo GOG Galaxy jest juz zainstalowany!
        echo.
        pause
        goto launcher_menu
    )
    color %YELLOW%
    echo Instalowanie GOG Galaxy...
    choco install goggalaxy -y
    set GOG_INSTALLED=1
    pause
    goto launcher_menu
)

if "%launcher_choice%"=="3" (
    if %EPIC_INSTALLED% equ 1 (
        color %RED%
        echo.
        echo Epic Games Launcher jest juz zainstalowany!
        echo.
        pause
        goto launcher_menu
    )
    color %YELLOW%
    echo Instalowanie Epic Games Launcher...
    choco install epicgameslauncher -y
    set EPIC_INSTALLED=1
    pause
    goto launcher_menu
)

if "%launcher_choice%"=="4" (
    color %YELLOW%
    echo Instalowanie wszystkich launcherow gier...
    
    if %STEAM_INSTALLED% equ 0 (
        echo Instalowanie Steam...
        choco install steam -y
        set STEAM_INSTALLED=1
    ) else (
        echo Steam jest juz zainstalowany.
    )
    
    if %GOG_INSTALLED% equ 0 (
        echo Instalowanie GOG Galaxy...
        choco install goggalaxy -y
        set GOG_INSTALLED=1
    ) else (
        echo GOG Galaxy jest juz zainstalowany.
    )
    
    if %EPIC_INSTALLED% equ 0 (
        echo Instalowanie Epic Games Launcher...
        choco install epicgameslauncher -y
        set EPIC_INSTALLED=1
    ) else (
        echo Epic Games Launcher jest juz zainstalowany.
    )
    
    echo.
    echo Instalacja launcherow zakonczona!
    pause
    goto check_browsers
)

if "%launcher_choice%"=="5" (
    color %YELLOW%
    echo.
    echo Dostepne launchery: steam, goggalaxy, epicgameslauncher
    echo Wpisz nazwy launcherow oddzielone przecinkami np. steam,goggalaxy
    echo.
    set /p selected_launchers=Wybrane launchery: 
    
    echo.
    echo Instalowanie wybranych launcherow...
    
    echo %selected_launchers% | findstr /i "steam" >nul
    if not errorlevel 1 (
        if %STEAM_INSTALLED% equ 0 (
            echo Instalowanie Steam...
            choco install steam -y
            set STEAM_INSTALLED=1
        ) else (
            echo Steam jest juz zainstalowany.
        )
    )
    
    echo %selected_launchers% | findstr /i "goggalaxy" >nul
    if not errorlevel 1 (
        if %GOG_INSTALLED% equ 0 (
            echo Instalowanie GOG Galaxy...
            choco install goggalaxy -y
            set GOG_INSTALLED=1
        ) else (
            echo GOG Galaxy jest juz zainstalowany.
        )
    )
    
    echo %selected_launchers% | findstr /i "epicgameslauncher" >nul
    if not errorlevel 1 (
        if %EPIC_INSTALLED% equ 0 (
            echo Instalowanie Epic Games Launcher...
            choco install epicgameslauncher -y
            set EPIC_INSTALLED=1
        ) else (
            echo Epic Games Launcher jest juz zainstalowany.
        )
    )
    
    echo.
    echo Instalacja wybranych launcherow zakonczona!
    pause
    goto check_browsers
)

if "%launcher_choice%"=="6" goto check_browsers

:: Invalid choice
color %RED%
echo.
echo Nieprawidlowy wybor! Sprobuj ponownie.
pause
goto launcher_menu

:check_browsers
:: Check if Chocolatey is installed
where choco >nul 2>&1
if %errorLevel% neq 0 (
    color %RED%
    echo.
    echo Chocolatey nie jest zainstalowany! Zainstaluj go najpierw.
    pause
    goto menu
)

:: Initialize browser variables
set INSTALLED_BROWSERS=
set INSTALLED_VIA_CHOCO=
set BROWSER_COUNT=0
set CHOCO_BROWSER_COUNT=0

:: Check Chocolatey package list for browsers
for /f "delims=" %%a in ('choco list --local-only --limitoutput') do (
    set "pkg=%%a"
    set "pkg=!pkg:~0,-10!"  :: Remove version info
    if "!pkg!"=="googlechrome" (
        set INSTALLED_VIA_CHOCO=!INSTALLED_VIA_CHOCO! Chrome
        set /a CHOCO_BROWSER_COUNT+=1
    )
    if "!pkg!"=="firefox" (
        set INSTALLED_VIA_CHOCO=!INSTALLED_VIA_CHOCO! Firefox
        set /a CHOCO_BROWSER_COUNT+=1
    )
    if "!pkg!"=="microsoft-edge" (
        set INSTALLED_VIA_CHOCO=!INSTALLED_VIA_CHOCO! Edge
        set /a CHOCO_BROWSER_COUNT+=1
    )
    if "!pkg!"=="opera" (
        set INSTALLED_VIA_CHOCO=!INSTALLED_VIA_CHOCO! Opera
        set /a CHOCO_BROWSER_COUNT+=1
    )
    if "!pkg!"=="brave" (
        set INSTALLED_VIA_CHOCO=!INSTALLED_VIA_CHOCO! Brave
        set /a CHOCO_BROWSER_COUNT+=1
    )
)

:: System-wide browser detection
:: Chrome detection
set CHROME_INSTALLED=0
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" >nul 2>&1
if %errorlevel% equ 0 (
    set INSTALLED_BROWSERS=!INSTALLED_BROWSERS! Chrome
    set /a BROWSER_COUNT+=1
    set CHROME_INSTALLED=1
)

:: Firefox detection
set FIREFOX_INSTALLED=0
reg query "HKLM\SOFTWARE\Mozilla\Mozilla Firefox" >nul 2>&1
if %errorlevel% equ 0 (
    set INSTALLED_BROWSERS=!INSTALLED_BROWSERS! Firefox
    set /a BROWSER_COUNT+=1
    set FIREFOX_INSTALLED=1
)

:: Edge detection (modern) - Check both possible registry locations
set EDGE_INSTALLED=0
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" >nul 2>&1
if %errorlevel% neq 0 (
    reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" >nul 2>&1
)
if %errorlevel% equ 0 (
    set INSTALLED_BROWSERS=!INSTALLED_BROWSERS! Edge
    set /a BROWSER_COUNT+=1
    set EDGE_INSTALLED=1
)

:: Opera detection
set OPERA_INSTALLED=0
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\opera.exe" >nul 2>&1
if %errorlevel% equ 0 (
    set INSTALLED_BROWSERS=!INSTALLED_BROWSERS! Opera
    set /a BROWSER_COUNT+=1
    set OPERA_INSTALLED=1
)

:: Brave detection - Check all possible registry locations
set BRAVE_INSTALLED=0
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\brave.exe" >nul 2>&1
if %errorlevel% neq 0 (
    reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\brave.exe" >nul 2>&1
)
if %errorlevel% neq 0 (
    reg query "HKLM\SOFTWARE\BraveSoftware\Brave-Browser" >nul 2>&1
)
if %errorlevel% equ 0 (
    set INSTALLED_BROWSERS=!INSTALLED_BROWSERS! Brave
    set /a BROWSER_COUNT+=1
    set BRAVE_INSTALLED=1
)

:: Display browser installation status
if %BROWSER_COUNT% gtr 0 (
    color %RED%
    echo.
    echo WYKRYWANIE PRZEGLADAREK W SYSTEMIE:
    echo Zainstalowane przegladarki: !INSTALLED_BROWSERS!
    
    if %CHOCO_BROWSER_COUNT% gtr 0 (
        color %GREEN%
        echo.
        echo WYKRYWANIE PRZEGLADAREK CHOCOLATEY:
        echo Przegladarki zainstalowane przez Chocolatey: !INSTALLED_VIA_CHOCO!
    )
    echo.
    color %YELLOW%
    pause
)

goto browser_menu

:browser_menu
cls
echo.
color %BLUE%
echo #################################
echo #   INSTALACJA PRZEGLADAREK     #
echo #################################
color %YELLOW%
echo.

:: Display browser options with installation status
if %CHROME_INSTALLED% equ 1 (
    echo 1. Google Chrome jest ju zainstalowany
) else (
    echo 1. Zainstaluj Google Chrome
)

if %FIREFOX_INSTALLED% equ 1 (
    echo 2. Mozilla Firefox jest ju zainstalowany
) else (
    echo 2. Zainstaluj Mozilla Firefox
)

if %OPERA_INSTALLED% equ 1 (
    echo 3. Opera jest ju zainstalowany
) else (
    echo 3. Zainstaluj Opera
)

if %EDGE_INSTALLED% equ 1 (
    echo 4. Microsoft Edge jest ju zainstalowany
) else (
    echo 4. Zainstaluj Microsoft Edge
)

if %BRAVE_INSTALLED% equ 1 (
    echo 5. Przegladarka Brave jest ju zainstalowany
) else (
    echo 5. Zainstaluj przegladarke Brave
)

echo 6. Pomin instalacje przegladarki
echo 7. Powrot do menu glownego
echo.
color %RED%
set /p browser_choice=Wybierz opcje [1-7]: 
color %DEFAULT%

if "%browser_choice%"=="1" (
    if %CHROME_INSTALLED% equ 1 (
        color %RED%
        echo.
        echo Google Chrome jest juz zainstalowany!
        echo.
        pause
        goto browser_menu
    )
    color %YELLOW%
    echo Instalowanie Google Chrome...
    choco install googlechrome -y
    set CHROME_INSTALLED=1
    pause
    goto browser_menu
)

if "%browser_choice%"=="2" (
    if %FIREFOX_INSTALLED% equ 1 (
        color %RED%
        echo.
        echo Mozilla Firefox jest juz zainstalowany!
        echo.
        pause
        goto browser_menu
    )
    color %YELLOW%
    echo Instalowanie Mozilla Firefox...
    choco install firefox -y
    set FIREFOX_INSTALLED=1
    pause
    goto browser_menu
)

if "%browser_choice%"=="3" (
    if %OPERA_INSTALLED% equ 1 (
        color %RED%
        echo.
        echo Opera jest juz zainstalowana!
        echo.
        pause
        goto browser_menu
    )
    color %YELLOW%
    echo Instalowanie Opery...
    choco install opera -y
    set OPERA_INSTALLED=1
    pause
    goto browser_menu
)

if "%browser_choice%"=="4" (
    if %EDGE_INSTALLED% equ 1 (
        color %RED%
        echo.
        echo Microsoft Edge jest juz zainstalowany!
        echo.
        pause
        goto browser_menu
    )
    color %YELLOW%
    echo Instalowanie Microsoft Edge...
    choco install microsoft-edge -y
    set EDGE_INSTALLED=1
    pause
    goto browser_menu
)

if "%browser_choice%"=="5" (
    if %BRAVE_INSTALLED% equ 1 (
        color %RED%
        echo.
        echo Przegladarka Brave jest juz zainstalowana!
        echo.
        pause
        goto browser_menu
    )
    color %YELLOW%
    echo Instalowanie przegladarki Brave...
    choco install brave -y
    set BRAVE_INSTALLED=1
    pause
    goto browser_menu
)

if "%browser_choice%"=="6" goto install_tools
if "%browser_choice%"=="7" goto menu

:: Invalid choice
color %RED%
echo.
echo Nieprawidlowy wybor! Sprobuj ponownie.
pause
goto browser_menu

:: List of tools to install (modify as needed)
:install_tools
set TOOLS=git vscode 7zip directx dotnet-all vcredist-all jre openjdk openssh openssl 

for %%t in (%TOOLS%) do (
    echo Instalowanie %%t...
    choco install %%t -y
    echo.
)

color %YELLOW%
echo.
echo Instalacja narzedzi zakonczona!
pause
goto menu

:upgrade_packages
:: Check if Chocolatey is installed
where choco >nul 2>&1
if %errorLevel% neq 0 (
    color %RED%
    echo.
    echo Chocolatey nie jest zainstalowany! Zainstaluj go najpierw.
    pause
    goto menu
)

color %YELLOW%
echo.
echo Aktualizowanie wszystkich pakietow...
echo.
color %DEFAULT%

choco upgrade all -y

color %YELLOW%
echo.
echo Aktualizacja pakietow zakonczona!
pause
goto menu

:install_nvidia_app
:: Check if Chocolatey is installed
where choco >nul 2>&1
if %errorLevel% neq 0 (
    color %RED%
    echo.
    echo Chocolatey nie jest zainstalowany! Zainstaluj go najpierw.
    pause
    goto menu
)

:: Check if NVIDIA app is already installed
set NVIDIA_APP_INSTALLED=0
for /f "delims=" %%a in ('choco list --local-only --limitoutput') do (
    set "pkg=%%a"
    set "pkg=!pkg:~0,-10!"  :: Remove version info
    if "!pkg!"=="nvidia-geforce-experience" (
        set NVIDIA_APP_INSTALLED=1
    )
)

:: Check registry for NVIDIA GeForce Experience
if %NVIDIA_APP_INSTALLED% equ 0 (
    reg query "HKLM\SOFTWARE\NVIDIA Corporation\Global\GFExperience" >nul 2>&1 || reg query "HKLM\SOFTWARE\WOW6432Node\NVIDIA Corporation\Global\GFExperience" >nul 2>&1
    if %errorlevel% equ 0 (
        set NVIDIA_APP_INSTALLED=1
    )
)

:: Display NVIDIA app installation menu
cls
echo.
color %BLUE%
echo #################################
echo #   INSTALACJA APLIKACJI NVIDIA #
echo #################################
color %YELLOW%
echo.

if %NVIDIA_APP_INSTALLED% equ 1 (
    echo NVIDIA GeForce Experience jest juz zainstalowany!
    echo.
    echo 1. Uruchom NVIDIA GeForce Experience
    echo 2. Odinstaluj NVIDIA GeForce Experience
    echo 3. Powrot do menu glownego
    echo.
    color %RED%
    set /p nvidia_choice=Wybierz opcje [1-3]: 
    color %DEFAULT%
    
    if "%nvidia_choice%"=="1" (
        echo Uruchamianie NVIDIA GeForce Experience...
        start "" "C:\Program Files\NVIDIA Corporation\NVIDIA GeForce Experience\NVIDIA GeForce Experience.exe"
        goto menu
    ) else if "%nvidia_choice%"=="2" (
        echo Odinstalowywanie NVIDIA GeForce Experience...
        choco uninstall nvidia-geforce-experience -y
        echo Odinstalowano NVIDIA GeForce Experience.
        pause
        goto menu
    ) else if "%nvidia_choice%"=="3" (
        goto menu
    ) else (
        color %RED%
        echo.
        echo Nieprawidlowy wybor! Sprobuj ponownie.
        pause
        goto install_nvidia_app
    )
) else (
    echo NVIDIA GeForce Experience nie jest zainstalowany.
    echo.
    echo 1. Zainstaluj NVIDIA GeForce Experience
    echo 2. Powrot do menu glownego
    echo.
    color %RED%
    set /p nvidia_choice=Wybierz opcje [1-2]: 
    color %DEFAULT%
    
    if "%nvidia_choice%"=="1" (
        color %YELLOW%
        echo Instalowanie NVIDIA GeForce Experience...
        choco install nvidia-geforce-experience -y
        echo.
        echo Instalacja NVIDIA GeForce Experience zakonczona!
        pause
        goto menu
    ) else if "%nvidia_choice%"=="2" (
        goto menu
    ) else (
        color %RED%
        echo.
        echo Nieprawidlowy wybor! Sprobuj ponownie.
        pause
        goto install_nvidia_app
    )
)

:exit_script
color %DEFAULT%
exit /b