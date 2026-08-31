@echo off
chcp 1251 >nul
REM ============================================================================
REM Батник для запуску PowerShell скрипту визначення характеристик системи (JSON)
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

REM Визначаємо шлях до JSON-експорту скрипту
setlocal enabledelayedexpansion
set "scriptPath=%~dp0get-system-info-json.ps1"

REM Запускаємо PowerShell скрипт для збереження інформації в JSON
echo.
echo [INFO] Запуск скрипту експорту системної інформації до JSON...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "!scriptPath!"

echo.
echo [INFO] Готово. Перевірте system-info.json у тій же теці.
pause
