# Script para compartir el APK de MedWear
# Creado automaticamente

$apkPath = "$PSScriptRoot\build\app\outputs\flutter-apk\app-release.apk"

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "    COMPARTIR APK DE MEDWEAR" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

if (Test-Path $apkPath) {
    $apkInfo = Get-Item $apkPath
    $sizeInMB = [math]::Round($apkInfo.Length / 1MB, 2)
    
    Write-Host "APK encontrado:" -ForegroundColor Green
    Write-Host "   Nombre: $($apkInfo.Name)" -ForegroundColor White
    Write-Host "   Tamano: $sizeInMB MB" -ForegroundColor White
    Write-Host "   Fecha: $($apkInfo.LastWriteTime)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Selecciona una opcion:" -ForegroundColor Yellow
    Write-Host "1. Abrir carpeta del APK" -ForegroundColor White
    Write-Host "2. Copiar APK al escritorio" -ForegroundColor White
    Write-Host "3. Copiar APK a Documentos" -ForegroundColor White
    Write-Host "4. Abrir WhatsApp Web para compartir" -ForegroundColor White
    Write-Host "5. Abrir Telegram Web para compartir" -ForegroundColor White
    Write-Host "6. Copiar ruta completa al portapapeles" -ForegroundColor White
    Write-Host "0. Salir`n" -ForegroundColor White
    
    $opcion = Read-Host "Opcion"
    
    switch ($opcion) {
        "1" {
            Write-Host "`nAbriendo carpeta..." -ForegroundColor Green
            explorer.exe /select,$apkPath
        }
        "2" {
            $destino = "$env:USERPROFILE\Desktop\MedWear-app-release.apk"
            Copy-Item $apkPath $destino -Force
            Write-Host "`nAPK copiado al escritorio: $destino" -ForegroundColor Green
            explorer.exe /select,$destino
        }
        "3" {
            $destino = "$env:USERPROFILE\Documents\MedWear-app-release.apk"
            Copy-Item $apkPath $destino -Force
            Write-Host "`nAPK copiado a Documentos: $destino" -ForegroundColor Green
            explorer.exe /select,$destino
        }
        "4" {
            Write-Host "`nAbriendo WhatsApp Web..." -ForegroundColor Green
            Write-Host "   1. Escanea el QR con tu telefono" -ForegroundColor Yellow
            Write-Host "   2. Haz clic en el clip" -ForegroundColor Yellow
            Write-Host "   3. Selecciona Documento" -ForegroundColor Yellow
            Write-Host "   4. Busca el APK en la carpeta que se abrira`n" -ForegroundColor Yellow
            Start-Process "https://web.whatsapp.com"
            Start-Sleep -Seconds 2
            explorer.exe /select,$apkPath
        }
        "5" {
            Write-Host "`nAbriendo Telegram Web..." -ForegroundColor Green
            Write-Host "   1. Arrastra el APK a la conversacion`n" -ForegroundColor Yellow
            Start-Process "https://web.telegram.org"
            Start-Sleep -Seconds 2
            explorer.exe /select,$apkPath
        }
        "6" {
            Set-Clipboard -Value $apkPath
            Write-Host "`nRuta copiada al portapapeles:" -ForegroundColor Green
            Write-Host "   $apkPath`n" -ForegroundColor White
        }
        "0" {
            Write-Host "`nHasta luego!`n" -ForegroundColor Cyan
        }
        default {
            Write-Host "`nOpcion no valida`n" -ForegroundColor Red
        }
    }
} else {
    Write-Host "No se encontro el APK." -ForegroundColor Red
    Write-Host "   Asegurate de haber construido el APK con: flutter build apk`n" -ForegroundColor Yellow
}

Write-Host "Presiona Enter para salir..." -ForegroundColor Gray
Read-Host
