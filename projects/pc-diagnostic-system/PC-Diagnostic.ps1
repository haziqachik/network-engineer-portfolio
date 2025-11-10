<#
.SYNOPSIS
    Ultimate PC Diagnostic, Optimization, and Upgrade Recommendation System

.DESCRIPTION
    Comprehensive Windows PC diagnostic tool that:
    - Performs hardware inventory and health checks
    - Detects failing hardware (RAM, drives, overheating)
    - Analyzes system bottlenecks
    - Provides intelligent upgrade recommendations
    - Optimizes system for gaming and recording
    - Generates detailed HTML reports
    
.PARAMETER Mode
    Operation mode: Diagnostic, Optimize, Full (default)

.PARAMETER CreateRestorePoint
    Create system restore point before optimizations (default: true)

.PARAMETER WhatIf
    Show what would be done without making changes

.EXAMPLE
    .\PC-Diagnostic.ps1
    Run full diagnostic and optimization

.EXAMPLE
    .\PC-Diagnostic.ps1 -Mode Diagnostic
    Run diagnostics only, no optimizations

.EXAMPLE
    .\PC-Diagnostic.ps1 -WhatIf
    Preview all changes without applying them
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Diagnostic", "Optimize", "Full")]
    [string]$Mode = "Full",
    
    [Parameter(Mandatory=$false)]
    [bool]$CreateRestorePoint = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory=$false)]
    [switch]$Interactive = $true
)

# Script configuration
$ErrorActionPreference = "Continue"
$ScriptVersion = "1.0.0"
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesPath = Join-Path $ScriptPath "modules"
$ConfigPath = Join-Path $ScriptPath "config\config.json"
$ReportsPath = Join-Path $ScriptPath "reports"

# Color scheme
$Colors = @{
    Title = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "White"
}

# Banner
function Show-Banner {
    Clear-Host
    Write-Host @"
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║        🖥️  PC DIAGNOSTIC & OPTIMIZATION SYSTEM v$ScriptVersion  💻        ║
║                                                                       ║
║  Comprehensive hardware analysis, optimization, and upgrade advice   ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor $Colors.Title
    Write-Host "`nMode: $Mode | WhatIf: $WhatIf | Interactive: $Interactive`n" -ForegroundColor $Colors.Info
}

# Check admin privileges
function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Load configuration
function Get-Configuration {
    try {
        if (Test-Path $ConfigPath) {
            $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            return $config
        } else {
            Write-Host "[!] Configuration file not found: $ConfigPath" -ForegroundColor $Colors.Warning
            return $null
        }
    } catch {
        Write-Host "[!] Error loading configuration: $_" -ForegroundColor $Colors.Error
        return $null
    }
}

