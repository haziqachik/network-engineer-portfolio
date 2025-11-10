# Changelog

All notable changes to the PC Diagnostic & Optimization System will be documented in this file.

## [1.0.0] - 2025-11-10

### Added

#### Core Features
- **Comprehensive Diagnostic Module**
  - Complete hardware inventory (CPU, RAM, GPU, Motherboard, Storage, Network)
  - RAM health checking with WHEA error detection for failing hardware
  - Disk health monitoring (SMART status, capacity, health indicators)
  - Temperature monitoring via WMI with threshold alerts
  - Driver version checking and age detection
  - Startup programs enumeration and analysis
  - Background process resource consumption monitoring
  - Network adapter and driver analysis
  - Windows Update status checking
  - Real-time performance metrics collection

- **Intelligent Upgrade Recommendations**
  - Bottleneck analysis (CPU/GPU pairing, RAM sufficiency)
  - RAM upgrade paths with budget tiers and compatibility checks
  - GPU recommendations for gaming and 120fps recording
  - Storage recommendations (NVMe for recording, SATA for archive)
  - PSU requirement calculations based on current and planned hardware
  - Cooling solution recommendations based on detected temperatures
  - Budget-tier options (Budget/Mid-Range/High-End)
  - Cost estimates for all recommended upgrades

- **System Optimization Module**
  - Automatic restore point creation before changes
  - Temporary file cleanup (Windows temp, cache, update files)
  - Startup program optimization and management
  - Windows services optimization for gaming/recording profiles
  - Page file optimization (16-32GB for recording workloads)
  - High Performance power plan activation
  - Visual effects optimization for performance
  - Windows Game Mode and GPU scheduling enablement
  - Network settings optimization (DNS, throttling)
  - Disk optimization (TRIM for SSDs, defrag for HDDs)

- **Advanced Reporting**
  - Professional HTML report generation with CSS styling
  - Executive summary with critical issues highlighted
  - Performance scoring (Gaming, Recording, Multitasking)
  - Color-coded priority system (Critical/High/Medium/Low)
  - Interactive hardware inventory tables
  - Bottleneck visualization
  - Upgrade recommendations with pricing
  - Before/after comparison metrics
  - JSON export for automation and integration

- **Recording & Gaming Optimization**
  - 120fps recording capability analysis
  - Bitrate calculator based on hardware
  - NVIDIA NVENC / AMD VCE encoder detection
  - Storage write speed requirements for various bitrates
  - RAM allocation recommendations for simultaneous gaming + recording
  - Game-specific optimizations (Valorant compatibility)
  - OBS settings recommendations

- **Critical Issue Detection**
  - **WHEA Error Detection**: Identifies failing RAM hardware (Event ID 46/47)
  - Old driver detection (e.g., MediaTek MT7612US from 2015)
  - Overheating component alerts
  - Insufficient resource warnings
  - Disk space and health alerts

#### Safety Features
- Automatic system restore point creation
- Registry backup before modifications
- User confirmation prompts for critical changes
- WhatIf mode for previewing changes without applying
- Admin privilege verification
- Rollback capability through restore points

#### User Experience
- Interactive CLI with color-coded output
- Progress indicators for long-running operations
- Helpful error messages and guidance
- Multiple operation modes (Diagnostic, Optimize, Full)
- Batch file launcher for easy execution
- Comprehensive README with examples

#### Documentation
- Main README.md with complete usage instructions
- Recording Optimization Guide (docs/RECORDING_OPTIMIZATION.md)
- Configuration guide (config/config.json)
- Troubleshooting section
- Example outputs and screenshots

### Technical Implementation

#### Architecture
- Modular PowerShell design with separate concerns:
  - `DiagnosticModule.ps1`: Hardware inventory and health
  - `OptimizationModule.ps1`: System optimization functions
  - `RecommendationModule.ps1`: Upgrade analysis engine
  - `ReportingModule.ps1`: HTML/JSON report generation
- JSON configuration for customization
- Export-ModuleMember for clean module interfaces
- Comprehensive error handling and logging

#### Compatibility
- Windows 10/11 support
- PowerShell 5.1+ compatibility
- WMI/CIM queries for hardware data
- COM object usage for Windows Update queries
- Registry access for startup programs and settings

### Known Limitations

1. **Temperature Monitoring**: Not all systems expose temperature via WMI
   - Workaround: Tool notes this in report and continues with other diagnostics

2. **SMART Data**: Some storage controllers don't support SMART queries
   - Workaround: Falls back to basic disk health status

3. **Admin Requirements**: Some optimizations require administrator privileges
   - Workaround: Tool detects privilege level and adapts

### Target Use Cases

1. **Content Creators**: Recording at high framerates (120fps+)
2. **Gamers**: System optimization for maximum FPS
3. **System Administrators**: Quick hardware diagnostics
4. **Upgrade Planning**: Intelligent component recommendations
5. **Troubleshooting**: Hardware failure detection (RAM, disks)

### Security Considerations

- Only safe, documented Windows optimizations
- No registry modifications to critical system keys
- No driver installations (only recommendations)
- Restore point creation before any changes
- WhatIf mode for validation before execution

### Performance Impact

- Diagnostic phase: 2-5 minutes (non-destructive)
- Optimization phase: 5-10 minutes (with user confirmation)
- Report generation: <1 minute
- Total runtime (Full mode): 10-15 minutes

### Future Enhancements (Planned)

- [ ] GPU temperature monitoring via GPU-specific APIs
- [ ] Automatic driver update downloads
- [ ] Network speed testing integration
- [ ] Scheduled monitoring task creation
- [ ] Email report delivery
- [ ] Cloud price API integration for real-time hardware costs
- [ ] Benchmark integration (3DMark, Cinebench)
- [ ] Multiple report format exports (PDF, Markdown)

---

## Version Numbering

This project follows Semantic Versioning (SemVer):
- **Major**: Incompatible API changes or major feature overhauls
- **Minor**: New features, backwards compatible
- **Patch**: Bug fixes, backwards compatible
