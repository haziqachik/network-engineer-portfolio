<#
.SYNOPSIS
    Hardware upgrade advisor and recommendation engine.

.DESCRIPTION
    Analyzes current hardware, detects bottlenecks, recommends compatible upgrades
    with pricing, and prioritizes based on use case and budget.

.PARAMETER Budget
    Available budget in USD (default: 500)

.PARAMETER UseCase
    Primary use case: Gaming, Recording, or Both (default: Both)

.EXAMPLE
    .\Get-UpgradeRecommendations.ps1
    Uses defaults (Budget: $500, UseCase: Both)

.EXAMPLE
    .\Get-UpgradeRecommendations.ps1 -Budget 200 -UseCase Recording
    $200 budget focused on recording performance

.NOTES
    Author: Network Engineering Portfolio
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(50, 5000)]
    [int]$Budget = 500,
    
    [Parameter()]
    [ValidateSet("Gaming", "Recording", "Both")]
    [string]$UseCase = "Both"
)

# Color functions
function Write-Header { param($Text) Write-Host "`n$Text" -ForegroundColor Cyan }
function Write-Success { param($Text) Write-Host "  [✓] $Text" -ForegroundColor Green }
function Write-Warning { param($Text) Write-Host "  [!] $Text" -ForegroundColor Yellow }
function Write-Error { param($Text) Write-Host "  [✗] $Text" -ForegroundColor Red }
function Write-Info { param($Text) Write-Host "  [*] $Text" -ForegroundColor White }
function Write-Priority {
    param($Level, $Text)
    $color = switch($Level) {
        "CRITICAL" { "Red" }
        "HIGH" { "Yellow" }
        "MEDIUM" { "Cyan" }
        "LOW" { "White" }
    }
    Write-Host "  [$Level] $Text" -ForegroundColor $color
}

# Get system information
function Get-SystemInfo {
    try {
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike "*Microsoft*" } | Select-Object -First 1
        $motherboard = Get-CimInstance Win32_BaseBoard
        $os = Get-CimInstance Win32_OperatingSystem
        $ram = Get-CimInstance Win32_PhysicalMemory
        $disks = Get-CimInstance Win32_DiskDrive
        
        return @{
            CPU = @{
                Name = $cpu.Name
                Cores = $cpu.NumberOfCores
                Threads = $cpu.NumberOfLogicalProcessors
                MaxClockSpeed = $cpu.MaxClockSpeed
                Socket = $cpu.SocketDesignation
            }
            GPU = @{
                Name = $gpu.Name
                VRAM = [math]::Round($gpu.AdapterRAM / 1GB, 2)
                DriverVersion = $gpu.DriverVersion
            }
            RAM = @{
                TotalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
                Sticks = $ram.Count
                Speed = ($ram | Select-Object -First 1).Speed
                Type = "DDR4" # Assumed for Ryzen 9 5900X
            }
            Motherboard = @{
                Manufacturer = $motherboard.Manufacturer
                Product = $motherboard.Product
            }
            Storage = $disks | ForEach-Object {
                @{
                    Model = $_.Model
                    SizeGB = [math]::Round($_.Size / 1GB, 0)
                    Interface = $_.InterfaceType
                }
            }
        }
    }
    catch {
        return $null
    }
}

