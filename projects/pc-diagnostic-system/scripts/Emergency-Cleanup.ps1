<#
.SYNOPSIS
    Emergency RAM cleanup script before recording/gaming sessions.

.DESCRIPTION
    Aggressively frees RAM by closing Chrome, Discord, Steam, and other memory-heavy processes.
    Clears clipboard and standby memory. Shows before/after RAM usage.
    Critical for systems with failing RAM or high memory pressure.

.PARAMETER Force
    Run in non-interactive mode without confirmation prompts.

.EXAMPLE
    .\Emergency-Cleanup.ps1
    Interactive mode with confirmations

.EXAMPLE
    .\Emergency-Cleanup.ps1 -Force
    Non-interactive mode, closes everything immediately

.NOTES
    Author: Network Engineering Portfolio
    Version: 1.0.0
    Critical for systems with <20% free RAM
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force
)

# Color functions
function Write-Header { param($Text) Write-Host "`n$Text" -ForegroundColor Cyan }
function Write-Success { param($Text) Write-Host "  [✓] $Text" -ForegroundColor Green }
function Write-Warning { param($Text) Write-Host "  [!] $Text" -ForegroundColor Yellow }
function Write-Error { param($Text) Write-Host "  [✗] $Text" -ForegroundColor Red }
function Write-Info { param($Text) Write-Host "  [*] $Text" -ForegroundColor White }

# Get RAM usage
function Get-RAMUsage {
    $os = Get-CimInstance Win32_OperatingSystem
    $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRAM = $totalRAM - $freeRAM
    $usagePercent = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
    
    return @{
        TotalGB = $totalRAM
        UsedGB = $usedRAM
        FreeGB = $freeRAM
        UsagePercent = $usagePercent
    }
}

# Clear standby memory (requires admin)
function Clear-StandbyMemory {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Warning "Standby memory clearing requires Administrator privileges"
        return $false
    }
    
    try {
        # Clear standby list using Windows API
        $source = @"
using System;
using System.Runtime.InteropServices;
public class MemoryManager {
    [DllImport("kernel32.dll")]
    public static extern bool SetProcessWorkingSetSize(IntPtr proc, int min, int max);
    
    public static void ClearMemory() {
        GC.Collect();
        GC.WaitForPendingFinalizers();
        if (Environment.OSVersion.Platform == PlatformID.Win32NT) {
            SetProcessWorkingSetSize(System.Diagnostics.Process.GetCurrentProcess().Handle, -1, -1);
        }
    }
}
"@
        Add-Type -TypeDefinition $source -ErrorAction SilentlyContinue
        [MemoryManager]::ClearMemory()
        
        # Also try EmptyStandbyList if available
        if (Test-Path "$env:SystemRoot\System32\RAMMap.exe") {
            & "$env:SystemRoot\System32\RAMMap.exe" -EmptyStandbyList -ErrorAction SilentlyContinue
        }
        
        return $true
    }
    catch {
        Write-Warning "Could not clear standby memory: $_"
        return $false
    }
}

