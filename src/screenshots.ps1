# ============================================================
#  screenshots.ps1 — Organização de screenshots do Tibia
# ============================================================

function Organizar-Screenshots {
    Write-Host "`n=== Organização de Screenshots ===`n"

    # TODO (ponto 3): $origem está hardcoded para Tibia Principal.
    # Adicionar menu de seleção (Principal / Test Server) igual ao de Atualizar-Minimap,
    # e também permitir escolher $destino (ex: OneDrive vs pasta local).

    $timestamp   = Get-Date -Format "yyyyMMdd-HHmmss"
    $origem      = Join-Path $env:LOCALAPPDATA "Tibia\packages\Tibia\screenshots"
    $destino     = $script:Config.DestinoScreenshots
    $pastaBackup = Join-Path $script:Config.PastaBackup "screenshots"
    if (-not (Test-Path $pastaBackup)) {
        New-Item -Path $pastaBackup -ItemType Directory | Out-Null
    }
    $backupCaminho = Join-Path $pastaBackup "screenshots-backup-$timestamp.zip"

    Write-Host "Destino configurado: $destino" -ForegroundColor DarkGray

    if (-not (Test-Path $origem)) {
        Write-Host "❌ A pasta de screenshots não foi encontrada: $origem" -ForegroundColor Red
        return
    }

    if (-not (Test-Path $destino)) {
        New-Item -Path $destino -ItemType Directory | Out-Null
    }

    Write-Host "Criando backup..."
    Compress-Archive -Path $origem -DestinationPath $backupCaminho -Force
    Write-Host "Backup criado em: $backupCaminho"

    Write-Host "Copiando arquivos..."
    Get-ChildItem -Path $origem -Filter *.png | ForEach-Object {
        $nomeArquivo = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $partes      = $nomeArquivo -split '_'

        if ($partes.Count -ge 4) {
            $personagem    = $partes[2]
            $contexto      = $partes[3]
            $pastaContexto = Join-Path $destino $personagem | Join-Path -ChildPath $contexto

            if (-not (Test-Path $pastaContexto)) {
                New-Item -Path $pastaContexto -ItemType Directory | Out-Null
            }

            Copy-Item -Path $_.FullName -Destination $pastaContexto
        } else {
            Write-Host "Nome de arquivo inválido: $($_.Name). Pulando..." -ForegroundColor Yellow
        }
    }

    Remove-Item -Path $origem -Recurse -Force
    Write-Host "✅ Screenshots organizadas com sucesso!" -ForegroundColor Green
    Read-Host "`nPressione Enter para voltar ao menu"
}