# Detect bottlenecks
function Get-Bottlenecks {
    param($SystemInfo, $UseCase)
    
    $bottlenecks = @()
    
    # RAM analysis
    if ($SystemInfo.RAM.TotalGB -lt 32 -and ($UseCase -eq "Recording" -or $UseCase -eq "Both")) {
        $bottlenecks += @{
            Component = "RAM"
            Priority = "CRITICAL"
            Issue = "16GB insufficient for 120fps recording + gaming"
            Impact = "Crashes, stuttering, recording failures"
            Recommendation = "Upgrade to 32GB DDR4 3200MHz+"
        }
    }
    elseif ($SystemInfo.RAM.TotalGB -lt 16) {
        $bottlenecks += @{
            Component = "RAM"
            Priority = "HIGH"
            Issue = "Less than 16GB RAM"
            Impact = "Performance issues in modern games"
            Recommendation = "Upgrade to 16GB minimum, 32GB preferred"
        }
    }
    
    # GPU analysis
    $gpuName = $SystemInfo.GPU.Name
    if ($gpuName -like "*RTX 2070*" -or $gpuName -like "*RTX 2060*") {
        if ($UseCase -eq "Recording" -or $UseCase -eq "Both") {
            $bottlenecks += @{
                Component = "GPU"
                Priority = "MEDIUM"
                Issue = "RTX 2000 series - older NVENC"
                Impact = "Good encoding, but newer GPUs more efficient"
                Recommendation = "RTX 3060+ for better encoding (optional)"
            }
        }
    }
    elseif ($gpuName -like "*GTX 10*" -or $gpuName -like "*GTX 16*") {
        $bottlenecks += @{
            Component = "GPU"
            Priority = "HIGH"
            Issue = "Older GPU generation"
            Impact = "Limited encoding quality, lower FPS"
            Recommendation = "RTX 3060+ for better performance"
        }
    }
    
    # Storage analysis
    $hasSSD = $false
    foreach ($disk in $SystemInfo.Storage) {
        if ($disk.Model -like "*SSD*" -or $disk.Model -like "*NVMe*") {
            $hasSSD = $true
            break
        }
    }
    
    if (-not $hasSSD -and ($UseCase -eq "Recording" -or $UseCase -eq "Both")) {
        $bottlenecks += @{
            Component = "Storage"
            Priority = "HIGH"
            Issue = "No SSD detected for recording"
            Impact = "Recording stutters, frame drops"
            Recommendation = "Add NVMe SSD for recording storage"
        }
    }
    
    return $bottlenecks
}

# Get upgrade recommendations
function Get-UpgradeOptions {
    param($Budget, $Bottlenecks, $SystemInfo)
    
    $recommendations = @()
    
    # RAM upgrades
    $ramUpgrade = @{
        Component = "RAM"
        Options = @(
            @{
                Name = "Corsair Vengeance LPX 32GB (2x16GB) DDR4 3200MHz"
                Price = 85
                Performance = "+100% capacity, crucial for recording"
                Link = "https://www.amazon.com/s?k=Corsair+Vengeance+32GB+DDR4+3200"
            },
            @{
                Name = "G.Skill Ripjaws V 32GB (2x16GB) DDR4 3200MHz"
                Price = 80
                Performance = "+100% capacity, excellent compatibility"
                Link = "https://www.amazon.com/s?k=G.Skill+Ripjaws+32GB+DDR4+3200"
            },
            @{
                Name = "Corsair Vengeance RGB 32GB (2x16GB) DDR4 3600MHz"
                Price = 110
                Performance = "+100% capacity + faster speed"
                Link = "https://www.amazon.com/s?k=Corsair+Vengeance+32GB+DDR4+3600"
            }
        )
    }
    
    # GPU upgrades
    $gpuUpgrade = @{
        Component = "GPU"
        Options = @(
            @{
                Name = "RTX 4060 8GB"
                Price = 300
                Performance = "Great 1080p gaming + excellent NVENC"
                Link = "https://www.amazon.com/s?k=RTX+4060"
            },
            @{
                Name = "RTX 4060 Ti 16GB"
                Price = 450
                Performance = "1440p gaming + best NVENC encoding"
                Link = "https://www.amazon.com/s?k=RTX+4060+Ti+16GB"
            },
            @{
                Name = "RTX 4070 12GB"
                Price = 550
                Performance = "High-end 1440p + premium encoding"
                Link = "https://www.amazon.com/s?k=RTX+4070"
            },
            @{
                Name = "AMD RX 7600 8GB"
                Price = 270
                Performance = "Budget 1080p gaming, good encoding"
                Link = "https://www.amazon.com/s?k=RX+7600"
            }
        )
    }
    
    # Storage upgrades
    $storageUpgrade = @{
        Component = "Storage"
        Options = @(
            @{
                Name = "Samsung 980 PRO 1TB NVMe"
                Price = 90
                Performance = "7000MB/s read - perfect for recording"
                Link = "https://www.amazon.com/s?k=Samsung+980+PRO+1TB"
            },
            @{
                Name = "WD Black SN850X 1TB NVMe"
                Price = 95
                Performance = "7300MB/s read - top tier"
                Link = "https://www.amazon.com/s?k=WD+Black+SN850X+1TB"
            },
            @{
                Name = "Crucial P3 Plus 1TB NVMe"
                Price = 65
                Performance = "5000MB/s read - budget option"
                Link = "https://www.amazon.com/s?k=Crucial+P3+Plus+1TB"
            }
        )
    }
    
    return @{
        RAM = $ramUpgrade
        GPU = $gpuUpgrade
        Storage = $storageUpgrade
    }
}

