# PC Diagnostic Module
# Comprehensive hardware inventory and health diagnostics

function Get-SystemInventory {
    Write-Host "`n[*] Collecting system inventory..." -ForegroundColor Cyan
    
    $inventory = @{
        Computer = Get-ComputerInfo | Select-Object CsName, OsName, OsVersion, OsBuildNumber, OsArchitecture
        CPU = Get-WmiObject Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed, CurrentClockSpeed
        RAM = Get-WmiObject Win32_PhysicalMemory | Select-Object Manufacturer, PartNumber, Capacity, Speed, ConfiguredClockSpeed
        GPU = Get-WmiObject Win32_VideoController | Select-Object Name, AdapterRAM, DriverVersion, DriverDate, VideoProcessor
        Motherboard = Get-WmiObject Win32_BaseBoard | Select-Object Manufacturer, Product, Version
        BIOS = Get-WmiObject Win32_BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate
        Disk = Get-WmiObject Win32_DiskDrive | Select-Object Model, Size, MediaType, InterfaceType
        Network = Get-WmiObject Win32_NetworkAdapter | Where-Object {$_.NetEnabled -eq $true} | Select-Object Name, MACAddress, Speed
    }
    
    return $inventory
}

function Get-RAMHealth {
    Write-Host "`n[*] Checking RAM health and errors..." -ForegroundColor Cyan
    
    $ramInfo = @{
        TotalRAM_GB = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        AvailableRAM_GB = [math]::Round((Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
        MemoryModules = @()
        WHEAErrors = @()
        CriticalErrors = @()
    }
    
    # Get individual RAM modules
    $ramModules = Get-WmiObject Win32_PhysicalMemory
    foreach ($module in $ramModules) {
        $ramInfo.MemoryModules += @{
            Capacity_GB = [math]::Round($module.Capacity / 1GB, 2)
            Speed = $module.Speed
            Manufacturer = $module.Manufacturer
            PartNumber = $module.PartNumber
            DeviceLocator = $module.DeviceLocator
        }
    }
    
    # Check for WHEA errors (hardware errors including RAM failures)
    Write-Host "  [*] Scanning event logs for WHEA errors (RAM failures)..." -ForegroundColor Yellow
    try {
        $wheaErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-WHEA-Logger'
        } -MaxEvents 100 -ErrorAction SilentlyContinue | Where-Object {$_.Id -eq 46 -or $_.Id -eq 47 -or $_.Id -eq 18}
        
        foreach ($error in $wheaErrors) {
            $ramInfo.WHEAErrors += @{
                TimeCreated = $error.TimeCreated
                EventID = $error.Id
                Message = $error.Message
                Level = $error.LevelDisplayName
            }
        }
        
        if ($wheaErrors.Count -gt 0) {
            Write-Host "  [!] CRITICAL: Found $($wheaErrors.Count) WHEA hardware errors!" -ForegroundColor Red
            Write-Host "  [!] This indicates FAILING HARDWARE - likely RAM!" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [!] Unable to read WHEA errors: $_" -ForegroundColor Yellow
    }
    
    # Check for memory-related critical errors
    try {
        $memErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            Level = 1,2
        } -MaxEvents 500 -ErrorAction SilentlyContinue | Where-Object {
            $_.Message -match 'memory|ram|WHEA|hardware error'
        }
        
        foreach ($error in $memErrors) {
            $ramInfo.CriticalErrors += @{
                TimeCreated = $error.TimeCreated
                EventID = $error.Id
                Source = $error.ProviderName
                Message = $error.Message.Substring(0, [Math]::Min(200, $error.Message.Length))
            }
        }
    } catch {
        Write-Host "  [!] Unable to read critical errors: $_" -ForegroundColor Yellow
    }
    
    # Check memory usage
    $ramInfo.UsagePercent = [math]::Round((($ramInfo.TotalRAM_GB - $ramInfo.AvailableRAM_GB) / $ramInfo.TotalRAM_GB) * 100, 2)
    
    return $ramInfo
}

function Get-DiskHealth {
    Write-Host "`n[*] Analyzing disk health..." -ForegroundColor Cyan
    
    $diskHealth = @()
    
    # Get physical disks
    $disks = Get-PhysicalDisk
    
    foreach ($disk in $disks) {
        $diskInfo = @{
            FriendlyName = $disk.FriendlyName
            MediaType = $disk.MediaType
            Size_GB = [math]::Round($disk.Size / 1GB, 2)
            HealthStatus = $disk.HealthStatus
            OperationalStatus = $disk.OperationalStatus
        }
        
        # Try to get SMART data
        try {
            $smart = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue
            if ($smart) {
                $diskInfo.Temperature = $smart.Temperature
                $diskInfo.ReadErrorsTotal = $smart.ReadErrorsTotal
                $diskInfo.WriteErrorsTotal = $smart.WriteErrorsTotal
                $diskInfo.PowerOnHours = $smart.PowerOnHours
            }
        } catch {
            $diskInfo.SMARTError = "Unable to retrieve SMART data"
        }
        
        $diskHealth += $diskInfo
    }
    
    # Get logical disk info
    $volumes = Get-Volume | Where-Object {$_.DriveLetter}
    foreach ($vol in $volumes) {
        $volInfo = @{
            DriveLetter = $vol.DriveLetter
            FileSystem = $vol.FileSystemType
            Size_GB = [math]::Round($vol.Size / 1GB, 2)
            FreeSpace_GB = [math]::Round($vol.SizeRemaining / 1GB, 2)
            UsedPercent = if ($vol.Size -gt 0) { [math]::Round((($vol.Size - $vol.SizeRemaining) / $vol.Size) * 100, 2) } else { 0 }
        }
        
        $diskHealth += $volInfo
    }
    
    return $diskHealth
}

function Get-TemperatureData {
    Write-Host "`n[*] Monitoring temperatures..." -ForegroundColor Cyan
    
    $tempData = @{
        CPU = @()
        GPU = @()
        Warnings = @()
    }
    
    # Try to get CPU temperature from WMI (not all systems support this)
    try {
        $cpuTemp = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" -ErrorAction SilentlyContinue
        if ($cpuTemp) {
            foreach ($temp in $cpuTemp) {
                $celsius = [math]::Round(($temp.CurrentTemperature / 10) - 273.15, 2)
                $tempData.CPU += @{
                    Zone = $temp.InstanceName
                    Temperature_C = $celsius
                    Status = if ($celsius -gt 85) { "CRITICAL" } elseif ($celsius -gt 70) { "WARNING" } else { "OK" }
                }
                
                if ($celsius -gt 70) {
                    $tempData.Warnings += "CPU temperature high: $celsius°C"
                }
            }
        } else {
            $tempData.CPU += @{ Status = "Temperature monitoring not available via WMI" }
        }
    } catch {
        $tempData.CPU += @{ Status = "Temperature monitoring not supported on this system" }
    }
    
    return $tempData
}

function Get-DriverStatus {
    Write-Host "`n[*] Checking driver versions..." -ForegroundColor Cyan
    
    $drivers = @()
    
    # Get critical drivers (GPU, Network, Storage)
    $deviceClasses = @('Display', 'Net', 'DiskDrive', 'HDC')
    
    foreach ($class in $deviceClasses) {
        $devices = Get-WmiObject Win32_PnPSignedDriver | Where-Object {$_.DeviceClass -eq $class}
        
        foreach ($device in $devices) {
            if ($device.DeviceName) {
                $driverInfo = @{
                    DeviceName = $device.DeviceName
                    DriverVersion = $device.DriverVersion
                    DriverDate = $device.DriverDate
                    Manufacturer = $device.Manufacturer
                    DeviceClass = $device.DeviceClass
                }
                
                # Check if driver is old (more than 2 years)
                if ($device.DriverDate) {
                    try {
                        $driverDate = [DateTime]::ParseExact($device.DriverDate.Substring(0,8), 'yyyyMMdd', $null)
                        $daysSinceUpdate = (Get-Date) - $driverDate
                        
                        if ($daysSinceUpdate.TotalDays -gt 730) {
                            $driverInfo.Warning = "Driver is over 2 years old"
                        }
                    } catch {}
                }
                
                $drivers += $driverInfo
            }
        }
    }
    
    return $drivers
}

function Get-StartupPrograms {
    Write-Host "`n[*] Analyzing startup programs..." -ForegroundColor Cyan
    
    $startupItems = @()
    
    # Get startup programs from registry
    $regPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    )
    
    foreach ($path in $regPaths) {
        try {
            $items = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            if ($items) {
                $properties = $items.PSObject.Properties | Where-Object {$_.Name -notmatch '^PS'}
                foreach ($prop in $properties) {
                    $startupItems += @{
                        Name = $prop.Name
                        Command = $prop.Value
                        Location = $path
                    }
                }
            }
        } catch {}
    }
    
    # Get from Task Scheduler startup tasks
    try {
        $scheduledTasks = Get-ScheduledTask | Where-Object {$_.State -eq 'Ready' -and $_.Triggers.TriggerType -eq 'AtLogon'}
        foreach ($task in $scheduledTasks) {
            $startupItems += @{
                Name = $task.TaskName
                Command = $task.Actions.Execute
                Location = "Task Scheduler"
            }
        }
    } catch {}
    
    return $startupItems
}

