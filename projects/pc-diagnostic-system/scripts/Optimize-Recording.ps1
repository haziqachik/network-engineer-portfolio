<#
.SYNOPSIS
    Recording settings optimizer for OBS/ShadowPlay.

.DESCRIPTION
    Detects GPU capabilities, recommends optimal encoder settings,
    checks if system can handle target FPS and bitrate settings.
    Provides specific OBS/ShadowPlay configurations.

.PARAMETER TargetFPS
    Target recording frame rate (default: 120)

.PARAMETER Bitrate
    Target bitrate in Kbps (default: 15000)

.EXAMPLE
    .\Optimize-Recording.ps1
    Uses default settings (120 FPS, 15000 Kbps)

.EXAMPLE
    .\Optimize-Recording.ps1 -TargetFPS 60 -Bitrate 8000
    Optimizes for 60 FPS at 8 Mbps

.NOTES
    Author: Network Engineering Portfolio
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(30, 240)]
    [int]$TargetFPS = 120,
    
    [Parameter()]
    [ValidateRange(2500, 50000)]
    [int]$Bitrate = 15000
)

# Color functions
function Write-Header { param($Text) Write-Host "`n$Text" -ForegroundColor Cyan }
function Write-Success { param($Text) Write-Host "  [✓] $Text" -ForegroundColor Green }
function Write-Warning { param($Text) Write-Host "  [!] $Text" -ForegroundColor Yellow }
function Write-Error { param($Text) Write-Host "  [✗] $Text" -ForegroundColor Red }
function Write-Info { param($Text) Write-Host "  [*] $Text" -ForegroundColor White }

# Detect GPU
function Get-GPUInfo {
    try {
        $gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike "*Microsoft*" } | Select-Object -First 1
        
        $isNVIDIA = $gpu.Name -like "*NVIDIA*" -or $gpu.Name -like "*GeForce*" -or $gpu.Name -like "*RTX*" -or $gpu.Name -like "*GTX*"
        $isAMD = $gpu.Name -like "*AMD*" -or $gpu.Name -like "*Radeon*"
        $isIntel = $gpu.Name -like "*Intel*"
        
        return @{
            Name = $gpu.Name
            DriverVersion = $gpu.DriverVersion
            DriverDate = $gpu.DriverDate
            VRAM = [math]::Round($gpu.AdapterRAM / 1GB, 2)
            IsNVIDIA = $isNVIDIA
            IsAMD = $isAMD
            IsIntel = $isIntel
        }
    }
    catch {
        return $null
    }
}

# Get system specs
function Get-SystemSpecs {
    try {
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $os = Get-CimInstance Win32_OperatingSystem
        $ram = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        
        return @{
            CPU = $cpu.Name
            CPUCores = $cpu.NumberOfCores
            CPUThreads = $cpu.NumberOfLogicalProcessors
            RAMGB = $ram
        }
    }
    catch {
        return $null
    }
}

# Check storage write speed
function Test-StorageSpeed {
    param($DriveLetter = "C")
    
    try {
        # Simple write test
        $testFile = "$DriveLetter`:\temp_write_test_$(Get-Random).tmp"
        $testSize = 100MB
        $data = New-Object byte[] $testSize
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        [System.IO.File]::WriteAllBytes($testFile, $data)
        $stopwatch.Stop()
        
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        
        $writeMBps = [math]::Round($testSize / $stopwatch.Elapsed.TotalSeconds / 1MB, 0)
        
        return $writeMBps
    }
    catch {
        return 0
    }
}

