<#
.SYNOPSIS
    Analyzes Windows crash dumps and WHEA hardware errors.

.DESCRIPTION
    Parses minidump files, shows crash statistics, checks for WHEA RAM/CPU errors,
    identifies crash patterns, and provides color-coded diagnosis.
    Essential for systems experiencing frequent BSODs.

.EXAMPLE
    .\Analyze-Crashes.ps1
    Analyzes all crash dumps and shows detailed statistics

.NOTES
    Author: Network Engineering Portfolio
    Version: 1.0.0
    Requires: Windows Event Log access for WHEA error detection
#>

[CmdletBinding()]
param()

# Color functions
function Write-Header { param($Text) Write-Host "`n$Text" -ForegroundColor Cyan }
function Write-Success { param($Text) Write-Host "  [✓] $Text" -ForegroundColor Green }
function Write-Warning { param($Text) Write-Host "  [!] $Text" -ForegroundColor Yellow }
function Write-Error { param($Text) Write-Host "  [✗] $Text" -ForegroundColor Red }
function Write-Info { param($Text) Write-Host "  [*] $Text" -ForegroundColor White }
function Write-Critical { param($Text) Write-Host "`n  🚨 CRITICAL: $Text" -ForegroundColor Red -BackgroundColor Black }

# Get crash dump files
function Get-CrashDumps {
    $dumpPaths = @(
        "$env:SystemRoot\Minidump",
        "$env:SystemRoot\MEMORY.DMP",
        "$env:SystemRoot\LiveKernelReports"
    )
    
    $dumps = @()
    
    foreach ($path in $dumpPaths) {
        if (Test-Path $path) {
            if ($path -like "*.DMP") {
                # Single file
                if (Test-Path $path) {
                    $dumps += Get-Item $path
                }
            }
            else {
                # Directory
                $dumps += Get-ChildItem -Path $path -Filter "*.dmp" -ErrorAction SilentlyContinue
            }
        }
    }
    
    return $dumps
}

# Analyze WHEA errors
function Get-WHEAErrors {
    param(
        [int]$DaysBack = 30
    )
    
    try {
        $startDate = (Get-Date).AddDays(-$DaysBack)
        
        # Check for WHEA-Logger events (Event ID 46, 47 indicate hardware errors)
        $wheaErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-WHEA-Logger'
            StartTime = $startDate
        } -ErrorAction SilentlyContinue
        
        return $wheaErrors
    }
    catch {
        return @()
    }
}

# Get blue screen events
function Get-BlueScreenEvents {
    param(
        [int]$DaysBack = 30
    )
    
    try {
        $startDate = (Get-Date).AddDays(-$DaysBack)
        
        # Event ID 1001 = Blue Screen
        # Event ID 6008 = Unexpected shutdown
        $bsodEvents = @()
        
        # Bug Check events
        $bsodEvents += Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-WER-SystemErrorReporting'
            ID = 1001
            StartTime = $startDate
        } -ErrorAction SilentlyContinue
        
        # Unexpected shutdown events
        $shutdownEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'EventLog'
            ID = 6008
            StartTime = $startDate
        } -ErrorAction SilentlyContinue
        
        return @{
            BSODs = $bsodEvents
            UnexpectedShutdowns = $shutdownEvents
        }
    }
    catch {
        return @{
            BSODs = @()
            UnexpectedShutdowns = @()
        }
    }
}

# Analyze crash patterns
function Get-CrashPattern {
    param($Events)
    
    if ($Events.Count -eq 0) {
        return $null
    }
    
    # Group by hour of day
    $hourPattern = $Events | Group-Object { $_.TimeCreated.Hour } | 
        Sort-Object Count -Descending | Select-Object -First 1
    
    # Group by day of week
    $dayPattern = $Events | Group-Object { $_.TimeCreated.DayOfWeek } |
        Sort-Object Count -Descending | Select-Object -First 1
    
    # Recent trend
    $last7Days = ($Events | Where-Object { $_.TimeCreated -gt (Get-Date).AddDays(-7) }).Count
    $last24Hours = ($Events | Where-Object { $_.TimeCreated -gt (Get-Date).AddHours(-24) }).Count
    
    return @{
        MostCommonHour = "$($hourPattern.Name):00"
        MostCommonDay = $dayPattern.Name
        Last7Days = $last7Days
        Last24Hours = $last24Hours
    }
}

