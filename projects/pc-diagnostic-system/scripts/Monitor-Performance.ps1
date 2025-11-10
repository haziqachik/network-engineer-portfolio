<#
.SYNOPSIS
    Real-time performance monitoring with alerts and logging.

.DESCRIPTION
    Tracks CPU/RAM/GPU usage in real-time, alerts when RAM >90%,
    shows temperatures if available, detects bottlenecks,
    and logs data to CSV for analysis.

.PARAMETER Duration
    Monitoring duration in seconds (default: 60)

.PARAMETER LogFile
    Optional CSV file path for logging data

.EXAMPLE
    .\Monitor-Performance.ps1
    Monitors for 60 seconds with live display

.EXAMPLE
    .\Monitor-Performance.ps1 -Duration 300 -LogFile "C:\logs\perf.csv"
    Monitors for 5 minutes and logs to CSV

.NOTES
    Author: Network Engineering Portfolio
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(10, 3600)]
    [int]$Duration = 60,
    
    [Parameter()]
    [string]$LogFile
)

# Color functions
function Write-Header { param($Text) Write-Host "`n$Text" -ForegroundColor Cyan }
function Write-Success { param($Text) Write-Host "  [✓] $Text" -ForegroundColor Green }
function Write-Warning { param($Text) Write-Host "  [!] $Text" -ForegroundColor Yellow }
function Write-Error { param($Text) Write-Host "  [✗] $Text" -ForegroundColor Red }
function Write-Info { param($Text) Write-Host "  [*] $Text" -ForegroundColor White }

# Get current performance metrics
function Get-PerformanceMetrics {
    try {
        # CPU usage
        $cpuUsage = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
        
        # RAM usage
        $os = Get-CimInstance Win32_OperatingSystem
        $totalRAM = $os.TotalVisibleMemorySize / 1MB
        $freeRAM = $os.FreePhysicalMemory / 1MB
        $usedRAM = $totalRAM - $freeRAM
        $ramPercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
        
        # GPU usage (if available)
        $gpuUsage = 0
        try {
            $gpu = Get-Counter '\GPU Engine(*)\Utilization Percentage' -ErrorAction SilentlyContinue
            if ($gpu) {
                $gpuUsage = ($gpu.CounterSamples | Measure-Object -Property CookedValue -Sum).Sum
            }
        }
        catch {
            # GPU counters not available
        }
        
        # Disk usage
        $diskUsage = (Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk | 
            Where-Object { $_.Name -eq "_Total" }).PercentDiskTime
        
        return @{
            Timestamp = Get-Date
            CPUPercent = [math]::Round($cpuUsage, 1)
            RAMPercent = $ramPercent
            RAMUsedGB = [math]::Round($usedRAM, 2)
            RAMTotalGB = [math]::Round($totalRAM, 2)
            GPUPercent = [math]::Round($gpuUsage, 1)
            DiskPercent = [math]::Round($diskUsage, 1)
        }
    }
    catch {
        return $null
    }
}

# Get top processes by memory
function Get-TopMemoryProcesses {
    param([int]$Count = 5)
    
    Get-Process | Sort-Object WorkingSet64 -Descending | 
        Select-Object -First $Count | 
        ForEach-Object {
            @{
                Name = $_.ProcessName
                MemoryMB = [math]::Round($_.WorkingSet64 / 1MB, 0)
            }
        }
}

# Display colored metric
function Write-Metric {
    param(
        [string]$Name,
        [double]$Value,
        [string]$Unit,
        [double]$WarningThreshold,
        [double]$CriticalThreshold
    )
    
    $color = if ($Value -ge $CriticalThreshold) { "Red" }
              elseif ($Value -ge $WarningThreshold) { "Yellow" }
              else { "Green" }
    
    $bar = ""
    $barLength = [math]::Min([math]::Round($Value / 5), 20)
    $bar = "█" * $barLength
    
    Write-Host "  $Name`: " -NoNewline -ForegroundColor White
    Write-Host "$bar " -NoNewline -ForegroundColor $color
    Write-Host "$Value$Unit" -ForegroundColor $color
}

