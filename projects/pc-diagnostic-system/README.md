# 🖥️ PC Diagnostic & Optimization System

**Ultimate Windows PC diagnostic, optimization, and upgrade recommendation tool**

A comprehensive PowerShell-based system diagnostic tool designed to identify hardware issues, optimize system performance, and provide intelligent upgrade recommendations—especially for gaming and recording workloads.

## 🎯 Key Features

### 📊 Comprehensive Diagnostics
- **Hardware Inventory**: Complete CPU, RAM, GPU, motherboard, storage, and BIOS information
- **Health Monitoring**: 
  - RAM health with WHEA error detection (detects failing hardware)
  - Disk health (SMART status, bad sectors)
  - Temperature monitoring with threshold alerts
  - Driver version checking
- **Performance Analysis**: Real-time CPU, memory, and disk usage metrics
- **Event Log Analysis**: Automatic parsing for hardware errors and crashes
- **Network Analysis**: Adapter enumeration with driver compatibility checks
- **Startup Programs**: Identifies resource-heavy auto-start applications

### 🎮 Gaming & Recording Optimization
- **Recording-Specific Features**:
  - 120fps recording capability analysis
  - Bitrate recommendations based on hardware
  - NVIDIA NVENC/AMD VCE encoder detection
  - Storage write speed requirements
  - RAM allocation recommendations
- **Performance Optimizations**:
  - Windows Game Mode enablement
  - Hardware GPU scheduling
  - Visual effects optimization
  - Power plan configuration
  - Network optimization

### ⚡ Intelligent Upgrade Recommendations
- **Bottleneck Analysis**: Identifies CPU/GPU pairing issues
- **Component Recommendations**:
  - RAM: Upgrade paths with cost estimates (critical for recording)
  - GPU: Budget-tier recommendations for 120fps gaming + recording
  - Storage: NVMe SSD recommendations for recording workloads
  - PSU: Power requirement calculations
  - Cooling: Solutions based on detected temperatures
- **Budget Tiers**: Budget, Mid-Range, High-End options
- **Compatibility Checks**: Ensures recommended hardware works together

### 🛠️ Automated Optimizations
- **Safe System Cleanup**:
  - Temporary file removal
  - Windows Update cache cleanup
  - Startup program management
  - Windows services optimization
- **Performance Tuning**:
  - Page file optimization (16-32GB for recording)
  - High performance power plan
  - Network settings (DNS, throttling)
  - Disk optimization (TRIM for SSDs, defrag for HDDs)
- **Safety Features**:
  - Automatic restore point creation
  - Registry backups
  - User confirmation prompts
  - WhatIf mode for previewing changes

### 📈 Professional Reporting
- **HTML Report**: Beautiful, interactive report with:
  - Executive summary highlighting critical issues
  - Performance scores (gaming, recording, multitasking)
  - Hardware inventory tables
  - Color-coded priority system
  - Upgrade recommendations with pricing
  - Before/after metrics
- **JSON Export**: Structured data for automation and integration

## 🚨 Critical Issue Detection

This tool is designed to detect and alert you to critical hardware failures:

### ⚠️ RAM Failure Detection
The system specifically checks for **WHEA-Logger Event ID 46/47** errors that indicate physical RAM failure:
- Scans Windows Event Logs for hardware errors
- Identifies memory-related critical errors
- Provides immediate alerts and replacement recommendations
- **This is critical for systems experiencing crashes, recording failures, and game crashes**

### 🔧 Other Critical Checks
- Outdated drivers (e.g., MediaTek MT7612US WiFi from 2015)
- Overheating components (CPU/GPU temperature monitoring)
- Disk failures (SMART status warnings)
- Insufficient RAM for workload (recording at 120fps)
- Power supply inadequacy for hardware

## 📋 Requirements

- **Operating System**: Windows 10/11
- **PowerShell**: Version 5.1 or higher
- **Privileges**: Administrator rights recommended (required for optimizations)
- **Disk Space**: ~50MB for reports and temporary files

## 🚀 Quick Start

### 1. Download and Extract
```powershell
# Clone or download the repository
git clone https://github.com/haziqachik/network-engineer-portfolio.git
cd network-engineer-portfolio/projects/pc-diagnostic-system
```

### 2. Run the Diagnostic Tool

**Full Diagnostic + Optimization (Recommended)**
```powershell
# Run as Administrator (Right-click PowerShell → Run as Administrator)
.\PC-Diagnostic.ps1
```

