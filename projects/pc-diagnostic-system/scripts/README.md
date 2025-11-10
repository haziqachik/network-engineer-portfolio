# PC Diagnostic Scripts Collection

**Complete diagnostic and optimization toolkit for Windows PC troubleshooting**

This collection of specialized PowerShell scripts and batch launchers provides comprehensive diagnostics, optimization, and recommendations for PC hardware issues, particularly for systems experiencing RAM failures, crashes, and performance problems during gaming/recording.

---

## 📁 Scripts Overview

### 🚨 Emergency / Critical

#### `Emergency-Cleanup.ps1`
**Purpose:** Free RAM before recording/gaming sessions  
**Use When:** RAM usage >80% or before starting memory-intensive tasks

**Features:**
- Closes Chrome, Discord, Steam, and other memory-heavy processes
- Clears clipboard and standby memory
- Shows before/after RAM usage
- Alerts if RAM still >80% after cleanup
- Supports `-Force` parameter for non-interactive mode

**Usage:**
```powershell
.\Emergency-Cleanup.ps1              # Interactive mode
.\Emergency-Cleanup.ps1 -Force       # Non-interactive, close everything immediately
```

**When to Use:**
- Before starting recording sessions
- When RAM usage is critically high (>85%)
- Before launching games with high memory requirements
- When experiencing stuttering or slowdowns

---

#### `Quick-Health-Check.ps1`
**Purpose:** Fast system health check (under 30 seconds)  
**Use When:** Daily monitoring or quick system status check

**Features:**
- Checks for WHEA hardware errors
- Shows current RAM usage
- Lists recent crash dumps
- Checks disk space on all drives
- Shows top 5 memory consumers
- Displays only critical alerts

**Usage:**
```powershell
.\Quick-Health-Check.ps1
```

**Exit Codes:**
- `0` = System healthy
- `1` = Warnings detected
- `2` = Critical issues detected

**Recommended:** Run daily or after crashes/freezes

---

### 🔍 Diagnostics

#### `Analyze-Crashes.ps1`
**Purpose:** Comprehensive crash dump and WHEA error analysis  
**Use When:** Experiencing blue screens, crashes, or unexplained reboots

**Features:**
- Scans all minidump files
- Shows crash statistics (total, last 7 days, last 24 hours)
- Detects WHEA RAM/CPU errors
- Identifies crash patterns (time of day, day of week)
- Color-coded severity diagnosis
- Lists recent crash files with dates

**Usage:**
```powershell
.\Analyze-Crashes.ps1
```

**Severity Levels:**
- **CRITICAL:** 5+ crashes in 7 days or WHEA errors
- **HIGH:** 3-4 crashes in 7 days
- **MODERATE:** 1-2 crashes or multiple old dumps
- **NORMAL:** No significant issues

**What It Detects:**
- WHEA-Logger Event ID 46/47 (hardware failures)
- Blue Screen of Death (BSOD) events
- Unexpected shutdown events
- Memory-related crashes
- CPU/Bus/PCI errors

---

#### `Test-RAM.ps1`
**Purpose:** Interactive RAM testing guide and diagnostic scheduler  
**Use When:** WHEA errors detected or crashes suspected from RAM

**Features:**
- Detects installed RAM sticks (DIMM slots)
- Provides step-by-step testing instructions
- Can schedule Windows Memory Diagnostic
- Checks for WHEA errors specific to RAM
- Recommends which stick to remove/replace
- Shows replacement options

**Usage:**
```powershell
.\Test-RAM.ps1
```

**Testing Process:**
1. **Phase 1:** Run full system memory test with all RAM installed
2. **Phase 2:** If errors found, test each stick individually
3. **Phase 3:** Replace identified bad stick

**Critical for:**
- Systems with WHEA errors (indicates physical RAM failure)
- Frequent crashes during memory-intensive tasks
- Failed RAM is causing your 7 crashes in 10 days

---

#### `Monitor-Performance.ps1`
**Purpose:** Real-time performance monitoring with logging  
**Use When:** Troubleshooting performance issues or monitoring during gaming/recording

**Features:**
- Tracks CPU/RAM/GPU/Disk usage in real-time
- Alerts when RAM >90%
- Shows temperature if available
- Detects performance bottlenecks
- Logs data to CSV for trend analysis
- Color-coded output (green/yellow/red)

