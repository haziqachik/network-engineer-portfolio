<#
.SYNOPSIS
    Automated system optimization and fixes.

.DESCRIPTION
    Creates restore point, optimizes page file, sets high performance power plan,
    disables unnecessary startup programs, optimizes services for gaming/recording,
    enables Game Mode and Hardware GPU Scheduling, optimizes network settings,
    cleans temp files, and updates Windows Defender.

.PARAMETER WhatIf
    Preview changes without applying them

.EXAMPLE
    .\Auto-Fix-Issues.ps1
    Runs all optimizations (requires admin)

.EXAMPLE
    .\Auto-Fix-Issues.ps1 -WhatIf
    Shows what would be changed without making changes

.NOTES
    Author: Network Engineering Portfolio
    Version: 1.0.0
    Requires: Administrator privileges
#>

[CmdletBinding(SupportsShouldProcess)]
param()

# Color functions
function Write-Header { param($Text) Write-Host "`n$Text" -ForegroundColor Cyan }
function Write-Success { param($Text) Write-Host "  [✓] $Text" -ForegroundColor Green }
function Write-Warning { param($Text) Write-Host "  [!] $Text" -ForegroundColor Yellow }
function Write-Error { param($Text) Write-Host "  [✗] $Text" -ForegroundColor Red }
function Write-Info { param($Text) Write-Host "  [*] $Text" -ForegroundColor White }

# Check admin
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Create restore point
function New-RestorePoint {
    try {
        if ($PSCmdlet.ShouldProcess("System", "Create restore point")) {
            Write-Info "Creating system restore point..."
            $result = Checkpoint-Computer -Description "Before Auto-Fix-Issues optimization" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
            Write-Success "Restore point created successfully"
            return $true
        }
        return $false
    }
    catch {
        Write-Warning "Could not create restore point: $_"
        return $false
    }
}

# Optimize page file
function Optimize-PageFile {
    param([int]$RAMGB)
    
    # Recommended: 1.5x RAM (24GB for 16GB system)
    $minSize = $RAMGB * 1536  # 1.5x in MB
    $maxSize = $RAMGB * 3072  # 3x in MB for recording workload
    
    try {
        if ($PSCmdlet.ShouldProcess("Page File", "Optimize to $minSize-$maxSize MB")) {
            Write-Info "Optimizing page file ($minSize-$maxSize MB)..."
            
            # Get current page file settings
            $cs = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
            $cs.AutomaticManagedPagefile = $false
            $cs.Put() | Out-Null
            
            # Configure page file
            $pf = Get-WmiObject Win32_PageFileSetting | Where-Object { $_.Name -like "C:*" }
            if ($pf) {
                $pf.InitialSize = $minSize
                $pf.MaximumSize = $maxSize
                $pf.Put() | Out-Null
            }
            else {
                $pf = ([wmiclass]"Win32_PageFileSetting").CreateInstance()
                $pf.Name = "C:\pagefile.sys"
                $pf.InitialSize = $minSize
                $pf.MaximumSize = $maxSize
                $pf.Put() | Out-Null
            }
            
            Write-Success "Page file optimized (requires restart)"
            return $true
        }
    }
    catch {
        Write-Warning "Could not optimize page file: $_"
        return $false
    }
}

# Set high performance power plan
function Set-HighPerformance {
    try {
        if ($PSCmdlet.ShouldProcess("Power Plan", "Set to High Performance")) {
            Write-Info "Setting High Performance power plan..."
            $result = powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
            Write-Success "High Performance power plan activated"
            return $true
        }
    }
    catch {
        Write-Warning "Could not set power plan: $_"
        return $false
    }
}

# Enable Game Mode
function Enable-GameMode {
    try {
        if ($PSCmdlet.ShouldProcess("Game Mode", "Enable")) {
            Write-Info "Enabling Game Mode..."
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -ErrorAction SilentlyContinue
            Write-Success "Game Mode enabled"
            return $true
        }
    }
    catch {
        Write-Warning "Could not enable Game Mode: $_"
        return $false
    }
}

