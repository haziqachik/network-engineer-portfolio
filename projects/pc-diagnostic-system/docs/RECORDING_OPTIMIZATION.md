# Recording Optimization Guide

## 🎥 Optimizing for 120fps Recording

This guide specifically addresses optimal settings for recording gameplay at 120fps while maintaining smooth gaming performance.

### Critical Hardware Requirements

#### Minimum Specs for 120fps Recording + Gaming
- **RAM**: 32GB (16GB absolute minimum, but may cause issues)
- **CPU**: 8+ cores / 16+ threads (for simultaneous gaming + encoding)
- **GPU**: RTX 3060 or better (NVENC encoder)
- **Storage**: NVMe SSD dedicated to recordings (3000+ MB/s write speed)
- **PSU**: 650W+ (depending on GPU)

#### Why These Specs Matter
1. **RAM (32GB)**:
   - Game: 6-8GB
   - Recording software: 2-4GB
   - Windows + background: 4-6GB
   - Recording buffer: 8-12GB
   - **Total**: 20-30GB during active recording

2. **Dedicated Recording SSD**:
   - At 20,000 Kbps bitrate: ~9GB/hour
   - Prevents stuttering in game
   - Avoids disk bottleneck during intense scenes

3. **NVENC Encoder (NVIDIA GPU)**:
   - Hardware encoding offloads CPU
   - Minimal performance impact (2-5 fps)
   - Better quality than x264 at same bitrate

### CRITICAL Issue: RAM Failure

**Your Specific Problem:**
```
Event ID: 46 - WHEA-Logger
Component: Memory
Error Source: Machine Check Exception
```

**What This Means:**
- Physical RAM module is failing
- Causes: Random crashes, recording failures, data corruption
- **Solution**: Replace RAM immediately - no software fix possible

**Temporary Workarounds Until Replacement:**
1. Reduce recording bitrate to 10,000 Kbps
2. Close all background apps
3. Disable browser hardware acceleration
4. Don't run Discord/Chrome while recording
5. Lower game graphics settings

### Recommended Bitrate Settings

Based on hardware capability:

| Resolution | FPS | Good Quality | Best Quality | Storage/Hour |
|------------|-----|--------------|--------------|--------------|
| 1080p      | 60  | 12,000 Kbps  | 16,000 Kbps  | 5.4 - 7.2 GB |
| 1080p      | 120 | 16,000 Kbps  | 20,000 Kbps  | 7.2 - 9.0 GB |
| 1440p      | 60  | 16,000 Kbps  | 24,000 Kbps  | 7.2 - 10.8 GB|
| 1440p      | 120 | 24,000 Kbps  | 32,000 Kbps  | 10.8 - 14.4 GB|

**Your Current Setup (12,000 Kbps @ 120fps):**
- ⚠️ Too low for 120fps - visible compression artifacts
- ✅ Safe for your storage speed
- **Recommended**: Increase to 16,000-20,000 Kbps after RAM replacement

### OBS Studio Settings (Recommended)

#### Output Settings
```
Output Mode: Advanced
Encoder: NVIDIA NVENC H.264 (if RTX GPU) or H.265 for better compression
Rate Control: CBR (Constant Bitrate)
Bitrate: 16,000 - 20,000 Kbps
Keyframe Interval: 2
Preset: Quality (or P5 if available)
Profile: high
Look-ahead: ON (if available)
Psycho Visual Tuning: ON
GPU: 0 (dedicated GPU)
Max B-frames: 2
```

#### Video Settings
```
Base Resolution: 1920x1080 (or your monitor resolution)
Output Resolution: 1920x1080
Downscale Filter: Lanczos (best quality, slightly more CPU)
FPS: 120 (if your monitor supports it)
```

#### Advanced Settings
```
Process Priority: Above Normal
Renderer: Direct3D 11
Color Format: NV12
Color Space: 709
Color Range: Partial
```

### Windows Optimizations

Run the diagnostic tool's optimization mode, which will:

1. **Page File Optimization**
   - Sets to 16GB-32GB (critical for your RAM situation)
   - Prevents "out of memory" errors during recording

2. **Power Plan**
   - High Performance mode
   - Prevents CPU throttling during long recordings

3. **Game Mode**
   - Prioritizes game + OBS processes
   - Reduces background interference

4. **Visual Effects**
   - Disables unnecessary animations
   - Frees up GPU resources

5. **Network Optimization**
   - Disables bandwidth throttling
   - Better for streaming (if you decide to stream later)

### MediaTek WiFi Driver Issue

**Your Specific Problem:**
- MediaTek MT7612US driver from 2015
- Known to cause instability and disconnects

