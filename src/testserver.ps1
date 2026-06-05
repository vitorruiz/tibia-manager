# ============================================================
#  testserver.ps1 — Sincronização com o Test Server
# ============================================================

function Configurar-TestServer {
    $sourceBase      = Join-Path $env:LOCALAPPDATA "Tibia\packages\Tibia"
    $destinationBase = Join-Path $env:LOCALAPPDATA "Tibia\packages\TibiaExternal"
    $foldersToCopy   = @("characterdata", "conf", "minimap")

    Write-Host "=== Iniciando cópia de pastas fixas ===" -ForegroundColor Cyan
    Write-Host "Origem : $sourceBase"        -ForegroundColor Yellow
    Write-Host "Destino: $destinationBase`n" -ForegroundColor Yellow

    foreach ($folder in $foldersToCopy) {
        $sourcePath = Join-Path $sourceBase $folder
        $destPath   = Join-Path $destinationBase $folder

        Write-Host "➡️ Processando pasta: $folder" -ForegroundColor Cyan

        if (-not (Test-Path $sourcePath)) {
            Write-Host "❌ Pasta de origem não encontrada: $sourcePath" -ForegroundColor Red
            continue
        }

        if (Test-Path $destPath) {
            Write-Host "🗑️  Removendo pasta existente no destino..." -ForegroundColor Yellow
            try {
                Remove-Item -Path $destPath -Recurse -Force -ErrorAction Stop
                Write-Host "✅ Pasta anterior removida com sucesso." -ForegroundColor Green
            } catch {
                Write-Host "⚠️ Erro ao remover pasta destino: $_" -ForegroundColor Red
                continue
            }
        }

        try {
            Write-Host "📂 Copiando de '$sourcePath' para '$destPath'..."
            Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force -ErrorAction Stop
            Write-Host "✅ Pasta copiada com sucesso!" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Erro ao copiar: $_" -ForegroundColor Red
        }

        Write-Host ""
    }

    Write-Host "🎯 Processo concluído!" -ForegroundColor Cyan
    Read-Host "`nPressione Enter para voltar ao menu"
}
