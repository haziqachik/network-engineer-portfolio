# PC Optimization Module
# System cleanup and performance optimization functions

function New-RestorePoint {
    param(
        [string]$Description = "PC Diagnostic Tool - Before Optimizations"
    )
    
    Write-Host "`n[*] Creating system restore point..." -ForegroundColor Cyan
    
    try {
        # Enable system restore if not enabled
        Enable-ComputerRestore -Drive "$env:SystemDrive\"
        
        # Create restore point
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS"
        Write-Host "  [✓] Restore point created successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  [!] Failed to create restore point: $_" -ForegroundColor Red
        return $false
    }
}

function Optimize-TempFiles {
    param(
        [switch]$WhatIf
    )
    
    Write-Host "`n[*] Cleaning temporary files..." -ForegroundColor Cyan
    
    $cleanupPaths = @(
        "$env:TEMP",
        "$env:WINDIR\Temp",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:LOCALAPPDATA\Temp"
    )
    
    $totalFreed = 0
    
    foreach ($path in $cleanupPaths) {
        if (Test-Path $path) {
            try {
                $sizeBefore = (Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum).Sum
                
                if (-not $WhatIf) {
                    Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | 
                        Where-Object {!$_.PSIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-7)} | 
                        Remove-Item -Force -ErrorAction SilentlyContinue
                }
                
                $sizeAfter = (Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum).Sum
                
                $freed = $sizeBefore - $sizeAfter
                $totalFreed += $freed
                
                Write-Host "  [✓] Cleaned: $path - Freed $([math]::Round($freed / 1MB, 2)) MB" -ForegroundColor Green
            } catch {
                Write-Host "  [!] Error cleaning $path : $_" -ForegroundColor Yellow
            }
        }
    }
    
    # Clean Windows Update cache
    try {
        if (-not $WhatIf) {
            Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
            $updateCache = "$env:WINDIR\SoftwareDistribution\Download"
            if (Test-Path $updateCache) {
                $sizeBefore = (Get-ChildItem -Path $updateCache -Recurse -Force -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum).Sum
                Remove-Item -Path "$updateCache\*" -Recurse -Force -ErrorAction SilentlyContinue
                $totalFreed += $sizeBefore
                Write-Host "  [✓] Cleaned Windows Update cache - Freed $([math]::Round($sizeBefore / 1MB, 2)) MB" -ForegroundColor Green
            }
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Host "  [!] Error cleaning Windows Update cache: $_" -ForegroundColor Yellow
    }
    
    Write-Host "`n  [✓] Total space freed: $([math]::Round($totalFreed / 1GB, 2)) GB" -ForegroundColor Green
    
    return $totalFreed
}

function Optimize-StartupPrograms {
    param(
        [switch]$WhatIf,
        [switch]$Interactive
    )
    
    Write-Host "`n[*] Optimizing startup programs..." -ForegroundColor Cyan
    
    $disabled = @()
    
    # Get startup tasks
    try {
        $startupTasks = Get-ScheduledTask | Where-Object {
            $_.State -eq 'Ready' -and 
            $_.Settings.Enabled -eq $true -and
            $_.Triggers.TriggerType -eq 'AtLogon'
        }
        
        # List of commonly unnecessary startup tasks
        $unnecessaryTasks = @(
            'AdobeAAMUpdater',
            'GoogleUpdateTask',
            'CCleaner',
            'DropboxUpdate',
            'OneDrive',
            'Skype'
        )
        
        foreach ($task in $startupTasks) {
            if ($unnecessaryTasks -contains $task.TaskName -or $task.TaskName -match ($unnecessaryTasks -join '|')) {
                if ($Interactive) {
                    $response = Read-Host "Disable startup task '$($task.TaskName)'? (Y/N)"
                    if ($response -ne 'Y') { continue }
                }
                
                if (-not $WhatIf) {
                    Disable-ScheduledTask -TaskName $task.TaskName -ErrorAction SilentlyContinue
                }
                
                $disabled += $task.TaskName
                Write-Host "  [✓] Disabled: $($task.TaskName)" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "  [!] Error optimizing startup tasks: $_" -ForegroundColor Yellow
    }
    
    return $disabled
}

function Optimize-WindowsServices {
    param(
        [switch]$WhatIf,
        [string]$Profile = "Gaming" # Gaming, Recording, Balanced
    )
    
    Write-Host "`n[*] Optimizing Windows services for $Profile profile..." -ForegroundColor Cyan
    
    # Services safe to disable for gaming/recording
    $servicesToDisable = @{
        Gaming = @(
            'TabletInputService',
            'WSearch',  # Windows Search (can re-enable if needed)
            'SysMain',  # Superfetch
            'DiagTrack',  # Diagnostics Tracking
            'dmwappushservice'
        )
        Recording = @(
            'TabletInputService',
            'DiagTrack',
            'dmwappushservice'
        )
    }
    
    $optimized = @()
    
    foreach ($serviceName in $servicesToDisable[$Profile]) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service -and $service.StartType -ne 'Disabled') {
                if (-not $WhatIf) {
                    Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue
                    Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
                }
                $optimized += $serviceName
                Write-Host "  [✓] Disabled: $serviceName" -ForegroundColor Green
            }
        } catch {
            Write-Host "  [!] Error with $serviceName : $_" -ForegroundColor Yellow
        }
    }
    
    return $optimized
}

