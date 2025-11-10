# PC Upgrade Recommendation Module
# Intelligent hardware upgrade analysis and recommendations

function Get-BottleneckAnalysis {
    param(
        [object]$SystemInfo
    )
    
    Write-Host "`n[*] Analyzing system bottlenecks..." -ForegroundColor Cyan
    
    $analysis = @{
        Bottlenecks = @()
        Recommendations = @()
        PerformanceScore = @{
            Gaming = 0
            Recording = 0
            Multitasking = 0
        }
    }
    
    # CPU Analysis
    $cpu = $SystemInfo.CPU
    $cpuCores = $cpu.NumberOfCores
    $cpuThreads = $cpu.NumberOfLogicalProcessors
    
    # Rough CPU scoring (simplified)
    $cpuScore = $cpuCores * 10 + ($cpuThreads - $cpuCores) * 5
    
    # RAM Analysis
    $ramGB = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 0)
    
    # GPU Analysis
    $gpu = $SystemInfo.GPU
    $gpuName = $gpu.Name.ToLower()
    
    # Simple GPU tier detection
    $gpuTier = "Unknown"
    if ($gpuName -match 'rtx 40|rtx 4090|rtx 4080') { $gpuTier = "High-End" }
    elseif ($gpuName -match 'rtx 30|rtx 3080|rtx 3090|rx 6800|rx 6900') { $gpuTier = "High-End" }
    elseif ($gpuName -match 'rtx 3070|rtx 3060|rx 6700|rx 6600') { $gpuTier = "Mid-Range" }
    elseif ($gpuName -match 'rtx 20|gtx 16|rx 5') { $gpuTier = "Entry-Level" }
    elseif ($gpuName -match 'gtx 10|rx 4') { $gpuTier = "Budget" }
    else { $gpuTier = "Integrated/Low-End" }
    
    # Bottleneck Detection
    
    # 1. RAM Bottleneck (Critical for recording at 120fps)
    if ($ramGB -lt 16) {
        $analysis.Bottlenecks += @{
            Component = "RAM"
            Severity = "CRITICAL"
            Issue = "Insufficient RAM for 120fps recording + gaming"
            CurrentSpec = "$ramGB GB"
            Recommendation = "16GB minimum, 32GB recommended"
        }
    } elseif ($ramGB -lt 32) {
        $analysis.Bottlenecks += @{
            Component = "RAM"
            Severity = "HIGH"
            Issue = "RAM may be insufficient for smooth recording experience"
            CurrentSpec = "$ramGB GB"
            Recommendation = "32GB for optimal recording + gaming"
        }
    }
    
    # 2. CPU/GPU Pairing
    if ($cpuCores -lt 6 -and $gpuTier -eq "High-End") {
        $analysis.Bottlenecks += @{
            Component = "CPU"
            Severity = "HIGH"
            Issue = "CPU may bottleneck high-end GPU"
            CurrentSpec = "$cpuCores cores"
            Recommendation = "6-8 core CPU recommended"
        }
    }
    
    # 3. Recording-specific bottlenecks
    if ($cpuCores -lt 8) {
        $analysis.Bottlenecks += @{
            Component = "CPU"
            Severity = "MEDIUM"
            Issue = "Recording at 120fps requires strong multi-core CPU"
            CurrentSpec = "$cpuCores cores / $cpuThreads threads"
            Recommendation = "8+ cores for smooth recording + gaming"
        }
    }
    
    # Performance Scoring
    $analysis.PerformanceScore.Gaming = [math]::Min(100, ($cpuScore * 0.3 + (switch ($gpuTier) {
        "High-End" { 80 }
        "Mid-Range" { 60 }
        "Entry-Level" { 40 }
        "Budget" { 20 }
        default { 10 }
    }) * 0.7))
    
    $analysis.PerformanceScore.Recording = [math]::Min(100, ($cpuScore * 0.5 + ($ramGB * 2) * 0.3 + 
        (if ($gpuName -match 'nvenc|nvidia') { 20 } else { 10 })))
    
    $analysis.PerformanceScore.Multitasking = [math]::Min(100, ($cpuScore * 0.4 + ($ramGB * 2) * 0.6))
    
    return $analysis
}

