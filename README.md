# 🎮 Tibia Manager

Utilitário para automatizar tarefas repetitivas do Tibia no Windows: atualização de minimap, organização de screenshots, sincronização com o Test Server e gestão de backups.

---

## ✨ Funcionalidades

### 🗺️ Atualizar Minimap
- Download do minimap completo via [tibiamaps.io](https://tibiamaps.io)
- Opção de combinar seus marcadores atuais com os do mapa novo
- Backup automático criado antes de qualquer substituição

### 📸 Organizar Screenshots
- Move screenshots da pasta do Tibia para o destino configurado
- Organiza automaticamente em subpastas por personagem e contexto
- Cria backup compactado antes de mover

### 🔁 Configurar Test Server
- Copia pastas `characterdata`, `conf` e `minimap` do cliente principal para o Test Server
- Útil para manter a mesma configuração nos dois clientes

### 💾 Gerenciar Backups do Minimap
- Lista todos os backups disponíveis com data e tamanho
- Restaura qualquer backup anterior com um clique (salva o estado atual antes de restaurar)
- Limpa backups antigos mantendo apenas o mais recente

---

## 🚀 Como usar

### Opção 1 — Executável (recomendado)
1. Acesse a [última release](https://github.com/vitorruiz/tibia-manager/releases/latest)
2. Baixe o `TibiaManager.exe`
3. Execute — na primeira vez um assistente de configuração será exibido
4. Pronto, sem instalação necessária

> ⚠️ Se o Windows bloquear a execução, clique em **"Mais informações" → "Executar assim mesmo"**

### Opção 2 — Script PowerShell
```powershell
.\script.ps1
```
> Requer PowerShell 5.1 ou superior (já incluso no Windows 10/11)

---

## ⚙️ Configuração

Na primeira execução o Tibia Manager verifica a instalação do Tibia e solicita:

| Campo | Padrão |
|---|---|
| Pasta de destino das screenshots | `%USERPROFILE%\OneDrive\Pictures\Tibia Screenshots` |
| Pasta de backups | `%APPDATA%\TibiaManager\backups` |

As configurações são salvas em:
```
%APPDATA%\TibiaManager\config.json
```

Para alterar a qualquer momento, escolha a opção **9 - Reconfigurar** no menu principal.

### Estrutura de backups

```
%APPDATA%\TibiaManager\
├── config.json
└── backups\
    ├── minimap\
    │   ├── minimap-backup-20250101-120000.zip
    │   └── minimap-backup-20250605-183000.zip
    └── screenshots\
        └── screenshots-backup-20250605-183000.zip
```

---

## 🔄 Auto-update

O Tibia Manager verifica automaticamente se há uma nova versão disponível ao iniciar. Caso haja, oferece a opção de atualizar — o download e a substituição do executável são feitos automaticamente.

Para verificar manualmente, escolha a opção **8 - Verificar atualizações** no menu.

---

## 🛠️ Build local

Para gerar o executável na sua própria máquina:

```powershell
.\build.ps1
```

O script instala o módulo `ps2exe` automaticamente se necessário e gera o `TibiaManager.exe` na pasta do projeto.

**Ícone personalizado:** coloque um arquivo `icon.ico` na raiz do projeto antes de rodar o build.

---

## 🔖 Versionamento

As releases são geradas automaticamente a cada commit na branch `main` seguindo [Conventional Commits](https://www.conventionalcommits.org):

| Prefixo do commit | Tipo de bump | Exemplo |
|---|---|---|
| `fix:`, outros | patch | `v1.0.3` → `v1.0.4` |
| `feat:` | minor | `v1.0.4` → `v1.1.0` |
| `breaking:`, `major:` | major | `v1.1.0` → `v2.0.0` |