# Main script
try {
    Write-Header "═══════════════════════════════════════════════════════════"
    Write-Host "  📊 REAL-TIME PERFORMANCE MONITOR" -ForegroundColor Cyan
    Write-Header "═══════════════════════════════════════════════════════════"
    
    Write-Info "Duration: $Duration seconds"
    if ($LogFile) {
        Write-Info "Logging to: $LogFile"
        
        # Create log file with headers
        "Timestamp,CPU%,RAM%,RAM_GB,GPU%,Disk%" | Out-File -FilePath $LogFile -Encoding UTF8
    }
    
    Write-Info "Press Ctrl+C to stop monitoring early"
    Write-Header "`nStarting monitoring...`n"
    
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($Duration)
    $iteration = 0
    $alerts = @()
    
    while ((Get-Date) -lt $endTime) {
        $metrics = Get-PerformanceMetrics
        
        if (-not $metrics) {
            Write-Error "Failed to get performance metrics"
            Start-Sleep -Seconds 1
            continue
        }
        
        # Clear previous output and redraw
        if ($iteration -gt 0) {
            $cursorTop = [Console]::CursorTop - 12
            if ($cursorTop -lt 0) { $cursorTop = 0 }
            [Console]::SetCursorPosition(0, $cursorTop)
        }
        
        # Display current time
        $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 0)
        $remaining = $Duration - $elapsed
        Write-Host "  Time: $($metrics.Timestamp.ToString('HH:mm:ss')) | Elapsed: ${elapsed}s | Remaining: ${remaining}s  " -ForegroundColor Cyan
        Write-Host ""
        
        # Display metrics with color coding
        Write-Metric -Name "CPU Usage    " -Value $metrics.CPUPercent -Unit "%" -WarningThreshold 70 -CriticalThreshold 90
        Write-Metric -Name "RAM Usage    " -Value $metrics.RAMPercent -Unit "%" -WarningThreshold 75 -CriticalThreshold 90
        Write-Host "  RAM: $($metrics.RAMUsedGB) / $($metrics.RAMTotalGB) GB" -ForegroundColor Gray
        Write-Metric -Name "GPU Usage    " -Value $metrics.GPUPercent -Unit "%" -WarningThreshold 80 -CriticalThreshold 95
        Write-Metric -Name "Disk Usage   " -Value $metrics.DiskPercent -Unit "%" -WarningThreshold 80 -CriticalThreshold 95
        
        # Check for alerts
        if ($metrics.RAMPercent -ge 90) {
            $alert = "RAM critically high at $($metrics.RAMPercent)%"
            if ($alert -notin $alerts) {
                $alerts += $alert
                Write-Host "`n  🚨 ALERT: $alert" -ForegroundColor Red -BackgroundColor Black
            }
        }
        
        if ($metrics.CPUPercent -ge 95) {
            $alert = "CPU maxed out at $($metrics.CPUPercent)%"
            if ($alert -notin $alerts) {
                $alerts += $alert
                Write-Host "`n  🚨 ALERT: $alert" -ForegroundColor Red -BackgroundColor Black
            }
        }
        
        # Show top memory consumers
        Write-Host "`n  Top Memory Consumers:" -ForegroundColor Cyan
        $topProcs = Get-TopMemoryProcesses -Count 3
        foreach ($proc in $topProcs) {
            $color = if ($proc.MemoryMB -gt 2000) { "Red" } 
                     elseif ($proc.MemoryMB -gt 1000) { "Yellow" } 
                     else { "White" }
            Write-Host "    • $($proc.Name): $($proc.MemoryMB) MB" -ForegroundColor $color
        }
        
        # Log to CSV if specified
        if ($LogFile) {
            "$($metrics.Timestamp.ToString('yyyy-MM-dd HH:mm:ss')),$($metrics.CPUPercent),$($metrics.RAMPercent),$($metrics.RAMUsedGB),$($metrics.GPUPercent),$($metrics.DiskPercent)" | 
                Out-File -FilePath $LogFile -Append -Encoding UTF8
        }
        
        $iteration++
        Start-Sleep -Seconds 2
    }
    
    # Summary
    Write-Host "`n`n"
    Write-Header "═══════════════════════════════════════════════════════════"
    Write-Host "  ✓ Monitoring Complete" -ForegroundColor Green
    Write-Header "═══════════════════════════════════════════════════════════"
    
    if ($alerts.Count -gt 0) {
        Write-Header "`n⚠️  ALERTS DURING MONITORING"
        foreach ($alert in $alerts) {
            Write-Warning $alert
        }
        
        Write-Host "`n  Recommendations:" -ForegroundColor Cyan
        if ($alerts -match "RAM") {
            Write-Host "    • Run Emergency-Cleanup.ps1 to free RAM" -ForegroundColor White
            Write-Host "    • Close unnecessary applications" -ForegroundColor White
            Write-Host "    • Consider RAM upgrade (Get-UpgradeRecommendations.ps1)" -ForegroundColor White
        }
        if ($alerts -match "CPU") {
            Write-Host "    • Check for runaway processes" -ForegroundColor White
            Write-Host "    • Ensure proper cooling/temperatures" -ForegroundColor White
        }
    }
    else {
        Write-Success "No critical alerts during monitoring period"
    }
    
    if ($LogFile) {
        Write-Host "`n" -NoNewline
        Write-Success "Performance data logged to: $LogFile"
        Write-Info "You can analyze this data in Excel or use it for trending"
    }
    
    Write-Host ""
}
catch {
    Write-Host "`n" -NoNewline
    Write-Error "Monitoring failed: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