# Main script
try {
    Write-Header "═══════════════════════════════════════════════════════════"
    Write-Host "  💥 CRASH DUMP & ERROR ANALYZER" -ForegroundColor Red
    Write-Header "═══════════════════════════════════════════════════════════"
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Info "Analysis Time: $timestamp"
    
    # Find crash dumps
    Write-Header "`n📁 Scanning for Crash Dumps"
    $dumps = Get-CrashDumps
    
    if ($dumps.Count -eq 0) {
        Write-Success "No crash dump files found"
        $hasDumps = $false
    }
    else {
        Write-Warning "Found $($dumps.Count) crash dump file(s)"
        $hasDumps = $true
        
        # List recent dumps
        Write-Header "`n📋 Recent Crash Dump Files"
        $recentDumps = $dumps | Sort-Object LastWriteTime -Descending | Select-Object -First 10
        foreach ($dump in $recentDumps) {
            $age = ((Get-Date) - $dump.LastWriteTime).Days
            $ageText = if ($age -eq 0) { "Today" } elseif ($age -eq 1) { "Yesterday" } else { "$age days ago" }
            $sizeKB = [math]::Round($dump.Length / 1KB, 0)
            
            $color = if ($age -le 1) { "Red" } elseif ($age -le 7) { "Yellow" } else { "White" }
            Write-Host "    • $($dump.Name) - $ageText ($sizeKB KB)" -ForegroundColor $color
        }
    }
    
    # Analyze WHEA errors (hardware failures)
    Write-Header "`n🔧 Checking for WHEA Hardware Errors"
    $wheaErrors = Get-WHEAErrors -DaysBack 30
    
    if ($wheaErrors.Count -eq 0) {
        Write-Success "No WHEA hardware errors detected in last 30 days"
    }
    else {
        Write-Critical "Found $($wheaErrors.Count) WHEA hardware error(s) in last 30 days!"
        
        # Analyze error types
        $errorTypes = @{}
        foreach ($error in $wheaErrors) {
            $msg = $error.Message
            if ($msg -like "*memory*" -or $msg -like "*RAM*") {
                $errorTypes["RAM"] = ($errorTypes["RAM"] ?? 0) + 1
            }
            elseif ($msg -like "*processor*" -or $msg -like "*CPU*") {
                $errorTypes["CPU"] = ($errorTypes["CPU"] ?? 0) + 1
            }
            elseif ($msg -like "*bus*" -or $msg -like "*PCI*") {
                $errorTypes["Bus/PCI"] = ($errorTypes["Bus/PCI"] ?? 0) + 1
            }
            else {
                $errorTypes["Other"] = ($errorTypes["Other"] ?? 0) + 1
            }
        }
        
        Write-Host "`n  Error Breakdown:" -ForegroundColor Yellow
        foreach ($type in $errorTypes.Keys | Sort-Object { $errorTypes[$_] } -Descending) {
            $count = $errorTypes[$type]
            $color = if ($type -eq "RAM") { "Red" } else { "Yellow" }
            Write-Host "    • $type: $count error(s)" -ForegroundColor $color
        }
        
        if ($errorTypes.ContainsKey("RAM")) {
            Write-Host "`n  ⚠️  RAM FAILURE DETECTED!" -ForegroundColor Red -BackgroundColor Black
            Write-Host "  This indicates PHYSICAL RAM HARDWARE FAILURE" -ForegroundColor Red
            Write-Host "  Action Required: Run Test-RAM.ps1 to identify bad stick" -ForegroundColor Yellow
        }
    }
    
    # Get blue screen events
    Write-Header "`n💀 Analyzing Blue Screen Crashes"
    $crashes = Get-BlueScreenEvents -DaysBack 30
    $totalCrashes = $crashes.BSODs.Count + $crashes.UnexpectedShutdowns.Count
    
    if ($totalCrashes -eq 0) {
        Write-Success "No blue screen events detected in last 30 days"
    }
    else {
        Write-Warning "Found $totalCrashes crash event(s) in last 30 days"
        Write-Info "  - Blue Screens: $($crashes.BSODs.Count)"
        Write-Info "  - Unexpected Shutdowns: $($crashes.UnexpectedShutdowns.Count)"
        
        # Analyze patterns
        if ($crashes.BSODs.Count -gt 0) {
            Write-Header "`n📊 Crash Statistics"
            
            $allCrashes = @($crashes.BSODs) + @($crashes.UnexpectedShutdowns)
            $pattern = Get-CrashPattern -Events $allCrashes
            
            if ($pattern) {
                Write-Info "Last 24 hours: $($pattern.Last24Hours) crash(es)"
                Write-Info "Last 7 days: $($pattern.Last7Days) crash(es)"
                Write-Info "Most common time: $($pattern.MostCommonHour)"
                Write-Info "Most common day: $($pattern.MostCommonDay)"
                
                # Determine severity
                if ($pattern.Last7Days -ge 5) {
                    Write-Critical "SEVERE: $($pattern.Last7Days) crashes in 7 days indicates critical hardware failure!"
                }
                elseif ($pattern.Last7Days -ge 3) {
                    Write-Warning "HIGH: $($pattern.Last7Days) crashes in 7 days - investigate immediately"
                }
                elseif ($pattern.Last7Days -ge 1) {
                    Write-Warning "MODERATE: $($pattern.Last7Days) crash(es) in 7 days"
                }
            }
        }
    }
    
    # Overall diagnosis
    Write-Header "`n🔍 DIAGNOSIS"
    
    $severity = "NORMAL"
    $issues = @()
    
    if ($wheaErrors.Count -gt 0) {
        $severity = "CRITICAL"
        $issues += "WHEA hardware errors detected ($($wheaErrors.Count) events)"
    }
    
    if ($crashes.BSODs.Count -ge 5) {
        $severity = "CRITICAL"
        $issues += "Frequent blue screens ($($crashes.BSODs.Count) in 30 days)"
    }
    elseif ($crashes.BSODs.Count -ge 3) {
        if ($severity -ne "CRITICAL") { $severity = "HIGH" }
        $issues += "Multiple blue screens ($($crashes.BSODs.Count) in 30 days)"
    }
    
    if ($hasDumps -and $dumps.Count -gt 5) {
        if ($severity -eq "NORMAL") { $severity = "MODERATE" }
        $issues += "Multiple crash dumps found ($($dumps.Count) files)"
    }
    
    # Display diagnosis with color coding
    if ($severity -eq "CRITICAL") {
        Write-Host "`n  ══════════════════════════════════════" -ForegroundColor Red
        Write-Host "  🚨 SEVERITY: CRITICAL" -ForegroundColor Red -BackgroundColor Black
        Write-Host "  ══════════════════════════════════════" -ForegroundColor Red
    }
    elseif ($severity -eq "HIGH") {
        Write-Host "`n  ══════════════════════════════════════" -ForegroundColor Yellow
        Write-Host "  ⚠️  SEVERITY: HIGH" -ForegroundColor Yellow
        Write-Host "  ══════════════════════════════════════" -ForegroundColor Yellow
    }
    elseif ($severity -eq "MODERATE") {
        Write-Host "`n  ══════════════════════════════════════" -ForegroundColor Yellow
        Write-Host "  ⚠️  SEVERITY: MODERATE" -ForegroundColor Yellow
        Write-Host "  ══════════════════════════════════════" -ForegroundColor Yellow
    }
    else {
        Write-Host "`n  ══════════════════════════════════════" -ForegroundColor Green
        Write-Host "  ✓ SEVERITY: NORMAL" -ForegroundColor Green
        Write-Host "  ══════════════════════════════════════" -ForegroundColor Green
    }
    
    if ($issues.Count -gt 0) {
        Write-Host "`n  Issues Found:" -ForegroundColor White
        foreach ($issue in $issues) {
            Write-Host "    • $issue" -ForegroundColor $(if ($severity -eq "CRITICAL") { "Red" } else { "Yellow" })
        }
    }
    else {
        Write-Success "No significant issues detected"
    }
    
    # Recommendations
    Write-Header "`n💡 Recommendations"
    
    if ($severity -eq "CRITICAL" -or $severity -eq "HIGH") {
        if ($wheaErrors.Count -gt 0) {
            Write-Host "  1. Run Test-RAM.ps1 to identify failing RAM stick" -ForegroundColor Yellow
            Write-Host "  2. Test each RAM stick individually" -ForegroundColor Yellow
            Write-Host "  3. Replace the failing RAM stick ASAP" -ForegroundColor Yellow
        }
        if ($crashes.BSODs.Count -gt 0) {
            Write-Host "  4. Use WhoCrashed or BlueScreenView to analyze dump files" -ForegroundColor Yellow
            Write-Host "  5. Update all drivers (especially GPU, chipset, network)" -ForegroundColor Yellow
            Write-Host "  6. Run Windows Memory Diagnostic" -ForegroundColor Yellow
        }
        Write-Host "  7. Run Auto-Fix-Issues.ps1 for system optimization" -ForegroundColor Yellow
        Write-Host "  8. Consider hardware upgrade - run Get-UpgradeRecommendations.ps1" -ForegroundColor Yellow
    }
    elseif ($severity -eq "MODERATE") {
        Write-Host "  1. Monitor system stability" -ForegroundColor White
        Write-Host "  2. Run Quick-Health-Check.ps1 regularly" -ForegroundColor White
        Write-Host "  3. Keep drivers updated" -ForegroundColor White
    }
    else {
        Write-Success "System appears stable"
        Write-Info "  Continue monitoring with Quick-Health-Check.ps1"
    }
    
    Write-Header "═══════════════════════════════════════════════════════════"
    Write-Host "  ✓ Analysis Complete" -ForegroundColor Green
    Write-Header "═══════════════════════════════════════════════════════════`n"
    
    # Return exit code based on severity
    if ($severity -eq "CRITICAL") {
        exit 2
    }
    elseif ($severity -eq "HIGH") {
        exit 1
    }
    else {
        exit 0
    }
}
catch {
    Write-Host "`n" -NoNewline
    Write-Error "Analysis failed: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