**Diagnostic Only (No Changes)**
```powershell
.\PC-Diagnostic.ps1 -Mode Diagnostic
```

**Preview Changes (WhatIf Mode)**
```powershell
.\PC-Diagnostic.ps1 -WhatIf
```

**Optimization Only**
```powershell
.\PC-Diagnostic.ps1 -Mode Optimize
```

**Non-Interactive Mode**
```powershell
.\PC-Diagnostic.ps1 -Interactive:$false
```

## 📖 Usage Examples

### Example 1: First-Time System Diagnosis
```powershell
# Run as Administrator
.\PC-Diagnostic.ps1 -Mode Diagnostic

# Reviews:
# - Complete hardware inventory
# - Checks for WHEA errors (failing RAM)
# - Analyzes bottlenecks
# - Provides upgrade recommendations
# - Generates HTML report
```

### Example 2: Optimize for Recording Performance
```powershell
# Run as Administrator
.\PC-Diagnostic.ps1 -Mode Full

# Performs:
# - Full system diagnostic
# - Creates restore point
# - Cleans temporary files
# - Optimizes page file (16-32GB for recording)
# - Enables Game Mode and GPU scheduling
# - Sets High Performance power plan
# - Generates before/after report
```

### Example 3: Preview All Changes
```powershell
.\PC-Diagnostic.ps1 -WhatIf

# Shows what would be changed without making any modifications
# Perfect for understanding impact before running
```

## 📊 Understanding the Reports

### HTML Report Sections

1. **Executive Summary**
   - Critical issues highlighted first (RAM failures, old drivers)
   - Immediate action items
   - Overall system health

2. **Performance Scores**
   - Gaming Performance (0-100)
   - Recording Performance (0-100)
   - Multitasking Performance (0-100)

3. **Hardware Inventory**
   - Complete component list with specifications
   - Current RAM usage visualization
   - GPU VRAM details

4. **Bottleneck Analysis**
   - Component-by-component analysis
   - Priority-coded recommendations
   - Current vs. recommended specs

5. **Upgrade Recommendations**
   - RAM: Upgrade paths with costs
   - GPU: Options for 120fps recording
   - Storage: NVMe recommendations for recording
   - PSU: Power calculations
   - Cooling: Solutions based on temps

6. **Optimization Results**
   - List of all optimizations applied
   - Space freed, services disabled
   - Performance improvements

7. **Disk & Network Health**
   - Drive capacity and free space
   - Network adapter status
   - Driver versions and warnings

### Priority Levels

- 🔴 **CRITICAL**: Immediate action required (failing hardware, severe bottlenecks)
- 🟠 **HIGH**: Strongly recommended (old drivers, insufficient RAM for workload)
- 🔵 **MEDIUM**: Recommended for better performance
- 🟢 **LOW**: Optional improvements

## 🎯 Specific Use Cases

### For Recording at 120fps (User's Scenario)

The tool is optimized for this exact use case:

**What it checks:**
- RAM: Minimum 32GB recommended for 120fps recording + gaming
- GPU: NVENC encoder support for efficient recording
- Storage: Write speed requirements for high bitrate recording
- CPU: Multi-core performance for simultaneous gaming + encoding
- Page File: Configures 16-32GB virtual memory

**Critical for your scenario:**
- ✅ Detects failing RAM (WHEA errors)
- ✅ Recommends bitrate based on storage speed
- ✅ Identifies old WiFi drivers (MediaTek MT7612US)
- ✅ Optimizes committed memory settings
- ✅ Prevents recording crashes and frame drops

### For General Gaming

**Optimizations applied:**
- Game Mode enabled
- Hardware GPU scheduling
- High performance power plan
- Visual effects reduced
- Background processes minimized

### For Content Creation

**Focus on:**
- Multi-core CPU utilization
- RAM capacity for editing
- Storage speed for project files
- GPU encoder quality

## ⚙️ Configuration

Edit `config/config.json` to customize:

```json
{
  "temperature_thresholds": {
    "cpu_warning": 70,
    "cpu_critical": 85
  },
  "optimization": {
    "create_restore_point": true,
    "require_confirmation": true
  },
  "upgrade_recommendations": {
    "budget_tiers": {
      "budget": 300,
      "mid_range": 800,
      "high_end": 2000
    }
  }
}
```

## 🛡️ Safety Features

