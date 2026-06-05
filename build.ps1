[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
#  build.ps1 — Gera TibiaManager.exe usando ps2exe
#  Uso: .\build.ps1
# ============================================================

$scriptPath = Join-Path $PSScriptRoot "script.ps1"
$outputPath = Join-Path $PSScriptRoot "TibiaManager.exe"
$iconPath   = Join-Path $PSScriptRoot "icon.ico"

Write-Host "`n=== Build do Tibia Manager ===" -ForegroundColor Cyan

# Verifica se o ps2exe está instalado
if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "Módulo ps2exe não encontrado. Instalando..." -ForegroundColor Yellow
    try {
        Install-Module -Name ps2exe -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "✅ ps2exe instalado com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "❌ Falha ao instalar ps2exe: $_" -ForegroundColor Red
        Write-Host "Execute manualmente: Install-Module -Name ps2exe -Scope CurrentUser" -ForegroundColor Yellow
        exit 1
    }
}

Import-Module ps2exe

Write-Host "Compilando $scriptPath..." -ForegroundColor DarkGray

# Resolve os parâmetros do build — ícone é opcional
$buildParams = @{
    inputFile   = $scriptPath
    outputFile  = $outputPath
    title       = "Tibia Manager"
    description = "Gerenciador de minimap, screenshots e test server do Tibia"
    version     = "1.0.0"
    noConsole   = $false
    requireAdmin = $false
}

if (Test-Path $iconPath) {
    $buildParams.iconFile = $iconPath
    Write-Host "🎨 Ícone encontrado: $iconPath" -ForegroundColor DarkGray
} else {
    Write-Host "⚠️  icon.ico não encontrado em $PSScriptRoot — executável será gerado sem ícone." -ForegroundColor Yellow
    Write-Host "   Para adicionar: coloque um arquivo icon.ico na pasta do projeto e rode o build novamente." -ForegroundColor DarkGray
}

Invoke-ps2exe @buildParams

if (Test-Path $outputPath) {
    Write-Host "`n✅ Executável gerado com sucesso!" -ForegroundColor Green
    Write-Host "   📦 $outputPath" -ForegroundColor Cyan
} else {
    Write-Host "`n❌ Falha na geração do executável." -ForegroundColor Red
    exit 1
}