**Usage:**
```powershell
.\Monitor-Performance.ps1                                    # 60 seconds, live display
.\Monitor-Performance.ps1 -Duration 300                      # 5 minutes
.\Monitor-Performance.ps1 -Duration 120 -LogFile "perf.csv" # 2 min with logging
```

**Use During:**
- Gaming sessions to identify bottlenecks
- Recording to ensure resources are available
- Benchmarking system performance
- Troubleshooting stuttering or frame drops

---

### ⚙️ Optimization

#### `Optimize-Recording.ps1`
**Purpose:** Get optimal OBS/ShadowPlay settings for your hardware  
**Use When:** Setting up recording or changing recording quality

**Features:**
- Detects GPU (NVIDIA/AMD/Intel)
- Recommends encoder (NVENC, VCE, x264)
- Checks if system can handle target settings
- Provides specific OBS/ShadowPlay configurations
- Warns if RAM too low for target FPS
- Calculates optimal bitrate

**Usage:**
```powershell
.\Optimize-Recording.ps1                              # Default: 120 FPS, 15000 Kbps
.\Optimize-Recording.ps1 -TargetFPS 60 -Bitrate 8000  # 60 FPS, 8 Mbps
```

**Parameters:**
- `-TargetFPS`: Target recording frame rate (30-240, default: 120)
- `-Bitrate`: Target bitrate in Kbps (2500-50000, default: 15000)

**For Your System:**
- RTX 2070 SUPER has 6th gen NVENC (very good quality)
- System can handle 120fps IF RAM upgraded to 32GB
- Recommended bitrate for 1080p 120fps: 12000-15000 Kbps

---

#### `Auto-Fix-Issues.ps1`
**Purpose:** Automated system optimization (safe, creates restore point)  
**Use When:** Setting up new system or optimizing for gaming/recording

**Features:**
- Creates system restore point before changes
- Optimizes page file (1.5-3x RAM size)
- Sets High Performance power plan
- Disables unnecessary startup programs
- Optimizes Windows services
- Enables Game Mode
- Enables Hardware Accelerated GPU Scheduling
- Optimizes network settings (disables throttling)
- Cleans temporary files
- Updates Windows Defender definitions

**Usage:**
```powershell
.\Auto-Fix-Issues.ps1         # Apply all optimizations
.\Auto-Fix-Issues.ps1 -WhatIf # Preview changes only
```

**⚠️ Requirements:**
- Administrator privileges (REQUIRED)
- Creates restore point for safety
- Some changes require restart

**Safe Because:**
- Always creates restore point first
- All changes are standard Windows optimizations
- Can be reverted via System Restore
- WhatIf mode available

---

### 💰 Planning & Recommendations

#### `Get-UpgradeRecommendations.ps1`
**Purpose:** Hardware upgrade advisor with pricing and compatibility  
**Use When:** Planning hardware upgrades

**Features:**
- Analyzes current hardware (CPU/GPU/RAM/Storage)
- Detects bottlenecks specific to use case
- Recommends compatible RAM (DDR4 3200MHz for Ryzen 9)
- Suggests GPU upgrades with prices
- Checks motherboard compatibility
- Provides Amazon/Newegg search links
- Prioritizes recommendations (Critical/High/Medium/Low)

**Usage:**
```powershell
.\Get-UpgradeRecommendations.ps1                        # $500 budget, Both use case
.\Get-UpgradeRecommendations.ps1 -Budget 200            # $200 budget
.\Get-UpgradeRecommendations.ps1 -UseCase Recording     # Recording focus
.\Get-UpgradeRecommendations.ps1 -Budget 800 -UseCase Gaming  # Gaming focus
```

**Parameters:**
- `-Budget`: Available budget in USD (50-5000, default: 500)
- `-UseCase`: Primary use (Gaming, Recording, Both - default: Both)

**For Your System:**
- **CRITICAL:** Upgrade from 16GB to 32GB RAM (~$85-110)
- **OPTIONAL:** GPU upgrade (RTX 2070 SUPER still capable)
- **RECOMMENDED:** Add NVMe SSD for recording (~$65-95)

