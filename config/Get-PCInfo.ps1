<#
.SYNOPSIS
  Obtiene serial de BIOS, clave OEM y versión de Windows 11.
.DESCRIPTION
  Usa CIM en lugar de WMIC, con fallback al registro para la clave.
#>

# 1. Forzar ejecución como Admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Ejecuta este script como Administrador."
    exit 1
}

# 2. Serial de BIOS por CIM
try {
    $serial = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
} catch {
    $serial = "Error obteniendo serial."
}

# 3. Clave OEM por SoftwareLicensingService (OA3xOriginalProductKey)
try {
    $oemKey = (Get-CimInstance -ClassName SoftwareLicensingService).OA3xOriginalProductKey
} catch {
    $oemKey = ''
}

# 4. Fallback: decodificar DigitalProductId desde el registro si no hay OEMKey
if ([string]::IsNullOrWhiteSpace($oemKey)) {
    # Lee el DigitalProductId
    try {
        $dpid = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'DigitalProductId').DigitalProductId
    } catch {
        $dpid = $null
    }

    if ($dpid) {
        $Chars     = 'BCDFGHJKMPQRTVWXY2346789'
        $KeyOffset = 52
        [byte[]]$bytes = $dpid

        # Ajuste para Windows 8+
        if ((($bytes[66] -shr 3) -band 1) -eq 1) {
            $bytes[66] = ($bytes[66] -band 0xF7) -bor 0x80
        }

        $productKey = ''
        for ($i = 24; $i -ge 0; $i--) {
            $current = 0
            for ($j = 14; $j -ge 0; $j--) {
                $current = $current * 256 + $bytes[$j + $KeyOffset]
                $bytes[$j + $KeyOffset] = [math]::Floor($current / 24)
                $current = $current % 24
            }
            $productKey = $Chars[$current] + $productKey
            if (($i % 5) -eq 0 -and $i -ne 0) { $productKey = '-' + $productKey }
        }
        $oemKey = $productKey
    }
    else {
        $oemKey = "No disponible (Digital License sin clave almacenada)."
    }
}

# 5. Obtener versión del SO
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $osName    = $os.Caption
    $osVersion = $os.Version
} catch {
    $osName = "Desconocido"
    $osVersion = ""
}

# 6. Mostrar resultados
Write-Host "========================================"
Write-Host "   Serial de BIOS : $serial"
Write-Host "   Clave OEM      : $oemKey"
Write-Host "   SO instal.     : $osName $osVersion"
Write-Host "========================================"