function Get-BackgroundProcesses {
    Write-Host "`n[*] Analyzing resource-intensive background processes..." -ForegroundColor Cyan
    
    $processes = Get-Process | Where-Object {$_.CPU -gt 0} | 
        Sort-Object CPU -Descending | 
        Select-Object -First 20 Name, 
            @{Name="CPU(s)";Expression={[math]::Round($_.CPU, 2)}},
            @{Name="Memory(MB)";Expression={[math]::Round($_.WorkingSet / 1MB, 2)}},
            @{Name="Threads";Expression={$_.Threads.Count}},
            Id
    
    return $processes
}

function Get-NetworkAdapters {
    Write-Host "`n[*] Enumerating network adapters..." -ForegroundColor Cyan
    
    $adapters = @()
    
    $netAdapters = Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}
    
    foreach ($adapter in $netAdapters) {
        $adapterInfo = @{
            Name = $adapter.Name
            InterfaceDescription = $adapter.InterfaceDescription
            Status = $adapter.Status
            LinkSpeed = $adapter.LinkSpeed
            MacAddress = $adapter.MacAddress
        }
        
        # Get driver info
        try {
            $driver = Get-WmiObject Win32_PnPSignedDriver | Where-Object {$_.DeviceName -eq $adapter.InterfaceDescription}
            if ($driver) {
                $adapterInfo.DriverVersion = $driver.DriverVersion
                $adapterInfo.DriverDate = $driver.DriverDate
                
                # Check for old MediaTek driver (user's specific issue)
                if ($driver.DeviceName -match 'MediaTek' -and $driver.DriverDate) {
                    try {
                        $driverDate = [DateTime]::ParseExact($driver.DriverDate.Substring(0,8), 'yyyyMMdd', $null)
                        if ($driverDate.Year -le 2015) {
                            $adapterInfo.CriticalWarning = "OUTDATED DRIVER - MediaTek MT7612US driver from 2015 detected!"
                        }
                    } catch {}
                }
            }
        } catch {}
        
        $adapters += $adapterInfo
    }
    
    return $adapters
}

