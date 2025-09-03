<# 
  fix-gopro-webcam.ps1
  Forza la instalación del driver UVC (USB Video Device) para que la GoPro se vea como webcam en Windows.
  Probado en Windows 10/11. Requiere PowerShell como Administrador.
#>

function Assert-Admin {
  $current = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  if (-not $current.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "[X] Este script debe ejecutarse como Administrador." -ForegroundColor Red
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
    Log "No existe DriverStore en $root" "ERR"
    return $null
  }
  $cands = Get-ChildItem -Path $root -Directory -Filter "usbvideo.inf_*" -ErrorAction SilentlyContinue |
           Sort-Object LastWriteTime -Descending
  if (!$cands -or $cands.Count -eq 0) {
    Log "No encontré carpetas usbvideo.inf_* en DriverStore." "WARN"
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
    Log "No existe $infPath" "ERR"
    return $false
  }
  Log "Instalando driver UVC desde: $infPath"
  $args = "/add-driver `"$infPath`" /install"
  $proc = Start-Process -FilePath pnputil.exe -ArgumentList $args -Wait -PassThru -WindowStyle Hidden
  if ($proc.ExitCode -eq 0) {
    Log "Driver UVC instalado correctamente." "OK"
    return $true
  } else {
    Log "pnputil devolvió código $($proc.ExitCode)." "ERR"
    return $false
  }
}

function Get-GoProDevice {
  try { Import-Module PnpDevice -ErrorAction Stop | Out-Null } catch {
    Log "No pude cargar el módulo PnpDevice. Continuaré sin operaciones sobre el dispositivo." "WARN"
    return $null
  }
  $devs = Get-PnpDevice | Where-Object {
    $_.FriendlyName -match 'gopro|hero' -or $_.InstanceId -match 'gopro|hero'
  }
  if (!$devs -or $devs.Count -eq 0) {
    $wpd = Get-PnpDevice | Where-Object { $_.Class -match 'WPD|Portable' -and $_.Status -eq 'OK' }
    if ($wpd) {
      Log "No hallé una GoPro por nombre. Dispositivos portátiles conectados (pista):" "WARN"
      $wpd | Select-Object FriendlyName,InstanceId,Class | Format-Table | Out-String | Write-Host
    }
    return $null
  }
  return $devs | Select-Object -First 1
}

function Refresh-Device {
  param([string]$instanceId)
  try {
    Disable-PnpDevice -InstanceId $instanceId -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
    Start-Sleep -Milliseconds 800
    Enable-PnpDevice  -InstanceId $instanceId -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
    Log "Reinicié el dispositivo $instanceId" "OK"
  } catch {
    Log "No pude reiniciar el dispositivo automáticamente. Desconecta y vuelve a conectar el USB." "WARN"
  }
}

function Restart-GoProUtility {
  $names = @("GoProWebcam","GoPro Webcam","GoProWebcam.exe","GoPro Webcam Desktop Utility")
  Get-Process | Where-Object { $names -contains $_.ProcessName -or $_.ProcessName -like "GoPro*" } |
    ForEach-Object { 
      Log "Cerrando proceso $($_.ProcessName)..." "INFO"
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
    Log "Lanzando GoPro Webcam Utility: $exe"
    Start-Process -FilePath $exe -Verb RunAs -ErrorAction SilentlyContinue | Out-Null
  } else {
    Log "No encontré el ejecutable de GoPro Webcam Utility. Asegúrate de tenerla instalada." "WARN"
  }
}

Assert-Admin
Log "=== GoPro Webcam Fix (UVC) para Windows ==="
Log "1) Buscando usbvideo.inf en DriverStore…"
$inf = Get-UsbVideoInfPath
if (-not $inf) { Log "No encontré usbvideo.inf en DriverStore. Asegúrate de tener Windows actualizado." "ERR"; exit 2 }

Log "2) Instalando driver UVC…"
$ok = Install-UvcDriver -infPath $inf
if (-not $ok) { Log "Fallo instalando el driver UVC. Aborta." "ERR"; exit 3 }

Log "3) Detectando tu GoPro (puede figurar como MTP/Portátil)…"
$dev = Get-GoProDevice
if ($dev) {
  Log "Encontré un candidato: $($dev.FriendlyName) [$($dev.InstanceId)] (Clase: $($dev.Class))" "OK"
  Log "Intentando refrescar el dispositivo para que Windows re-evalúe el binding…" "INFO"
  Refresh-Device -instanceId $dev.InstanceId
} else {
  Log "No pude identificar claramente la GoPro por nombre. No pasa nada, seguimos." "WARN"
}

Log "4) Reiniciando GoPro Webcam Utility…"
Restart-GoProUtility

Log "5) PASOS FINALES:"
Log " - Desconecta y vuelve a conectar la GoPro al USB 3.0 (mejor directo a la placa)."
Log " - En la cámara debe poner 'USB conectado' (normal en HERO 10/11/12/13)."
Log " - Abre la bandeja (iconos junto al reloj) y verifica el icono de GoPro: azul = OK."
Log " - En 'Administrador de dispositivos' debe aparecer en 'Cámaras/Dispositivos de imagen' como 'USB Video Device' o 'GoPro Webcam'." "INFO"
Log "Si aún aparece como 'Dispositivo portátil (MTP)', prueba otro cable USB-C (de datos) y otro puerto USB 3.0, y reinicia." "INFO"