function Get-RAMUpgradeRecommendation {
    param(
        [object]$RAMInfo,
        [string]$UseCase = "Recording" # Gaming, Recording, Professional
    )
    
    Write-Host "`n[*] Analyzing RAM upgrade options..." -ForegroundColor Cyan
    
    $recommendation = @{
        CurrentRAM_GB = $RAMInfo.TotalRAM_GB
        RecommendedRAM_GB = 0
        UpgradePath = ""
        EstimatedCost = 0
        Priority = ""
        Reason = ""
        Options = @()
    }
    
    $currentRAM = $RAMInfo.TotalRAM_GB
    
    # Determine recommended RAM based on use case
    switch ($UseCase) {
        "Recording" {
            if ($currentRAM -lt 32) {
                $recommendation.RecommendedRAM_GB = 32
                $recommendation.Priority = "CRITICAL"
                $recommendation.Reason = "120fps recording + gaming requires 32GB minimum. Current usage shows memory pressure."
            } else {
                $recommendation.RecommendedRAM_GB = $currentRAM
                $recommendation.Priority = "LOW"
                $recommendation.Reason = "RAM capacity is adequate for recording workloads"
            }
        }
        "Gaming" {
            if ($currentRAM -lt 16) {
                $recommendation.RecommendedRAM_GB = 16
                $recommendation.Priority = "HIGH"
            } else {
                $recommendation.RecommendedRAM_GB = $currentRAM
                $recommendation.Priority = "LOW"
            }
        }
        "Professional" {
            if ($currentRAM -lt 64) {
                $recommendation.RecommendedRAM_GB = 64
                $recommendation.Priority = "MEDIUM"
            }
        }
    }
    
    # Generate upgrade options
    if ($currentRAM -lt $recommendation.RecommendedRAM_GB) {
        $ramSpeed = ($RAMInfo.MemoryModules | Select-Object -First 1).Speed
        
        # Option 1: Add more RAM (if slots available)
        $recommendation.Options += @{
            Type = "Add RAM"
            Configuration = "Add $($recommendation.RecommendedRAM_GB - $currentRAM)GB (total $($recommendation.RecommendedRAM_GB)GB)"
            Speed = "$ramSpeed MHz"
            EstimatedCost = [math]::Round(($recommendation.RecommendedRAM_GB - $currentRAM) * 30, 0)
            Pros = "Keep existing RAM, lower cost"
            Cons = "Need available slots, same speed required"
        }
        
        # Option 2: Replace all RAM
        $recommendation.Options += @{
            Type = "Replace RAM"
            Configuration = "$($recommendation.RecommendedRAM_GB)GB kit (2x$($recommendation.RecommendedRAM_GB/2)GB)"
            Speed = "3200-3600 MHz (recommended)"
            EstimatedCost = [math]::Round($recommendation.RecommendedRAM_GB * 35, 0)
            Pros = "Dual-channel, matched kit, higher speed option"
            Cons = "Higher cost, old RAM not reusable"
        }
        
        $recommendation.UpgradePath = "Upgrade to $($recommendation.RecommendedRAM_GB)GB"
        $recommendation.EstimatedCost = ($recommendation.Options | Measure-Object -Property EstimatedCost -Minimum).Minimum
    }
    
    # CRITICAL: Check for WHEA errors indicating RAM failure
    if ($RAMInfo.WHEAErrors.Count -gt 0) {
        $recommendation.CriticalWarning = "⚠️ FAILING RAM DETECTED - REPLACE IMMEDIATELY"
        $recommendation.Priority = "CRITICAL"
        $recommendation.Reason = "WHEA hardware errors detected - physical RAM failure. System crashes and instability will continue until RAM is replaced."
        $recommendation.EstimatedCost = [math]::Round($currentRAM * 35, 0) # Full replacement needed
    }
    
    return $recommendation
}

