<#
.SYNOPSIS
    Fast system health check (under 30 seconds).

.DESCRIPTION
    Quickly checks for WHEA errors, shows RAM usage, lists crash dumps,
    checks disk space, shows top memory consumers, and displays critical alerts only.

.EXAMPLE
    .\Quick-Health-Check.ps1
    Runs fast health check

.NOTES
    Author: Network Engineering Portfolio
    Version: 1.0.0
    Runtime target: <30 seconds
#>

[CmdletBinding()]
param()

# Color functions
function Write-Header { param($Text) Write-Host "`n$Text" -ForegroundColor Cyan }
function Write-Success { param($Text) Write-Host "  [✓] $Text" -ForegroundColor Green }
function Write-Warning { param($Text) Write-Host "  [!] $Text" -ForegroundColor Yellow }
function Write-Error { param($Text) Write-Host "  [✗] $Text" -ForegroundColor Red }
function Write-Info { param($Text) Write-Host "  [*] $Text" -ForegroundColor White }
function Write-Critical { param($Text) Write-Host "  🚨 $Text" -ForegroundColor Red -BackgroundColor Black }

# Main script
try {
    $startTime = Get-Date
    
    Write-Header "═══════════════════════════════════════════════════════════"
    Write-Host "  ⚡ QUICK HEALTH CHECK" -ForegroundColor Cyan
    Write-Header "═══════════════════════════════════════════════════════════"
    
    $criticalIssues = @()
    $warnings = @()
    
    # 1. RAM Usage (2 seconds)
    Write-Header "`n💾 RAM Status"
    $os = Get-CimInstance Win32_OperatingSystem
    $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRAM = $totalRAM - $freeRAM
    $ramPercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
    
    Write-Info "Total: $totalRAM GB"
    Write-Info "Used: $usedRAM GB ($ramPercent%)"
    Write-Info "Free: $freeRAM GB"
    
    if ($ramPercent -ge 90) {
        $criticalIssues += "RAM critically high at $ramPercent%"
        Write-Critical "RAM at $ramPercent% - CRITICAL!"
    }
    elseif ($ramPercent -ge 80) {
        $warnings += "RAM high at $ramPercent%"
        Write-Warning "RAM at $ramPercent% - Monitor closely"
    }
    else {
        Write-Success "RAM usage OK ($ramPercent%)"
    }
    
    # 2. WHEA Errors (5 seconds)
    Write-Header "`n🔧 Hardware Errors (WHEA)"
    try {
        $wheaErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-WHEA-Logger'
        } -MaxEvents 50 -ErrorAction SilentlyContinue
        
        $recentErrors = $wheaErrors | Where-Object { $_.TimeCreated -gt (Get-Date).AddDays(-7) }
        
        if ($recentErrors.Count -eq 0) {
            Write-Success "No WHEA errors in last 7 days"
        }
        else {
            $criticalIssues += "$($recentErrors.Count) WHEA hardware errors in last 7 days"
            Write-Critical "Found $($recentErrors.Count) WHEA errors in last 7 days!"
            
            # Check for RAM errors
            $ramErrors = $recentErrors | Where-Object { $_.Message -like "*memory*" -or $_.Message -like "*RAM*" }
            if ($ramErrors.Count -gt 0) {
                Write-Error "  → $($ramErrors.Count) are RAM-related - HARDWARE FAILURE!"
            }
        }
    }
    catch {
        Write-Info "Could not check WHEA errors"
    }
    
    # 3. Crash Dumps (3 seconds)
    Write-Header "`n💥 Recent Crashes"
    $dumpPath = "$env:SystemRoot\Minidump"
    
    if (Test-Path $dumpPath) {
        $dumps = Get-ChildItem -Path $dumpPath -Filter "*.dmp" -ErrorAction SilentlyContinue
        $recentDumps = $dumps | Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) }
        
        if ($recentDumps.Count -eq 0) {
            Write-Success "No crash dumps in last 7 days"
        }
        else {
            $warnings += "$($recentDumps.Count) crash dumps in last 7 days"
            Write-Warning "Found $($recentDumps.Count) crash dump(s) in last 7 days"
            
            $latestCrash = ($dumps | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
            if ($latestCrash) {
                $crashAge = ((Get-Date) - $latestCrash.LastWriteTime).TotalHours
                $crashAgeText = if ($crashAge -lt 1) { "less than 1 hour ago" }
                                elseif ($crashAge -lt 24) { "$([math]::Round($crashAge, 0)) hours ago" }
                                else { "$([math]::Round($crashAge / 24, 0)) days ago" }
                Write-Info "  Latest crash: $crashAgeText"
            }
        }
    }
    else {
        Write-Success "No crash dumps folder"
    }
    
    # 4. Disk Space (3 seconds)
    Write-Header "`n💿 Disk Space"
    $drives = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    
    foreach ($drive in $drives) {
        $freePercent = [math]::Round(($drive.FreeSpace / $drive.Size) * 100, 1)
        $freeGB = [math]::Round($drive.FreeSpace / 1GB, 1)
        $totalGB = [math]::Round($drive.Size / 1GB, 1)
        
        if ($freePercent -lt 10) {
            $warnings += "Drive $($drive.DeviceID) low on space ($freePercent% free)"
            Write-Warning "$($drive.DeviceID) $freeGB / $totalGB GB ($freePercent% free) - LOW!"
        }
        elseif ($freePercent -lt 20) {
            Write-Info "$($drive.DeviceID) $freeGB / $totalGB GB ($freePercent% free)"
        }
        else {
            Write-Success "$($drive.DeviceID) $freeGB / $totalGB GB ($freePercent% free)"
        }
    }
    
    # 5. Top Memory Consumers (3 seconds)
    Write-Header "`n📊 Top Memory Consumers"
    $topProcesses = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5
    
    foreach ($proc in $topProcesses) {
        $memGB = [math]::Round($proc.WorkingSet64 / 1GB, 2)
        $color = if ($memGB -gt 2) { "Red" } elseif ($memGB -gt 1) { "Yellow" } else { "White" }
        Write-Host "  • $($proc.ProcessName): $memGB GB" -ForegroundColor $color
        
        if ($memGB -gt 5 -and $proc.ProcessName -eq "chrome") {
            $warnings += "Chrome using excessive memory ($memGB GB)"
        }
    }
    
    # Summary
    $elapsed = ((Get-Date) - $startTime).TotalSeconds
    
    Write-Header "`n═══════════════════════════════════════════════════════════"
    Write-Host "  📋 HEALTH SUMMARY" -ForegroundColor Cyan
    Write-Header "═══════════════════════════════════════════════════════════"
    
    if ($criticalIssues.Count -eq 0 -and $warnings.Count -eq 0) {
        Write-Host "`n  ✅ SYSTEM HEALTHY" -ForegroundColor Green -BackgroundColor Black
        Write-Host "`n  No critical issues or warnings detected.`n" -ForegroundColor Green
    }
    else {
        if ($criticalIssues.Count -gt 0) {
            Write-Host "`n  🚨 CRITICAL ISSUES:" -ForegroundColor Red -BackgroundColor Black
            foreach ($issue in $criticalIssues) {
                Write-Host "    • $issue" -ForegroundColor Red
            }
        }
        
        if ($warnings.Count -gt 0) {
            Write-Host "`n  ⚠️  WARNINGS:" -ForegroundColor Yellow
            foreach ($warning in $warnings) {
                Write-Host "    • $warning" -ForegroundColor Yellow
            }
        }
        
        # Recommendations
        Write-Host "`n  💡 RECOMMENDED ACTIONS:" -ForegroundColor Cyan
        
        if ($criticalIssues -match "WHEA") {
            Write-Host "    1. Run Test-RAM.ps1 to identify failing hardware" -ForegroundColor White
            Write-Host "    2. Run Analyze-Crashes.ps1 for detailed analysis" -ForegroundColor White
        }
        
        if ($criticalIssues -match "RAM" -or $warnings -match "RAM") {
            Write-Host "    3. Run Emergency-Cleanup.ps1 to free RAM" -ForegroundColor White
            Write-Host "    4. Close Chrome and other memory-heavy apps" -ForegroundColor White
        }
        
        if ($warnings -match "crash") {
            Write-Host "    5. Run Analyze-Crashes.ps1 for crash analysis" -ForegroundColor White
        }
        
        if ($warnings -match "disk") {
            Write-Host "    6. Free up disk space or add storage" -ForegroundColor White
        }
        
        Write-Host ""
    }
    
    Write-Info "Check completed in $([math]::Round($elapsed, 1)) seconds"
    
    Write-Header "═══════════════════════════════════════════════════════════"
    Write-Host "  ✓ Quick Health Check Complete" -ForegroundColor Green
    Write-Header "═══════════════════════════════════════════════════════════`n"
    
    Write-Host "For detailed diagnostics, run:" -ForegroundColor Cyan
    Write-Host "  • Analyze-Crashes.ps1 - Full crash analysis" -ForegroundColor White
    Write-Host "  • Test-RAM.ps1 - RAM testing guide" -ForegroundColor White
    Write-Host "  • Monitor-Performance.ps1 - Real-time monitoring`n" -ForegroundColor White
    
    # Exit code based on severity
    if ($criticalIssues.Count -gt 0) {
        exit 2
    }
    elseif ($warnings.Count -gt 0) {
        exit 1
    }
    else {
        exit 0
    }
}
catch {
    Write-Host "`n" -NoNewline
    Write-Error "Health check failed: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