# Main script
try {
    Write-Header "═══════════════════════════════════════════════════════════"
    Write-Host "  🎯 HARDWARE UPGRADE ADVISOR" -ForegroundColor Cyan
    Write-Header "═══════════════════════════════════════════════════════════"
    
    Write-Info "Budget: `$$Budget"
    Write-Info "Use Case: $UseCase"
    
    # Get system info
    Write-Header "`n🔍 Analyzing Current Hardware"
    $system = Get-SystemInfo
    
    if (-not $system) {
        Write-Error "Failed to detect system hardware"
        exit 1
    }
    
    Write-Info "CPU: $($system.CPU.Name)"
    Write-Info "GPU: $($system.GPU.Name)"
    Write-Info "RAM: $($system.RAM.TotalGB)GB ($($system.RAM.Sticks)x sticks @ $($system.RAM.Speed)MHz)"
    Write-Info "Motherboard: $($system.Motherboard.Manufacturer) $($system.Motherboard.Product)"
    
    # Detect bottlenecks
    Write-Header "`n⚡ Bottleneck Analysis"
    $bottlenecks = Get-Bottlenecks -SystemInfo $system -UseCase $UseCase
    
    if ($bottlenecks.Count -eq 0) {
        Write-Success "No significant bottlenecks detected for $UseCase use case"
    }
    else {
        Write-Warning "Found $($bottlenecks.Count) bottleneck(s)"
        
        foreach ($bottleneck in $bottlenecks | Sort-Object { 
            switch($_.Priority) {
                "CRITICAL" { 0 }
                "HIGH" { 1 }
                "MEDIUM" { 2 }
                "LOW" { 3 }
            }
        }) {
            Write-Host ""
            Write-Priority $bottleneck.Priority "$($bottleneck.Component): $($bottleneck.Issue)"
            Write-Host "    Impact: $($bottleneck.Impact)" -ForegroundColor Gray
            Write-Host "    Fix: $($bottleneck.Recommendation)" -ForegroundColor White
        }
    }
    
    # Get upgrade recommendations
    Write-Header "`n💰 UPGRADE RECOMMENDATIONS (Budget: `$$Budget)"
    $upgrades = Get-UpgradeOptions -Budget $Budget -Bottlenecks $bottlenecks -SystemInfo $system
    
    # Prioritize based on bottlenecks and budget
    $criticalBottlenecks = $bottlenecks | Where-Object { $_.Priority -eq "CRITICAL" }
    $highBottlenecks = $bottlenecks | Where-Object { $_.Priority -eq "HIGH" }
    
    # RAM recommendations (CRITICAL for this user)
    if ($system.RAM.TotalGB -lt 32 -and ($UseCase -eq "Recording" -or $UseCase -eq "Both")) {
        Write-Header "`n🚨 PRIORITY #1: RAM UPGRADE (CRITICAL)"
        Write-Host "  Current: $($system.RAM.TotalGB)GB" -ForegroundColor Red
        Write-Host "  Needed: 32GB for stable 120fps recording + gaming`n" -ForegroundColor Yellow
        
        foreach ($option in $upgrades.RAM.Options) {
            if ($option.Price -le $Budget) {
                $withinBudget = "✓ WITHIN BUDGET"
                $color = "Green"
            }
            else {
                $withinBudget = "Over budget"
                $color = "Gray"
            }
            
            Write-Host "  Option: $($option.Name)" -ForegroundColor $color
            Write-Host "    Price: `$$($option.Price) - $withinBudget" -ForegroundColor $color
            Write-Host "    Benefit: $($option.Performance)" -ForegroundColor White
            Write-Host "    Buy: $($option.Link)" -ForegroundColor Cyan
            Write-Host ""
        }
        
        Write-Host "  ⚠️  IMPORTANT NOTES:" -ForegroundColor Yellow
        Write-Host "    • Compatible with Ryzen 9 5900X" -ForegroundColor White
        Write-Host "    • Remove existing 16GB, install new 32GB kit" -ForegroundColor White
        Write-Host "    • Enable XMP/DOCP in BIOS after install" -ForegroundColor White
        Write-Host "    • Will ELIMINATE crashes from RAM shortage" -ForegroundColor Green
    }
    
    # GPU recommendations
    if ($Budget -gt 200 -and ($UseCase -eq "Gaming" -or $UseCase -eq "Both")) {
        Write-Header "`n🎮 PRIORITY #2: GPU UPGRADE (OPTIONAL)"
        Write-Host "  Current: $($system.GPU.Name)" -ForegroundColor White
        Write-Host "  RTX 2070 SUPER is still capable, upgrade only if budget allows`n" -ForegroundColor Cyan
        
        $affordableGPUs = $upgrades.GPU.Options | Where-Object { $_.Price -le $Budget } | Sort-Object Price
        
        if ($affordableGPUs.Count -gt 0) {
            foreach ($option in $affordableGPUs) {
                Write-Host "  Option: $($option.Name)" -ForegroundColor Green
                Write-Host "    Price: `$$($option.Price)" -ForegroundColor Green
                Write-Host "    Benefit: $($option.Performance)" -ForegroundColor White
                Write-Host "    Buy: $($option.Link)" -ForegroundColor Cyan
                Write-Host ""
            }
        }
        else {
            Write-Info "GPU upgrades start at ~`$270 (outside current budget)"
        }
    }
    
    # Storage recommendations
    if ($UseCase -eq "Recording" -or $UseCase -eq "Both") {
        Write-Header "`n💾 PRIORITY #3: STORAGE UPGRADE (RECOMMENDED)"
        Write-Host "  Add dedicated NVMe SSD for recording to prevent frame drops`n" -ForegroundColor Cyan
        
        $affordableStorage = $upgrades.Storage.Options | Where-Object { $_.Price -le $Budget } | Sort-Object Price
        
        foreach ($option in $affordableStorage) {
            Write-Host "  Option: $($option.Name)" -ForegroundColor Green
            Write-Host "    Price: `$$($option.Price)" -ForegroundColor Green
            Write-Host "    Benefit: $($option.Performance)" -ForegroundColor White
            Write-Host "    Buy: $($option.Link)" -ForegroundColor Cyan
            Write-Host ""
        }
        
        Write-Host "  💡 Tip: Record to separate drive from game installation" -ForegroundColor Yellow
    }
    
    # Budget allocation
    Write-Header "`n📊 RECOMMENDED BUDGET ALLOCATION"
    
    if ($Budget -ge 200) {
        Write-Host "`n  For your `$$Budget budget and '$UseCase' use case:`n" -ForegroundColor Cyan
        
        if ($system.RAM.TotalGB -lt 32) {
            Write-Host "  1. RAM (32GB): ~`$85-110 " -ForegroundColor Green -NoNewline
            Write-Host "← CRITICAL - Do this FIRST!" -ForegroundColor Red
            
            $remaining = $Budget - 85
            if ($remaining -ge 65) {
                Write-Host "  2. NVMe SSD (1TB): ~`$65-95 " -ForegroundColor Green -NoNewline
                Write-Host "← Improves recording stability" -ForegroundColor Yellow
                
                $remaining = $remaining - 65
                if ($remaining -gt 0) {
                    Write-Host "  3. Remaining: `$$remaining (save for GPU upgrade)" -ForegroundColor White
                }
            }
            else {
                Write-Host "  2. Remaining: `$$remaining (save for storage/GPU)" -ForegroundColor White
            }
        }
        else {
            Write-Success "RAM already sufficient (32GB+)"
            Write-Host "  1. NVMe SSD: ~`$65-95" -ForegroundColor Green
            Write-Host "  2. GPU: ~`$270-550 (if budget allows)" -ForegroundColor Cyan
        }
    }
    else {
        Write-Warning "Budget under `$200 - recommend saving more for RAM upgrade"
        Write-Host "  Target: `$85-110 for 32GB DDR4 RAM (critical upgrade)" -ForegroundColor Yellow
    }
    
    # Compatibility notes
    Write-Header "`n✅ COMPATIBILITY NOTES"
    Write-Success "Ryzen 9 5900X supports:"
    Write-Info "  • DDR4 RAM up to 3200MHz (officially), higher with XMP"
    Write-Info "  • PCIe 4.0 (compatible with all modern GPUs and NVMe SSDs)"
    Write-Info "  • Most AM4 motherboards support 128GB RAM maximum"
    
    # Final recommendation summary
    Write-Header "`n🎯 FINAL RECOMMENDATION"
    
    if ($system.RAM.TotalGB -lt 32 -and ($UseCase -eq "Recording" -or $UseCase -eq "Both")) {
        Write-Host ""
        Write-Host "  ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "  ║  🚨 IMMEDIATE ACTION: UPGRADE RAM TO 32GB           ║" -ForegroundColor Red
        Write-Host "  ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Why it's critical:" -ForegroundColor Yellow
        Write-Host "    • 16GB insufficient for 120fps recording + gaming" -ForegroundColor White
        Write-Host "    • Causing crashes and recording failures" -ForegroundColor White
        Write-Host "    • Chrome alone uses 5GB, leaving <11GB for games" -ForegroundColor White
        Write-Host "    • Modern games need 8-12GB, recording needs 4-6GB" -ForegroundColor White
        Write-Host ""
        Write-Host "  Best option:" -ForegroundColor Green
        Write-Host "    Corsair/G.Skill 32GB (2x16GB) DDR4 3200MHz - `$80-85" -ForegroundColor Green
        Write-Host ""
        Write-Host "  This single upgrade will:" -ForegroundColor Cyan
        Write-Host "    ✓ Eliminate RAM-related crashes" -ForegroundColor Green
        Write-Host "    ✓ Allow smooth 120fps recording" -ForegroundColor Green
        Write-Host "    ✓ Remove need for constant cleanup" -ForegroundColor Green
        Write-Host "    ✓ Future-proof for 3-5 years" -ForegroundColor Green
    }
    else {
        Write-Success "Current hardware adequate for $UseCase"
        Write-Info "Consider GPU upgrade for better performance (optional)"
    }
    
    Write-Header "═══════════════════════════════════════════════════════════"
    Write-Host "  ✓ Upgrade Analysis Complete" -ForegroundColor Green
    Write-Header "═══════════════════════════════════════════════════════════`n"
}
catch {
    Write-Host "`n" -NoNewline
    Write-Error "Upgrade analysis failed: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