function Optimize-PageFile {
    param(
        [int]$MinSize_MB = 16384,  # 16GB minimum for recording
        [int]$MaxSize_MB = 32768,  # 32GB maximum
        [switch]$WhatIf
    )
    
    Write-Host "`n[*] Optimizing page file (virtual memory)..." -ForegroundColor Cyan
    
    try {
        $computerSystem = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
        
        if (-not $WhatIf) {
            # Disable automatic page file management
            $computerSystem.AutomaticManagedPagefile = $false
            $computerSystem.Put() | Out-Null
            
            # Set custom page file size
            $pageFile = Get-WmiObject Win32_PageFileSetting
            if ($pageFile) {
                $pageFile.Delete()
            }
            
            # Create new page file with optimal size
            $pageFile = ([wmiclass]"Win32_PageFileSetting").CreateInstance()
            $pageFile.Name = "$env:SystemDrive\pagefile.sys"
            $pageFile.InitialSize = $MinSize_MB
            $pageFile.MaximumSize = $MaxSize_MB
            $pageFile.Put() | Out-Null
        }
        
        Write-Host "  [✓] Page file configured: $MinSize_MB MB - $MaxSize_MB MB" -ForegroundColor Green
        Write-Host "  [!] Restart required for changes to take effect" -ForegroundColor Yellow
        
        return $true
    } catch {
        Write-Host "  [!] Failed to optimize page file: $_" -ForegroundColor Red
        return $false
    }
}

function Optimize-PowerPlan {
    param(
        [switch]$WhatIf
    )
    
    Write-Host "`n[*] Setting High Performance power plan..." -ForegroundColor Cyan
    
    try {
        if (-not $WhatIf) {
            # Get High Performance plan GUID
            $highPerfGuid = (powercfg /L | Select-String "High performance").ToString().Split()[3]
            
            if ($highPerfGuid) {
                powercfg /S $highPerfGuid
                Write-Host "  [✓] High Performance power plan activated" -ForegroundColor Green
                
                # Disable USB selective suspend
                powercfg /SETACVALUEINDEX $highPerfGuid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
                powercfg /SETDCVALUEINDEX $highPerfGuid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
                
                Write-Host "  [✓] USB selective suspend disabled" -ForegroundColor Green
            }
        }
        return $true
    } catch {
        Write-Host "  [!] Failed to set power plan: $_" -ForegroundColor Red
        return $false
    }
}

