<#
.SYNOPSIS
    Finalized Chocolatey Manager
    - Core functions unchanged.
    - Added Safety Lock (Input disabled during scan).
    - Added Dynamic Status Bar (Shows detailed app info).
    - Added Navigation Legend.
#>

# --- 1. ADMIN CHECK ---
try {
    $curID = [Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not ([Security.Principal.WindowsPrincipal]$curID).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
} catch {
    Write-Warning "Admin check failed."
    Pause
}

# --- 2. CONFIGURATION ---
try {
    if ($host.UI.RawUI.WindowSize.Width -lt 110) { $host.UI.RawUI.WindowSize = @{Width=110; Height=$host.UI.RawUI.WindowSize.Height} }
    if ($host.UI.RawUI.WindowSize.Height -lt 40) { $host.UI.RawUI.WindowSize = @{Width=$host.UI.RawUI.WindowSize.Width; Height=40} }
} catch {}

$script:PageSize = 25
$script:CurrentPage = 0
$script:TotalPages = 1
$script:TotalItems = 0
$script:RawSearchResults = @() 
$script:ViewList = @()         
$script:GlobalStates = @{}     
$script:LocalVersions = @{}
$script:Cursor = 0
$script:State = "MENU"
$script:ListName = "Main Menu"
$script:StatusMsg = "Ready"
$script:ScanJob = $null
$script:IsScanning = $false

# Recommended List
$RecommendedApps = @(
    @{Id="steam"; RegName="Steam"}, @{Id="goggalaxy"; RegName="GOG Galaxy"}, @{Id="epicgameslauncher"; RegName="Epic Games Launcher"},
    @{Id="googlechrome"; RegName="Google Chrome"}, @{Id="firefox"; RegName="Mozilla Firefox"}, @{Id="microsoft-edge"; RegName="Microsoft Edge"},
    @{Id="opera"; RegName="Opera"}, @{Id="brave"; RegName="Brave"}, @{Id="git"; RegName="Git"}, @{Id="vscode"; RegName="Visual Studio Code"},
    @{Id="7zip"; RegName="7-Zip"}, @{Id="directx"; RegName="DirectX"}, @{Id="dotnet-all"; RegName="Microsoft .NET"},
    @{Id="vcredist-all"; RegName="Microsoft Visual C++"}, @{Id="jre"; RegName="Java"}, @{Id="openjdk"; RegName="OpenJDK"},
    @{Id="openssh"; RegName="OpenSSH"}, @{Id="openssl"; RegName="OpenSSL"}, @{Id="nvidia-app"; RegName="NVIDIA App"}
)

# --- 3. BACKGROUND JOB LOGIC ---

function Start-Scan-Job {
    if ($script:ScanJob -and $script:ScanJob.State -eq 'Running') {
        Stop-Job $script:ScanJob
        Remove-Job $script:ScanJob
    }

    $script:IsScanning = $true
    Update-Context-Status # Update status to "Scanning..."
    Draw-Viewer

    $itemsToScan = $script:ViewList
    $script:ScanJob = Start-Job -ScriptBlock {
        param($items)
        $results = @{}
        
        # 1. Choco Map
        $chocoRaw = (choco list --local-only --limit-output) 
        $chocoMap = @{}
        foreach ($line in $chocoRaw) {
            if ($line -match "\|") {
                $p = $line -split "\|"
                $chocoMap[$p[0].ToLower()] = $p[1]
            }
        }

        # 2. Registry Paths
        $regPaths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")

        # 3. Process
        foreach ($item in $items) {
            $id = $item.Id.ToLower()
            $regPattern = if ($item.RegName) { $item.RegName } else { $id }
            $status = 0
            $version = "-"

            if ($chocoMap.ContainsKey($id)) {
                $status = 2 # Managed
                $version = $chocoMap[$id]
            } else {
                $foundReg = $false
                foreach ($path in $regPaths) {
                    $keys = Get-ItemProperty $path -ErrorAction SilentlyContinue
                    foreach ($k in $keys) {
                        if ($k.DisplayName -match "$regPattern") {
                            $foundReg = $true
                            break
                        }
                    }
                    if ($foundReg) { break }
                }
                if ($foundReg) { $status = 4; $version = "Manual" }
            }
            $results[$id] = @{S=$status; V=$version}
        }
        return $results
    } -ArgumentList (,$itemsToScan)
}

function Check-Job-Completion {
    if ($script:ScanJob -and $script:ScanJob.State -eq 'Completed') {
        $data = Receive-Job $script:ScanJob
        Remove-Job $script:ScanJob
        $script:ScanJob = $null
        $script:IsScanning = $false
        
        if ($data) {
            foreach ($key in $data.Keys) {
                if ($script:GlobalStates[$key] -ne 1 -and $script:GlobalStates[$key] -ne 3) {
                    $script:GlobalStates[$key] = $data[$key].S
                    $script:LocalVersions[$key] = $data[$key].V
                }
            }
            Update-Context-Status
            Draw-Viewer
        }
    }
}

# --- 4. DATA MANAGEMENT ---

function Load-Data-Set {
    param($data, $name)
    $script:RawSearchResults = $data
    $script:ListName = $name
    $script:TotalItems = $data.Count
    $script:TotalPages = [Math]::Ceiling($data.Count / $script:PageSize)
    if ($script:TotalPages -eq 0) { $script:TotalPages = 1 }
    $script:CurrentPage = 0
    $script:Cursor = 0
    $script:State = "VIEWER"
    Load-Page 0
}

function Load-Page {
    param([int]$pageNum)
    $start = $pageNum * $script:PageSize
    if ($start -ge $script:RawSearchResults.Count) { return }
    $end = [Math]::Min(($start + $script:PageSize - 1), ($script:RawSearchResults.Count - 1))
    $script:ViewList = $script:RawSearchResults[$start..$end]
    $script:CurrentPage = $pageNum
    $script:Cursor = 0 
    Start-Scan-Job
}

function Perform-Search {
    Clear-Host
    Write-Host "`n`n"
    Write-Host "    SEARCH ONLINE" -ForegroundColor Cyan
    Write-Host "    =============" -ForegroundColor Gray
    Write-Host "    Enter app name (empty to cancel):"
    Write-Host "    > " -NoNewline -ForegroundColor Yellow
    
    $query = Read-Host
    
    if (-not [string]::IsNullOrWhiteSpace($query)) {
        Write-Host "`n    Searching... " -ForegroundColor Green
        $results = choco search $query --limit-output
        if ($results) {
            $parsed = @()
            foreach ($line in $results) {
                if ($line -match "\|") {
                    $p = $line -split "\|"
                    $parsed += @{Id=$p[0]; RegName=$p[0]; LatestVer=$p[1]}
                }
            }
            Load-Data-Set $parsed "Search: '$query'"
        } else {
            Write-Host "    No results." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

# --- 5. SAFE RENDERING ---

function Print-Line ($text, $fg, $bg, $width) {
    if ($text.Length -ge $width) { $text = $text.Substring(0, $width - 1) }
    $padded = $text.PadRight($width)
    Write-Host $padded -NoNewline -ForegroundColor $fg -BackgroundColor $bg
}

function Update-Context-Status {
    if ($script:IsScanning) {
        $script:StatusMsg = "Scanning system for installed apps... (Please Wait)"
        return
    }

    if ($script:ViewList.Count -eq 0) {
        $script:StatusMsg = "List is empty."
        return
    }

    $item = $script:ViewList[$script:Cursor]
    $id = $item.Id
    $st = $script:GlobalStates[$id]
    $ver = $script:LocalVersions[$id]
    
    $stText = "Available"
    switch ($st) {
        1 { $stText = "Marked for INSTALL" }
        2 { $stText = "INSTALLED (Managed)" }
        3 { $stText = "Marked for UNINSTALL" }
        4 { $stText = "EXTERNAL (Manual Install)" }
    }
    
    $script:StatusMsg = "Selected: $id | Status: $stText | Local Ver: $ver"
}

function Draw-Main-Menu {
    Clear-Host
    $w = $host.UI.RawUI.WindowSize.Width
    
    Write-Host (" " * $w) -BackgroundColor Blue
    Write-Host "   CHOCOLATEY MANAGER PRO (STABLE)   ".PadRight($w) -BackgroundColor Blue -ForegroundColor White
    Write-Host (" " * $w) -BackgroundColor Blue
    
    Write-Host "`n`n"
    Write-Host "      [1] Load Recommended Apps" -ForegroundColor Yellow
    Write-Host "`n      [2] Search Online" -ForegroundColor Cyan
    Write-Host "`n      [Q] Quit" -ForegroundColor Gray
    
    $y = $host.UI.RawUI.WindowSize.Height - 1
    if ($y -gt 0) {
        $host.UI.RawUI.CursorPosition = @{x=0; y=$y}
        Print-Line " [STATUS] Select an option..." "White" "DarkBlue" $w
    }
}

function Draw-Viewer {
    $host.UI.RawUI.CursorPosition = @{x=0; y=0}
    try {
        $w = $host.UI.RawUI.WindowSize.Width
        $h = $host.UI.RawUI.WindowSize.Height
        
        # Header
        Print-Line " LIST: $($script:ListName)" "White" "DarkCyan" $w
        Print-Line " FOUND: $($script:TotalItems) | PAGE: $($script:CurrentPage+1)/$script:TotalPages " "Black" "DarkGray" $w
        
        # Columns
        $colNameW = [Math]::Max(10, [Math]::Floor($w * 0.45))
        $colVerW = [Math]::Max(10, [Math]::Floor($w * 0.25))
        
        $head = " NAME".PadRight($colNameW) + "VERSION".PadRight($colVerW) + "STATUS"
        Print-Line $head "Gray" "Black" $w
        Print-Line ("-" * $w) "DarkGray" "Black" $w
        
        # Rows
        $rowsAvailable = $h - 7 # Increased buffer for Legend + Status
        $drawCount = [Math]::Min($script:PageSize, $rowsAvailable)
        
        for ($i = 0; $i -lt $drawCount; $i++) {
            if ($i -lt $script:ViewList.Count) {
                $item = $script:ViewList[$i]
                $id = $item.Id
                $state = $script:GlobalStates[$id]
                $ver = $script:LocalVersions[$id]
                if (-not $ver) { $ver = $item.LatestVer }
                if (-not $ver) { $ver = "..." }
                
                $sym = "[_]"; $col = "Gray"; $type = "Avail"
                switch ($state) {
                    0 { $sym="[_]"; $col="Gray"; $type="Avail" }
                    1 { $sym="[*]"; $col="Yellow"; $type="Install" }
                    2 { $sym="[$]"; $col="Green"; $type="Managed" }
                    3 { $sym="[x]"; $col="Red"; $type="Remove" }
                    4 { $sym="[-]"; $col="DarkMagenta"; $type="External" }
                }
                
                $txtId = "$sym $id"; if ($txtId.Length -ge $colNameW) { $txtId = $txtId.Substring(0, $colNameW-1) }
                $txtVer = "$ver"; if ($txtVer.Length -ge $colVerW) { $txtVer = $txtVer.Substring(0, $colVerW-1) }
                
                $line = $txtId.PadRight($colNameW) + $txtVer.PadRight($colVerW) + $type
                
                if ($i -eq $script:Cursor) {
                    Print-Line $line "Black" "White" $w
                } else {
                    Print-Line $line $col "Black" $w
                }
            } else {
                Print-Line " " "Gray" "Black" $w
            }
        }
        
        # Legend (Fixed above Status)
        $legY = $h - 2
        $host.UI.RawUI.CursorPosition = @{x=0; y=$legY}
        Print-Line " [ARROWS] Navigate   [SPACE] Toggle   [ENTER] Apply   [ESC] Menu   [←/→] Page" "Black" "Gray" $w
        
        # Status Bar
        $statY = $h - 1
        $host.UI.RawUI.CursorPosition = @{x=0; y=$statY}
        Print-Line " [STATUS] $script:StatusMsg" "White" "DarkBlue" $w
        
    } catch { }
}

# --- 6. EXECUTION LOOP ---

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

Draw-Main-Menu

while ($true) {
    if ($script:State -eq "VIEWER") {
        Check-Job-Completion
    }

    if ($host.UI.RawUI.KeyAvailable) {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        if ($script:State -eq "MENU") {
            switch ($key.VirtualKeyCode) {
                49 { Load-Data-Set $RecommendedApps "xplod24 Recommended"; Draw-Viewer }
                50 { Perform-Search; if ($script:State -eq "VIEWER") { Draw-Viewer } else { Draw-Main-Menu } }
                81 { Clear-Host; exit }
            }
        }
        elseif ($script:State -eq "VIEWER") {
            $needsRedraw = $false
            switch ($key.VirtualKeyCode) {
                27 { $script:State = "MENU"; Draw-Main-Menu }
                38 { 
                    if ($script:Cursor -gt 0) { 
                        $script:Cursor--; 
                        Update-Context-Status
                        $needsRedraw=$true 
                    } 
                }
                40 { 
                    $rowsVisible = $host.UI.RawUI.WindowSize.Height - 7
                    $limit = [Math]::Min($script:ViewList.Count, $rowsVisible) - 1
                    if ($script:Cursor -lt $limit) { 
                        $script:Cursor++; 
                        Update-Context-Status
                        $needsRedraw=$true 
                    } 
                }
                37 { if ($script:CurrentPage -gt 0) { Load-Page ($script:CurrentPage - 1); Draw-Viewer } }
                39 { if ($script:CurrentPage -lt ($script:TotalPages - 1)) { Load-Page ($script:CurrentPage + 1); Draw-Viewer } }
                32 { # SPACE
                    if ($script:IsScanning) {
                        $script:StatusMsg = "Please wait for scan to complete..."; $needsRedraw=$true
                    } else {
                        $item = $script:ViewList[$script:Cursor]
                        $id = $item.Id
                        $st = $script:GlobalStates[$id]
                        if ($st -eq 0) { $script:GlobalStates[$id] = 1 }
                        elseif ($st -eq 1) { $script:GlobalStates[$id] = 0 }
                        elseif ($st -eq 2) { $script:GlobalStates[$id] = 3 }
                        elseif ($st -eq 3) { $script:GlobalStates[$id] = 2 }
                        Update-Context-Status
                        $needsRedraw=$true
                    }
                }
                13 { # ENTER
                    if ($script:IsScanning) {
                         $script:StatusMsg = "Please wait for scan to complete..."; $needsRedraw=$true
                    } else {
                        $actions = @()
                        $script:GlobalStates.Keys | ForEach-Object {
                            if ($script:GlobalStates[$_] -eq 1) { $actions += @{Id=$_; Type="Install"} }
                            if ($script:GlobalStates[$_] -eq 3) { $actions += @{Id=$_; Type="Uninstall"} }
                        }
                        if ($actions.Count -gt 0) {
                            Clear-Host
                            foreach ($a in $actions) {
                                Write-Host "$($a.Type)ing $($a.Id)..." -ForegroundColor Yellow
                                if ($a.Type -eq "Install") { choco install $a.Id -y } else { choco uninstall $a.Id -y }
                            }
                            Write-Host "Done. Press any key..."
                            $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
                            Start-Scan-Job; Draw-Viewer
                        }
                    }
                }
            }
            if ($needsRedraw) { Draw-Viewer }
        }
    }
    Start-Sleep -Milliseconds 50
}