function Get-GPUUpgradeRecommendation {
    param(
        [object]$GPU,
        [string]$UseCase = "Recording",
        [int]$Budget = 1000
    )
    
    Write-Host "`n[*] Analyzing GPU upgrade options..." -ForegroundColor Cyan
    
    $recommendation = @{
        CurrentGPU = $GPU.Name
        Recommendations = @()
        EncoderAnalysis = ""
    }
    
    $gpuName = $GPU.Name.ToLower()
    
    # Check for NVENC support (critical for recording)
    if ($gpuName -match 'nvidia|geforce|rtx|gtx') {
        $recommendation.EncoderAnalysis = "✓ NVIDIA GPU detected - NVENC encoder available for efficient recording"
    } elseif ($gpuName -match 'amd|radeon|rx') {
        $recommendation.EncoderAnalysis = "AMD GPU detected - VCE/AMF encoder available (NVENC generally preferred for recording)"
    } else {
        $recommendation.EncoderAnalysis = "⚠️ No dedicated GPU encoder detected - CPU encoding will impact performance"
    }
    
    # Budget tier recommendations for 120fps recording + gaming
    $budgetOptions = @(
        @{
            Tier = "Budget ($300-$400)"
            Options = @("RTX 4060", "RTX 3060", "RX 6600")
            Performance = "1080p 120fps gaming + recording capable"
            VRAM = "8-12GB"
            EncoderQuality = "Good (NVENC/AMF)"
        },
        @{
            Tier = "Mid-Range ($500-$700)"
            Options = @("RTX 4060 Ti", "RTX 3070", "RX 6700 XT")
            Performance = "1080p/1440p 120fps+ gaming + recording"
            VRAM = "12-16GB"
            EncoderQuality = "Excellent (NVENC/AMF)"
        },
        @{
            Tier = "High-End ($800-$1200)"
            Options = @("RTX 4070", "RTX 4070 Ti", "RX 6800 XT")
            Performance = "1440p/4K 120fps gaming + high bitrate recording"
            VRAM = "16GB"
            EncoderQuality = "Excellent (NVENC/AMF)"
        },
        @{
            Tier = "Enthusiast ($1200+)"
            Options = @("RTX 4080", "RTX 4090", "RX 7900 XTX")
            Performance = "4K 120fps+ gaming + 4K recording no compromises"
            VRAM = "16-24GB"
            EncoderQuality = "Best-in-class"
        }
    )
    
    # Recommend based on budget
    foreach ($tier in $budgetOptions) {
        $recommendation.Recommendations += $tier
    }
    
    # Specific recommendation for user's 120fps recording use case
    $recommendation.BestForRecording = @{
        Primary = "RTX 4060 Ti or RTX 4070"
        Reason = "Best NVENC encoder quality, 12-16GB VRAM for recording buffer, excellent 1080p/1440p 120fps performance"
        EstimatedCost = "$500-$700"
        PowerRequirement = "550-650W PSU recommended"
    }
    
    return $recommendation
}

function Get-StorageUpgradeRecommendation {
    param(
        [object]$DiskInfo
    )
    
    Write-Host "`n[*] Analyzing storage upgrade options..." -ForegroundColor Cyan
    
    $recommendation = @{
        CurrentStorage = @()
        Recommendations = @()
        RecordingStorageNeeds = ""
    }
    
    foreach ($disk in $DiskInfo) {
        if ($disk.MediaType) {
            $recommendation.CurrentStorage += @{
                Type = $disk.MediaType
                Size_GB = $disk.Size_GB
                Health = $disk.HealthStatus
            }
        }
    }
    
    # Calculate recording storage needs
    # 120fps at 12000 bitrate = ~5.4GB per hour
    $bitrateKbps = 12000
    $recordingRateGBperHour = ($bitrateKbps * 3600) / (8 * 1024 * 1024)
    
    $recommendation.RecordingStorageNeeds = @"
Recording at 120fps:
- Current bitrate (12000): ~$([math]::Round($recordingRateGBperHour, 1)) GB/hour
- Recommended bitrate (15000-20000): ~$([math]::Round($recordingRateGBperHour * 1.5, 1)) - $([math]::Round($recordingRateGBperHour * 2, 1)) GB/hour
- Recommended: 1TB+ NVMe SSD for recording drive
"@
    
    # Storage recommendations
    $recommendation.Recommendations = @(
        @{
            Type = "NVMe SSD (Primary/OS)"
            Capacity = "500GB - 1TB"
            Purpose = "Operating system, applications, games"
            Speed = "3000+ MB/s read/write"
            EstimatedCost = "$60-$120"
            Priority = "HIGH"
        },
        @{
            Type = "NVMe SSD (Recording)"
            Capacity = "1TB - 2TB"
            Purpose = "Dedicated recording storage - prevents frame drops"
            Speed = "3000+ MB/s write (critical for 120fps)"
            EstimatedCost = "$80-$180"
            Priority = "CRITICAL for recording"
            Reason = "Separate drive prevents recording stutters and game performance impact"
        },
        @{
            Type = "SATA SSD / HDD (Storage)"
            Capacity = "2TB - 4TB"
            Purpose = "Archive recordings, media storage"
            Speed = "500+ MB/s (SSD) or 150+ MB/s (HDD)"
            EstimatedCost = "$80-$120 (SSD) or $60-$80 (HDD)"
            Priority = "MEDIUM"
        }
    )
    
    return $recommendation
}