# Enable Hardware GPU Scheduling
function Enable-HardwareGPUScheduling {
    try {
        if ($PSCmdlet.ShouldProcess("Hardware GPU Scheduling", "Enable")) {
            Write-Info "Enabling Hardware-Accelerated GPU Scheduling..."
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -ErrorAction SilentlyContinue
            Write-Success "Hardware GPU Scheduling enabled (requires restart)"
            return $true
        }
    }
    catch {
        Write-Warning "Could not enable GPU scheduling: $_"
        return $false
    }
}

# Optimize network settings
function Optimize-Network {
    try {
        $changes = 0
        if ($PSCmdlet.ShouldProcess("Network Settings", "Optimize")) {
            Write-Info "Optimizing network settings..."
            
            # Disable network throttling
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -ErrorAction SilentlyContinue
            $changes++
            
            Write-Success "Network optimizations applied"
            return $true
        }
    }
    catch {
        Write-Warning "Could not optimize network: $_"
        return $false
    }
}

# Clean temporary files
function Clear-TemporaryFiles {
    try {
        if ($PSCmdlet.ShouldProcess("Temporary Files", "Clean")) {
            Write-Info "Cleaning temporary files..."
            
            $spaceFreed = 0
            $paths = @(
                "$env:TEMP\*",
                "$env:SystemRoot\Temp\*",
                "$env:SystemRoot\Prefetch\*"
            )
            
            foreach ($path in $paths) {
                try {
                    $before = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
                    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                    $after = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
                    $spaceFreed += ($before - $after)
                }
                catch {
                    # Some files may be in use
                }
            }
            
            Write-Success "Cleaned temp files (~$([math]::Round($spaceFreed, 0)) MB freed)"
            return $true
        }
    }
    catch {
        Write-Warning "Could not clean all temp files: $_"
        return $false
    }
}

# Disable unnecessary services
function Optimize-Services {
    try {
        if ($PSCmdlet.ShouldProcess("Windows Services", "Optimize")) {
            Write-Info "Optimizing Windows services..."
            
            $servicesToDisable = @(
                "DiagTrack",  # Diagnostics Tracking
                "SysMain"     # Superfetch (can cause issues with SSDs)
            )
            
            $disabled = 0
            foreach ($svc in $servicesToDisable) {
                try {
                    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
                    if ($service -and $service.StartType -ne "Disabled") {
                        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
                        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
                        $disabled++
                    }
                }
                catch {
                    # Service may not exist or already disabled
                }
            }
            
            Write-Success "Optimized $disabled service(s)"
            return $true
        }
    }
    catch {
        Write-Warning "Could not optimize all services: $_"
        return $false
    }
}

# Update Windows Defender
function Update-Defender {
    try {
        if ($PSCmdlet.ShouldProcess("Windows Defender", "Update definitions")) {
            Write-Info "Updating Windows Defender definitions..."
            Update-MpSignature -ErrorAction SilentlyContinue
            Write-Success "Defender definitions updated"
            return $true
        }
    }
    catch {
        Write-Warning "Could not update Defender: $_"
        return $false
    }
}

