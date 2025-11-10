@echo off
REM Launch-All-Diagnostics.bat - Master launcher for PC diagnostic scripts
REM Author: Network Engineering Portfolio
REM Version: 1.0.0

setlocal enabledelayedexpansion

REM Color codes (for use with echo)
set "HEADER=echo."
set "SUCCESS=echo   [OK]"
set "WARNING=echo   [!]"
set "ERROR=echo   [X]"
set "INFO=echo   [*]"

cls
echo.
echo ========================================================================
echo   PC DIAGNOSTIC SCRIPT COLLECTION - Master Launcher
echo ========================================================================
echo.

REM Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] WARNING: Not running as Administrator
    echo [!] Some scripts require elevated privileges
    echo.
    echo Right-click this file and select "Run as Administrator" for full functionality.
    echo.
    pause
) else (
    echo [OK] Running with Administrator privileges
    echo.
)

REM Set execution policy for current session
echo [*] Setting PowerShell execution policy...
powershell.exe -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force" >nul 2>&1
echo [OK] Execution policy set
echo.

:menu
cls
echo.
echo ========================================================================
echo   PC DIAGNOSTIC SCRIPT COLLECTION - Main Menu
echo ========================================================================
echo.
echo   CRITICAL / EMERGENCY:
echo   1. Emergency RAM Cleanup         - Free memory before recording/gaming
echo   2. Quick Health Check            - Fast system check (^<30 seconds)
echo.
echo   DIAGNOSTICS:
echo   3. Analyze Crashes               - Check for BSOD and WHEA errors
echo   4. Test RAM                      - Interactive RAM testing guide
echo   5. Monitor Performance           - Real-time system monitoring
echo.
echo   OPTIMIZATION:
echo   6. Optimize Recording Settings   - Get OBS/ShadowPlay recommendations
echo   7. Auto-Fix Issues              - Automated system optimization
echo.
echo   PLANNING:
echo   8. Get Upgrade Recommendations  - Hardware upgrade advisor
echo.
echo   ADVANCED:
echo   9. Run All Diagnostics          - Complete system analysis
echo   0. Generate Combined Report      - Run all checks and create report
echo.
echo   H. Help / Information
echo   Q. Quit
echo.
echo ========================================================================
echo.
set /p choice="Enter your choice: "

if /i "%choice%"=="1" goto emergency_cleanup
if /i "%choice%"=="2" goto health_check
if /i "%choice%"=="3" goto analyze_crashes
if /i "%choice%"=="4" goto test_ram
if /i "%choice%"=="5" goto monitor_performance
if /i "%choice%"=="6" goto optimize_recording
if /i "%choice%"=="7" goto auto_fix
if /i "%choice%"=="8" goto upgrade_recommendations
if /i "%choice%"=="9" goto run_all
if /i "%choice%"=="0" goto combined_report
if /i "%choice%"=="H" goto help
if /i "%choice%"=="Q" goto quit

echo.
echo [X] Invalid choice. Please try again.
timeout /t 2 >nul
goto menu

:emergency_cleanup
cls
echo.
echo ========================================================================
echo   EMERGENCY RAM CLEANUP
echo ========================================================================
echo.
echo This will close Chrome, Discord, Steam and other memory-heavy apps.
echo.
set /p confirm="Continue? (Y/N): "
if /i not "%confirm%"=="Y" goto menu

echo.
echo [*] Running Emergency Cleanup...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Emergency-Cleanup.ps1"
goto done

:health_check
cls
echo.
echo ========================================================================
echo   QUICK HEALTH CHECK
echo ========================================================================
echo.
echo [*] Running Quick Health Check (30 seconds)...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Quick-Health-Check.ps1"
goto done

:analyze_crashes
cls
echo.
echo ========================================================================
echo   CRASH ANALYSIS
echo ========================================================================
echo.
echo [*] Analyzing crash dumps and WHEA errors...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Analyze-Crashes.ps1"
goto done

