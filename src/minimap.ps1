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
    $marcadoresAtualPath = "$tempExtractFolder\minimapmarkers-atual.bin"

    # Pasta de backup centralizada no AppData
    $pastaBackup = Join-Path $script:Config.PastaBackup "minimap"
    if (-not (Test-Path $pastaBackup)) {
        New-Item -Path $pastaBackup -ItemType Directory | Out-Null
    }
    $backupZip = Join-Path $pastaBackup "minimap-backup-$timestamp-pre-atualizacao.zip"

    Write-Host "Selecione a versão do minimap para baixar:"
    Write-Host "1 - Mapa completo com marcadores do tibiamaps.io"
    Write-Host "2 - Mapa completo sem marcadores"
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

    if ($opcao -eq "2") {
        # Sem marcadores no download: sempre preserva os marcadores atuais
        $combinar = "1"
        Write-Host "`nMarcadores atuais serão preservados (o arquivo baixado não contém marcadores)." -ForegroundColor DarkGray
    } else {
        Write-Host "`nDeseja combinar os seus marcadores com os do mapa baixado?"
        Write-Host "1 - Sim, combinar (mantém os seus e adiciona os do tibiamaps.io)"
        Write-Host "2 - Não, usar apenas os marcadores do tibiamaps.io"
        $combinar = Read-Host "Digite a opção"
    }

    Write-Host "`nBaixando minimap de: $url"
    Write-Host "Isso pode levar alguns segundos dependendo da sua conexão..." -ForegroundColor DarkGray

    $maxTentativas = 3
    $baixou        = $false

    while (-not $baixou) {
        for ($tentativa = 1; $tentativa -le $maxTentativas; $tentativa++) {
            try {
                if ($tentativa -gt 1) {
                    Write-Host "Tentativa $tentativa de $maxTentativas..." -ForegroundColor DarkGray
                }
                Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
                Write-Host "✅ Download concluído." -ForegroundColor Green
                $baixou = $true
                break
            } catch {
                Write-Host "⚠️  Não foi possível baixar o mapa (tentativa $tentativa de $maxTentativas)." -ForegroundColor Yellow
                Write-Host "    Detalhe: $($_.Exception.Message)" -ForegroundColor DarkGray
                if ($tentativa -lt $maxTentativas) {
                    Start-Sleep -Seconds 3
                }
            }
        }

        if (-not $baixou) {
            Write-Host "`n❌ Não foi possível baixar o mapa do tibiamaps.io." -ForegroundColor Red
            Write-Host "   Verifique sua conexão com a internet e se o site está acessível." -ForegroundColor DarkGray
            $tentarNovamente = Read-Host "Deseja tentar novamente? (s/n)"
            if ($tentarNovamente -ne "s") {
                Write-Host "Operação cancelada." -ForegroundColor Yellow
                return
            }
        }
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
        if (Test-Path $minimapMarkerOriginal) {
            Write-Host "Copiando marcadores em uso para temp..."
            Copy-Item -Path $minimapMarkerOriginal -Destination $marcadoresAtualPath -Force
        } else {
            Write-Host "Nenhum marcador atual encontrado, será usado apenas o do mapa baixado." -ForegroundColor DarkGray
        }
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
            $marcadoresBaixadoPath = Join-Path $extractedMinimap "minimapmarkers.bin"

            if ((Test-Path $marcadoresAtualPath) -and (Test-Path $marcadoresBaixadoPath)) {
                $arquivoCombinado = Join-Path $tempExtractFolder "minimapmarkers-combinado.bin"
                Combinar-Marcadores -atualPath $marcadoresAtualPath -baixadoPath $marcadoresBaixadoPath -destinoPath $arquivoCombinado
                Copy-Item -Path $arquivoCombinado -Destination $marcadoresBaixadoPath -Force
            } elseif (Test-Path $marcadoresAtualPath) {
                Copy-Item -Path $marcadoresAtualPath -Destination $extractedMinimap -Force
                Write-Host "Mapa baixado não contém marcadores, mantendo apenas os seus." -ForegroundColor DarkGray
            } elseif (Test-Path $marcadoresBaixadoPath) {
                Write-Host "Nenhum marcador atual encontrado, usando apenas os do mapa baixado." -ForegroundColor DarkGray
            } else {
                Write-Host "Nenhum marcador encontrado (nem no mapa atual nem no baixado)." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Usando marcadores do mapa baixado."
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
        [string]$atualPath,
        [string]$baixadoPath,
        [string]$destinoPath
    )

    $backupPath = Join-Path (Split-Path $atualPath) "minimapmarkers-atual-backup.bin"
    Copy-Item -Path $atualPath -Destination $backupPath -Force

    $bytesAtual   = Read-BinaryFile -path $atualPath
    $bytesBaixado = Read-BinaryFile -path $baixadoPath

    Write-Host "Extraindo marcadores em uso..."
    $marcadoresAtual   = Extrair-Marcadores -dados $bytesAtual
    Write-Host "Extraindo marcadores do mapa baixado..."
    $marcadoresBaixado = Extrair-Marcadores -dados $bytesBaixado

    $todos = @{}

    # Marcadores em uso têm prioridade: entram primeiro e não são sobrescritos
    Write-Host "Mesclando marcadores..."
    foreach ($m in $marcadoresAtual) {
        $todos[$m.Chave] = $m.Dados
    }
    foreach ($m in $marcadoresBaixado) {
        if (-not $todos.ContainsKey($m.Chave)) {
            $todos[$m.Chave] = $m.Dados
        }
    }

    $listaBytes = [System.Collections.Generic.List[byte]]::new()
    Write-Host "Gerando arquivo final do minimapmarkers.bin..."
    foreach ($dado in $todos.Values) {
        $listaBytes.AddRange([byte[]]$dado)
    }
    $finalBytes = $listaBytes.ToArray()

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
