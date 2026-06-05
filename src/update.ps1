# ============================================================
#  update.ps1 — Auto-update via GitHub Releases
# ============================================================

function Verificar-Atualizacao {
    param ([switch]$Silencioso)

    # Só verifica se estiver rodando como .exe compilado
    if ($script:Versao -eq "dev") {
        if (-not $Silencioso) {
            Write-Host "⚠️  Auto-update não disponível em modo dev." -ForegroundColor Yellow
        }
        return
    }

    if (-not $Silencioso) {
        Write-Host "`nVerificando atualizações..." -ForegroundColor DarkGray
    }

    try {
        $release = Invoke-RestMethod `
            -Uri "https://api.github.com/repos/vitorruiz/tibia-manager/releases/latest" `
            -UseBasicParsing `
            -ErrorAction Stop

        $tagLatest = $release.tag_name.TrimStart("v")
        $tagAtual  = $script:Versao

        if ($tagLatest -eq $tagAtual) {
            if (-not $Silencioso) {
                Write-Host "✅ Você já está na versão mais recente ($tagAtual)." -ForegroundColor Green
            }
            return
        }

        Write-Host "`n🆕 Nova versão disponível: v$tagLatest (atual: v$tagAtual)" -ForegroundColor Cyan
        Write-Host "Deseja atualizar agora?"
        Write-Host "1 - Sim, atualizar"
        Write-Host "2 - Não, continuar sem atualizar"
        $resposta = Read-Host "Digite a opção"

        if ($resposta -ne "1") {
            Write-Host "Atualização ignorada." -ForegroundColor Yellow
            return
        }

        # Localiza o asset TibiaManager.exe na release
        $asset = $release.assets | Where-Object { $_.name -eq "TibiaManager.exe" } | Select-Object -First 1
        if (-not $asset) {
            Write-Host "❌ Executável não encontrado na release. Tente mais tarde." -ForegroundColor Red
            return
        }

        $exeAtual   = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $exeNovo    = "$env:TEMP\TibiaManager-new.exe"
        $scriptTemp = "$env:TEMP\tibia-manager-update.ps1"

        Write-Host "Baixando v$tagLatest..." -ForegroundColor DarkGray
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $exeNovo -UseBasicParsing -ErrorAction Stop
        Write-Host "✅ Download concluído." -ForegroundColor Green

        # Cria script auxiliar que aguarda o processo fechar, substitui e relança
        $updateScript = @"
Start-Sleep -Seconds 2
`$destino = '$($exeAtual -replace "'", "''")'
`$origem  = '$($exeNovo  -replace "'", "''")'
try {
    Copy-Item -Path `$origem -Destination `$destino -Force
    Start-Process -FilePath `$destino
} catch {
    [System.Windows.Forms.MessageBox]::Show("Falha ao aplicar atualização: `$_", "Tibia Manager")
} finally {
    Remove-Item -Path `$origem  -Force -ErrorAction SilentlyContinue
    Remove-Item -Path '$scriptTemp' -Force -ErrorAction SilentlyContinue
}
"@
        Set-Content -Path $scriptTemp -Value $updateScript -Encoding UTF8

        Write-Host "Aplicando atualização e reiniciando..." -ForegroundColor Cyan
        Start-Process -FilePath "powershell.exe" `
            -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptTemp`"" `
            -WindowStyle Hidden

        exit

    } catch {
        if (-not $Silencioso) {
            Write-Host "❌ Não foi possível verificar atualizações: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
