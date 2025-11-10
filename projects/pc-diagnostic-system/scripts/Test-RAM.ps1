<#
.SYNOPSIS
    Interactive RAM testing guide and diagnostic tool.

.DESCRIPTION
    Detects installed RAM sticks, guides user through testing each stick individually,
    schedules Windows Memory Diagnostic, checks for WHEA errors,
    and recommends which stick to remove/replace.

.EXAMPLE
    .\Test-RAM.ps1
    Launches interactive RAM testing guide

.NOTES
    Author: Network Engineering Portfolio
    Version: 1.0.0
    Requires: Administrator privileges for memory diagnostic scheduling
#>

[CmdletBinding()]
param()

# Color functions
function Write-Header { param($Text) Write-Host "`n$Text" -ForegroundColor Cyan }
function Write-Success { param($Text) Write-Host "  [✓] $Text" -ForegroundColor Green }
function Write-Warning { param($Text) Write-Host "  [!] $Text" -ForegroundColor Yellow }
function Write-Error { param($Text) Write-Host "  [✗] $Text" -ForegroundColor Red }
function Write-Info { param($Text) Write-Host "  [*] $Text" -ForegroundColor White }
function Write-Critical { param($Text) Write-Host "`n  🚨 $Text" -ForegroundColor Red -BackgroundColor Black }

# Check admin privileges
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Get RAM information
function Get-RAMInfo {
    try {
        $ram = Get-CimInstance Win32_PhysicalMemory
        $slots = @()
        
        foreach ($stick in $ram) {
            $slots += @{
                DeviceLocator = $stick.DeviceLocator
                Capacity = [math]::Round($stick.Capacity / 1GB, 0)
                Speed = $stick.Speed
                Manufacturer = $stick.Manufacturer
                PartNumber = $stick.PartNumber.Trim()
                SerialNumber = $stick.SerialNumber
            }
        }
        
        return $slots
    }
    catch {
        return $null
    }
}

# Get WHEA RAM errors
function Get-WHEARAMErrors {
    try {
        $wheaErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-WHEA-Logger'
        } -MaxEvents 100 -ErrorAction SilentlyContinue | Where-Object {
            $_.Message -like "*memory*" -or $_.Message -like "*RAM*"
        }
        
        return $wheaErrors
    }
    catch {
        return @()
    }
}

# Schedule Windows Memory Diagnostic
function Start-MemoryDiagnostic {
    try {
        # Create scheduled task to run memory diagnostic on next boot
        $result = & mdsched.exe
        return $true
    }
    catch {
        return $false
    }
}