function Optimize-VisualEffects {
    param(
        [switch]$WhatIf
    )
    
    Write-Host "`n[*] Optimizing visual effects for performance..." -ForegroundColor Cyan
    
    try {
        if (-not $WhatIf) {
            # Set to "Adjust for best performance"
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -ErrorAction SilentlyContinue
            
            # Disable animations
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value 0 -ErrorAction SilentlyContinue
            
            # Disable transparency
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -ErrorAction SilentlyContinue
        }
        
        Write-Host "  [✓] Visual effects optimized for performance" -ForegroundColor Green
        Write-Host "  [!] Restart Explorer.exe or log off for full effect" -ForegroundColor Yellow
        
        return $true
    } catch {
        Write-Host "  [!] Failed to optimize visual effects: $_" -ForegroundColor Red
        return $false
    }
}

function Enable-GameMode {
    param(
        [switch]$WhatIf
    )
    
    Write-Host "`n[*] Enabling Windows Game Mode..." -ForegroundColor Cyan
    
    try {
        if (-not $WhatIf) {
            # Enable Game Mode
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -ErrorAction SilentlyContinue
            
            # Enable Hardware Accelerated GPU Scheduling (Windows 10 2004+)
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -ErrorAction SilentlyContinue
        }
        
        Write-Host "  [✓] Game Mode enabled" -ForegroundColor Green
        Write-Host "  [✓] Hardware GPU Scheduling enabled" -ForegroundColor Green
        
        return $true
    } catch {
        Write-Host "  [!] Failed to enable Game Mode: $_" -ForegroundColor Red
        return $false
    }
}

function Optimize-NetworkSettings {
    param(
        [switch]$WhatIf
    )
    
    Write-Host "`n[*] Optimizing network settings..." -ForegroundColor Cyan
    
    try {
        if (-not $WhatIf) {
            # Disable Network Throttling Index
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -ErrorAction SilentlyContinue
            
            # Set DNS to Google DNS (faster than most ISP DNS)
            $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
            foreach ($adapter in $adapters) {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("8.8.8.8","8.8.4.4") -ErrorAction SilentlyContinue
            }
        }
        
        Write-Host "  [✓] Network throttling disabled" -ForegroundColor Green
        Write-Host "  [✓] DNS set to Google DNS (8.8.8.8, 8.8.4.4)" -ForegroundColor Green
        
        return $true
    } catch {
        Write-Host "  [!] Failed to optimize network: $_" -ForegroundColor Red
        return $false
    }
}

function Optimize-DiskPerformance {
    param(
        [switch]$WhatIf
    )
    
    Write-Host "`n[*] Optimizing disk performance..." -ForegroundColor Cyan
    
    $results = @()
    
    # Get all volumes
    $volumes = Get-Volume | Where-Object {$_.DriveLetter -and $_.DriveType -eq 'Fixed'}
    
    foreach ($vol in $volumes) {
        try {
            $drive = $vol.DriveLetter
            
            # Check if SSD (TRIM) or HDD (defrag)
            $physicalDisk = Get-PhysicalDisk | Where-Object {
                (Get-Partition -DriveLetter $drive).DiskNumber -eq $_.DeviceId
            }
            
            if ($physicalDisk.MediaType -eq 'SSD') {
                if (-not $WhatIf) {
                    # Optimize SSD (TRIM)
                    Optimize-Volume -DriveLetter $drive -ReTrim -ErrorAction SilentlyContinue
                }
                Write-Host "  [✓] SSD $drive : TRIM optimization scheduled" -ForegroundColor Green
                $results += "SSD $drive optimized"
            } else {
                if (-not $WhatIf) {
                    # Defrag HDD
                    Optimize-Volume -DriveLetter $drive -Defrag -ErrorAction SilentlyContinue
                }
                Write-Host "  [✓] HDD $drive : Defragmentation scheduled" -ForegroundColor Green
                $results += "HDD $drive defragmented"
            }
        } catch {
            Write-Host "  [!] Error optimizing drive $drive : $_" -ForegroundColor Yellow
        }
    }
    
    return $results
}

# Export functions
Export-ModuleMember -Function New-RestorePoint, Optimize-TempFiles, Optimize-StartupPrograms, Optimize-WindowsServices, Optimize-PageFile, Optimize-PowerPlan, Optimize-VisualEffects, Enable-GameMode, Optimize-NetworkSettings, Optimize-DiskPerformance
