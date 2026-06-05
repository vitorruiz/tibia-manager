# ============================================================
#  backups.ps1 — Gestão de backups do minimap
# ============================================================

function Gerenciar-Backups {
    while ($true) {
        $pastaBackup = Join-Path $script:Config.PastaBackup "minimap"

        Write-Host "`n=== Gerenciar Backups do Minimap ===" -ForegroundColor Cyan

        if (-not (Test-Path $pastaBackup)) {
            Write-Host "Nenhum backup encontrado em: $pastaBackup" -ForegroundColor Yellow
        } else {
            $backups = Get-ChildItem -Path $pastaBackup -Filter "*.zip" | Sort-Object LastWriteTime -Descending
            if ($backups.Count -eq 0) {
                Write-Host "Nenhum backup encontrado." -ForegroundColor Yellow
            } else {
                Write-Host "  $($backups.Count) backup(s) disponível(is) em: $pastaBackup`n" -ForegroundColor DarkGray
            }
        }

        Write-Host "1 - Listar backups"
        Write-Host "2 - Restaurar backup"
        Write-Host "3 - Limpar backups antigos"
        Write-Host "0 - Voltar"
        $escolha = Read-Host "Escolha uma opção"

        switch ($escolha) {
            "1" { Listar-Backups }
            "2" { Restaurar-Backup }
            "3" { Limpar-Backups }
            "0" { return }
            default { Write-Host "Opção inválida." -ForegroundColor Red }
        }
    }
}

function Listar-Backups {
    $pastaBackup = Join-Path $script:Config.PastaBackup "minimap"

    if (-not (Test-Path $pastaBackup)) {
        Write-Host "Nenhum backup encontrado." -ForegroundColor Yellow
        return
    }

    $backups = Get-ChildItem -Path $pastaBackup -Filter "*.zip" | Sort-Object LastWriteTime -Descending

    if ($backups.Count -eq 0) {
        Write-Host "Nenhum backup encontrado." -ForegroundColor Yellow
        return
    }

    Write-Host "`n  #   Data                  Tamanho"
    Write-Host "  --- --------------------- --------"
    $i = 1
    foreach ($b in $backups) {
        $data    = $b.LastWriteTime.ToString("dd/MM/yyyy HH:mm:ss")
        $tamanho = "{0:N2} MB" -f ($b.Length / 1MB)
        $tag     = if ($i -eq 1) { " (mais recente)" } else { "" }
        Write-Host ("  {0,-3} {1,-21} {2,8}{3}" -f $i, $data, $tamanho, $tag) -ForegroundColor $(if ($i -eq 1) { "Green" } else { "White" })
        $i++
    }
}

function Restaurar-Backup {
    $pastaBackup       = Join-Path $script:Config.PastaBackup "minimap"
    $destinationFolder = Join-Path $env:LOCALAPPDATA "Tibia\packages\Tibia\minimap"
    $timestamp         = Get-Date -Format "yyyyMMdd-HHmmss"

    if (-not (Test-Path $pastaBackup)) {
        Write-Host "Nenhum backup encontrado." -ForegroundColor Yellow
        return
    }

    $backups = Get-ChildItem -Path $pastaBackup -Filter "*.zip" | Sort-Object LastWriteTime -Descending

    if ($backups.Count -eq 0) {
        Write-Host "Nenhum backup encontrado." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Listar-Backups
    Write-Host ""

    $input = Read-Host "Digite o número do backup para restaurar (0 para cancelar)"

    if ($input -eq "0") {
        Write-Host "Operação cancelada." -ForegroundColor Yellow
        return
    }

    $indice = $input -as [int]
    if ($null -eq $indice -or $indice -lt 1 -or $indice -gt $backups.Count) {
        Write-Host "Número inválido." -ForegroundColor Red
        return
    }

    $backupEscolhido = $backups[$indice - 1]

    # Faz backup do estado atual antes de restaurar
    if (Test-Path $destinationFolder) {
        $backupAtual = Join-Path $pastaBackup "minimap-backup-$timestamp.zip"
        Write-Host "Criando backup do minimap atual antes de restaurar..."
        Compress-Archive -Path "$destinationFolder\*" -DestinationPath $backupAtual -Force
        Write-Host "✅ Backup do estado atual salvo." -ForegroundColor Green

        Write-Host "Removendo minimap atual..."
        Remove-Item -Path $destinationFolder -Recurse -Force
    }

    Write-Host "Restaurando backup de $($backupEscolhido.LastWriteTime.ToString("dd/MM/yyyy HH:mm:ss"))..."
    $tempRestore = "$env:TEMP\minimap-restore"
    if (Test-Path $tempRestore) { Remove-Item $tempRestore -Recurse -Force }

    try {
        Expand-Archive -Path $backupEscolhido.FullName -DestinationPath $tempRestore -Force

        # O zip pode conter os arquivos direto ou dentro de subpasta "minimap"
        $subPasta = Join-Path $tempRestore "minimap"
        $origem   = if (Test-Path $subPasta) { $subPasta } else { $tempRestore }

        New-Item -Path $destinationFolder -ItemType Directory | Out-Null
        Copy-Item -Path "$origem\*" -Destination $destinationFolder -Recurse -Force
        Write-Host "✅ Backup restaurado com sucesso!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erro ao restaurar: $_" -ForegroundColor Red
    } finally {
        Remove-Item -Path $tempRestore -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Limpar-Backups {
    $pastaBackup = Join-Path $script:Config.PastaBackup "minimap"

    if (-not (Test-Path $pastaBackup)) {
        Write-Host "Nenhum backup encontrado." -ForegroundColor Yellow
        return
    }

    $backups = Get-ChildItem -Path $pastaBackup -Filter "*.zip" | Sort-Object LastWriteTime -Descending

    if ($backups.Count -le 1) {
        Write-Host "Apenas $($backups.Count) backup encontrado. Nada a limpar." -ForegroundColor Yellow
        return
    }

    $aRemover = $backups | Select-Object -Skip 1
    Write-Host "Serão removidos $($aRemover.Count) backup(s), mantendo apenas o mais recente:"
    Write-Host "  ✅ Mantendo: $($backups[0].LastWriteTime.ToString("dd/MM/yyyy HH:mm:ss"))" -ForegroundColor Green
    foreach ($b in $aRemover) {
        Write-Host "  🗑️  Removendo: $($b.LastWriteTime.ToString("dd/MM/yyyy HH:mm:ss"))" -ForegroundColor DarkGray
    }

    Write-Host ""
    $confirma = Read-Host "Confirmar? (s/n)"
    if ($confirma -ne "s") {
        Write-Host "Operação cancelada." -ForegroundColor Yellow
        return
    }

    foreach ($b in $aRemover) {
        Remove-Item -Path $b.FullName -Force
    }

    Write-Host "✅ $($aRemover.Count) backup(s) removido(s)." -ForegroundColor Green
}
