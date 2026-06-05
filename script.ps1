[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$script:Versao = "dev"

# ============================================================
#  Configuração persistente
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

# ============================================================
#  Inicialização — carrega ou executa setup na primeira vez
# ============================================================

$script:Config = Carregar-Config
if ($null -eq $script:Config) {
    $script:Config = Executar-Setup
}

# ============================================================
#  Funções principais
# ============================================================

function Atualizar-Minimap {
    $inicio = Get-Date
    Write-Host "`n=== Atualização do Minimap ===`n"

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

    Write-Host "Selecione onde deseja aplicar o minimap:"
    Write-Host "1 - Tibia Principal"
    Write-Host "2 - Tibia Test Server"
    Write-Host "0 - Cancelar"
    $localEscolha = Read-Host "Digite o número da opção desejada"

    switch ($localEscolha) {
        "1" {
            $baseFolder = Join-Path $env:LOCALAPPDATA "Tibia\packages\Tibia"
            Write-Host "Atualização será feita na versão: Principal"
        }
        "2" {
            $baseFolder = Join-Path $env:LOCALAPPDATA "Tibia\packages\TibiaExternal"
            Write-Host "Atualização será feita na versão: Test Server"
        }
        "0" {
            Write-Host "Operação cancelada pelo usuário." -ForegroundColor Yellow
            return
        }
        default {
            Write-Host "Opção inválida. Saindo..." -ForegroundColor Red
            return
        }
    }

    $destinationFolder = Join-Path $baseFolder "minimap"
    $tempExtractFolder = "$env:TEMP\minimap-temp"
    $zipPath = "$env:TEMP\minimap.zip"
    $currentMinimapMakerPath = "$tempExtractFolder\orig_minimapmarkers.bin"

    Write-Host "`nSelecione a versão do minimap para baixar:"
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
            Write-Host "Opção inválida. Saindo..." -ForegroundColor Red
            return
        }
    }

    Write-Host "`nDeseja combinar os marcadores atuais com os do mapa novo?"
    Write-Host "1 - Sim, combinar marcadores"
    Write-Host "2 - Não, manter arquivo minimapmarkers.bin atual"
    $combinar = Read-Host "Digite a opção"

    # Backup
    $backupZip = "$baseFolder\minimap-backup-$timestamp.zip"

    Write-Host "`nBaixando minimap de: $url"
    Write-Host "Isso pode levar alguns segundos dependendo da sua conexão..." -ForegroundColor DarkGray
    try {
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        Write-Host "✅ Download concluído." -ForegroundColor Green
    } catch {
        Write-Host "Error occurred: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        Write-Host "Erro ao baixar o arquivo. Verifique a URL ou sua conexão." -ForegroundColor Red
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

        Write-Host "Copiando arquivo $minimapMarkerOriginal na pasta $tempExtractFolder"
        Copy-Item -Path $minimapMarkerOriginal -Destination $currentMinimapMakerPath -Force

        Write-Host "Criando backup zipado da pasta minimap..."
        Compress-Archive -Path "$destinationFolder\*" -DestinationPath $backupZip -Force
        Write-Host "Backup criado em: $backupZip"
    } else {
        Write-Host "A pasta minimap não foi encontrada. Será criada durante a extração."
    }

    try {
        Write-Host "Expandindo minimap baixado..."
        Expand-Archive -Path $zipPath -DestinationPath $tempExtractFolder -Force
        $extractedMinimap = Join-Path $tempExtractFolder "minimap"
        if (!(Test-Path $extractedMinimap)) {
            Write-Host "A pasta 'minimap' não foi encontrada no conteúdo extraído. Cancelando atualização." -ForegroundColor Red
            return
        }

        if ($combinar -eq "1") {
            Write-Host "Combinando arquivos minimapmarkers.bin"
            $arquivoNovo = Join-Path $extractedMinimap "minimapmarkers.bin"

            if ((Test-Path $currentMinimapMakerPath) -and (Test-Path $arquivoNovo)) {
                $arquivoCombinado = Join-Path $tempExtractFolder "minimapmarkers.bin"
                Combinar-Marcadores -originalPath $currentMinimapMakerPath -novoPath $arquivoNovo -destinoPath $arquivoCombinado
                Copy-Item -Path $arquivoCombinado -Destination $extractedMinimap -Force
            } elseif (Test-Path $currentMinimapMakerPath) {
                Copy-Item -Path $currentMinimapMakerPath -Destination $extractedMinimap -Force
                Write-Host "Arquivos minimapmarkers.bin não encontrado no mapa baixado, copiando arquivo atual." -ForegroundColor Yellow
                Write-Host "✅ Arquivo minimapmarkers.bin copiado com sucesso." -ForegroundColor Green
            } else {
                Write-Host "Arquivos minimapmarkers.bin não encontrados para combinação." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Mantendo arquivo minimapmarkers.bin"
        }

        if (Test-Path $destinationFolder) {
            Write-Host "Removendo conteúdo antigo da pasta minimap..."
            Remove-Item -Path $destinationFolder -Recurse -Force
        }

        Write-Host "Atualizando arquivos com nova versão..."
        Copy-Item -Path $extractedMinimap -Destination $destinationFolder -Recurse -Force
    } finally {
        # Limpeza garantida mesmo em caso de erro
        Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempExtractFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    $fim = Get-Date
    $duracao = $fim - $inicio

    Write-Host "✅ Minimap atualizado com sucesso!" -ForegroundColor Green
    Write-Host "⏱️ Tempo total de execução: $($duracao.ToString())" -ForegroundColor Cyan
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

    Write-Host "Configurando marcadores atuais..."
    foreach ($m in $marcadoresOrig) {
        $todos[$m.Chave] = $m.Dados
    }

    Write-Host "Adicionando novos marcadores..."
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

function Organizar-Screenshots {
    Write-Host "`n=== Organização de Screenshots ===`n"

    # TODO (ponto 3): $origem está hardcoded para Tibia Principal.
    # Adicionar menu de seleção (Principal / Test Server) igual ao de Atualizar-Minimap,
    # e também permitir escolher $destino (ex: OneDrive vs pasta local).

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

    $origem = Join-Path $env:LOCALAPPDATA "Tibia\packages\Tibia\screenshots"
    $destino = $script:Config.DestinoScreenshots
    $pastaBackup = Join-Path $env:LOCALAPPDATA "Tibia\packages\Tibia"
    $backupNome = "screenshots-backup-$timestamp.zip"
    $backupCaminho = Join-Path -Path $pastaBackup -ChildPath $backupNome

    Write-Host "Destino configurado: $destino" -ForegroundColor DarkGray

    if (-not (Test-Path $origem)) {
        Write-Host "❌ A pasta de screenshots não foi encontrada: $origem" -ForegroundColor Red
        return
    }

    if (-Not (Test-Path -Path $destino)) {
        New-Item -Path $destino -ItemType Directory | Out-Null
    }

    Write-Host "Criando backup..."
    Compress-Archive -Path $origem -DestinationPath $backupCaminho -Force
    Write-Host "Backup criado em: $backupCaminho"

    Write-Host "Copiando arquivos..."
    Get-ChildItem -Path $origem -Filter *.png | ForEach-Object {
        $arquivo = $_.Name
        $nomeArquivo = [System.IO.Path]::GetFileNameWithoutExtension($arquivo)
        $partes = $nomeArquivo -split '_'

        if ($partes.Count -ge 4) {
            $personagem = $partes[2]
            $contexto   = $partes[3]

            $pastaPersonagem = Join-Path -Path $destino -ChildPath $personagem
            $pastaContexto   = Join-Path -Path $pastaPersonagem -ChildPath $contexto

            if (-Not (Test-Path -Path $pastaContexto)) {
                New-Item -Path $pastaContexto -ItemType Directory | Out-Null
            }

            Copy-Item -Path $_.FullName -Destination $pastaContexto
        } else {
            Write-Host "Nome de arquivo inválido: $arquivo. Pulando..." -ForegroundColor Yellow
        }
    }

    Remove-Item -Path $origem -Recurse -Force
    Write-Host "✅ Screenshots organizadas com sucesso!" -ForegroundColor Green
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
    $falhas = 0
    $i = 0

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

        $fim = $i + 2 + $tamBloco
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
            $x = $x1 -band 0x7F
            if ($x1 -band 0x80) {
                $x2 = $bloco[$j++]
                $x = ($x1 -band 0x7F) -bor (($x2 -band 0x7F) -shl 7)
                if ($x2 -band 0x80) {
                    $x3 = $bloco[$j++]
                    $x = $x -bor (($x3 -band 0x7F) -shl 14)
                }
            }

            if ($j -ge $bloco.Length -or $bloco[$j] -ne 0x10) { throw "tag y ausente" }
            $j++

            # Coordenada Y — varint de até 3 bytes
            $y1 = $bloco[$j++]
            $y = $y1 -band 0x7F
            if ($y1 -band 0x80) {
                $y2 = $bloco[$j++]
                $y = ($y1 -band 0x7F) -bor (($y2 -band 0x7F) -shl 7)
                if ($y2 -band 0x80) {
                    $y3 = $bloco[$j++]
                    $y = $y -bor (($y3 -band 0x7F) -shl 14)
                }
            }

            if ($j -ge $bloco.Length -or $bloco[$j] -ne 0x18) { throw "tag z ausente" }
            $j++

            $z = $bloco[$j]
            $chave = "$x-$y-$z"
        } catch {
            # Registra a falha com motivo e offset para facilitar debug futuro
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

function Configurar-TestServer {
    # Caminho de origem e destino fixos
    $sourceBase      = Join-Path $env:LOCALAPPDATA "Tibia\packages\Tibia"
    $destinationBase = Join-Path $env:LOCALAPPDATA "Tibia\packages\TibiaExternal"

    # Lista de pastas que serão copiadas
    $foldersToCopy = @(
        "characterdata",
        "conf",
        "minimap"
    )

    Write-Host "=== Iniciando cópia de pastas fixas ===" -ForegroundColor Cyan
    Write-Host "Origem: $sourceBase"      -ForegroundColor Yellow
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
}

# ============================================================
#  Menu principal
# ============================================================

Write-Host "`n========== Gerenciador do Tibia =========="
Write-Host "           versão $script:Versao" -ForegroundColor DarkGray
Write-Host "1 - Atualizar Minimap"
Write-Host "2 - Organizar Screenshots"
Write-Host "3 - Configurar Test Server Client"
Write-Host "9 - Reconfigurar"
Write-Host "0 - Sair"
$escolha = Read-Host "Escolha uma opção"

switch ($escolha) {
    "1" { Atualizar-Minimap }
    "2" { Organizar-Screenshots }
    "3" { Configurar-TestServer }
    "9" {
        $script:Config = Executar-Setup -Reconfigurar
        Write-Host "`nConfigurações atualizadas." -ForegroundColor Green
    }
    "0" { Write-Host "Saindo..."; exit }
    default { Write-Host "Opção inválida. Saindo..." -ForegroundColor Red; exit }
}