# Main script
try {
    Write-Header "═══════════════════════════════════════════════════════════"
    Write-Host "  🎥 RECORDING SETTINGS OPTIMIZER" -ForegroundColor Cyan
    Write-Header "═══════════════════════════════════════════════════════════"
    
    Write-Info "Target Settings:"
    Write-Info "  - FPS: $TargetFPS"
    Write-Info "  - Bitrate: $Bitrate Kbps ($([math]::Round($Bitrate/1000, 1)) Mbps)"
    
    # Get system info
    Write-Header "`n🔍 Analyzing System Hardware"
    $gpu = Get-GPUInfo
    $system = Get-SystemSpecs
    
    if (-not $gpu -or -not $system) {
        Write-Error "Failed to detect system hardware"
        exit 1
    }
    
    Write-Info "GPU: $($gpu.Name)"
    Write-Info "CPU: $($system.CPU)"
    Write-Info "RAM: $($system.RAMGB) GB"
    Write-Info "CPU Cores/Threads: $($system.CPUCores)/$($system.CPUThreads)"
    
    # Determine encoder
    Write-Header "`n🎯 Recommended Encoder"
    
    $encoder = $null
    $encoderQuality = $null
    
    if ($gpu.IsNVIDIA) {
        $encoder = "NVENC (NVIDIA)"
        
        # Determine NVENC generation based on GPU name
        if ($gpu.Name -like "*RTX 40*" -or $gpu.Name -like "*RTX 50*") {
            $encoderQuality = "8th Gen (Excellent - AV1 support)"
            $recommended = "av1_nvenc or h264_nvenc"
        }
        elseif ($gpu.Name -like "*RTX 30*") {
            $encoderQuality = "7th Gen (Excellent)"
            $recommended = "h264_nvenc"
        }
        elseif ($gpu.Name -like "*RTX 20*" -or $gpu.Name -like "*GTX 16*") {
            $encoderQuality = "6th Gen (Very Good)"
            $recommended = "h264_nvenc"
        }
        elseif ($gpu.Name -like "*GTX 10*") {
            $encoderQuality = "5th Gen (Good)"
            $recommended = "h264_nvenc"
        }
        else {
            $encoderQuality = "Older generation"
            $recommended = "h264_nvenc"
        }
        
        Write-Success "GPU Encoder: $encoder"
        Write-Info "Quality: $encoderQuality"
        Write-Info "OBS Encoder: $recommended"
    }
    elseif ($gpu.IsAMD) {
        $encoder = "VCE/VCN (AMD)"
        $encoderQuality = "Good"
        $recommended = "h264_amf"
        
        Write-Success "GPU Encoder: $encoder"
        Write-Info "Quality: $encoderQuality"
        Write-Info "OBS Encoder: $recommended"
    }
    else {
        $encoder = "x264 (CPU)"
        $encoderQuality = "Best quality, high CPU usage"
        $recommended = "x264"
        
        Write-Warning "No GPU encoder detected - will use CPU encoding"
        Write-Info "Quality: $encoderQuality"
        Write-Info "OBS Encoder: $recommended"
        Write-Warning "CPU encoding at ${TargetFPS}fps will be very demanding!"
    }
    
    # Check system capabilities
    Write-Header "`n⚡ System Capability Analysis"
    
    $issues = @()
    $warnings = @()
    $canHandle = $true
    
    # RAM check
    $recommendedRAM = if ($TargetFPS -ge 120) { 32 } elseif ($TargetFPS -ge 60) { 16 } else { 8 }
    if ($system.RAMGB -lt $recommendedRAM) {
        $issues += "RAM: $($system.RAMGB)GB (recommended: ${recommendedRAM}GB for ${TargetFPS}fps)"
        $canHandle = $false
    }
    else {
        Write-Success "RAM: $($system.RAMGB)GB (sufficient)"
    }
    
    # CPU check (for encoding overhead)
    if ($encoder -like "*CPU*" -or $encoder -like "*x264*") {
        if ($system.CPUThreads -lt 12) {
            $warnings += "CPU has only $($system.CPUThreads) threads - x264 encoding may struggle"
        }
        else {
            Write-Success "CPU: $($system.CPUThreads) threads (sufficient for CPU encoding)"
        }
    }
    else {
        Write-Success "Using GPU encoder - minimal CPU overhead"
    }
    
    # Storage speed check
    Write-Info "Testing storage write speed..."
    $writeSpeed = Test-StorageSpeed
    
    # Calculate required write speed
    $requiredSpeed = [math]::Round($Bitrate / 8 / 1024, 1) # MB/s
    
    if ($writeSpeed -gt 0) {
        Write-Info "Storage write speed: $writeSpeed MB/s"
        if ($writeSpeed -lt $requiredSpeed * 2) {
            $warnings += "Storage may struggle with $Bitrate Kbps bitrate (detected: ${writeSpeed}MB/s, need: ~${requiredSpeed}MB/s)"
        }
        else {
            Write-Success "Storage speed: Sufficient ($writeSpeed MB/s)"
        }
    }
    else {
        Write-Warning "Could not test storage speed"
    }
    
    # Display issues
    if ($issues.Count -gt 0) {
        Write-Header "`n⚠️  ISSUES DETECTED"
        foreach ($issue in $issues) {
            Write-Error $issue
        }
    }
    
    if ($warnings.Count -gt 0) {
        Write-Header "`n⚠️  WARNINGS"
        foreach ($warning in $warnings) {
            Write-Warning $warning
        }
    }
    
    # Recommendation
    Write-Header "`n✅ SYSTEM CAPABILITY"
    if ($canHandle -and $warnings.Count -eq 0) {
        Write-Success "System CAN handle ${TargetFPS}fps at ${Bitrate}Kbps"
    }
    elseif ($canHandle) {
        Write-Warning "System MIGHT handle ${TargetFPS}fps at ${Bitrate}Kbps, but with warnings"
    }
    else {
        Write-Error "System CANNOT reliably handle ${TargetFPS}fps at ${Bitrate}Kbps"
        Write-Host "`n  Recommendations:" -ForegroundColor Yellow
        Write-Host "    1. Reduce target FPS to 60" -ForegroundColor White
        Write-Host "    2. Reduce bitrate to 8000-10000 Kbps" -ForegroundColor White
        Write-Host "    3. Upgrade RAM to ${recommendedRAM}GB" -ForegroundColor White
        Write-Host "    4. Run Get-UpgradeRecommendations.ps1 for upgrade options" -ForegroundColor White
    }
    
    # Calculate optimal bitrate
    Write-Header "`n📊 Optimal Settings Recommendation"
    
    # Bitrate recommendations based on resolution and FPS
    # Assuming 1080p (adjust if different)
    if ($TargetFPS -ge 120) {
        $optimalBitrate = 15000
        $maxBitrate = 20000
    }
    elseif ($TargetFPS -ge 60) {
        $optimalBitrate = 8000
        $maxBitrate = 12000
    }
    else {
        $optimalBitrate = 5000
        $maxBitrate = 8000
    }
    
    Write-Info "Resolution: 1080p (assumed)"
    Write-Info "Optimal Bitrate: $optimalBitrate Kbps"
    Write-Info "Max Bitrate: $maxBitrate Kbps"
    
    if ($Bitrate -gt $maxBitrate) {
        Write-Warning "Your bitrate ($Bitrate Kbps) is higher than recommended"
    }
    elseif ($Bitrate -lt $optimalBitrate * 0.7) {
        Write-Warning "Your bitrate ($Bitrate Kbps) might be too low for good quality"
    }
    else {
        Write-Success "Your bitrate ($Bitrate Kbps) is in the optimal range"
    }
    
    # OBS Settings
    Write-Header "`n🎛️  OBS STUDIO SETTINGS"
    
    Write-Host "`n  Output Settings:" -ForegroundColor Cyan
    Write-Host "    Output Mode: Advanced" -ForegroundColor White
    Write-Host "    Encoder: $recommended" -ForegroundColor White
    Write-Host "    Rate Control: CBR" -ForegroundColor White
    Write-Host "    Bitrate: $Bitrate Kbps" -ForegroundColor White
    
    if ($gpu.IsNVIDIA) {
        Write-Host "    Preset: Quality (or Max Quality if GPU allows)" -ForegroundColor White
        Write-Host "    Profile: high" -ForegroundColor White
        Write-Host "    Look-ahead: ON" -ForegroundColor White
        Write-Host "    Psycho Visual Tuning: ON" -ForegroundColor White
        Write-Host "    GPU: 0" -ForegroundColor White
        Write-Host "    Max B-frames: 2" -ForegroundColor White
    }
    elseif ($gpu.IsAMD) {
        Write-Host "    Quality Preset: Quality" -ForegroundColor White
        Write-Host "    Profile: high" -ForegroundColor White
        Write-Host "    Keyframe Interval: 2" -ForegroundColor White
    }
    else {
        Write-Host "    CPU Usage Preset: veryfast (adjust based on CPU load)" -ForegroundColor White
        Write-Host "    Profile: high" -ForegroundColor White
    }
    
    Write-Host "`n  Video Settings:" -ForegroundColor Cyan
    Write-Host "    Base Resolution: 1920x1080" -ForegroundColor White
    Write-Host "    Output Resolution: 1920x1080" -ForegroundColor White
    Write-Host "    Downscale Filter: Lanczos" -ForegroundColor White
    Write-Host "    FPS: $TargetFPS" -ForegroundColor White
    
    # ShadowPlay Settings (if NVIDIA)
    if ($gpu.IsNVIDIA) {
        Write-Header "`n🎮 NVIDIA SHADOWPLAY SETTINGS"
        Write-Host "`n  Quality: Custom" -ForegroundColor White
        Write-Host "  Resolution: In-game" -ForegroundColor White
        Write-Host "  Frame rate: $TargetFPS FPS" -ForegroundColor White
        Write-Host "  Bit rate: $Bitrate Kbps" -ForegroundColor White
    }
    
    # Performance tips
    Write-Header "`n💡 Performance Tips"
    Write-Host "  1. Close Chrome and Discord before recording" -ForegroundColor White
    Write-Host "  2. Use Emergency-Cleanup.ps1 before long sessions" -ForegroundColor White
    Write-Host "  3. Record to fast SSD (not same drive as game)" -ForegroundColor White
    Write-Host "  4. Enable Game Mode in Windows" -ForegroundColor White
    Write-Host "  5. Set Windows power plan to High Performance" -ForegroundColor White
    Write-Host "  6. Monitor RAM usage with Monitor-Performance.ps1" -ForegroundColor White
    
    if ($system.RAMGB -lt 32 -and $TargetFPS -ge 120) {
        Write-Host "  7. CRITICAL: Upgrade to 32GB RAM for stable ${TargetFPS}fps recording" -ForegroundColor Red
    }
    
    Write-Header "═══════════════════════════════════════════════════════════"
    Write-Host "  ✓ Optimization Complete" -ForegroundColor Green
    Write-Header "═══════════════════════════════════════════════════════════`n"
}
catch {
    Write-Host "`n" -NoNewline
    Write-Error "Optimization failed: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