function Get-WindowsUpdateStatus {
    Write-Host "`n[*] Checking Windows Update status..." -ForegroundColor Cyan
    
    $updateStatus = @{
        LastSearchTime = "Unknown"
        PendingUpdates = 0
        Updates = @()
    }
    
    try {
        $session = New-Object -ComObject Microsoft.Update.Session
        $searcher = $session.CreateUpdateSearcher()
        
        $updateStatus.LastSearchTime = $searcher.GetTotalHistoryCount()
        
        $searchResult = $searcher.Search("IsInstalled=0")
        $updateStatus.PendingUpdates = $searchResult.Updates.Count
        
        foreach ($update in $searchResult.Updates) {
            $updateStatus.Updates += @{
                Title = $update.Title
                Description = $update.Description.Substring(0, [Math]::Min(100, $update.Description.Length))
                IsDownloaded = $update.IsDownloaded
            }
        }
    } catch {
        $updateStatus.Error = "Unable to query Windows Update: $_"
    }
    
    return $updateStatus
}

function Get-PerformanceMetrics {
    Write-Host "`n[*] Collecting performance metrics..." -ForegroundColor Cyan
    
    $metrics = @{
        CPU_Usage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        Memory_Usage = (Get-Counter '\Memory\% Committed Bytes In Use').CounterSamples.CookedValue
        Disk_QueueLength = (Get-Counter '\PhysicalDisk(_Total)\Current Disk Queue Length').CounterSamples.CookedValue
    }
    
    return $metrics
}

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Export functions
Export-ModuleMember -Function Get-SystemInventory, Get-RAMHealth, Get-DiskHealth, Get-TemperatureData, Get-DriverStatus, Get-StartupPrograms, Get-BackgroundProcesses, Get-NetworkAdapters, Get-WindowsUpdateStatus, Get-PerformanceMetrics, Test-AdminPrivileges