**Fix:**
1. Visit MediaTek's website or your USB adapter manufacturer
2. Download latest driver (should be 2020+ version)
3. Uninstall old driver via Device Manager
4. Install new driver
5. Restart PC

**Alternative:** Consider upgrading to:
- PCIe WiFi card (more stable)
- Ethernet connection (best for gaming/recording)

### Recording Best Practices

#### Before Recording Session
1. ✅ Close unnecessary apps (Chrome, Discord, etc.)
2. ✅ Disable automatic Windows updates
3. ✅ Clean temp files (use diagnostic tool)
4. ✅ Check available disk space (50GB+ free)
5. ✅ Verify OBS preview shows no dropped frames

#### During Recording
1. ✅ Monitor temps (should stay under 80°C)
2. ✅ Watch OBS stats for dropped frames
3. ✅ Keep Task Manager open on 2nd monitor (if available)
4. ✅ Don't tab out frequently (causes stutters)

#### After Recording
1. ✅ Move recordings to archive drive
2. ✅ Clear OBS logs if no issues
3. ✅ Check Event Viewer for WHEA errors

### Troubleshooting Recording Issues

#### Stuttering/Frame Drops in Recording
**Causes:**
- Disk write speed too slow
- RAM maxed out
- GPU encoder overloaded

**Solutions:**
- Lower bitrate by 20%
- Record to faster drive (NVMe)
- Close background apps
- Lower game graphics settings

#### Game FPS Drops While Recording
**Causes:**
- CPU encoder overload (if using x264)
- GPU encoder on wrong GPU
- Insufficient RAM

**Solutions:**
- Switch to NVENC (GPU encoder)
- Verify OBS using dedicated GPU
- Increase page file size
- Add more RAM (32GB recommended)

#### Recordings Become Unusable
**Causes:**
- **Failing RAM** (your current issue!)
- Disk errors
- OBS crashes

**Solutions:**
- Replace RAM (priority #1)
- Run `chkdsk /f` on recording drive
- Update OBS to latest version
- Check OBS crash logs

### Valorant-Specific Optimizations

Valorant's anti-cheat (Vanguard) can interfere with recording:

1. **OBS Capture Method**:
   - Use "Game Capture" (NOT Window or Display)
   - Run OBS as Administrator
   - Add Valorant manually to sources

2. **Vanguard Compatibility**:
   - OBS is generally safe
   - Avoid injector-based tools
   - Keep OBS updated

3. **Performance Settings**:
   - Valorant: Uncap FPS or set to 240+
   - Let GPU headroom for NVENC
   - Disable in-game overlays (except OBS)

### Expected Results After Optimizations

With proper optimizations and RAM replacement:

| Metric | Before | After |
|--------|--------|-------|
| Recording FPS | 120 (unstable) | 120 (stable) |
| Game FPS | 120-180 | 180-240 |
| Dropped Frames | 5-10% | <0.1% |
| RAM Usage | 17/35 GB (near max) | 20/35 GB (safe) |
| Crashes | Frequent | Rare/None |
| Recording Quality | Compressed | Clear |

### Upgrade Priority (Your Situation)

1. **CRITICAL - Replace RAM** ($100-$150)
   - Fix WHEA errors
   - Stop crashes
   - Enable stable 32GB

2. **HIGH - Update WiFi Driver** (Free)
   - Fix disconnects
   - Improve stability

3. **MEDIUM - Add Recording SSD** ($80-$120)
   - 1TB NVMe
   - Dedicated for recordings
   - Prevents game stutters

4. **LOW - GPU Upgrade** ($500-$700)
   - Only if current GPU < RTX 3060
   - Better NVENC quality
   - Higher game FPS

### Quick Command Reference

```powershell
# Run full diagnostic + optimization
.\PC-Diagnostic.ps1

# Check RAM health only
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WHEA-Logger'}

# Check current page file size
Get-WmiObject Win32_PageFileUsage

# Monitor OBS stats while recording
# OBS Stats Dock → View → Docks → Stats

# Clear temp files manually
cleanmgr /d C:

# Check disk write speed
winsat disk -drive C
```

### Resources

- [OBS Studio Download](https://obsproject.com/)
- [NVIDIA NVENC Settings Guide](https://www.nvidia.com/en-us/geforce/guides/broadcasting-guide/)
- [Valorant Performance Guide](https://playvalorant.com/en-us/news/game-updates/performance-optimization/)
- [RAM Compatibility Checker](https://www.crucial.com/store/advisor)

---

**Remember**: The #1 priority is replacing your failing RAM. All optimizations are temporary workarounds until the hardware is fixed.
