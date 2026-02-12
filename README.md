# Evolution API - Easyscale

Self-hosted WhatsApp API usando [Evolution API](https://github.com/EvolutionAPI/evolution-api) como substituto do z-api, hospedado no Easypanel.

## Stack

- **Evolution API** — API REST para WhatsApp (open source, imagem Docker oficial)
- **Redis 7** — Cache e filas (local na VPS)
- **PostgreSQL** — Supabase (externo) ou local via Docker

---

## Deploy no Easypanel

### Como funciona o deploy

O Easypanel detecta o `Dockerfile` e faz o build da imagem `atendai/evolution-api:latest` diretamente. Não há código fonte para compilar — o `Dockerfile` apenas referencia a imagem oficial.

### Pré-requisitos

- VPS com [Easypanel](https://easypanel.io) instalado
- Domínio apontando para a VPS
- Projeto criado no Supabase (ou use PostgreSQL local)

### Passo a passo no Easypanel

**1. Crie um novo projeto** (ex: `easyscale`)

**2. Adicione o serviço Evolution API:**
- Tipo: **App**
- Source: **GitHub** → `jefersonalvarenga/evolution-api`
- Branch: `main`
- Build method: **Dockerfile** (detectado automaticamente)
- Porta: `8080`

**3. Adicione o serviço Redis:**
- Tipo: **Redis**
- Defina uma senha forte

**4. Configure as variáveis de ambiente** no serviço `evolution-api`:

| Variável | Onde obter |
|---|---|
| `SERVER_URL` | URL pública do serviço (ex: `https://evolution.seudominio.com`) |
| `AUTHENTICATION_API_KEY` | Gere com `openssl rand -hex 32` |
| `DATABASE_URL` | Supabase → Settings → Database → URI (connection pooling) |
| `CACHE_REDIS_URI` | `redis://:SENHA@nome-servico-redis:6379/1` |
| `REDIS_PASSWORD` | Senha definida no serviço Redis |

> **Dica:** No Easypanel, o hostname do Redis é o nome do serviço dentro do projeto.
> Exemplo: se o projeto é `easyscale` e o serviço Redis é `redis`, use `easyscale_redis` ou apenas `redis` dependendo da versão do Easypanel.

**5. Aponte o domínio** para o serviço — HTTPS via Let's Encrypt é automático

**6. Deploy** e aguarde o container subir (~1-2 min na primeira vez)

**7. Verifique:** acesse `https://seu-dominio.com` — deve retornar `{"status":"online"}`

---

## Banco de dados: Supabase vs PostgreSQL local

| | Supabase | PostgreSQL local |
|---|---|---|
| Custo | Grátis (até 500MB) | Grátis |
| Manutenção | Zero | Você gerencia backups |
| Performance | Boa (latência de rede) | Ótima (local) |
| Recomendado | ✅ Se já usa Supabase | Se quiser isolamento total |

**Para usar Supabase:**
- Pegue a connection string em: Supabase → Settings → Database → **Connection pooling** → URI
- Use a porta `6543` (pooler) para produção, não `5432` diretamente

**Para usar PostgreSQL local:**
```bash
docker compose --profile local-db up -d
# DATABASE_URL=postgresql://evolution:senha@postgres:5432/evolution?schema=public
```

---

## Desenvolvimento local

```bash
# 1. Clone o repositório
git clone git@github.com:jefersonalvarenga/evolution-api.git
cd evolution-api

# 2. Copie e configure o .env
cp .env.example .env
# Edite .env com suas configurações

# 3. Suba os containers (usando Supabase como banco)
docker compose up -d

# 4. Acompanhe os logs
docker compose logs -f evolution-api

# Ou com PostgreSQL local:
docker compose --profile local-db up -d
```

API disponível em `http://localhost:8080`

---

## Primeiros passos após o deploy

### 1. Criar instância WhatsApp

```bash
curl -X POST https://SUA_URL/instance/create \
  -H "apikey: SUA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "clinica-principal",
    "integration": "WHATSAPP-BAILEYS",
    "webhook": "https://seu-n8n.com/webhook/whatsapp",
    "webhookByEvents": false,
    "events": ["MESSAGES_UPSERT", "CONNECTION_UPDATE", "QRCODE_UPDATED"]
  }'
```

### 2. Conectar via QR Code

```bash
curl -X GET https://SUA_URL/instance/connect/clinica-principal \
  -H "apikey: SUA_API_KEY"
```

Abra a URL retornada e escaneie o QR Code com o WhatsApp.

### 3. Enviar mensagem

```bash
curl -X POST https://SUA_URL/message/sendText/clinica-principal \
  -H "apikey: SUA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "5511999999999",
    "text": "Olá! Teste da Evolution API."
  }'
```

---

## Migração do z-api → Evolution API

### Endpoints

| Ação | z-api | Evolution API |
|---|---|---|
| Enviar texto | `POST /send-text` | `POST /message/sendText/{instance}` |
| Enviar imagem | `POST /send-image` | `POST /message/sendMedia/{instance}` |
| Enviar áudio | `POST /send-audio` | `POST /message/sendWhatsAppAudio/{instance}` |
| Status conexão | `GET /status` | `GET /instance/connectionState/{instance}` |
| QR Code | `GET /qr-code` | `GET /instance/connect/{instance}` |

### Formato do Webhook recebido (atualizar no n8n)

**z-api (antigo):**
```json
{
  "phone": "5511999999999",
  "body": "Olá",
  "isGroupMsg": false
}
```

**Evolution API (novo):**
```json
{
  "event": "messages.upsert",
  "instance": "clinica-principal",
  "data": {
    "key": {
      "remoteJid": "5511999999999@s.whatsapp.net",
      "fromMe": false
    },
    "message": {
      "conversation": "Olá"
    },
    "pushName": "Nome do Contato"
  }
}
```

**Campos para atualizar no n8n:**

| Dado | z-api | Evolution API |
|---|---|---|
| Número do contato | `{{$json.phone}}` | `{{$json.data.key.remoteJid.split('@')[0]}}` |
| Texto da mensagem | `{{$json.body}}` | `{{$json.data.message.conversation}}` |
| Nome do contato | `{{$json.senderName}}` | `{{$json.data.pushName}}` |
| É grupo? | `{{$json.isGroupMsg}}` | `{{$json.data.key.remoteJid.includes('@g.us')}}` |

---

## Endpoints de referência

| Método | Endpoint | Descrição |
|---|---|---|
| `GET` | `/` | Health check |
| `GET` | `/instance/fetchInstances` | Listar todas as instâncias |
| `POST` | `/instance/create` | Criar instância |
| `DELETE` | `/instance/delete/{instance}` | Deletar instância |
| `GET` | `/instance/connect/{instance}` | QR Code / conectar |
| `GET` | `/instance/connectionState/{instance}` | Status da conexão |
| `POST` | `/message/sendText/{instance}` | Enviar texto |
| `POST` | `/message/sendMedia/{instance}` | Enviar mídia |
| `POST` | `/webhook/set/{instance}` | Configurar webhook |
| `GET` | `/webhook/find/{instance}` | Ver webhook configurado |

Swagger completo: `https://SUA_URL/docs`
