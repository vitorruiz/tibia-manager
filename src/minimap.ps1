# ============================================================
#  minimap.ps1 — Atualização e combinação de minimap
# ============================================================

function Atualizar-Minimap {
    $inicio = Get-Date
    Write-Host "`n=== Atualização do Minimap ===`n"

    $timestamp         = Get-Date -Format "yyyyMMdd-HHmmss"
    $baseFolder        = Join-Path $env:LOCALAPPDATA "Tibia\packages\Tibia"
    $destinationFolder = Join-Path $baseFolder "minimap"
    $tempExtractFolder = "$env:TEMP\minimap-temp"
    $zipPath           = "$env:TEMP\minimap.zip"
    $currentMinimapMakerPath = "$tempExtractFolder\orig_minimapmarkers.bin"

    # Pasta de backup centralizada no AppData
    $pastaBackup = Join-Path $script:Config.PastaBackup "minimap"
    if (-not (Test-Path $pastaBackup)) {
        New-Item -Path $pastaBackup -ItemType Directory | Out-Null
    }
    $backupZip = Join-Path $pastaBackup "minimap-backup-$timestamp.zip"

    Write-Host "Selecione a versão do minimap para baixar:"
    Write-Host "1 - Mapa completo com marcadores"
    Write-Host "2 - Mapa completo sem marcadores (mantém os marcadores atuais)"
    Write-Host "0 - Cancelar"
    $opcao = Read-Host "Digite o número da opção desejada"

    switch ($opcao) {
        "1" {
            $url = "https://tibiamaps.io/downloads/minimap-with-markers"
            Write-Host "Versão: Mapa completo com marcadores selecionada"
        }
        "2" {
            $url = "https://tibiamaps.io/downloads/minimap-without-markers"
            Write-Host "Versão: Mapa completo sem marcadores selecionada"
        }
        "0" {
            Write-Host "Operação cancelada pelo usuário." -ForegroundColor Yellow
            return
        }
        default {
            Write-Host "Opção inválida." -ForegroundColor Red
            return
        }
    }

    Write-Host "`nDeseja combinar os marcadores atuais com os do mapa novo?"
    Write-Host "1 - Sim, combinar marcadores"
    Write-Host "2 - Não, manter arquivo minimapmarkers.bin atual"
    $combinar = Read-Host "Digite a opção"

    Write-Host "`nBaixando minimap de: $url"
    Write-Host "Isso pode levar alguns segundos dependendo da sua conexão..." -ForegroundColor DarkGray
    try {
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        Write-Host "✅ Download concluído." -ForegroundColor Green
    } catch {
        Write-Host "Erro ao baixar o arquivo: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    if (!(Test-Path $zipPath)) {
        Write-Host "O arquivo ZIP não foi encontrado após o download." -ForegroundColor Red
        return
    }

    if (Test-Path $tempExtractFolder) {
        Remove-Item -Path $tempExtractFolder -Recurse -Force
    }
    New-Item -Path $tempExtractFolder -ItemType Directory | Out-Null

    if (Test-Path $destinationFolder) {
        $minimapMarkerOriginal = Join-Path $destinationFolder "minimapmarkers.bin"
        Write-Host "Copiando marcadores atuais para temp..."
        Copy-Item -Path $minimapMarkerOriginal -Destination $currentMinimapMakerPath -Force
        Write-Host "Criando backup em: $backupZip"
        Compress-Archive -Path "$destinationFolder\*" -DestinationPath $backupZip -Force
        Write-Host "✅ Backup criado." -ForegroundColor Green
    } else {
        Write-Host "A pasta minimap não foi encontrada. Será criada durante a extração."
    }

    try {
        Write-Host "Expandindo minimap baixado..."
        Expand-Archive -Path $zipPath -DestinationPath $tempExtractFolder -Force
        $extractedMinimap = Join-Path $tempExtractFolder "minimap"
        if (!(Test-Path $extractedMinimap)) {
            Write-Host "A pasta 'minimap' não foi encontrada no conteúdo extraído. Cancelando." -ForegroundColor Red
            return
        }

        if ($combinar -eq "1") {
            Write-Host "Combinando arquivos minimapmarkers.bin..."
            $arquivoNovo = Join-Path $extractedMinimap "minimapmarkers.bin"

            if ((Test-Path $currentMinimapMakerPath) -and (Test-Path $arquivoNovo)) {
                $arquivoCombinado = Join-Path $tempExtractFolder "minimapmarkers.bin"
                Combinar-Marcadores -originalPath $currentMinimapMakerPath -novoPath $arquivoNovo -destinoPath $arquivoCombinado
                Copy-Item -Path $arquivoCombinado -Destination $extractedMinimap -Force
            } elseif (Test-Path $currentMinimapMakerPath) {
                Copy-Item -Path $currentMinimapMakerPath -Destination $extractedMinimap -Force
                Write-Host "minimapmarkers.bin não encontrado no mapa baixado, mantendo o atual." -ForegroundColor Yellow
            } else {
                Write-Host "minimapmarkers.bin não encontrado para combinação." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Mantendo arquivo minimapmarkers.bin atual."
        }

        if (Test-Path $destinationFolder) {
            Write-Host "Removendo minimap antigo..."
            Remove-Item -Path $destinationFolder -Recurse -Force
        }

        Write-Host "Aplicando novo minimap..."
        Copy-Item -Path $extractedMinimap -Destination $destinationFolder -Recurse -Force
    } finally {
        Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempExtractFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    $duracao = (Get-Date) - $inicio
    Write-Host "✅ Minimap atualizado com sucesso!" -ForegroundColor Green
    Write-Host "⏱️ Tempo total: $($duracao.ToString())" -ForegroundColor Cyan
}

function Combinar-Marcadores {
    param (
        [string]$originalPath,
        [string]$novoPath,
        [string]$destinoPath
    )

    $backupPath = Join-Path (Split-Path $originalPath) "minimapmarkers-backup.bin"
    Copy-Item -Path $originalPath -Destination $backupPath -Force

    $origBytes = Read-BinaryFile -path $originalPath
    $novoBytes = Read-BinaryFile -path $novoPath

    Write-Host "Extraindo marcadores atuais..."
    $marcadoresOrig = Extrair-Marcadores -dados $origBytes
    Write-Host "Extraindo marcadores baixados..."
    $marcadoresNovo = Extrair-Marcadores -dados $novoBytes

    $todos = @{}

    Write-Host "Mesclando marcadores..."
    foreach ($m in $marcadoresOrig) {
        $todos[$m.Chave] = $m.Dados
    }
    foreach ($m in $marcadoresNovo) {
        if (-not $todos.ContainsKey($m.Chave)) {
            $todos[$m.Chave] = $m.Dados
        }
    }

    # TODO (ponto 1): $finalBytes += dentro de loop cria um novo array a cada iteração (O(n²)).
    # Substituir por [System.Collections.Generic.List[byte]] e AddRange(), ou usar:
    #   [byte[]]($todos.Values | ForEach-Object { $_ })
    # para montar o array de uma vez só, antes de chamar Write-BinaryFile.
    $finalBytes = @()
    Write-Host "Gerando arquivo final do minimapmarkers.bin..."
    foreach ($dado in $todos.Values) {
        $finalBytes += $dado
    }

    Write-BinaryFile -path $destinoPath -content $finalBytes
    Write-Host "✅ Arquivo minimapmarkers.bin combinado com sucesso." -ForegroundColor Green
}

function Read-BinaryFile {
    param ([string]$path)
    return [System.IO.File]::ReadAllBytes($path)
}

function Write-BinaryFile {
    param (
        [string]$path,
        [byte[]]$content
    )
    [System.IO.File]::WriteAllBytes($path, $content)
}

function Extrair-Marcadores {
    param (
        [byte[]]$dados
    )

    $marcadores = @()
    $falhas     = 0
    $i          = 0

    while ($i -lt $dados.Length) {
        # 0x0A é o field tag do protobuf para o campo "markers" — só avança se
        # o byte seguinte (tamanho do bloco) for plausível e o bloco couber no buffer.
        if ($dados[$i] -ne 0x0A -or ($i + 1 -ge $dados.Length)) {
            $i++
            continue
        }

        $tamBloco = $dados[$i + 1]

        # Tamanho zero ou bloco além do fim do buffer: byte 0x0A falso, pula.
        if ($tamBloco -eq 0 -or ($i + 2 + $tamBloco) -gt $dados.Length) {
            $i++
            continue
        }

        $fim   = $i + 2 + $tamBloco
        $bloco = $dados[$i..($fim - 1)]

        # Valida estrutura esperada: 0A <sz1> 0A <sz2> 08 <x_varint> 10 <y_varint> 18 <z>
        try {
            $j = 0
            if ($bloco[$j] -ne 0x0A) { throw "campo externo ausente" }
            $j += 2  # pula tag + size1

            if ($j -ge $bloco.Length -or $bloco[$j] -ne 0x0A) { throw "campo interno ausente" }
            $j += 2  # pula tag + size2

            if ($j -ge $bloco.Length -or $bloco[$j] -ne 0x08) { throw "tag x ausente" }
            $j++

            # Coordenada X — varint de até 3 bytes
            $x1 = $bloco[$j++]
            $x  = $x1 -band 0x7F
            if ($x1 -band 0x80) {
                $x2 = $bloco[$j++]
                $x  = ($x1 -band 0x7F) -bor (($x2 -band 0x7F) -shl 7)
                if ($x2 -band 0x80) {
                    $x3 = $bloco[$j++]
                    $x  = $x -bor (($x3 -band 0x7F) -shl 14)
                }
            }

            if ($j -ge $bloco.Length -or $bloco[$j] -ne 0x10) { throw "tag y ausente" }
            $j++

            # Coordenada Y — varint de até 3 bytes
            $y1 = $bloco[$j++]
            $y  = $y1 -band 0x7F
            if ($y1 -band 0x80) {
                $y2 = $bloco[$j++]
                $y  = ($y1 -band 0x7F) -bor (($y2 -band 0x7F) -shl 7)
                if ($y2 -band 0x80) {
                    $y3 = $bloco[$j++]
                    $y  = $y -bor (($y3 -band 0x7F) -shl 14)
                }
            }

            if ($j -ge $bloco.Length -or $bloco[$j] -ne 0x18) { throw "tag z ausente" }
            $j++

            $z     = $bloco[$j]
            $chave = "$x-$y-$z"
        } catch {
            $falhas++
            Write-Verbose "Parse falhou no offset $i`: $_"
            $chave = "invalid-$i"
        }

        $marcadores += [PSCustomObject]@{
            Chave = $chave
            Dados = $bloco
        }

        $i = $fim
    }

    if ($falhas -gt 0) {
        Write-Host "⚠️  $falhas bloco(s) não puderam ser parseados e foram ignorados." -ForegroundColor Yellow
    }

    return $marcadores
}