# Main script
try {
    Write-Header "═══════════════════════════════════════════════════════════"
    Write-Host "  🚨 EMERGENCY RAM CLEANUP" -ForegroundColor Red
    Write-Header "═══════════════════════════════════════════════════════════"
    
    # Get initial RAM state
    Write-Header "📊 Initial RAM Status"
    $beforeRAM = Get-RAMUsage
    Write-Info "Total RAM: $($beforeRAM.TotalGB) GB"
    Write-Info "Used RAM: $($beforeRAM.UsedGB) GB ($($beforeRAM.UsagePercent)%)"
    Write-Info "Free RAM: $($beforeRAM.FreeGB) GB"
    
    if ($beforeRAM.UsagePercent -lt 70) {
        Write-Success "RAM usage is acceptable (<70%). Cleanup may not be necessary."
        if (-not $Force) {
            $continue = Read-Host "`nContinue anyway? (Y/N)"
            if ($continue -ne 'Y') {
                Write-Info "Cleanup cancelled."
                exit 0
            }
        }
    }
    
    # Define memory-heavy processes to close
    $processesToClose = @(
        @{Name="chrome"; Display="Google Chrome"; Critical=$true},
        @{Name="msedge"; Display="Microsoft Edge"; Critical=$false},
        @{Name="discord"; Display="Discord"; Critical=$false},
        @{Name="Steam"; Display="Steam Client"; Critical=$false},
        @{Name="EpicGamesLauncher"; Display="Epic Games Launcher"; Critical=$false},
        @{Name="spotify"; Display="Spotify"; Critical=$false},
        @{Name="slack"; Display="Slack"; Critical=$false},
        @{Name="teams"; Display="Microsoft Teams"; Critical=$false},
        @{Name="OneDrive"; Display="OneDrive"; Critical=$false},
        @{Name="Dropbox"; Display="Dropbox"; Critical=$false}
    )
    
    Write-Header "`n🔍 Scanning for Memory-Heavy Processes"
    
    $foundProcesses = @()
    foreach ($proc in $processesToClose) {
        $running = Get-Process -Name $proc.Name -ErrorAction SilentlyContinue
        if ($running) {
            $totalMem = ($running | Measure-Object WorkingSet64 -Sum).Sum / 1GB
            $foundProcesses += @{
                Name = $proc.Name
                Display = $proc.Display
                Count = $running.Count
                MemoryGB = [math]::Round($totalMem, 2)
                Critical = $proc.Critical
            }
        }
    }
    
    if ($foundProcesses.Count -eq 0) {
        Write-Info "No memory-heavy processes found running."
    }
    else {
        Write-Info "Found $($foundProcesses.Count) applications using memory:"
        foreach ($proc in $foundProcesses | Sort-Object -Property MemoryGB -Descending) {
            $color = if ($proc.MemoryGB -gt 1) { "Red" } elseif ($proc.MemoryGB -gt 0.5) { "Yellow" } else { "White" }
            Write-Host "    • $($proc.Display): $($proc.MemoryGB) GB ($($proc.Count) instance(s))" -ForegroundColor $color
        }
        
        if (-not $Force) {
            Write-Host "`n" -NoNewline
            $response = Read-Host "Close these applications? (Y/N)"
            if ($response -ne 'Y') {
                Write-Info "Process cleanup cancelled."
                $foundProcesses = @()
            }
        }
    }
    
    # Close processes
    if ($foundProcesses.Count -gt 0) {
        Write-Header "`n🛑 Closing Applications"
        
        foreach ($proc in $foundProcesses) {
            try {
                if ($PSCmdlet.ShouldProcess($proc.Display, "Close")) {
                    $processes = Get-Process -Name $proc.Name -ErrorAction SilentlyContinue
                    if ($processes) {
                        $processes | Stop-Process -Force -ErrorAction SilentlyContinue
                        Start-Sleep -Milliseconds 500
                        
                        # Verify closure
                        $stillRunning = Get-Process -Name $proc.Name -ErrorAction SilentlyContinue
                        if (-not $stillRunning) {
                            Write-Success "Closed $($proc.Display) - Freed ~$($proc.MemoryGB) GB"
                        }
                        else {
                            Write-Warning "Some $($proc.Display) processes may still be running"
                        }
                    }
                }
            }
            catch {
                Write-Error "Failed to close $($proc.Display): $_"
            }
        }
    }
    
    # Clear clipboard
    Write-Header "`n🗑️ Clearing Clipboard"
    try {
        if ($PSCmdlet.ShouldProcess("Clipboard", "Clear")) {
            [System.Windows.Forms.Clipboard]::Clear() 2>$null
            # Alternative method
            echo $null | Set-Clipboard -ErrorAction SilentlyContinue
            Write-Success "Clipboard cleared"
        }
    }
    catch {
        Write-Info "Clipboard already empty or inaccessible"
    }
    
    # Clear standby memory
    Write-Header "`n💾 Clearing Standby Memory"
    if ($PSCmdlet.ShouldProcess("Standby Memory", "Clear")) {
        $cleared = Clear-StandbyMemory
        if ($cleared) {
            Write-Success "Standby memory cleared"
        }
        else {
            Write-Warning "Could not clear standby memory (may require admin rights)"
        }
    }
    
    # Force garbage collection
    Write-Info "Running garbage collection..."
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
    
    # Wait for memory to settle
    Start-Sleep -Seconds 2
    
    # Get final RAM state
    Write-Header "`n📊 Final RAM Status"
    $afterRAM = Get-RAMUsage
    $freedGB = [math]::Round($afterRAM.FreeGB - $beforeRAM.FreeGB, 2)
    $freedPercent = [math]::Round($beforeRAM.UsagePercent - $afterRAM.UsagePercent, 1)
    
    Write-Info "Total RAM: $($afterRAM.TotalGB) GB"
    Write-Info "Used RAM: $($afterRAM.UsedGB) GB ($($afterRAM.UsagePercent)%)"
    Write-Info "Free RAM: $($afterRAM.FreeGB) GB"
    
    Write-Header "`n✨ Results"
    if ($freedGB -gt 0) {
        Write-Success "Freed: $freedGB GB ($freedPercent% of total RAM)"
    }
    elseif ($freedGB -lt 0) {
        Write-Warning "RAM usage increased by $([math]::Abs($freedGB)) GB"
    }
    else {
        Write-Info "No significant change in RAM usage"
    }
    
    # Alert if still high
    if ($afterRAM.UsagePercent -gt 80) {
        Write-Header "`n⚠️  CRITICAL WARNING" 
        Write-Error "RAM usage still at $($afterRAM.UsagePercent)%!"
        Write-Host ""
        Write-Host "  Recommendations:" -ForegroundColor Yellow
        Write-Host "    1. Close additional applications manually" -ForegroundColor White
        Write-Host "    2. Restart your computer" -ForegroundColor White
        Write-Host "    3. Run Test-RAM.ps1 to check for failing hardware" -ForegroundColor White
        Write-Host "    4. Consider upgrading from 16GB to 32GB RAM" -ForegroundColor White
        Write-Host ""
    }
    elseif ($afterRAM.UsagePercent -gt 70) {
        Write-Warning "RAM usage at $($afterRAM.UsagePercent)% - Monitor closely during recording/gaming"
    }
    else {
        Write-Success "RAM usage is now at acceptable levels ($($afterRAM.UsagePercent)%)"
    }
    
    Write-Header "═══════════════════════════════════════════════════════════"
    Write-Host "  ✓ Cleanup Complete" -ForegroundColor Green
    Write-Header "═══════════════════════════════════════════════════════════`n"
}
catch {
    Write-Host "`n" -NoNewline
    Write-Error "Emergency cleanup failed: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