:test_ram
cls
echo.
echo ========================================================================
echo   RAM TESTING GUIDE
echo ========================================================================
echo.
echo [*] Launching interactive RAM testing guide...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Test-RAM.ps1"
goto done

:monitor_performance
cls
echo.
echo ========================================================================
echo   PERFORMANCE MONITORING
echo ========================================================================
echo.
set /p duration="Enter monitoring duration in seconds (default 60): "
if "%duration%"=="" set duration=60

echo.
set /p logfile="Enter log file path (optional, press Enter to skip): "

if "%logfile%"=="" (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0Monitor-Performance.ps1" -Duration %duration%
) else (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0Monitor-Performance.ps1" -Duration %duration% -LogFile "%logfile%"
)
goto done

:optimize_recording
cls
echo.
echo ========================================================================
echo   RECORDING SETTINGS OPTIMIZER
echo ========================================================================
echo.
set /p fps="Enter target FPS (default 120): "
if "%fps%"=="" set fps=120

set /p bitrate="Enter target bitrate in Kbps (default 15000): "
if "%bitrate%"=="" set bitrate=15000

echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Optimize-Recording.ps1" -TargetFPS %fps% -Bitrate %bitrate%
goto done

:auto_fix
cls
echo.
echo ========================================================================
echo   AUTOMATED SYSTEM OPTIMIZATION
echo ========================================================================
echo.
echo This will:
echo   - Create a system restore point
echo   - Optimize page file (virtual memory)
echo   - Set High Performance power plan
echo   - Enable Game Mode and GPU scheduling
echo   - Optimize network settings
echo   - Clean temporary files
echo   - Optimize Windows services
echo.
echo [!] WARNING: Some changes require a restart
echo.
set /p confirm="Continue with optimization? (Y/N): "
if /i not "%confirm%"=="Y" goto menu

echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Auto-Fix-Issues.ps1"
goto done

:upgrade_recommendations
cls
echo.
echo ========================================================================
echo   HARDWARE UPGRADE RECOMMENDATIONS
echo ========================================================================
echo.
set /p budget="Enter your budget in USD (default 500): "
if "%budget%"=="" set budget=500

echo.
echo Select use case:
echo   1. Gaming
echo   2. Recording
echo   3. Both (default)
echo.
set /p usecase_choice="Enter choice (1-3): "

set usecase=Both
if "%usecase_choice%"=="1" set usecase=Gaming
if "%usecase_choice%"=="2" set usecase=Recording

echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Get-UpgradeRecommendations.ps1" -Budget %budget% -UseCase %usecase%
goto done

:run_all
cls
echo.
echo ========================================================================
echo   RUNNING ALL DIAGNOSTICS
echo ========================================================================
echo.
echo This will run all diagnostic scripts in sequence.
echo Estimated time: 5-10 minutes
echo.
set /p confirm="Continue? (Y/N): "
if /i not "%confirm%"=="Y" goto menu

echo.
echo [*] Running diagnostics...
echo.

echo [1/4] Quick Health Check...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Quick-Health-Check.ps1"

echo.
echo [2/4] Analyzing Crashes...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Analyze-Crashes.ps1"

echo.
echo [3/4] Recording Optimization Analysis...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Optimize-Recording.ps1"

echo.
echo [4/4] Upgrade Recommendations...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Get-UpgradeRecommendations.ps1"

echo.
echo [OK] All diagnostics complete!
goto done

:combined_report
cls
echo.
echo ========================================================================
echo   COMBINED DIAGNOSTIC REPORT
echo ========================================================================
echo.
echo Generating comprehensive report from all diagnostic tools...
echo.

set timestamp=%date:~-4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set timestamp=%timestamp: =0%
set reportdir=%~dp0..\reports
set reportfile=%reportdir%\Combined-Report_%timestamp%.txt

