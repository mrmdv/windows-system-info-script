@echo off
REM ============================================================================
REM Батник для запуску PowerShell скрипту визначення характеристик системи
REM ============================================================================

REM Перевіряємо, чи запущено з правами адміністратора
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [ПОМИЛКА] Скрипт потребує прав адміністратора!
    echo Запустіть CMD від імені адміністратора та спробуйте знову.
    echo.
    pause
    exit /b 1
)

REM Визначаємо шлях до скрипту
setlocal enabledelayedexpansion
set "scriptPath=%~dp0get-system-info.ps1"

REM Запускаємо PowerShell скрипт
echo.
echo [INFO] Запуск скрипту визначення характеристик системи...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "!scriptPath!"

echo.
pause