function Get-PSURecommendation {
    param(
        [object]$CurrentSystem,
        [object]$PlannedUpgrades
    )
    
    Write-Host "`n[*] Calculating PSU requirements..." -ForegroundColor Cyan
    
    $powerCalc = @{
        CurrentEstimate = 0
        UpgradedEstimate = 0
        RecommendedPSU = ""
        Breakdown = @{}
    }
    
    # Rough power estimates (watts)
    $cpuPower = 65  # Base estimate
    if ($CurrentSystem.CPU.NumberOfCores -ge 8) { $cpuPower = 125 }
    if ($CurrentSystem.CPU.NumberOfCores -ge 12) { $cpuPower = 150 }
    
    $gpuPower = 75  # Base estimate
    $gpuName = $CurrentSystem.GPU.Name.ToLower()
    if ($gpuName -match 'rtx 4090') { $gpuPower = 450 }
    elseif ($gpuName -match 'rtx 4080') { $gpuPower = 320 }
    elseif ($gpuName -match 'rtx 4070') { $gpuPower = 200 }
    elseif ($gpuName -match 'rtx 4060') { $gpuPower = 115 }
    elseif ($gpuName -match 'rtx 30') { $gpuPower = 220 }
    elseif ($gpuName -match 'rtx 20|gtx 16') { $gpuPower = 160 }
    
    $ramPower = 3 * ($CurrentSystem.RAM.MemoryModules.Count)
    $storagePower = 10 * ($CurrentSystem.Disk.Count)
    $motherboardPower = 50
    $peripheralsPower = 30
    
    $powerCalc.CurrentEstimate = $cpuPower + $gpuPower + $ramPower + $storagePower + $motherboardPower + $peripheralsPower
    $powerCalc.Breakdown = @{
        CPU = $cpuPower
        GPU = $gpuPower
        RAM = $ramPower
        Storage = $storagePower
        Motherboard = $motherboardPower
        Peripherals = $peripheralsPower
    }
    
    # Add 20% headroom for efficiency and future upgrades
    $recommendedWattage = [math]::Ceiling($powerCalc.CurrentEstimate * 1.2 / 50) * 50
    
    # PSU recommendations
    if ($recommendedWattage -lt 550) {
        $powerCalc.RecommendedPSU = "550W 80+ Bronze or better"
        $powerCalc.EstimatedCost = "$50-$80"
    } elseif ($recommendedWattage -lt 750) {
        $powerCalc.RecommendedPSU = "650W-750W 80+ Gold"
        $powerCalc.EstimatedCost = "$80-$120"
    } else {
        $powerCalc.RecommendedPSU = "850W+ 80+ Gold or Platinum"
        $powerCalc.EstimatedCost = "$120-$200"
    }
    
    return $powerCalc
}

function Get-CoolingRecommendation {
    param(
        [object]$TempData,
        [object]$CPU
    )
    
    Write-Host "`n[*] Analyzing cooling requirements..." -ForegroundColor Cyan
    
    $recommendation = @{
        CurrentStatus = "Unknown"
        Recommendations = @()
        Priority = "LOW"
    }
    
    # Check CPU temperatures
    if ($TempData.CPU.Count -gt 0) {
        $maxTemp = ($TempData.CPU | Measure-Object -Property Temperature_C -Maximum).Maximum
        
        if ($maxTemp -gt 85) {
            $recommendation.CurrentStatus = "CRITICAL - Overheating"
            $recommendation.Priority = "CRITICAL"
            $recommendation.Recommendations += "Immediate action required: Check thermal paste, clean dust, verify fan operation"
        } elseif ($maxTemp -gt 75) {
            $recommendation.CurrentStatus = "WARNING - Running Hot"
            $recommendation.Priority = "HIGH"
            $recommendation.Recommendations += "Consider better cooling solution"
        } else {
            $recommendation.CurrentStatus = "OK"
            $recommendation.Priority = "LOW"
        }
    }
    
    # Cooling upgrade options
    $recommendation.Recommendations += @"
Cooling Upgrade Options:
1. Tower Air Cooler: $30-$80 (Good for most CPUs)
2. AIO Liquid Cooler (240mm): $80-$120 (Better for 8+ core CPUs)
3. AIO Liquid Cooler (360mm): $120-$200 (Best for high-end CPUs, recording workloads)
4. Case Fans: $10-$30 each (Improve overall airflow)

For recording + gaming, good cooling is critical to prevent thermal throttling!
"@
    
    return $recommendation
}

# Export functions
Export-ModuleMember -Function Get-BottleneckAnalysis, Get-RAMUpgradeRecommendation, Get-GPUUpgradeRecommendation, Get-StorageUpgradeRecommendation, Get-PSURecommendation, Get-CoolingRecommendation
