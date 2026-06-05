[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$script:Versao = "dev"

# Carrega módulos — em modo dev usa dot-sourcing; no build o conteúdo é concatenado
$modules = @("config", "update", "minimap", "screenshots", "testserver", "backups")
foreach ($m in $modules) {
    . "$PSScriptRoot\src\$m.ps1"
}

# ============================================================
#  Inicialização
# ============================================================

$script:Config = Carregar-Config
if ($null -eq $script:Config) {
    $script:Config = Executar-Setup
}

Verificar-Atualizacao -Silencioso

# ============================================================
#  Menu principal
# ============================================================

while ($true) {
    Write-Host "`n========== Gerenciador do Tibia =========="
    Write-Host "           versão $script:Versao" -ForegroundColor DarkGray
    Write-Host "1 - Atualizar Minimap"
    Write-Host "2 - Organizar Screenshots"
    Write-Host "3 - Configurar Test Server Client"
    Write-Host "4 - Gerenciar Backups do Minimap"
    Write-Host "8 - Verificar atualizações"
    Write-Host "9 - Reconfigurar"
    Write-Host "0 - Sair"
    $escolha = Read-Host "Escolha uma opção"

    switch ($escolha) {
        "1" { Atualizar-Minimap }
        "2" { Organizar-Screenshots }
        "3" { Configurar-TestServer }
        "4" { Gerenciar-Backups }
        "8" { Verificar-Atualizacao }
        "9" {
            $script:Config = Executar-Setup -Reconfigurar
            Write-Host "`nConfigurações atualizadas." -ForegroundColor Green
        }
        "0" { Write-Host "Saindo..."; exit }
        default { Write-Host "Opção inválida." -ForegroundColor Red }
    }
}