# Main execution
try {
    Show-Banner
    
    # Check admin privileges
    $isAdmin = Test-AdminPrivileges
    if (-not $isAdmin) {
        Write-Host "⚠️  WARNING: Not running as Administrator" -ForegroundColor $Colors.Warning
        Write-Host "Some features require elevated privileges (optimizations, driver checks, etc.)" -ForegroundColor $Colors.Warning
        Write-Host ""
        
        if ($Interactive) {
            $response = Read-Host "Continue anyway? (Y/N)"
            if ($response -ne 'Y') {
                Write-Host "`nExiting. Please run as Administrator for full functionality." -ForegroundColor $Colors.Info
                exit
            }
        }
    } else {
        Write-Host "✓ Running with Administrator privileges" -ForegroundColor $Colors.Success
    }
    
    # Load configuration
    Write-Host "`n[*] Loading configuration..." -ForegroundColor $Colors.Info
    $config = Get-Configuration
    
    # Load modules
    Write-Host "[*] Loading diagnostic modules..." -ForegroundColor $Colors.Info
    
    $modulesToLoad = @(
        "DiagnosticModule.ps1",
        "OptimizationModule.ps1",
        "RecommendationModule.ps1",
        "ReportingModule.ps1"
    )
    
    foreach ($module in $modulesToLoad) {
        $modulePath = Join-Path $ModulesPath $module
        if (Test-Path $modulePath) {
            Import-Module $modulePath -Force
            Write-Host "  [✓] Loaded: $module" -ForegroundColor $Colors.Success
        } else {
            Write-Host "  [!] Module not found: $module" -ForegroundColor $Colors.Error
            exit 1
        }
    }
    
    # Initialize data structures
    $diagnosticData = @{
        Inventory = $null
        RAM = $null
        Disk = $null
        Temperature = $null
        Drivers = $null
        Startup = $null
        Processes = $null
        Network = $null
        WindowsUpdate = $null
        Performance = $null
    }
    
    $recommendations = @{
        Bottleneck = $null
        RAM = $null
        GPU = $null
        Storage = $null
        PSU = $null
        Cooling = $null
    }
    
    $optimizationResults = @()
    
    # ==================== DIAGNOSTIC PHASE ====================
    if ($Mode -eq "Diagnostic" -or $Mode -eq "Full") {
        Write-Host "`n" + ("="*75) -ForegroundColor $Colors.Title
        Write-Host "PHASE 1: SYSTEM DIAGNOSTICS" -ForegroundColor $Colors.Title
        Write-Host ("="*75) -ForegroundColor $Colors.Title
        
        # Collect system inventory
        $diagnosticData.Inventory = Get-SystemInventory
        
        # Check RAM health (CRITICAL)
        $diagnosticData.RAM = Get-RAMHealth
        
        # Disk health
        $diagnosticData.Disk = Get-DiskHealth
        
        # Temperature monitoring
        $diagnosticData.Temperature = Get-TemperatureData
        
        # Driver status
        $diagnosticData.Drivers = Get-DriverStatus
        
        # Startup programs
        $diagnosticData.Startup = Get-StartupPrograms
        Write-Host "  [*] Found $($diagnosticData.Startup.Count) startup items" -ForegroundColor $Colors.Info
        
        # Background processes
        $diagnosticData.Processes = Get-BackgroundProcesses
        
        # Network adapters
        $diagnosticData.Network = Get-NetworkAdapters
        
        # Windows Update status
        $diagnosticData.WindowsUpdate = Get-WindowsUpdateStatus
        
        # Performance metrics
        $diagnosticData.Performance = Get-PerformanceMetrics
        Write-Host "  [*] CPU Usage: $([math]::Round($diagnosticData.Performance.CPU_Usage, 1))%" -ForegroundColor $Colors.Info
        Write-Host "  [*] Memory Usage: $([math]::Round($diagnosticData.Performance.Memory_Usage, 1))%" -ForegroundColor $Colors.Info
        
        Write-Host "`n✓ Diagnostic phase complete" -ForegroundColor $Colors.Success
    }
    
    # ==================== ANALYSIS PHASE ====================
    if ($Mode -eq "Diagnostic" -or $Mode -eq "Full") {
        Write-Host "`n" + ("="*75) -ForegroundColor $Colors.Title
        Write-Host "PHASE 2: BOTTLENECK ANALYSIS & RECOMMENDATIONS" -ForegroundColor $Colors.Title
        Write-Host ("="*75) -ForegroundColor $Colors.Title
        
        # Bottleneck analysis
        $recommendations.Bottleneck = Get-BottleneckAnalysis -SystemInfo $diagnosticData.Inventory
        
        # RAM upgrade recommendations
        $recommendations.RAM = Get-RAMUpgradeRecommendation -RAMInfo $diagnosticData.RAM -UseCase "Recording"
        
        # GPU upgrade recommendations
        $recommendations.GPU = Get-GPUUpgradeRecommendation -GPU $diagnosticData.Inventory.GPU -UseCase "Recording" -Budget 800
        
        # Storage recommendations
        $recommendations.Storage = Get-StorageUpgradeRecommendation -DiskInfo $diagnosticData.Disk
        
        # PSU recommendations
        $recommendations.PSU = Get-PSURecommendation -CurrentSystem $diagnosticData.Inventory -PlannedUpgrades $null
        
        # Cooling recommendations
        $recommendations.Cooling = Get-CoolingRecommendation -TempData $diagnosticData.Temperature -CPU $diagnosticData.Inventory.CPU
        
        # Display critical findings
        Write-Host "`n🔍 CRITICAL FINDINGS:" -ForegroundColor $Colors.Warning
        if ($diagnosticData.RAM.WHEAErrors.Count -gt 0) {
            Write-Host "  ⚠️  FAILING RAM DETECTED - $($diagnosticData.RAM.WHEAErrors.Count) WHEA errors" -ForegroundColor $Colors.Error
            Write-Host "      ACTION REQUIRED: Replace RAM immediately!" -ForegroundColor $Colors.Error
        }
        
        $oldMediaTek = $diagnosticData.Network | Where-Object {$_.CriticalWarning}
        if ($oldMediaTek) {
            Write-Host "  ⚠️  OUTDATED DRIVER: MediaTek WiFi driver from 2015" -ForegroundColor $Colors.Warning
            Write-Host "      ACTION: Update network driver" -ForegroundColor $Colors.Warning
        }
        
        if ($recommendations.Bottleneck.Bottlenecks.Count -gt 0) {
            Write-Host "`n  Performance Bottlenecks Detected:" -ForegroundColor $Colors.Warning
            foreach ($bottleneck in $recommendations.Bottleneck.Bottlenecks) {
                $color = switch ($bottleneck.Severity) {
                    "CRITICAL" { $Colors.Error }
                    "HIGH" { $Colors.Warning }
                    default { $Colors.Info }
                }
                Write-Host "    - $($bottleneck.Component): $($bottleneck.Issue)" -ForegroundColor $color
            }
        }
        
        Write-Host "`n✓ Analysis phase complete" -ForegroundColor $Colors.Success
    }
    
    # ==================== OPTIMIZATION PHASE ====================
    if ($Mode -eq "Optimize" -or $Mode -eq "Full") {
        Write-Host "`n" + ("="*75) -ForegroundColor $Colors.Title
        Write-Host "PHASE 3: SYSTEM OPTIMIZATION" -ForegroundColor $Colors.Title
        Write-Host ("="*75) -ForegroundColor $Colors.Title
        
        if ($Interactive -and -not $WhatIf) {
            Write-Host "`nThe following optimizations will be performed:" -ForegroundColor $Colors.Info
            Write-Host "  • Clean temporary files" -ForegroundColor $Colors.Info
            Write-Host "  • Optimize startup programs" -ForegroundColor $Colors.Info
            Write-Host "  • Configure Windows services for gaming/recording" -ForegroundColor $Colors.Info
            Write-Host "  • Optimize page file (virtual memory)" -ForegroundColor $Colors.Info
            Write-Host "  • Set high performance power plan" -ForegroundColor $Colors.Info
            Write-Host "  • Optimize visual effects" -ForegroundColor $Colors.Info
            Write-Host "  • Enable Game Mode" -ForegroundColor $Colors.Info
            Write-Host "  • Optimize network settings" -ForegroundColor $Colors.Info
            Write-Host "  • Optimize disk performance" -ForegroundColor $Colors.Info
            Write-Host ""
            
            $response = Read-Host "Proceed with optimizations? (Y/N)"
            if ($response -ne 'Y') {
                Write-Host "`nSkipping optimization phase." -ForegroundColor $Colors.Warning
                $Mode = "Diagnostic"
            }
        }
        
        if ($Mode -eq "Optimize" -or $Mode -eq "Full") {
            # Create restore point if requested
            if ($CreateRestorePoint -and -not $WhatIf -and $isAdmin) {
                $restored = New-RestorePoint -Description "PC Diagnostic Tool - Before Optimizations"
                if ($restored) {
                    $optimizationResults += "System restore point created"
                }
            }
            
            # Perform optimizations
            try {
                # Clean temp files
                $freed = Optimize-TempFiles -WhatIf:$WhatIf
                $optimizationResults += "Cleaned temporary files - Freed $([math]::Round($freed / 1GB, 2)) GB"
                
                # Optimize startup
                if ($isAdmin) {
                    $disabled = Optimize-StartupPrograms -WhatIf:$WhatIf
                    if ($disabled.Count -gt 0) {
                        $optimizationResults += "Disabled $($disabled.Count) unnecessary startup items"
                    }
                }
                
                # Optimize Windows services
                if ($isAdmin) {
                    $services = Optimize-WindowsServices -Profile "Recording" -WhatIf:$WhatIf
                    if ($services.Count -gt 0) {
                        $optimizationResults += "Optimized $($services.Count) Windows services for recording"
                    }
                }
                
                # Optimize page file
                if ($isAdmin) {
                    $pageFileOptimized = Optimize-PageFile -MinSize_MB 16384 -MaxSize_MB 32768 -WhatIf:$WhatIf
                    if ($pageFileOptimized) {
                        $optimizationResults += "Page file optimized (16GB-32GB) for recording workloads"
                    }
                }
                
                # Set power plan
                if ($isAdmin) {
                    $powerPlanSet = Optimize-PowerPlan -WhatIf:$WhatIf
                    if ($powerPlanSet) {
                        $optimizationResults += "High Performance power plan activated"
                    }
                }
                
                # Optimize visual effects
                $visualOptimized = Optimize-VisualEffects -WhatIf:$WhatIf
                if ($visualOptimized) {
                    $optimizationResults += "Visual effects optimized for performance"
                }
                
                # Enable Game Mode
                $gameModeEnabled = Enable-GameMode -WhatIf:$WhatIf
                if ($gameModeEnabled) {
                    $optimizationResults += "Windows Game Mode and GPU scheduling enabled"
                }
                
                # Optimize network
                if ($isAdmin) {
                    $networkOptimized = Optimize-NetworkSettings -WhatIf:$WhatIf
                    if ($networkOptimized) {
                        $optimizationResults += "Network settings optimized (DNS, throttling disabled)"
                    }
                }
                
                # Optimize disk
                if ($isAdmin) {
                    $diskResults = Optimize-DiskPerformance -WhatIf:$WhatIf
                    if ($diskResults.Count -gt 0) {
                        $optimizationResults += "Disk optimization scheduled for $($diskResults.Count) drives"
                    }
                }
                
                Write-Host "`n✓ Optimization phase complete - $($optimizationResults.Count) optimizations applied" -ForegroundColor $Colors.Success
                
            } catch {
                Write-Host "`n[!] Error during optimization: $_" -ForegroundColor $Colors.Error
            }
        }
    }
    
    # ==================== REPORTING PHASE ====================
    Write-Host "`n" + ("="*75) -ForegroundColor $Colors.Title
    Write-Host "PHASE 4: GENERATING REPORTS" -ForegroundColor $Colors.Title
    Write-Host ("="*75) -ForegroundColor $Colors.Title
    
    # Ensure reports directory exists
    if (-not (Test-Path $ReportsPath)) {
        New-Item -ItemType Directory -Path $ReportsPath -Force | Out-Null
    }
    
    # Generate HTML report
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $htmlReportPath = Join-Path $ReportsPath "PC-Diagnostic-Report_$timestamp.html"
    $htmlReport = New-HTMLReport -DiagnosticData $diagnosticData -Recommendations $recommendations -OptimizationResults $optimizationResults -OutputPath $htmlReportPath
    
    # Generate JSON report
    $jsonReportPath = Join-Path $ReportsPath "PC-Diagnostic-Report_$timestamp.json"
    $jsonReport = Export-JSONReport -DiagnosticData $diagnosticData -Recommendations $recommendations -OutputPath $jsonReportPath
    
    # ==================== SUMMARY ====================
    Write-Host "`n" + ("="*75) -ForegroundColor $Colors.Title
    Write-Host "SUMMARY" -ForegroundColor $Colors.Title
    Write-Host ("="*75) -ForegroundColor $Colors.Title
    
    Write-Host "`n📊 Performance Scores:" -ForegroundColor $Colors.Info
    if ($recommendations.Bottleneck) {
        Write-Host "  • Gaming: $([math]::Round($recommendations.Bottleneck.PerformanceScore.Gaming))/100" -ForegroundColor $Colors.Success
        Write-Host "  • Recording: $([math]::Round($recommendations.Bottleneck.PerformanceScore.Recording))/100" -ForegroundColor $Colors.Success
        Write-Host "  • Multitasking: $([math]::Round($recommendations.Bottleneck.PerformanceScore.Multitasking))/100" -ForegroundColor $Colors.Success
    }
    
    Write-Host "`n📁 Reports Generated:" -ForegroundColor $Colors.Info
    Write-Host "  • HTML Report: $htmlReportPath" -ForegroundColor $Colors.Success
    Write-Host "  • JSON Report: $jsonReportPath" -ForegroundColor $Colors.Success
    
    Write-Host "`n🎯 Top Priority Actions:" -ForegroundColor $Colors.Info
    if ($diagnosticData.RAM.WHEAErrors.Count -gt 0) {
        Write-Host "  1. CRITICAL: Replace failing RAM immediately" -ForegroundColor $Colors.Error
    }
    if ($recommendations.RAM.Priority -eq "CRITICAL" -or $recommendations.RAM.Priority -eq "HIGH") {
        Write-Host "  2. Upgrade RAM to $($recommendations.RAM.RecommendedRAM_GB)GB for smooth recording" -ForegroundColor $Colors.Warning
    }
    $oldDriver = $diagnosticData.Network | Where-Object {$_.CriticalWarning}
    if ($oldDriver) {
        Write-Host "  3. Update MediaTek WiFi driver" -ForegroundColor $Colors.Warning
    }
    
    Write-Host "`n✅ Analysis complete! Open the HTML report for detailed recommendations." -ForegroundColor $Colors.Success
    
    # Open report in browser if interactive
    if ($Interactive) {
        Write-Host ""
        $response = Read-Host "Open HTML report in browser? (Y/N)"
        if ($response -eq 'Y') {
            Start-Process $htmlReportPath
        }
    }
    
} catch {
    Write-Host "`n[ERROR] Script execution failed: $_" -ForegroundColor $Colors.Error
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor $Colors.Error
    exit 1
}

Write-Host "`n" -NoNewline
