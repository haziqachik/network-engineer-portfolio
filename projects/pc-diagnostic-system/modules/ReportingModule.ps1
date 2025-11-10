# PC Reporting Module
# Generate comprehensive HTML and JSON reports

function New-HTMLReport {
    param(
        [object]$DiagnosticData,
        [object]$Recommendations,
        [object]$OptimizationResults,
        [string]$OutputPath = ".\reports\PC-Diagnostic-Report.html"
    )
    
    Write-Host "`n[*] Generating HTML report..." -ForegroundColor Cyan
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $computerName = $env:COMPUTERNAME
    
    # Build HTML content
    $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PC Diagnostic Report - $computerName</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            color: #333;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header p { font-size: 1.1em; opacity: 0.9; }
        .section {
            padding: 30px 40px;
            border-bottom: 1px solid #e0e0e0;
        }
        .section:last-child { border-bottom: none; }
        .section h2 {
            color: #667eea;
            font-size: 1.8em;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
        }
        .section h2::before {
            content: '';
            width: 5px;
            height: 30px;
            background: #667eea;
            margin-right: 15px;
            border-radius: 3px;
        }
        .alert {
            padding: 20px;
            margin: 15px 0;
            border-radius: 8px;
            border-left: 5px solid;
            font-weight: 500;
        }
        .alert-critical {
            background: #fee;
            border-color: #d00;
            color: #d00;
        }
        .alert-high {
            background: #fff3cd;
            border-color: #ff9800;
            color: #856404;
        }
        .alert-medium {
            background: #cfe2ff;
            border-color: #0d6efd;
            color: #084298;
        }
        .alert-low {
            background: #d1e7dd;
            border-color: #198754;
            color: #0f5132;
        }
        .alert-success {
            background: #d1e7dd;
            border-color: #198754;
            color: #0f5132;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            border: 1px solid #e0e0e0;
        }
        .card h3 {
            color: #495057;
            margin-bottom: 15px;
            font-size: 1.2em;
        }
        .card-value {
            font-size: 2em;
            font-weight: bold;
            color: #667eea;
            margin: 10px 0;
        }
        .card-label {
            color: #6c757d;
            font-size: 0.9em;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #e0e0e0;
        }
        th {
            background: #f8f9fa;
            color: #495057;
            font-weight: 600;
        }
        tr:hover { background: #f8f9fa; }
        .badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 600;
        }
        .badge-critical { background: #d00; color: white; }
        .badge-high { background: #ff9800; color: white; }
        .badge-medium { background: #0d6efd; color: white; }
        .badge-low { background: #198754; color: white; }
        .progress-bar {
            width: 100%;
            height: 25px;
            background: #e0e0e0;
            border-radius: 15px;
            overflow: hidden;
            margin: 10px 0;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            transition: width 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
        }
        .score-container {
            display: flex;
            justify-content: space-around;
            margin: 30px 0;
        }
        .score-circle {
            text-align: center;
        }
        .score-value {
            width: 120px;
            height: 120px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 2em;
            font-weight: bold;
            margin: 0 auto 10px;
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        .checklist {
            list-style: none;
            margin: 20px 0;
        }
        .checklist li {
            padding: 10px;
            margin: 5px 0;
            background: #f8f9fa;
            border-radius: 5px;
            display: flex;
            align-items: center;
        }
        .checklist li::before {
            content: '✓';
            margin-right: 10px;
            color: #198754;
            font-weight: bold;
            font-size: 1.2em;
        }
        .footer {
            background: #f8f9fa;
            padding: 20px 40px;
            text-align: center;
            color: #6c757d;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🖥️ PC Diagnostic Report</h1>
            <p>Computer: $computerName | Generated: $timestamp</p>
        </div>
"@
    
    # Executive Summary Section
    $htmlContent += @"
        <div class="section">
            <h2>📋 Executive Summary</h2>
"@
    
    # Critical Issues
    $criticalIssues = @()
    
    if ($DiagnosticData.RAM.WHEAErrors.Count -gt 0) {
        $criticalIssues += @"
            <div class="alert alert-critical">
                <strong>⚠️ CRITICAL: FAILING RAM DETECTED</strong><br>
                Found $($DiagnosticData.RAM.WHEAErrors.Count) WHEA hardware errors indicating physical RAM failure.<br>
                <strong>Action Required:</strong> Replace RAM immediately to prevent data loss and system crashes.
            </div>
"@
    }
    
    # Check for old drivers
    $oldDrivers = $DiagnosticData.Drivers | Where-Object {$_.Warning}
    if ($oldDrivers) {
        foreach ($driver in $oldDrivers) {
            if ($driver.DeviceName -match 'MediaTek') {
                $criticalIssues += @"
            <div class="alert alert-high">
                <strong>⚠️ OUTDATED DRIVER: $($driver.DeviceName)</strong><br>
                Driver version: $($driver.DriverVersion) from $($driver.DriverDate.Substring(0,4))<br>
                <strong>Action Required:</strong> Update to latest driver for stability and performance.
            </div>
"@
            }
        }
    }
    
    if ($criticalIssues.Count -eq 0) {
        $htmlContent += '<div class="alert alert-success">✓ No critical hardware failures detected</div>'
    } else {
        $htmlContent += $criticalIssues -join "`n"
    }
    
    $htmlContent += "</div>"
    
    # Performance Scores Section
    if ($Recommendations.Bottleneck) {
        $scores = $Recommendations.Bottleneck.PerformanceScore
        $htmlContent += @"
        <div class="section">
            <h2>📊 Performance Scores</h2>
            <div class="score-container">
                <div class="score-circle">
                    <div class="score-value">$([math]::Round($scores.Gaming))</div>
                    <div class="card-label">Gaming Performance</div>
                </div>
                <div class="score-circle">
                    <div class="score-value">$([math]::Round($scores.Recording))</div>
                    <div class="card-label">Recording Performance</div>
                </div>
                <div class="score-circle">
                    <div class="score-value">$([math]::Round($scores.Multitasking))</div>
                    <div class="card-label">Multitasking Performance</div>
                </div>
            </div>
        </div>
"@
    }
    
    # Hardware Inventory Section
    $htmlContent += @"
        <div class="section">
            <h2>💻 Hardware Inventory</h2>
            <div class="grid">
                <div class="card">
                    <h3>Processor</h3>
                    <div class="card-label">$($DiagnosticData.Inventory.CPU.Name)</div>
                    <div class="card-value">$($DiagnosticData.Inventory.CPU.NumberOfCores)</div>
                    <div class="card-label">Cores / $($DiagnosticData.Inventory.CPU.NumberOfLogicalProcessors) Threads</div>
                </div>
                <div class="card">
                    <h3>Memory (RAM)</h3>
                    <div class="card-value">$($DiagnosticData.RAM.TotalRAM_GB) GB</div>
                    <div class="card-label">Available: $($DiagnosticData.RAM.AvailableRAM_GB) GB</div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: $($DiagnosticData.RAM.UsagePercent)%">
                            $($DiagnosticData.RAM.UsagePercent)% Used
                        </div>
                    </div>
                </div>
                <div class="card">
                    <h3>Graphics Card</h3>
                    <div class="card-label">$($DiagnosticData.Inventory.GPU.Name)</div>
                    <div class="card-value">$([math]::Round($DiagnosticData.Inventory.GPU.AdapterRAM / 1GB, 1)) GB</div>
                    <div class="card-label">VRAM</div>
                </div>
            </div>
        </div>
"@
    
    # Bottleneck Analysis
    if ($Recommendations.Bottleneck.Bottlenecks.Count -gt 0) {
        $htmlContent += @"
        <div class="section">
            <h2>🔍 Bottleneck Analysis</h2>
            <table>
                <thead>
                    <tr>
                        <th>Component</th>
                        <th>Issue</th>
                        <th>Current</th>
                        <th>Recommended</th>
                        <th>Priority</th>
                    </tr>
                </thead>
                <tbody>
"@
        foreach ($bottleneck in $Recommendations.Bottleneck.Bottlenecks) {
            $badgeClass = "badge-" + $bottleneck.Severity.ToLower()
            $htmlContent += @"
                    <tr>
                        <td><strong>$($bottleneck.Component)</strong></td>
                        <td>$($bottleneck.Issue)</td>
                        <td>$($bottleneck.CurrentSpec)</td>
                        <td>$($bottleneck.Recommendation)</td>
                        <td><span class="badge $badgeClass">$($bottleneck.Severity)</span></td>
                    </tr>
"@
        }
        $htmlContent += @"
                </tbody>
            </table>
        </div>
"@
    }
    
    # Upgrade Recommendations
    $htmlContent += @"
        <div class="section">
            <h2>⬆️ Upgrade Recommendations</h2>
"@
    
    if ($Recommendations.RAM) {
        $ramRec = $Recommendations.RAM
        $priorityClass = "alert-" + $ramRec.Priority.ToLower()
        
        if ($ramRec.CriticalWarning) {
            $htmlContent += @"
            <div class="alert alert-critical">
                <strong>$($ramRec.CriticalWarning)</strong><br>
                $($ramRec.Reason)
            </div>
"@
        }
        
        if ($ramRec.Options.Count -gt 0) {
            $htmlContent += "<h3>RAM Upgrade Options</h3><table><thead><tr><th>Option</th><th>Configuration</th><th>Speed</th><th>Cost</th><th>Pros/Cons</th></tr></thead><tbody>"
            foreach ($option in $ramRec.Options) {
                $htmlContent += @"
                <tr>
                    <td><strong>$($option.Type)</strong></td>
                    <td>$($option.Configuration)</td>
                    <td>$($option.Speed)</td>
                    <td>`$$($option.EstimatedCost)</td>
                    <td>✓ $($option.Pros)<br>✗ $($option.Cons)</td>
                </tr>
"@
            }
            $htmlContent += "</tbody></table>"
        }
    }
    
    if ($Recommendations.GPU) {
        $htmlContent += @"
            <h3>GPU Upgrade Recommendations</h3>
            <div class="alert alert-medium">
                $($Recommendations.GPU.EncoderAnalysis)
            </div>
            <div class="card">
                <h3>Best for 120fps Recording</h3>
                <strong>$($Recommendations.GPU.BestForRecording.Primary)</strong><br>
                $($Recommendations.GPU.BestForRecording.Reason)<br>
                <strong>Estimated Cost:</strong> $($Recommendations.GPU.BestForRecording.EstimatedCost)<br>
                <strong>Power Requirement:</strong> $($Recommendations.GPU.BestForRecording.PowerRequirement)
            </div>
"@
    }
    
    if ($Recommendations.Storage) {
        $htmlContent += @"
            <h3>Storage Recommendations</h3>
            <pre style="background: #f8f9fa; padding: 15px; border-radius: 5px;">$($Recommendations.Storage.RecordingStorageNeeds)</pre>
"@
    }
    
    $htmlContent += "</div>"
    
    # Optimization Results
    if ($OptimizationResults) {
        $htmlContent += @"
        <div class="section">
            <h2>⚡ Optimizations Applied</h2>
            <ul class="checklist">
"@
        foreach ($result in $OptimizationResults) {
            $htmlContent += "<li>$result</li>`n"
        }
        $htmlContent += @"
            </ul>
        </div>
"@
    }
    
    # Disk Health
    if ($DiagnosticData.Disk) {
        $htmlContent += @"
        <div class="section">
            <h2>💾 Disk Health</h2>
            <table>
                <thead>
                    <tr>
                        <th>Drive</th>
                        <th>Type</th>
                        <th>Size</th>
                        <th>Free Space</th>
                        <th>Health</th>
                    </tr>
                </thead>
                <tbody>
"@
        foreach ($disk in $DiagnosticData.Disk) {
            if ($disk.DriveLetter) {
                $healthBadge = if ($disk.UsedPercent -gt 90) { "badge-critical" } elseif ($disk.UsedPercent -gt 80) { "badge-high" } else { "badge-low" }
                $htmlContent += @"
                    <tr>
                        <td><strong>$($disk.DriveLetter):\</strong></td>
                        <td>$($disk.FileSystem)</td>
                        <td>$($disk.Size_GB) GB</td>
                        <td>$($disk.FreeSpace_GB) GB</td>
                        <td><span class="badge $healthBadge">$($disk.UsedPercent)% Used</span></td>
                    </tr>
"@
            }
        }
        $htmlContent += @"
                </tbody>
            </table>
        </div>
"@
    }
    
    # Network Adapters
    if ($DiagnosticData.Network) {
        $htmlContent += @"
        <div class="section">
            <h2>🌐 Network Adapters</h2>
            <table>
                <thead>
                    <tr>
                        <th>Adapter</th>
                        <th>Status</th>
                        <th>Speed</th>
                        <th>Driver</th>
                    </tr>
                </thead>
                <tbody>
"@
        foreach ($adapter in $DiagnosticData.Network) {
            $warning = if ($adapter.CriticalWarning) { "<br><span class='badge badge-critical'>$($adapter.CriticalWarning)</span>" } else { "" }
            $htmlContent += @"
                    <tr>
                        <td><strong>$($adapter.Name)</strong>$warning</td>
                        <td>$($adapter.Status)</td>
                        <td>$($adapter.LinkSpeed)</td>
                        <td>$($adapter.DriverVersion)</td>
                    </tr>
"@
        }
        $htmlContent += @"
                </tbody>
            </table>
        </div>
"@
    }
    
    # Close HTML
    $htmlContent += @"
        <div class="footer">
            <p>Report generated by PC Diagnostic & Optimization System v1.0</p>
            <p>For optimal recording at 120fps, ensure adequate RAM, dedicated recording SSD, and proper cooling.</p>
        </div>
    </div>
</body>
</html>
"@
    
    # Save HTML file
    try {
        $reportDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $reportDir)) {
            New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
        }
        
        $htmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "  [✓] HTML report saved: $OutputPath" -ForegroundColor Green
        
        return $OutputPath
    } catch {
        Write-Host "  [!] Failed to save HTML report: $_" -ForegroundColor Red
        return $null
    }
}

function Export-JSONReport {
    param(
        [object]$DiagnosticData,
        [object]$Recommendations,
        [string]$OutputPath = ".\reports\PC-Diagnostic-Report.json"
    )
    
    Write-Host "`n[*] Exporting JSON report..." -ForegroundColor Cyan
    
    $jsonData = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ComputerName = $env:COMPUTERNAME
        Diagnostics = $DiagnosticData
        Recommendations = $Recommendations
    }
    
    try {
        $reportDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $reportDir)) {
            New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
        }
        
        $jsonData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "  [✓] JSON report saved: $OutputPath" -ForegroundColor Green
        
        return $OutputPath
    } catch {
        Write-Host "  [!] Failed to save JSON report: $_" -ForegroundColor Red
        return $null
    }
}

# Export functions
Export-ModuleMember -Function New-HTMLReport, Export-JSONReport