# Main script
try {
    Write-Header "═══════════════════════════════════════════════════════════"
    Write-Host "  🔬 RAM TESTING & DIAGNOSTIC GUIDE" -ForegroundColor Red
    Write-Header "═══════════════════════════════════════════════════════════"
    
    $isAdmin = Test-Administrator
    if (-not $isAdmin) {
        Write-Warning "Not running as Administrator"
        Write-Info "Some features require admin privileges (memory diagnostic scheduling)"
        Write-Info "Right-click PowerShell and select 'Run as Administrator' for full functionality"
    }
    else {
        Write-Success "Running with Administrator privileges"
    }
    
    # Detect RAM configuration
    Write-Header "`n💾 Detecting RAM Configuration"
    $ramSlots = Get-RAMInfo
    
    if (-not $ramSlots -or $ramSlots.Count -eq 0) {
        Write-Error "Failed to detect RAM configuration"
        exit 1
    }
    
    $totalRAM = ($ramSlots | Measure-Object -Property Capacity -Sum).Sum
    Write-Info "Total RAM: $totalRAM GB"
    Write-Info "RAM Sticks: $($ramSlots.Count)"
    
    Write-Host "`n  Detected Configuration:" -ForegroundColor Cyan
    $slotNum = 1
    foreach ($slot in $ramSlots) {
        Write-Host "`n  Stick #$slotNum ($($slot.DeviceLocator)):" -ForegroundColor Yellow
        Write-Host "    Capacity: $($slot.Capacity) GB" -ForegroundColor White
        Write-Host "    Speed: $($slot.Speed) MHz" -ForegroundColor White
        Write-Host "    Manufacturer: $($slot.Manufacturer)" -ForegroundColor White
        Write-Host "    Part Number: $($slot.PartNumber)" -ForegroundColor White
        $slotNum++
    }
    
    # Check for WHEA errors
    Write-Header "`n🔍 Checking for WHEA RAM Errors"
    $ramErrors = Get-WHEARAMErrors
    
    if ($ramErrors.Count -eq 0) {
        Write-Success "No WHEA RAM errors detected in recent logs"
        Write-Info "However, if you're experiencing crashes, testing is still recommended"
    }
    else {
        Write-Critical "Found $($ramErrors.Count) WHEA RAM error(s)!"
        Write-Host "`n  This indicates PHYSICAL RAM FAILURE!" -ForegroundColor Red
        Write-Host "  Recent errors:" -ForegroundColor Yellow
        
        $recentErrors = $ramErrors | Select-Object -First 5
        foreach ($err in $recentErrors) {
            $age = ((Get-Date) - $err.TimeCreated).TotalHours
            $ageText = if ($age -lt 1) { "< 1 hour ago" } elseif ($age -lt 24) { "$([math]::Round($age, 0)) hours ago" } else { "$([math]::Round($age/24, 0)) days ago" }
            Write-Host "    • $ageText - Event ID: $($err.Id)" -ForegroundColor Red
        }
    }
    
    # Testing guide
    Write-Header "`n📋 RAM TESTING PROCEDURE"
    
    Write-Host "`n  This guide will help you identify the failing RAM stick." -ForegroundColor Cyan
    Write-Host "  You have $($ramSlots.Count) RAM stick(s) installed.`n" -ForegroundColor Cyan
    
    Write-Host "  IMPORTANT: Testing each stick individually is the MOST RELIABLE method." -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "  Step-by-Step Testing Process:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Phase 1: Initial Full System Test" -ForegroundColor Yellow
    Write-Host "    1. Keep all RAM sticks installed" -ForegroundColor White
    Write-Host "    2. Run Windows Memory Diagnostic (we can schedule this)" -ForegroundColor White
    Write-Host "    3. Restart and let it run (takes 15-30 minutes)" -ForegroundColor White
    Write-Host "    4. Check results after restart" -ForegroundColor White
    Write-Host ""
    
    Write-Host "  Phase 2: Individual Stick Testing (if errors found)" -ForegroundColor Yellow
    Write-Host "    For each RAM stick:" -ForegroundColor White
    Write-Host "      1. POWER OFF computer completely" -ForegroundColor Red
    Write-Host "      2. Remove ALL RAM sticks except ONE" -ForegroundColor Red
    Write-Host "      3. Boot with only that stick installed" -ForegroundColor White
    Write-Host "      4. Run memory diagnostic again" -ForegroundColor White
    Write-Host "      5. Use computer normally for 1-2 hours" -ForegroundColor White
    Write-Host "      6. Note if crashes occur" -ForegroundColor White
    Write-Host "      7. Repeat for next stick" -ForegroundColor White
    Write-Host ""
    
    Write-Host "  Your RAM Configuration:" -ForegroundColor Cyan
    $slotNum = 1
    foreach ($slot in $ramSlots) {
        Write-Host "    Stick #$slotNum: $($slot.DeviceLocator) - $($slot.Capacity)GB @ $($slot.Speed)MHz" -ForegroundColor White
        $slotNum++
    }
    Write-Host ""
    
    # Schedule Windows Memory Diagnostic
    Write-Host "`n  Would you like to schedule Windows Memory Diagnostic now?" -ForegroundColor Cyan
    Write-Host "  This will run on next reboot and test all installed RAM." -ForegroundColor White
    Write-Host ""
    
    $response = Read-Host "  Schedule Memory Diagnostic? (Y/N)"
    
    if ($response -eq 'Y' -or $response -eq 'y') {
        if ($isAdmin) {
            Write-Info "Launching Windows Memory Diagnostic..."
            Write-Host ""
            Write-Host "  The Memory Diagnostic tool will open." -ForegroundColor Yellow
            Write-Host "  Choose 'Restart now and check for problems'" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  After restart:" -ForegroundColor Cyan
            Write-Host "    • The test will run automatically (15-30 min)" -ForegroundColor White
            Write-Host "    • You'll see a blue screen with progress" -ForegroundColor White
            Write-Host "    • PC will restart when complete" -ForegroundColor White
            Write-Host "    • Check results in Event Viewer or notification" -ForegroundColor White
            Write-Host ""
            
            Start-Sleep -Seconds 2
            
            $scheduled = Start-MemoryDiagnostic
            if ($scheduled) {
                Write-Success "Memory Diagnostic tool launched"
            }
            else {
                Write-Error "Failed to launch Memory Diagnostic"
            }
        }
        else {
            Write-Error "Administrator privileges required to schedule Memory Diagnostic"
            Write-Info "Run this script as Administrator, or manually run: mdsched.exe"
        }
    }
    else {
        Write-Info "Memory Diagnostic not scheduled"
        Write-Info "You can run it manually anytime: mdsched.exe"
    }
    
    # Results interpretation guide
    Write-Header "`n📊 INTERPRETING RESULTS"
    
    Write-Host "`n  If Windows Memory Diagnostic finds errors:" -ForegroundColor Yellow
    Write-Host "    ➜ RAM is DEFINITELY failing - replace immediately" -ForegroundColor Red
    Write-Host ""
    Write-Host "  If NO errors found, but still having crashes:" -ForegroundColor Yellow
    Write-Host "    ➜ Test each stick individually (Phase 2 above)" -ForegroundColor Yellow
    Write-Host "    ➜ Run stress test: MemTest86 (bootable USB)" -ForegroundColor Yellow
    Write-Host "    ➜ Check for overheating or power issues" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  If one stick causes crashes in individual testing:" -ForegroundColor Yellow
    Write-Host "    ➜ That stick is bad - remove and replace it" -ForegroundColor Red
    Write-Host "    ➜ Can use PC temporarily with remaining stick(s)" -ForegroundColor Yellow
    Write-Host ""
    
    # Recommendations based on current config
    Write-Header "`n💡 RECOMMENDATIONS"
    
    if ($ramErrors.Count -gt 0) {
        Write-Host "`n  ⚠️  URGENT ACTIONS:" -ForegroundColor Red
        Write-Host "    1. Backup important data NOW" -ForegroundColor White
        Write-Host "    2. Run memory diagnostic immediately" -ForegroundColor White
        Write-Host "    3. Test each stick individually" -ForegroundColor White
        Write-Host "    4. Order replacement RAM (run Get-UpgradeRecommendations.ps1)" -ForegroundColor White
        Write-Host ""
        Write-Host "  ⚠️  TEMPORARY WORKAROUND:" -ForegroundColor Yellow
        Write-Host "    • Run Emergency-Cleanup.ps1 before gaming/recording" -ForegroundColor White
        Write-Host "    • Close all non-essential apps" -ForegroundColor White
        Write-Host "    • Avoid Chrome (uses 5+ GB RAM)" -ForegroundColor White
        Write-Host "    • Monitor with Monitor-Performance.ps1" -ForegroundColor White
    }
    else {
        Write-Host "`n  Preventive Testing:" -ForegroundColor Cyan
        Write-Host "    1. Run memory diagnostic as preventive measure" -ForegroundColor White
        Write-Host "    2. Monitor system stability" -ForegroundColor White
        Write-Host "    3. Run Quick-Health-Check.ps1 weekly" -ForegroundColor White
    }
    
    # Current RAM status
    $os = Get-CimInstance Win32_OperatingSystem
    $usagePercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
    
    Write-Header "`n📈 Current RAM Usage"
    Write-Info "Usage: $usagePercent%"
    
    if ($usagePercent -gt 85) {
        Write-Error "RAM critically high! Run Emergency-Cleanup.ps1 immediately"
    }
    elseif ($usagePercent -gt 75) {
        Write-Warning "RAM usage high - cleanup recommended"
    }
    else {
        Write-Success "RAM usage acceptable"
    }
    
    # Replacement guide
    if ($ramSlots.Count -eq 2) {
        Write-Header "`n🔄 Replacement Guide (2-stick configuration)"
        Write-Host ""
        Write-Host "  Current: 2x $($ramSlots[0].Capacity)GB @ $($ramSlots[0].Speed)MHz" -ForegroundColor White
        Write-Host ""
        Write-Host "  Option 1: Replace one bad stick" -ForegroundColor Cyan
        Write-Host "    • Buy matching stick: $($ramSlots[0].Capacity)GB DDR4 $($ramSlots[0].Speed)MHz" -ForegroundColor White
        Write-Host "    • Same brand preferred: $($ramSlots[0].Manufacturer)" -ForegroundColor White
        Write-Host "    • Cost: ~`$25-40" -ForegroundColor White
        Write-Host ""
        Write-Host "  Option 2: Upgrade to 32GB (RECOMMENDED)" -ForegroundColor Cyan
        Write-Host "    • Buy: 2x 16GB DDR4 3200MHz" -ForegroundColor White
        Write-Host "    • Fixes RAM issue AND improves performance" -ForegroundColor White
        Write-Host "    • Better for 120fps recording" -ForegroundColor White
        Write-Host "    • Cost: ~`$80-120" -ForegroundColor White
        Write-Host "    • Run Get-UpgradeRecommendations.ps1 for specific models" -ForegroundColor Yellow
    }
    
    Write-Header "═══════════════════════════════════════════════════════════"
    Write-Host "  ✓ RAM Testing Guide Complete" -ForegroundColor Green
    Write-Header "═══════════════════════════════════════════════════════════`n"
    
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Restart and run Memory Diagnostic (if scheduled)" -ForegroundColor White
    Write-Host "  2. Check Event Viewer for results" -ForegroundColor White
    Write-Host "  3. Test sticks individually if errors found" -ForegroundColor White
    Write-Host "  4. Run Get-UpgradeRecommendations.ps1 for replacement options`n" -ForegroundColor White
}
catch {
    Write-Host "`n" -NoNewline
    Write-Error "RAM testing guide failed: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