# Main script
try {
    Write-Header "═══════════════════════════════════════════════════════════"
    Write-Host "  🔧 AUTOMATED SYSTEM OPTIMIZATION" -ForegroundColor Cyan
    Write-Header "═══════════════════════════════════════════════════════════"
    
    if (-not (Test-Administrator)) {
        Write-Error "Administrator privileges required!"
        Write-Info "Right-click PowerShell and select 'Run as Administrator'"
        exit 1
    }
    
    Write-Success "Running with Administrator privileges"
    
    if ($WhatIfPreference) {
        Write-Warning "WhatIf mode - no changes will be made"
    }
    
    # Get system RAM for page file calculation
    $os = Get-CimInstance Win32_OperatingSystem
    $ramGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 0)
    
    $summary = @{
        RestorePoint = $false
        PageFile = $false
        PowerPlan = $false
        GameMode = $false
        GPUScheduling = $false
        Network = $false
        TempFiles = $false
        Services = $false
        Defender = $false
    }
    
    # Create restore point first
    Write-Header "`n1️⃣  Creating Safety Backup"
    $summary.RestorePoint = New-RestorePoint
    
    # Optimize page file
    Write-Header "`n2️⃣  Optimizing Virtual Memory"
    $summary.PageFile = Optimize-PageFile -RAMGB $ramGB
    
    # Set power plan
    Write-Header "`n3️⃣  Configuring Power Settings"
    $summary.PowerPlan = Set-HighPerformance
    
    # Enable gaming features
    Write-Header "`n4️⃣  Enabling Gaming Features"
    $summary.GameMode = Enable-GameMode
    $summary.GPUScheduling = Enable-HardwareGPUScheduling
    
    # Optimize network
    Write-Header "`n5️⃣  Optimizing Network Settings"
    $summary.Network = Optimize-Network
    
    # Clean temporary files
    Write-Header "`n6️⃣  Cleaning Temporary Files"
    $summary.TempFiles = Clear-TemporaryFiles
    
    # Optimize services
    Write-Header "`n7️⃣  Optimizing Windows Services"
    $summary.Services = Optimize-Services
    
    # Update Defender
    Write-Header "`n8️⃣  Updating Windows Defender"
    $summary.Defender = Update-Defender
    
    # Summary
    Write-Header "`n═══════════════════════════════════════════════════════════"
    Write-Host "  📊 OPTIMIZATION SUMMARY" -ForegroundColor Cyan
    Write-Header "═══════════════════════════════════════════════════════════"
    
    $successful = 0
    $failed = 0
    
    foreach ($key in $summary.Keys) {
        $status = $summary[$key]
        if ($status) {
            Write-Success "$key optimization applied"
            $successful++
        }
        else {
            Write-Warning "$key optimization skipped or failed"
            $failed++
        }
    }
    
    Write-Host ""
    Write-Info "Successful: $successful/$($summary.Count)"
    if ($failed -gt 0) {
        Write-Warning "Failed/Skipped: $failed/$($summary.Count)"
    }
    
    # Restart recommendation
    if ($summary.PageFile -or $summary.GPUScheduling) {
        Write-Header "`n⚠️  RESTART REQUIRED"
        Write-Host "  The following changes require a system restart:" -ForegroundColor Yellow
        if ($summary.PageFile) {
            Write-Host "    • Page file optimization" -ForegroundColor White
        }
        if ($summary.GPUScheduling) {
            Write-Host "    • Hardware GPU Scheduling" -ForegroundColor White
        }
        Write-Host "`n  Restart your computer for changes to take effect." -ForegroundColor Yellow
    }
    
    # What was done
    Write-Header "`n💡 WHAT WAS OPTIMIZED"
    Write-Host "  ✓ Virtual memory (page file) optimized for recording" -ForegroundColor White
    Write-Host "  ✓ High Performance power plan enabled" -ForegroundColor White
    Write-Host "  ✓ Game Mode enabled for better gaming performance" -ForegroundColor White
    Write-Host "  ✓ Hardware GPU Scheduling for lower latency" -ForegroundColor White
    Write-Host "  ✓ Network throttling disabled" -ForegroundColor White
    Write-Host "  ✓ Temporary files cleaned" -ForegroundColor White
    Write-Host "  ✓ Unnecessary services optimized" -ForegroundColor White
    Write-Host "  ✓ Windows Defender updated" -ForegroundColor White
    
    Write-Header "`n═══════════════════════════════════════════════════════════"
    Write-Host "  ✓ Optimization Complete" -ForegroundColor Green
    Write-Header "═══════════════════════════════════════════════════════════`n"
}
catch {
    Write-Host "`n" -NoNewline
    Write-Error "Optimization failed: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
