# ============================================================
#  config.ps1 — Gerenciamento de configuração persistente
# ============================================================

$script:ConfigPath = Join-Path $env:APPDATA "TibiaManager\config.json"

function Carregar-Config {
    if (Test-Path $script:ConfigPath) {
        try {
            $json = Get-Content $script:ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
            return $json
        } catch {
            Write-Host "⚠️  Falha ao ler config.json. Iniciando setup." -ForegroundColor Yellow
        }
    }
    return $null
}

function Salvar-Config {
    param ([PSCustomObject]$config)
    $pasta = Split-Path $script:ConfigPath
    if (-not (Test-Path $pasta)) {
        New-Item -Path $pasta -ItemType Directory | Out-Null
    }
    $config | ConvertTo-Json -Depth 3 | Set-Content $script:ConfigPath -Encoding UTF8
}

function Executar-Setup {
    param ([switch]$Reconfigurar)

    if ($Reconfigurar) {
        Write-Host "`n=== Reconfigurar ===" -ForegroundColor Cyan
    } else {
        Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║      Bem-vindo ao Tibia Manager! 🎮      ║" -ForegroundColor Cyan
        Write-Host "║   Vamos configurar o ambiente uma vez.   ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════╝`n" -ForegroundColor Cyan
    }

    $defaultDestino = Join-Path $env:USERPROFILE "OneDrive\Pictures\Tibia Screenshots"

    Write-Host "Pasta de destino para Screenshots:"
    Write-Host "  Padrão: $defaultDestino" -ForegroundColor DarkGray
    $input = Read-Host "Pressione Enter para usar o padrão ou digite outro caminho"
    $destinoScreenshots = if ($input.Trim() -eq "") { $defaultDestino } else { $input.Trim() }

    $config = [PSCustomObject]@{
        DestinoScreenshots = $destinoScreenshots
    }

    Salvar-Config -config $config
    Write-Host "`n✅ Configuração salva em: $script:ConfigPath" -ForegroundColor Green

    return $config
}
