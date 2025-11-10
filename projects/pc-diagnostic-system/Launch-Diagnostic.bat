@echo off
REM PC Diagnostic System Launcher
REM This batch file launches the PowerShell diagnostic tool with proper execution policy

setlocal

echo.
echo ========================================================================
echo   PC Diagnostic ^& Optimization System Launcher
echo ========================================================================
echo.

REM Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] WARNING: Not running as Administrator
    echo [!] Some features require elevated privileges
    echo.
    echo Right-click this file and select "Run as Administrator" for full functionality.
    echo.
    pause
    goto :menu
)

echo [OK] Running with Administrator privileges
echo.

:menu
echo Select operation mode:
echo.
echo   1. Full Diagnostic + Optimization (Recommended)
echo   2. Diagnostic Only (No changes to system)
echo   3. Preview Changes (WhatIf mode)
echo   4. Help / Usage Information
echo   5. Exit
echo.
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" goto full
if "%choice%"=="2" goto diagnostic
if "%choice%"=="3" goto whatif
if "%choice%"=="4" goto help
if "%choice%"=="5" goto exit
echo Invalid choice. Please try again.
echo.
goto menu

:full
echo.
echo Starting Full Diagnostic + Optimization...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0PC-Diagnostic.ps1" -Mode Full
goto done

:diagnostic
echo.
echo Starting Diagnostic Only (No Changes)...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0PC-Diagnostic.ps1" -Mode Diagnostic
goto done

:whatif
echo.
echo Starting Preview Mode (WhatIf)...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0PC-Diagnostic.ps1" -WhatIf
goto done

:help
echo.
echo ========================================================================
echo   PC Diagnostic System - Help
echo ========================================================================
echo.
echo This tool provides comprehensive PC diagnostics and optimization:
echo.
echo FEATURES:
echo   - Hardware inventory and health checks
echo   - RAM failure detection (WHEA errors)
echo   - Temperature monitoring
echo   - Driver version checking
echo   - Bottleneck analysis
echo   - Upgrade recommendations with pricing
echo   - System optimization for gaming/recording
echo   - HTML report generation
echo.
echo MODES:
echo   Full Diagnostic + Optimization:
echo     - Scans entire system
echo     - Applies safe optimizations
echo     - Creates restore point
echo     - Generates comprehensive report
echo.
echo   Diagnostic Only:
echo     - System analysis only
echo     - No changes made
echo     - Generates report with recommendations
echo.
echo   Preview (WhatIf):
echo     - Shows what would be changed
echo     - No actual modifications
echo.
echo CRITICAL DETECTIONS:
echo   - Failing RAM (WHEA errors)
echo   - Outdated drivers
echo   - Overheating components
echo   - Insufficient resources for workload
echo.
echo REPORTS:
echo   - HTML reports saved to: reports\ folder
echo   - JSON data exports for automation
echo.
echo For more information, see README.md
echo.
pause
goto menu

:done
echo.
echo ========================================================================
echo   Operation Complete
echo ========================================================================
echo.
echo Check the reports\ folder for detailed HTML and JSON reports.
echo.
pause
goto menu

:exit
echo.
echo Exiting PC Diagnostic System.
echo.
exit /b 0
