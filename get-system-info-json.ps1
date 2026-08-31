# PowerShell script to collect Windows system information and save it as JSON
# UTF-8 (no BOM)

$outFile = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath 'system-info.json'

# Helper to safely get first object or $null
function Get-First($scriptBlock) {
    try {
        & $scriptBlock | Select-Object -First 1
    } catch {
        return $null
    }
}

$data = [ordered]@{}

# Computer info
$cs = Get-First { Get-WmiObject -Class Win32_ComputerSystem }
$data.Computer = [ordered]@{
    Name = [System.Net.Dns]::GetHostName()
    Manufacturer = if ($cs -and $cs.Manufacturer) { $cs.Manufacturer } else { $null }
    Model = if ($cs -and $cs.Model) { $cs.Model } else { $null }
}

# Processor
$processor = Get-First { Get-WmiObject -Class Win32_Processor }
if ($processor) {
    $data.Processor = [ordered]@{
        Manufacturer = if ($processor.Manufacturer) { $processor.Manufacturer } else { $null }
        Model = if ($processor.Name) { $processor.Name } else { $null }
        NumberOfCores = $processor.NumberOfCores
        NumberOfLogicalProcessors = $processor.NumberOfLogicalProcessors
        MaxClockSpeedMHz = $processor.MaxClockSpeed
        Architecture = $processor.Architecture
    }
}

# Physical disk drives (manufacturer/model)
$diskDrives = Get-WmiObject -Class Win32_DiskDrive
$data.DiskDrives = @()
foreach ($drive in $diskDrives) {
    $sizeGB = if ($drive.Size) { [math]::Round($drive.Size / 1GB, 2) } else { $null }
    $data.DiskDrives += [ordered]@{
        DeviceID = $drive.DeviceID
        Manufacturer = if ($drive.Manufacturer) { $drive.Manufacturer } elseif ($drive.PNPDeviceID) { $drive.PNPDeviceID } else { $null }
        Model = if ($drive.Model) { $drive.Model } elseif ($drive.Caption) { $drive.Caption } else { $null }
        InterfaceType = $drive.InterfaceType
        SizeGB = $sizeGB
        SerialNumber = if ($drive.SerialNumber) { $drive.SerialNumber } else { $null }
    }
}

# Logical disks (partitions)
$logicalDisks = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
$data.LogicalDisks = @()
foreach ($disk in $logicalDisks) {
    if (-not $disk.Size) { continue }
    $sizeGB = [math]::Round($disk.Size / 1GB, 2)
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $usedGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
    $percentUsed = if ($sizeGB -ne 0) { [math]::Round(($usedGB / $sizeGB) * 100, 2) } else { 0 }

    $data.LogicalDisks += [ordered]@{
        DeviceID = $disk.DeviceID
        SizeGB = $sizeGB
        FreeSpaceGB = $freeGB
        UsedSpaceGB = $usedGB
        PercentUsed = $percentUsed
        FileSystem = $disk.FileSystem
        VolumeName = $disk.VolumeName
    }
}

# Keyboard
$keyboard = Get-First { Get-WmiObject -Class Win32_Keyboard }
if ($keyboard) {
    $data.Keyboard = [ordered]@{
        Manufacturer = if ($keyboard.Manufacturer) { $keyboard.Manufacturer } elseif ($keyboard.PNPDeviceID) { $keyboard.PNPDeviceID } else { $null }
        Model = if ($keyboard.Description) { $keyboard.Description } elseif ($keyboard.Name) { $keyboard.Name } else { $null }
        Status = $keyboard.Status
    }
}

# Pointing device (mouse)
$mouse = Get-First { Get-WmiObject -Class Win32_PointingDevice }
if ($mouse) {
    $data.PointingDevice = [ordered]@{
        Manufacturer = if ($mouse.Manufacturer) { $mouse.Manufacturer } elseif ($mouse.PNPDeviceID) { $mouse.PNPDeviceID } else { $null }
        Model = if ($mouse.Description) { $mouse.Description } elseif ($mouse.Name) { $mouse.Name } else { $null }
        Status = $mouse.Status
    }
}

# Monitor / Video adapter
$monitor = Get-First { Get-WmiObject -Class Win32_DesktopMonitor }
if ($monitor) {
    $data.Monitor = [ordered]@{
        Manufacturer = if ($monitor.MonitorManufacturer) { $monitor.MonitorManufacturer } elseif ($monitor.PNPDeviceID) { $monitor.PNPDeviceID } else { $null }
        Model = if ($monitor.Name) { $monitor.Name } elseif ($monitor.Description) { $monitor.Description } else { $null }
        Status = $monitor.Status
    }
} else {
    # Fallback to video controller
    $vc = Get-First { Get-WmiObject -Class Win32_VideoController }
    if ($vc) {
        $data.VideoController = [ordered]@{
            Manufacturer = if ($vc.AdapterCompatibility) { $vc.AdapterCompatibility } elseif ($vc.DriverVersion) { $vc.DriverVersion } else { $null }
            Model = if ($vc.Name) { $vc.Name } else { $null }
            VideoModeDescription = $vc.VideoModeDescription
        }
    }
}

# OS install date and info
$os = Get-First { Get-WmiObject -Class Win32_OperatingSystem }
if ($os) {
    $installDate = $null
    try { $installDate = [Management.ManagementDateTimeConverter]::ToDateTime($os.InstallDate) } catch {}
    $data.OS = [ordered]@{
        Caption = $os.Caption
        Version = $os.Version
        ServicePack = "$($os.ServicePackMajorVersion).$($os.ServicePackMinorVersion)"
        InstallDate = if ($installDate) { $installDate.ToString('yyyy-MM-ddTHH:mm:ss') } else { $null }
    }
}

# RAM
if ($cs) {
    $data.RAM_GB = if ($cs.TotalPhysicalMemory) { [math]::Round($cs.TotalPhysicalMemory / 1GB, 2) } else { $null }
}

# Timestamp
$data.CollectedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')

# Convert to JSON and save as UTF8 (no BOM)
$json = $data | ConvertTo-Json -Depth 8 -Compress
Set-Content -Path $outFile -Value $json -Encoding UTF8

Write-Host "Saved system info JSON to: $outFile"
