# Evolution API - Easyscale

Self-hosted WhatsApp API usando [Evolution API](https://github.com/EvolutionAPI/evolution-api) como substituto do z-api.

## Stack

- **Evolution API** — API REST para WhatsApp (open source)
- **PostgreSQL 15** — Banco de dados
- **Redis 7** — Cache e filas

---

## Deploy no Easypanel

### Pré-requisitos

- VPS com [Easypanel](https://easypanel.io) instalado
- Domínio apontando para a VPS

### Passo a passo

1. **No Easypanel**, crie um novo projeto (ex: `evolution`)

2. **Adicione o repositório GitHub** como fonte do projeto

3. **Configure as variáveis de ambiente** no painel do serviço `evolution-api`:

   | Variável | Descrição | Exemplo |
   |---|---|---|
   | `AUTHENTICATION_API_KEY` | Chave de acesso à API | `sua-chave-forte-aqui` |
   | `POSTGRES_PASSWORD` | Senha do PostgreSQL | `senha-forte-postgres` |
   | `POSTGRES_USER` | Usuário do PostgreSQL | `evolution` |
   | `POSTGRES_DB` | Nome do banco | `evolution` |
   | `REDIS_PASSWORD` | Senha do Redis | `senha-forte-redis` |

4. **Deploy** — o Easypanel vai subir os 3 serviços automaticamente

5. Acesse `https://seu-dominio.com` para verificar se a API está rodando

---

## Deploy Local (desenvolvimento)

```bash
# 1. Copie o .env de exemplo
cp .env.example .env

# 2. Edite as senhas e configurações
nano .env

# 3. Suba os containers
docker compose up -d

# 4. Verifique os logs
docker compose logs -f evolution-api
```

A API ficará disponível em `http://localhost:8080`.

---

## Primeiros passos após o deploy

### 1. Criar uma instância WhatsApp

```bash
curl -X POST https://sua-url.com/instance/create \
  -H "apikey: SUA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "clinica-principal",
    "integration": "WHATSAPP-BAILEYS",
    "webhook": "https://seu-n8n.com/webhook/whatsapp",
    "webhookByEvents": false,
    "events": [
      "MESSAGES_UPSERT",
      "CONNECTION_UPDATE",
      "QRCODE_UPDATED"
    ]
  }'
```

### 2. Conectar via QR Code

```bash
curl -X GET https://sua-url.com/instance/connect/clinica-principal \
  -H "apikey: SUA_API_KEY"
```

Acesse a URL retornada para escanear o QR Code.

### 3. Enviar mensagem

```bash
curl -X POST https://sua-url.com/message/sendText/clinica-principal \
  -H "apikey: SUA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "5511999999999",
    "text": "Olá! Mensagem de teste."
  }'
```

---

## Mapeamento z-api → Evolution API

| Ação | z-api | Evolution API |
|---|---|---|
| Enviar texto | `POST /send-text` | `POST /message/sendText/{instance}` |
| Enviar imagem | `POST /send-image` | `POST /message/sendMedia/{instance}` |
| Enviar áudio | `POST /send-audio` | `POST /message/sendWhatsAppAudio/{instance}` |
| Status conexão | `GET /status` | `GET /instance/connectionState/{instance}` |
| QR Code | `GET /qr-code` | `GET /instance/connect/{instance}` |

### Formato do Webhook recebido

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
      "fromMe": false,
      "id": "MSG_ID"
    },
    "message": {
      "conversation": "Olá"
    },
    "messageType": "conversation",
    "pushName": "Nome do Contato"
  }
}
```

> **Atenção no n8n:** atualize os campos de leitura do webhook de `body.phone` para `body.data.key.remoteJid` e de `body.text` para `body.data.message.conversation`.

---

## Endpoints úteis

| Método | Endpoint | Descrição |
|---|---|---|
| `GET` | `/` | Health check |
| `GET` | `/instance/fetchInstances` | Listar instâncias |
| `POST` | `/instance/create` | Criar instância |
| `DELETE` | `/instance/delete/{instance}` | Deletar instância |
| `GET` | `/instance/connect/{instance}` | QR Code para conectar |
| `GET` | `/instance/connectionState/{instance}` | Status da conexão |
| `POST` | `/message/sendText/{instance}` | Enviar texto |
| `POST` | `/message/sendMedia/{instance}` | Enviar mídia |
| `POST` | `/webhook/set/{instance}` | Configurar webhook |

Documentação completa: `https://sua-url.com/docs`

---

## Segurança

- Nunca exponha a `AUTHENTICATION_API_KEY` publicamente
- Use HTTPS sempre (Easypanel configura automaticamente via Let's Encrypt)
- Considere colocar a API atrás de um reverse proxy com rate limiting
