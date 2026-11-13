# Minezao

Servidor de Minecraft **Fabric 1.21.10** gerenciado com [packwiz](https://packwiz.infra.link/),
empacotado em Docker e implantado automaticamente numa VPS via GitHub Actions.

Este repositório funciona como um **template** de servidor moddado: a lista de mods, os
datapacks, o resourcepack e a infraestrutura de deploy vivem versionados aqui, e o próprio
`.mrpack` entregue ao servidor é gerado a partir deles.

| | |
|---|---|
| Minecraft | `1.21.10` |
| Loader | Fabric `0.20.1` |
| Java | 21 |
| Gerenciamento de mods | packwiz → `.mrpack` (formato Modrinth) |
| Hospedagem | Docker Compose (`itzg/minecraft-server`) |
| Deploy | GitHub Actions → SSH na VPS |

## Estrutura

```
.
├── pack.toml              # Manifesto packwiz (versões do MC/Fabric)
├── index.toml             # Índice de arquivos do pack (hashes)
├── mods/                  # Um .pw.toml por mod (metadados + hash + fonte Modrinth)
├── datapacks/             # Datapacks incluídos no pack
├── resourcepack/          # Fontes do resourcepack "textura-jombastica"
├── dist/                  # Artefatos gerados: minezao.mrpack e o .zip do resourcepack
├── scripts/
│   └── gera-mrpack.sh     # Refaz o índice e exporta o .mrpack
├── docker-compose.yml     # Serviços do servidor + backups automáticos
└── .github/workflows/     # Deploy automático no push para main
```

> `data/`, `backups/`, `.env` e os artefatos de `dist/` são ignorados no versionamento
> (veja `.gitignore`). O `.packwizignore` garante que infra e arquivos de servidor **não**
> entrem no `.mrpack` enviado aos clientes.

## Mods incluídos

Todos gerenciados via packwiz (origem Modrinth, com hash verificado):

- **Fabric API**, **Cloth Config** — dependências de base
- **Lithium**, **C2ME** — otimização de performance do servidor
- **Simple Voice Chat** — chat de voz (porta UDP `24454`)
- **AudioPlayer** — discos/áudio customizado
- **Datapack Injector**, **Inhabitor** — suporte a datapacks e simulação de chunks
- **Spark**, **Fabric Exporter**, **SHA1 Runtime** — profiling e utilitários

Cada mod é um arquivo `mods/<nome>.pw.toml`. Para atualizar as versões, use o packwiz
(veja abaixo) — não edite as URLs/hashes à mão.

## Datapacks

Ficam em `datapacks/` e são embutidos no pack:

- `datapack-jombastico` — datapack próprio do servidor
- Multiplayer Sleep, AFK Display, Painting Picker, Track Raw Statistics (de terceiros)

## Pré-requisitos

- [packwiz](https://packwiz.infra.link/installation/) no PATH
- Docker + Docker Compose (para rodar o servidor)

## Gerando o modpack

Depois de adicionar/atualizar mods ou datapacks, regenere o `.mrpack`:

```sh
./scripts/gera-mrpack.sh
```

O script roda `packwiz refresh` (recalcula o `index.toml`) e exporta
`dist/minezao.mrpack`.

Comandos úteis do packwiz:

```sh
packwiz modrinth add <slug>   # adiciona um mod do Modrinth
packwiz update --all          # atualiza todos os mods
packwiz refresh               # recalcula hashes do índice
```

## Rodando o servidor

O `docker-compose.yml` sobe dois serviços:

- **`minecraft`** — `itzg/minecraft-server:java21`, carregando o `dist/minezao.mrpack`
  (`TYPE: MODRINTH`), 5 GB de heap com Aikar flags, dificuldade `hard`, whitelist e RCON
  habilitados.
- **`backups`** — `itzg/mc-backup`, snapshot do mundo a cada 1 h (zstd), mantendo os 3 mais
  recentes e pausando quando não há jogadores online.

### Configuração

É necessário um arquivo `.env` na raiz com a senha do RCON (usada pelo servidor e pelo
serviço de backup):

```env
RCON_PASSWORD=troque-isto
```

Depois:

```sh
docker compose up -d        # sobe servidor + backups
docker compose logs -f minecraft
docker compose down
```

Portas expostas:

| Porta | Protocolo | Uso |
|-------|-----------|-----|
| `25565` | TCP | Jogo |
| `24454` | UDP | Simple Voice Chat |

> **Whitelist e OPs** estão fixados no `docker-compose.yml`. O resourcepack é servido
> direto do GitHub (`dist/textura-jombastica.zip`) e é **obrigatório** (`RESOURCE_PACK_ENFORCE`).
> Ao trocar o resourcepack, atualize também o `RESOURCE_PACK_SHA1`.

## Deploy automático

O workflow `.github/workflows/deploy.yml` roda a cada push na `main` (ou manualmente via
*workflow dispatch*). Ele conecta na VPS por SSH e dispara a atualização do servidor.

Secrets necessários no ambiente `deploy` do repositório:

| Secret | Descrição |
|--------|-----------|
| `SSH_PRIVATE_KEY` | Chave privada de deploy |
| `SSH_KNOWN_HOSTS` | Known hosts da VPS (verificação estrita) |
| `SSH_HOST` | Host/IP da VPS |

A conexão usa `StrictHostKeyChecking=yes` e `IdentitiesOnly=yes`; a chave é escrita com
permissão `600` e removida ao fim do job.

## Segurança

- `ONLINE_MODE=TRUE` e whitelist obrigatória (`ENFORCE_WHITELIST`).
- A senha do RCON vem de variável de ambiente (`.env`), **nunca** versionada.
- Deploy por SSH com host key verificada e chave efêmera.
- Volume de `dist/` montado como somente-leitura no container.

---

*Template pessoal — ajuste whitelist, OPs, MOTD e lista de mods conforme o seu servidor.*