### Before Making Changes
- ✅ Creates system restore point automatically
- ✅ Backs up registry before modifications
- ✅ Requests user confirmation for optimizations
- ✅ WhatIf mode to preview all changes

### Rollback Options
If something goes wrong:
```powershell
# Restore to previous state
rstrui.exe  # Opens System Restore GUI

# Or via PowerShell
Get-ComputerRestorePoint | Select-Object -First 1 | Restore-Computer
```

## 🔧 Troubleshooting

### "Execution Policy" Error
```powershell
# Run this first (as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Module not found" Error
Ensure you're running from the correct directory:
```powershell
cd path\to\pc-diagnostic-system
.\PC-Diagnostic.ps1
```

### "Access Denied" Errors
Run PowerShell as Administrator:
- Right-click PowerShell icon
- Select "Run as Administrator"

### Temperature Monitoring Not Working
Some systems don't expose temperature via WMI. The tool will note this in the report but continue with other diagnostics.

## 📁 File Structure

```
pc-diagnostic-system/
│
├── PC-Diagnostic.ps1           # Main launcher script
├── README.md                   # This file
│
├── config/
│   └── config.json             # Configuration settings
│
├── modules/
│   ├── DiagnosticModule.ps1    # Hardware inventory & health checks
│   ├── OptimizationModule.ps1  # System optimization functions
│   ├── RecommendationModule.ps1 # Upgrade recommendation engine
│   └── ReportingModule.ps1     # HTML/JSON report generation
│
├── reports/                    # Generated reports (created at runtime)
│   ├── PC-Diagnostic-Report_[timestamp].html
│   └── PC-Diagnostic-Report_[timestamp].json
│
└── docs/                       # Additional documentation
```

## 🤝 Integration with Portfolio

This project demonstrates:
- **PowerShell Expertise**: Advanced WMI queries, error handling, module design
- **System Administration**: Hardware diagnostics, optimization, troubleshooting
- **Automation**: Complete diagnostic workflow automation
- **User Experience**: Interactive CLI, beautiful HTML reports
- **Problem Solving**: Addressed real-world issues (RAM failures, recording crashes)

## 📝 Example Output

```
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║        🖥️  PC DIAGNOSTIC & OPTIMIZATION SYSTEM v1.0.0  💻           ║
║                                                                       ║
║  Comprehensive hardware analysis, optimization, and upgrade advice   ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝

✓ Running with Administrator privileges

[*] Loading diagnostic modules...
  [✓] Loaded: DiagnosticModule.ps1
  [✓] Loaded: OptimizationModule.ps1
  [✓] Loaded: RecommendationModule.ps1
  [✓] Loaded: ReportingModule.ps1

===========================================================================
PHASE 1: SYSTEM DIAGNOSTICS
===========================================================================

[*] Collecting system inventory...
[*] Checking RAM health and errors...
  [*] Scanning event logs for WHEA errors (RAM failures)...
  [!] CRITICAL: Found 15 WHEA hardware errors!
  [!] This indicates FAILING HARDWARE - likely RAM!
...

🔍 CRITICAL FINDINGS:
  ⚠️  FAILING RAM DETECTED - 15 WHEA errors
      ACTION REQUIRED: Replace RAM immediately!
  ⚠️  OUTDATED DRIVER: MediaTek WiFi driver from 2015
      ACTION: Update network driver

📊 Performance Scores:
  • Gaming: 75/100
  • Recording: 65/100
  • Multitasking: 70/100

✅ Analysis complete! Open the HTML report for detailed recommendations.
```

## 🔗 Related Resources

- [Windows Event Log Documentation](https://docs.microsoft.com/en-us/windows/win32/eventlog/)
- [PowerShell WMI Reference](https://docs.microsoft.com/en-us/powershell/scripting/samples/getting-wmi-objects)
- [OBS Recording Optimization Guide](https://obsproject.com/wiki/)
- [PC Part Compatibility Guide](https://pcpartpicker.com/)

## 📜 License

This project is part of a network engineering portfolio and is provided as-is for educational and diagnostic purposes.

## 🙏 Acknowledgments

Designed to solve real-world issues experienced by content creators and gamers, particularly:
- Detecting failing hardware (RAM failures causing crashes)
- Optimizing for 120fps recording workloads
- Identifying driver compatibility issues
- Providing actionable upgrade recommendations

---

**Version**: 1.0.0  
**Author**: Network Engineering Portfolio Project  
**Last Updated**: 2025-11-10
