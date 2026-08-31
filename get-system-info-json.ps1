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

# Computer name
$data.ComputerName = [System.Net.Dns]::GetHostName()

# Processor
$processor = Get-First { Get-WmiObject -Class Win32_Processor }
if ($processor) {
    $data.Processor = [ordered]@{
        Name = $processor.Name
        NumberOfCores = $processor.NumberOfCores
        NumberOfLogicalProcessors = $processor.NumberOfLogicalProcessors
        MaxClockSpeedMHz = $processor.MaxClockSpeed
        Architecture = $processor.Architecture
    }
}

# Disks
$disks = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
$data.Disks = @()
foreach ($disk in $disks) {
    if (-not $disk.Size) { continue }
    $sizeGB = [math]::Round($disk.Size / 1GB, 2)
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $usedGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
    $percentUsed = if ($sizeGB -ne 0) { [math]::Round(($usedGB / $sizeGB) * 100, 2) } else { 0 }

    $data.Disks += [ordered]@{
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
        Description = $keyboard.Description
        Status = $keyboard.Status
    }
}

# Pointing device (mouse)
$mouse = Get-First { Get-WmiObject -Class Win32_PointingDevice }
if ($mouse) {
    $data.PointingDevice = [ordered]@{
        Description = $mouse.Description
        Status = $mouse.Status
    }
}

# Monitor / Video adapter
$monitor = Get-First { Get-WmiObject -Class Win32_DesktopMonitor }
if ($monitor) {
    $data.Monitor = [ordered]@{
        Description = $monitor.Description
        Status = $monitor.Status
    }
} else {
    # Fallback to video controller
    $vc = Get-First { Get-WmiObject -Class Win32_VideoController }
    if ($vc) {
        $data.VideoController = [ordered]@{
            Adapter = $vc.Name
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
$cs = Get-First { Get-WmiObject -Class Win32_ComputerSystem }
if ($cs) {
    $data.RAM_GB = if ($cs.TotalPhysicalMemory) { [math]::Round($cs.TotalPhysicalMemory / 1GB, 2) } else { $null }
}

# Timestamp
$data.CollectedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')

# Convert to JSON and save as UTF8 (no BOM)
$json = $data | ConvertTo-Json -Depth 6 -Compress
Set-Content -Path $outFile -Value $json -Encoding UTF8

Write-Host "Saved system info JSON to: $outFile"
