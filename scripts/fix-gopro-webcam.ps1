<# 
  fix-gopro-webcam.ps1
  Forces installation of the UVC (USB Video Device) driver so GoPro is detected as a webcam in Windows.
  Tested on Windows 10/11. Must run as Administrator.
#>

function Assert-Admin {
  $current = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  if (-not $current.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "[X] This script must be run as Administrator." -ForegroundColor Red
    exit 1
  }
}

function Log {
  param([string]$msg, [string]$level = "INFO")
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $color = switch ($level) { 
    "INFO" { "Gray" } 
    "OK"   { "Green" }
    "WARN" { "Yellow" }
    "ERR"  { "Red" }
    default { "Gray" }
  }
  Write-Host "[$ts][$level] $msg" -ForegroundColor $color
}

function Get-UsbVideoInfPath {
  $root = "$env:WINDIR\System32\DriverStore\FileRepository"
  if (-not (Test-Path $root)) {
    Log "DriverStore not found at $root" "ERR"
    return $null
  }
  $cands = Get-ChildItem -Path $root -Directory -Filter "usbvideo.inf_*" -ErrorAction SilentlyContinue |
           Sort-Object LastWriteTime -Descending
  if (!$cands -or $cands.Count -eq 0) {
    Log "No usbvideo.inf_* folders found in DriverStore." "WARN"
    return $null
  }
  foreach ($c in $cands) {
    $inf = Join-Path $c.FullName "usbvideo.inf"
    if (Test-Path $inf) { return $inf }
  }
  return $null
}

function Install-UvcDriver {
  param([string]$infPath)
  if (-not (Test-Path $infPath)) {
    Log "Missing file: $infPath" "ERR"
    return $false
  }
  Log "Installing UVC driver from: $infPath"
  $args = "/add-driver `"$infPath`" /install"
  $proc = Start-Process -FilePath pnputil.exe -ArgumentList $args -Wait -PassThru -WindowStyle Hidden
  if ($proc.ExitCode -eq 0) {
    Log "UVC driver installed successfully." "OK"
    return $true
  } else {
    Log "pnputil returned exit code $($proc.ExitCode)." "ERR"
    return $false
  }
}

function Restart-GoProUtility {
  $names = @("GoProWebcam","GoPro Webcam","GoProWebcam.exe","GoPro Webcam Desktop Utility")
  Get-Process | Where-Object { $names -contains $_.ProcessName -or $_.ProcessName -like "GoPro*" } |
    ForEach-Object { 
      Log "Killing process $($_.ProcessName)..." "INFO"
      Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
  Start-Sleep -Seconds 1
  $paths = @(
    "$env:ProgramFiles\GoPro\GoPro Webcam\GoProWebcam.exe",
    "$env:ProgramFiles\GoPro\Tools\Webcam\GoProWebcam.exe",
    "$env:ProgramFiles(x86)\GoPro\GoPro Webcam\GoProWebcam.exe"
  )
  $exe = $paths | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($exe) {
    Log "Starting GoPro Webcam Utility: $exe"
    Start-Process -FilePath $exe -Verb RunAs -ErrorAction SilentlyContinue | Out-Null
  } else {
    Log "GoPro Webcam Utility executable not found. Make sure it is installed." "WARN"
  }
}

Assert-Admin
Log "=== GoPro Webcam Fix (UVC) for Windows ==="
Log "1) Searching for usbvideo.inf in DriverStore…"
$inf = Get-UsbVideoInfPath
if (-not $inf) { Log "usbvideo.inf not found. Please update Windows." "ERR"; exit 2 }

Log "2) Installing UVC driver…"
$ok = Install-UvcDriver -infPath $inf
if (-not $ok) { Log "Driver installation failed." "ERR"; exit 3 }

Log "3) Restarting GoPro Webcam Utility…"
Restart-GoProUtility

Log "4) FINAL STEPS:"
Log " - Disconnect and reconnect your GoPro to a USB 3.0 port."
Log " - On the camera screen you should see 'USB connected' (normal on HERO 10/11/12/13)."
Log " - Check the tray icon: GoPro webcam should turn blue when ready."
Log " - In Device Manager, the GoPro should appear under 'Cameras / Imaging Devices' as 'USB Video Device' or 'GoPro Webcam'." "INFO"