if not exist "%reportdir%" mkdir "%reportdir%"

echo PC Diagnostic Report - %date% %time% > "%reportfile%"
echo ======================================================================== >> "%reportfile%"
echo. >> "%reportfile%"

echo [*] Running Quick Health Check...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Quick-Health-Check.ps1" >> "%reportfile%" 2>&1

echo. >> "%reportfile%"
echo ======================================================================== >> "%reportfile%"
echo. >> "%reportfile%"

echo [*] Running Crash Analysis...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Analyze-Crashes.ps1" >> "%reportfile%" 2>&1

echo. >> "%reportfile%"
echo ======================================================================== >> "%reportfile%"
echo. >> "%reportfile%"

echo [*] Getting Upgrade Recommendations...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Get-UpgradeRecommendations.ps1" >> "%reportfile%" 2>&1

echo.
echo [OK] Combined report generated: %reportfile%
echo.
echo Opening report...
notepad "%reportfile%"
goto done

:help
cls
echo.
echo ========================================================================
echo   HELP / INFORMATION
echo ========================================================================
echo.
echo SCRIPT DESCRIPTIONS:
echo.
echo Emergency RAM Cleanup
echo   Closes memory-heavy apps (Chrome, Discord, Steam) and clears
echo   standby memory. Use before recording/gaming sessions.
echo   Run time: ~10 seconds
echo.
echo Quick Health Check
echo   Fast check for critical issues: WHEA errors, RAM usage, crashes,
echo   disk space, and top memory consumers.
echo   Run time: ^<30 seconds
echo.
echo Analyze Crashes
echo   Comprehensive analysis of crash dumps and WHEA hardware errors.
echo   Identifies crash patterns and provides detailed diagnosis.
echo   Run time: ~1 minute
echo.
echo Test RAM
echo   Interactive guide for testing RAM sticks individually.
echo   Can schedule Windows Memory Diagnostic and provides step-by-step
echo   instructions for identifying failing RAM.
echo   Run time: Interactive (user-guided)
echo.
echo Monitor Performance
echo   Real-time monitoring of CPU, RAM, GPU, and disk usage with alerts.
echo   Can log data to CSV for analysis. Color-coded output.
echo   Run time: User-specified (default 60 seconds)
echo.
echo Optimize Recording Settings
echo   Analyzes GPU capabilities and system specs to recommend optimal
echo   OBS/ShadowPlay settings for your target FPS and bitrate.
echo   Run time: ~30 seconds
echo.
echo Auto-Fix Issues
echo   Automated system optimization: page file, power plan, Game Mode,
echo   GPU scheduling, network settings, temp file cleanup, and more.
echo   Creates restore point before changes. REQUIRES ADMIN.
echo   Run time: 2-3 minutes
echo.
echo Get Upgrade Recommendations
echo   Analyzes hardware bottlenecks and provides upgrade recommendations
echo   with pricing and compatibility information based on your budget.
echo   Run time: ~20 seconds
echo.
echo ========================================================================
echo.
echo CRITICAL FOR YOUR SYSTEM (Based on diagnostics):
echo   - 6 WHEA RAM errors detected = FAILING RAM
echo   - 7 crashes in 10 days = CRITICAL hardware issue
echo   - 91.8%% RAM usage = Insufficient RAM for workload
echo.
echo RECOMMENDED IMMEDIATE ACTIONS:
echo   1. Run Quick Health Check (option 2)
echo   2. Run Test RAM to identify bad stick (option 4)
echo   3. Get upgrade recommendations for new RAM (option 8)
echo   4. Use Emergency Cleanup before recording (option 1)
echo.
echo ========================================================================
echo.
pause
goto menu

:done
echo.
echo ========================================================================
echo   Operation Complete
echo ========================================================================
echo.
pause
goto menu

:quit
echo.
echo Exiting PC Diagnostic Script Collection.
echo.
exit /b 0