---

### 🎛️ Master Launcher

#### `Launch-All-Diagnostics.bat`
**Purpose:** Menu-driven interface to run any script  
**Use When:** Prefer GUI-style menu instead of command line

**Features:**
- Menu-driven interface
- Options to run any individual script
- Auto-detects admin privileges
- Sets execution policy automatically
- Option to run all diagnostics
- Can generate combined report
- Built-in help system

**Usage:**
```batch
Launch-All-Diagnostics.bat
```

**Menu Options:**
1. Emergency RAM Cleanup
2. Quick Health Check
3. Analyze Crashes
4. Test RAM
5. Monitor Performance
6. Optimize Recording Settings
7. Auto-Fix Issues
8. Get Upgrade Recommendations
9. Run All Diagnostics
0. Generate Combined Report
H. Help / Information

**Tip:** Right-click and "Run as Administrator" for full functionality

---

## 📖 Recommended Workflow

### For Systems with Failing RAM (Like Yours):

**Immediate Actions:**
```powershell
# 1. Run quick health check to confirm issues
.\Quick-Health-Check.ps1

# 2. Analyze crashes to identify patterns
.\Analyze-Crashes.ps1

# 3. Test RAM to identify bad stick
.\Test-RAM.ps1

# 4. Get upgrade recommendations
.\Get-UpgradeRecommendations.ps1 -Budget 200 -UseCase Recording
```

**Daily Maintenance (Until RAM Replaced):**
```powershell
# Before each recording/gaming session:
.\Emergency-Cleanup.ps1 -Force

# Weekly monitoring:
.\Quick-Health-Check.ps1
```

**After RAM Upgrade:**
```powershell
# Optimize system for new hardware:
.\Auto-Fix-Issues.ps1

# Verify RAM is working:
.\Quick-Health-Check.ps1
.\Test-RAM.ps1
```

---

### For General System Optimization:

```powershell
# 1. Initial diagnostics
.\Quick-Health-Check.ps1
.\Analyze-Crashes.ps1

# 2. If issues found, run auto-fix
.\Auto-Fix-Issues.ps1

# 3. Optimize for your use case
.\Optimize-Recording.ps1 -TargetFPS 120 -Bitrate 15000

# 4. Monitor to verify improvements
.\Monitor-Performance.ps1 -Duration 300 -LogFile "baseline.csv"
```

---

### For Recording Setup:

```powershell
# 1. Get optimal settings for hardware
.\Optimize-Recording.ps1 -TargetFPS 120 -Bitrate 15000

# 2. Optimize system
.\Auto-Fix-Issues.ps1

# 3. Before each session, free RAM
.\Emergency-Cleanup.ps1

# 4. Monitor during recording
.\Monitor-Performance.ps1 -Duration 600
```

---

## 🎯 Your Specific Situation

Based on your diagnostic results:
- **6 WHEA RAM hardware errors** → CRITICAL FAILURE
- **7 blue screen crashes in 10 days** → Hardware instability
- **91.8% RAM usage** → Insufficient for workload
- **System:** Ryzen 9 5900X, RTX 2070 SUPER, 16GB RAM

### Priority Actions (in order):

1. **IMMEDIATE - Run Test-RAM.ps1**
   ```powershell
   .\Test-RAM.ps1
   ```
   Identify which RAM stick is failing

2. **URGENT - Get Upgrade Plan**
   ```powershell
   .\Get-UpgradeRecommendations.ps1 -Budget 200 -UseCase Recording
   ```
   Get specific RAM upgrade recommendations

3. **DAILY - Before Recording/Gaming**
   ```powershell
   .\Emergency-Cleanup.ps1 -Force
   ```
   Free up RAM to prevent crashes

4. **MONITOR - Track System Health**
   ```powershell
   .\Quick-Health-Check.ps1
   ```
   Run daily to track stability

5. **AFTER RAM REPLACEMENT - Optimize**
   ```powershell
   .\Auto-Fix-Issues.ps1
   .\Optimize-Recording.ps1
   ```
   Configure system for new hardware

---

## 🔧 Troubleshooting

