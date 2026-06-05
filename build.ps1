[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
#  build.ps1 — Concatena os módulos e gera TibiaManager.exe
#  Uso: .\build.ps1
# ============================================================

$rootPath    = $PSScriptRoot
$outputPath  = Join-Path $rootPath "TibiaManager.exe"
$iconPath    = Join-Path $rootPath "icon.ico"
$bundlePath  = Join-Path $env:TEMP "TibiaManager-bundle.ps1"

Write-Host "`n=== Build do Tibia Manager ===" -ForegroundColor Cyan

# Ordem de concatenação: módulos primeiro, entry point por último
$modules = @(
    "src\config.ps1",
    "src\update.ps1",
    "src\minimap.ps1",
    "src\screenshots.ps1",
    "src\testserver.ps1"
)

Write-Host "Gerando bundle..." -ForegroundColor DarkGray

# Cabeçalho do bundle — define encoding e versão (será substituída pelo workflow)
$bundle = "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`n"
$bundle += "`$script:Versao = `"dev`"`n`n"

# Concatena cada módulo removendo a linha de encoding (já está no cabeçalho)
foreach ($module in $modules) {
    $path    = Join-Path $rootPath $module
    $content = Get-Content $path -Raw -Encoding UTF8
    # Remove a linha de encoding se existir no módulo
    $content = $content -replace '\[Console\]::OutputEncoding.*\n', ''
    $bundle += "# --- $module ---`n"
    $bundle += $content.Trim() + "`n`n"
}

# Adiciona o entry point sem o bloco de dot-sourcing e sem a linha de encoding/versão
$entryPoint = Get-Content (Join-Path $rootPath "script.ps1") -Raw -Encoding UTF8
$entryPoint = $entryPoint -replace '\[Console\]::OutputEncoding.*\n', ''
$entryPoint = $entryPoint -replace '\$script:Versao\s*=\s*"dev"\n', ''
$entryPoint = $entryPoint -replace '(?s)# Carrega módulos.*?}\n', ''
$bundle += "# --- entry point ---`n"
$bundle += $entryPoint.Trim() + "`n"

Set-Content -Path $bundlePath -Value $bundle -Encoding UTF8
Write-Host "✅ Bundle gerado em: $bundlePath" -ForegroundColor Green

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

Write-Host "Compilando executável..." -ForegroundColor DarkGray

$buildParams = @{
    inputFile    = $bundlePath
    outputFile   = $outputPath
    title        = "Tibia Manager"
    description  = "Gerenciador de minimap, screenshots e test server do Tibia"
    version      = "1.0.0"
    noConsole    = $false
    requireAdmin = $false
}

if (Test-Path $iconPath) {
    $buildParams.iconFile = $iconPath
    Write-Host "🎨 Ícone encontrado: $iconPath" -ForegroundColor DarkGray
} else {
    Write-Host "⚠️  icon.ico não encontrado — executável será gerado sem ícone." -ForegroundColor Yellow
    Write-Host "   Para adicionar: coloque um arquivo icon.ico na raiz do projeto." -ForegroundColor DarkGray
}

Invoke-ps2exe @buildParams

Remove-Item -Path $bundlePath -Force -ErrorAction SilentlyContinue

if (Test-Path $outputPath) {
    Write-Host "`n✅ Executável gerado com sucesso!" -ForegroundColor Green
    Write-Host "   📦 $outputPath" -ForegroundColor Cyan
} else {
    Write-Host "`n❌ Falha na geração do executável." -ForegroundColor Red
    exit 1
}
