# ============================================================================
# Скрипт для визначення характеристик комп'ютера на Windows 11
# ============================================================================
# Визначає: назва, процесор, жорсткий диск, клавіатура, миша, монітор, дата інсталяції ОС
# ============================================================================

Write-Host "================================" -ForegroundColor Green
Write-Host "Інформація про систему Windows 11" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# 1. НАЗВА КОМП'ЮТЕРА
Write-Host "`n1. НАЗВА КОМП'ЮТЕРА:" -ForegroundColor Yellow
$computerName = [System.Net.Dns]::GetHostName()
Write-Host "   $computerName"

# 2. ПРОЦЕСОР
Write-Host "`n2. ПРОЦЕСОР:" -ForegroundColor Yellow
$processor = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
Write-Host "   Назва: $($processor.Name)"
Write-Host "   Кількість ядер: $($processor.NumberOfCores)"
Write-Host "   Кількість логічних процесорів: $($processor.NumberOfLogicalProcessors)"
Write-Host "   Тактова частота: $($processor.MaxClockSpeed) MHz"
Write-Host "   Архітектура: $($processor.Architecture)"

# 3. ЖОРСТКИЙ ДИСК
Write-Host "`n3. ЖОРСТКИЙ ДИСК:" -ForegroundColor Yellow
$disks = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
foreach ($disk in $disks) {
    $size = [math]::Round($disk.Size / 1GB, 2)
    $freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
    $usedSpace = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
    $percentUsed = [math]::Round(($usedSpace / $size) * 100, 2)
    
    Write-Host "   Диск: $($disk.DeviceID)"
    Write-Host "      Загальний розмір: $size GB"
    Write-Host "      Вільне місце: $freeSpace GB"
    Write-Host "      Використано: $usedSpace GB ($percentUsed%)"
}

# 4. КЛАВІАТУРА
Write-Host "`n4. КЛАВІАТУРА:" -ForegroundColor Yellow
$keyboard = Get-WmiObject -Class Win32_Keyboard | Select-Object -First 1
if ($keyboard) {
    Write-Host "   Опис: $($keyboard.Description)"
    Write-Host "   Статус: $($keyboard.Status)"
} else {
    Write-Host "   Інформація про клавіатуру не знайдена"
}

# 5. МИША (МАНІПУЛЯТОР)
Write-Host "`n5. МИША (МАНІПУЛЯТОР):" -ForegroundColor Yellow
$mouse = Get-WmiObject -Class Win32_PointingDevice | Select-Object -First 1
if ($mouse) {
    Write-Host "   Опис: $($mouse.Description)"
    Write-Host "   Статус: $($mouse.Status)"
} else {
    Write-Host "   Інформація про мишу не знайдена"
}

# 6. МОНІТОР
Write-Host "`n6. МОНІТОР:" -ForegroundColor Yellow
$monitor = Get-WmiObject -Class Win32_DesktopMonitor | Select-Object -First 1
if ($monitor) {
    Write-Host "   Опис: $($monitor.Description)"
    Write-Host "   Статус: $($monitor.Status)"
} else {
    # Спроба отримати інформацію через реєстр
    $screenResolution = Get-WmiObject -Class Win32_VideoController | Select-Object -First 1
    if ($screenResolution) {
        Write-Host "   Розширення екрану: $($screenResolution.VideoModeDescription)"
        Write-Host "   Адаптер: $($screenResolution.Name)"
    }
}

# 7. ДАТА ІНСТАЛЯЦІЇ ОС
Write-Host "`n7. ДАТА ІНСТАЛЯЦІЇ ОС:" -ForegroundColor Yellow
$osInstallDate = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -First 1
$installDate = [Management.ManagementDateTimeConverter]::ToDateTime($osInstallDate.InstallDate)
Write-Host "   $($installDate.ToString('dd.MM.yyyy HH:mm:ss'))"

# ДОДАТКОВА ІНФОРМАЦІЯ
Write-Host "`n8. ДОДАТКОВА ІНФОРМАЦІЯ:" -ForegroundColor Yellow
Write-Host "   Операційна система: $($osInstallDate.Caption)"
Write-Host "   Версія: $($osInstallDate.Version)"
Write-Host "   Сервіс-пак: $($osInstallDate.ServicePackMajorVersion).$($osInstallDate.ServicePackMinorVersion)"

# Оперативна пам'ять
$ram = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -First 1
$ramGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
Write-Host "   Оперативна пам'ять: $ramGB GB"

Write-Host "`n================================" -ForegroundColor Green
Write-Host "Завершено" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