### "Execution Policy" Error
```powershell
# Run this as Administrator first:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Access Denied" Errors
- Right-click PowerShell
- Select "Run as Administrator"
- Re-run the script

### Scripts Not Found
Ensure you're in the scripts directory:
```powershell
cd path\to\pc-diagnostic-system\scripts
.\ScriptName.ps1
```

Or use full paths:
```powershell
.\path\to\scripts\ScriptName.ps1
```

### Temperature Monitoring Not Working
Some systems don't expose temperature via WMI. The scripts will note this but continue.

---

## 📊 Output Locations

All scripts generate output to:
- **Screen:** Color-coded console output
- **Reports:** `../reports/` directory (auto-created)
- **Logs:** User-specified paths for CSV data

Reports directory structure:
```
pc-diagnostic-system/
├── scripts/           (these scripts)
└── reports/           (generated reports)
    ├── Combined-Report_YYYYMMDD_HHMMSS.txt
    └── Performance-YYYYMMDD.csv
```

---

## ⚠️ Safety Features

All scripts include:
- ✅ Error handling with graceful failures
- ✅ Parameter validation
- ✅ Admin privilege checks (where needed)
- ✅ Color-coded output for clarity
- ✅ Progress indicators
- ✅ Helpful error messages
- ✅ WhatIf support (where applicable)
- ✅ Exit codes for automation

**Auto-Fix-Issues.ps1 specifically:**
- Creates system restore point BEFORE any changes
- All changes are reversible
- WhatIf mode available to preview
- Standard Windows optimizations only

---

## 🔗 Integration

These scripts complement the main PC-Diagnostic.ps1 tool by providing:
- **Focused solutions** for specific problems
- **Quick actions** for immediate needs
- **Specialized diagnostics** for deep-dive analysis
- **Automation-friendly** design with exit codes and parameters

---

## 📞 When to Use What

| Situation | Script to Run |
|-----------|--------------|
| About to start recording | `Emergency-Cleanup.ps1` |
| Computer crashed | `Analyze-Crashes.ps1` |
| Daily health check | `Quick-Health-Check.ps1` |
| WHEA errors detected | `Test-RAM.ps1` |
| Setting up OBS | `Optimize-Recording.ps1` |
| New PC or fresh Windows install | `Auto-Fix-Issues.ps1` |
| Planning upgrades | `Get-UpgradeRecommendations.ps1` |
| Investigating slowness | `Monitor-Performance.ps1` |
| Don't know what to run | `Launch-All-Diagnostics.bat` |

---

## 📄 Version Information

**Version:** 1.0.0  
**Author:** Network Engineering Portfolio  
**Last Updated:** 2025-11-10  
**Compatibility:** Windows 10/11, PowerShell 5.1+

---

## 🎓 Learning Resources

Understanding the diagnostics:
- [WHEA Errors Explained](https://docs.microsoft.com/en-us/windows-hardware/drivers/whea/)
- [Windows Memory Diagnostic Guide](https://support.microsoft.com/en-us/windows/windows-memory-diagnostic-tool)
- [OBS Recording Optimization](https://obsproject.com/wiki/GPU-overload-issues)
- [Hardware Compatibility](https://pcpartpicker.com/)

---

**⚠️ CRITICAL NOTE FOR YOUR SYSTEM:**

Your 6 WHEA RAM errors indicate **PHYSICAL HARDWARE FAILURE**. This is not a software issue. The RAM stick(s) are physically failing and **MUST BE REPLACED**. No amount of optimization or cleanup will fix this.

**Recommended immediate action:**
1. Run `Test-RAM.ps1` to identify the bad stick
2. Run `Get-UpgradeRecommendations.ps1` for replacement options
3. Order 32GB DDR4 3200MHz RAM (~$85-110)
4. Use `Emergency-Cleanup.ps1` daily until RAM arrives
5. After replacement, run `Auto-Fix-Issues.ps1` to optimize

The new 32GB RAM will:
- ✅ Eliminate crashes from failing hardware
- ✅ Provide enough memory for 120fps recording
- ✅ Allow Chrome + Discord + Game simultaneously
- ✅ Future-proof for 3-5 years
- ✅ Improve overall system stability

---

**Need help?** All scripts include built-in documentation accessible via:
```powershell
Get-Help .\ScriptName.ps1 -Full
```
