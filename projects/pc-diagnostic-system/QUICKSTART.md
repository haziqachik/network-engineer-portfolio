# Quick Start Guide

## 🚀 Getting Started in 3 Steps

### Step 1: Open as Administrator
Right-click on `Launch-Diagnostic.bat` → "Run as Administrator"

### Step 2: Choose Mode
```
1. Full Diagnostic + Optimization (Recommended)
2. Diagnostic Only (No changes)
3. Preview Changes (WhatIf mode)
```

### Step 3: Review Report
Open the generated HTML report in your browser for complete analysis.

---

## 💡 Common Commands

### Full Diagnostic + Optimization
```powershell
.\PC-Diagnostic.ps1
```

### Diagnostic Only (Safe Mode)
```powershell
.\PC-Diagnostic.ps1 -Mode Diagnostic
```

### Preview All Changes
```powershell
.\PC-Diagnostic.ps1 -WhatIf
```

### Non-Interactive Mode
```powershell
.\PC-Diagnostic.ps1 -Interactive:$false
```

---

## 🎯 What Gets Checked?

✅ **Hardware Health**
- RAM (WHEA error detection for failures)
- Disk health (SMART status)
- Temperatures
- Drivers (age and compatibility)

✅ **Performance**
- CPU/GPU bottlenecks
- RAM sufficiency for workload
- Storage speed requirements

✅ **Optimization Opportunities**
- Temp files to clean
- Unnecessary startup programs
- Windows services to disable
- Page file configuration

---

## ⚠️ Critical Alerts

The tool specifically detects:

1. **Failing RAM** (WHEA errors) → Replace immediately
2. **Old Drivers** (2+ years) → Update recommended
3. **Overheating** (>85°C) → Check cooling
4. **Low Disk Space** (>85% full) → Clean or upgrade

---

## 📊 Report Location

After running, find reports in:
```
projects/pc-diagnostic-system/reports/
├── PC-Diagnostic-Report_[timestamp].html  ← Open this
└── PC-Diagnostic-Report_[timestamp].json
```

---

## 🛡️ Safety Features

- Creates restore point before changes
- Requires confirmation for optimizations
- WhatIf mode available
- All changes are reversible

---

## ❓ Troubleshooting

**"Execution Policy" Error**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**"Access Denied" Errors**
→ Run as Administrator

**Temperature Not Showing**
→ Normal on some systems, tool continues anyway

---

## 📖 Full Documentation

See `README.md` for:
- Complete feature list
- Detailed usage examples
- Configuration options
- Troubleshooting guide

See `docs/RECORDING_OPTIMIZATION.md` for:
- 120fps recording optimization
- OBS settings
- Hardware recommendations

---

## 🎮 Specific Use Cases

### For Recording at 120fps
```powershell
# Run full optimization for recording
.\PC-Diagnostic.ps1 -Mode Full

# Check recommendations section for:
# - RAM upgrade needs (32GB recommended)
# - NVENC encoder detection
# - Bitrate recommendations
# - Storage write speed requirements
```

### For Gaming Performance
```powershell
# Diagnostic + Gaming optimizations
.\PC-Diagnostic.ps1 -Mode Full

# Enables:
# - Game Mode
# - High Performance power plan
# - Visual effects optimization
# - Startup program cleanup
```

### For System Health Check
```powershell
# Diagnostic only, no changes
.\PC-Diagnostic.ps1 -Mode Diagnostic

# Perfect for:
# - Monthly health checks
# - Pre-upgrade planning
# - Hardware failure detection
```

---

**Version**: 1.0.0  
**Questions?** See README.md or open an issue on GitHub
