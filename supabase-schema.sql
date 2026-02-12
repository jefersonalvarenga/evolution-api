-- ============================================================
-- Evolution API v2.2.3 - Schema SQL para Supabase
-- Gerado a partir do prisma/postgresql-schema.prisma oficial
--
-- Como usar:
-- 1. Abra o Supabase → SQL Editor
-- 2. Cole este conteúdo e clique em "Run"
-- 3. Todas as tabelas serão criadas no schema "public"
-- ============================================================

-- Enums
CREATE TYPE "InstanceConnectionStatus" AS ENUM ('open', 'close', 'connecting');
CREATE TYPE "DeviceMessage" AS ENUM ('ios', 'android', 'web', 'unknown', 'desktop');
CREATE TYPE "SessionStatus" AS ENUM ('opened', 'closed', 'paused');
CREATE TYPE "TriggerType" AS ENUM ('all', 'keyword', 'none', 'advanced');
CREATE TYPE "TriggerOperator" AS ENUM ('contains', 'equals', 'startsWith', 'endsWith', 'regex');
CREATE TYPE "OpenaiBotType" AS ENUM ('assistant', 'chatCompletion');
CREATE TYPE "DifyBotType" AS ENUM ('chatBot', 'textGenerator', 'agent', 'workflow');

-- ============================================================
-- Tabela principal: Instance
-- ============================================================
CREATE TABLE "Instance" (
    "id"                      TEXT         NOT NULL,
    "name"                    VARCHAR(255) NOT NULL,
    "connectionStatus"        "InstanceConnectionStatus" NOT NULL DEFAULT 'open',
    "ownerJid"                VARCHAR(100),
    "profileName"             VARCHAR(100),
    "profilePicUrl"           VARCHAR(500),
    "integration"             VARCHAR(100),
    "number"                  VARCHAR(100),
    "businessId"              VARCHAR(100),
    "token"                   VARCHAR(255),
    "clientName"              VARCHAR(100),
    "disconnectionReasonCode" INTEGER,
    "disconnectionObject"     JSONB,
    "disconnectionAt"         TIMESTAMP,
    "createdAt"               TIMESTAMP    DEFAULT NOW(),
    "updatedAt"               TIMESTAMP,

    CONSTRAINT "Instance_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Instance_name_key" ON "Instance"("name");

-- ============================================================
-- Session
-- ============================================================
CREATE TABLE "Session" (
    "id"        TEXT      NOT NULL,
    "sessionId" TEXT      NOT NULL,
    "creds"     TEXT,
    "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Session_sessionId_key" ON "Session"("sessionId");
ALTER TABLE "Session" ADD CONSTRAINT "Session_sessionId_fkey"
    FOREIGN KEY ("sessionId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Chat
-- ============================================================
CREATE TABLE "Chat" (
    "id"             TEXT         NOT NULL,
    "remoteJid"      VARCHAR(100) NOT NULL,
    "name"           VARCHAR(100),
    "labels"         JSONB,
    "createdAt"      TIMESTAMP    DEFAULT NOW(),
    "updatedAt"      TIMESTAMP,
    "instanceId"     TEXT         NOT NULL,
    "unreadMessages" INTEGER      NOT NULL DEFAULT 0,

    CONSTRAINT "Chat_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Chat_instanceId_remoteJid_key" ON "Chat"("instanceId", "remoteJid");
CREATE INDEX "Chat_instanceId_idx" ON "Chat"("instanceId");
CREATE INDEX "Chat_remoteJid_idx" ON "Chat"("remoteJid");
ALTER TABLE "Chat" ADD CONSTRAINT "Chat_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Contact
-- ============================================================
CREATE TABLE "Contact" (
    "id"            TEXT         NOT NULL,
    "remoteJid"     VARCHAR(100) NOT NULL,
    "pushName"      VARCHAR(100),
    "profilePicUrl" VARCHAR(500),
    "createdAt"     TIMESTAMP    DEFAULT NOW(),
    "updatedAt"     TIMESTAMP,
    "instanceId"    TEXT         NOT NULL,

    CONSTRAINT "Contact_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Contact_remoteJid_instanceId_key" ON "Contact"("remoteJid", "instanceId");
CREATE INDEX "Contact_remoteJid_idx" ON "Contact"("remoteJid");
CREATE INDEX "Contact_instanceId_idx" ON "Contact"("instanceId");
ALTER TABLE "Contact" ADD CONSTRAINT "Contact_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- IntegrationSession (necessária antes de Message)
-- ============================================================
CREATE TABLE "IntegrationSession" (
    "id"         TEXT           NOT NULL,
    "sessionId"  VARCHAR(255)   NOT NULL,
    "remoteJid"  VARCHAR(100)   NOT NULL,
    "pushName"   TEXT,
    "status"     "SessionStatus" NOT NULL,
    "awaitUser"  BOOLEAN        NOT NULL DEFAULT FALSE,
    "context"    JSONB,
    "type"       VARCHAR(100),
    "createdAt"  TIMESTAMP      DEFAULT NOW(),
    "updatedAt"  TIMESTAMP      NOT NULL,
    "instanceId" TEXT           NOT NULL,
    "parameters" JSONB,
    "botId"      TEXT,

    CONSTRAINT "IntegrationSession_pkey" PRIMARY KEY ("id")
);
ALTER TABLE "IntegrationSession" ADD CONSTRAINT "IntegrationSession_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Message
-- ============================================================
CREATE TABLE "Message" (
    "id"                           TEXT          NOT NULL,
    "key"                          JSONB         NOT NULL,
    "pushName"                     VARCHAR(100),
    "participant"                  VARCHAR(100),
    "messageType"                  VARCHAR(100)  NOT NULL,
    "message"                      JSONB         NOT NULL,
    "contextInfo"                  JSONB,
    "source"                       "DeviceMessage" NOT NULL,
    "messageTimestamp"             INTEGER       NOT NULL,
    "chatwootMessageId"            INTEGER,
    "chatwootInboxId"              INTEGER,
    "chatwootConversationId"       INTEGER,
    "chatwootContactInboxSourceId" VARCHAR(100),
    "chatwootIsRead"               BOOLEAN,
    "instanceId"                   TEXT          NOT NULL,
    "webhookUrl"                   VARCHAR(500),
    "status"                       VARCHAR(30),
    "sessionId"                    TEXT,

    CONSTRAINT "Message_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "Message_instanceId_idx" ON "Message"("instanceId");
ALTER TABLE "Message" ADD CONSTRAINT "Message_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;
ALTER TABLE "Message" ADD CONSTRAINT "Message_sessionId_fkey"
    FOREIGN KEY ("sessionId") REFERENCES "IntegrationSession"("id");

-- ============================================================
-- MessageUpdate
-- ============================================================
CREATE TABLE "MessageUpdate" (
    "id"          TEXT         NOT NULL,
    "keyId"       VARCHAR(100) NOT NULL,
    "remoteJid"   VARCHAR(100) NOT NULL,
    "fromMe"      BOOLEAN      NOT NULL,
    "participant" VARCHAR(100),
    "pollUpdates" JSONB,
    "status"      VARCHAR(30)  NOT NULL,
    "messageId"   TEXT         NOT NULL,
    "instanceId"  TEXT         NOT NULL,

    CONSTRAINT "MessageUpdate_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "MessageUpdate_instanceId_idx" ON "MessageUpdate"("instanceId");
CREATE INDEX "MessageUpdate_messageId_idx" ON "MessageUpdate"("messageId");
ALTER TABLE "MessageUpdate" ADD CONSTRAINT "MessageUpdate_messageId_fkey"
    FOREIGN KEY ("messageId") REFERENCES "Message"("id") ON DELETE CASCADE;
ALTER TABLE "MessageUpdate" ADD CONSTRAINT "MessageUpdate_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Media
-- ============================================================
CREATE TABLE "Media" (
    "id"         TEXT         NOT NULL,
    "fileName"   VARCHAR(500) NOT NULL,
    "type"       VARCHAR(100) NOT NULL,
    "mimetype"   VARCHAR(100) NOT NULL,
    "createdAt"  DATE         DEFAULT NOW(),
    "messageId"  TEXT         NOT NULL,
    "instanceId" TEXT         NOT NULL,

    CONSTRAINT "Media_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Media_messageId_key" ON "Media"("messageId");
ALTER TABLE "Media" ADD CONSTRAINT "Media_messageId_fkey"
    FOREIGN KEY ("messageId") REFERENCES "Message"("id") ON DELETE CASCADE;
ALTER TABLE "Media" ADD CONSTRAINT "Media_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Webhook
-- ============================================================
CREATE TABLE "Webhook" (
    "id"              TEXT         NOT NULL,
    "url"             VARCHAR(500) NOT NULL,
    "headers"         JSONB,
    "enabled"         BOOLEAN      DEFAULT TRUE,
    "events"          JSONB,
    "webhookByEvents" BOOLEAN      DEFAULT FALSE,
    "webhookBase64"   BOOLEAN      DEFAULT FALSE,
    "createdAt"       TIMESTAMP    DEFAULT NOW(),
    "updatedAt"       TIMESTAMP    NOT NULL,
    "instanceId"      TEXT         NOT NULL,

    CONSTRAINT "Webhook_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Webhook_instanceId_key" ON "Webhook"("instanceId");
CREATE INDEX "Webhook_instanceId_idx" ON "Webhook"("instanceId");
ALTER TABLE "Webhook" ADD CONSTRAINT "Webhook_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Chatwoot
-- ============================================================
CREATE TABLE "Chatwoot" (
    "id"                      TEXT         NOT NULL,
    "enabled"                 BOOLEAN      DEFAULT TRUE,
    "accountId"               VARCHAR(100),
    "token"                   VARCHAR(100),
    "url"                     VARCHAR(500),
    "nameInbox"               VARCHAR(100),
    "signMsg"                 BOOLEAN      DEFAULT FALSE,
    "signDelimiter"           VARCHAR(100),
    "number"                  VARCHAR(100),
    "reopenConversation"      BOOLEAN      DEFAULT FALSE,
    "conversationPending"     BOOLEAN      DEFAULT FALSE,
    "mergeBrazilContacts"     BOOLEAN      DEFAULT FALSE,
    "importContacts"          BOOLEAN      DEFAULT FALSE,
    "importMessages"          BOOLEAN      DEFAULT FALSE,
    "daysLimitImportMessages" INTEGER,
    "organization"            VARCHAR(100),
    "logo"                    VARCHAR(500),
    "ignoreJids"              JSONB,
    "createdAt"               TIMESTAMP    DEFAULT NOW(),
    "updatedAt"               TIMESTAMP    NOT NULL,
    "instanceId"              TEXT         NOT NULL,

    CONSTRAINT "Chatwoot_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Chatwoot_instanceId_key" ON "Chatwoot"("instanceId");
ALTER TABLE "Chatwoot" ADD CONSTRAINT "Chatwoot_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Label
-- ============================================================
CREATE TABLE "Label" (
    "id"           TEXT         NOT NULL,
    "labelId"      VARCHAR(100),
    "name"         VARCHAR(100) NOT NULL,
    "color"        VARCHAR(100) NOT NULL,
    "predefinedId" VARCHAR(100),
    "createdAt"    TIMESTAMP    DEFAULT NOW(),
    "updatedAt"    TIMESTAMP    NOT NULL,
    "instanceId"   TEXT         NOT NULL,

    CONSTRAINT "Label_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Label_labelId_instanceId_key" ON "Label"("labelId", "instanceId");
ALTER TABLE "Label" ADD CONSTRAINT "Label_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Proxy
-- ============================================================
CREATE TABLE "Proxy" (
    "id"         TEXT         NOT NULL,
    "enabled"    BOOLEAN      NOT NULL DEFAULT FALSE,
    "host"       VARCHAR(100) NOT NULL,
    "port"       VARCHAR(100) NOT NULL,
    "protocol"   VARCHAR(100) NOT NULL,
    "username"   VARCHAR(100) NOT NULL,
    "password"   VARCHAR(100) NOT NULL,
    "createdAt"  TIMESTAMP    DEFAULT NOW(),
    "updatedAt"  TIMESTAMP    NOT NULL,
    "instanceId" TEXT         NOT NULL,

    CONSTRAINT "Proxy_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Proxy_instanceId_key" ON "Proxy"("instanceId");
ALTER TABLE "Proxy" ADD CONSTRAINT "Proxy_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Setting
-- ============================================================
CREATE TABLE "Setting" (
    "id"              TEXT         NOT NULL,
    "rejectCall"      BOOLEAN      NOT NULL DEFAULT FALSE,
    "msgCall"         VARCHAR(100),
    "groupsIgnore"    BOOLEAN      NOT NULL DEFAULT FALSE,
    "alwaysOnline"    BOOLEAN      NOT NULL DEFAULT FALSE,
    "readMessages"    BOOLEAN      NOT NULL DEFAULT FALSE,
    "readStatus"      BOOLEAN      NOT NULL DEFAULT FALSE,
    "syncFullHistory" BOOLEAN      NOT NULL DEFAULT FALSE,
    "wavoipToken"     VARCHAR(100),
    "createdAt"       TIMESTAMP    DEFAULT NOW(),
    "updatedAt"       TIMESTAMP    NOT NULL,
    "instanceId"      TEXT         NOT NULL,

    CONSTRAINT "Setting_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Setting_instanceId_key" ON "Setting"("instanceId");
CREATE INDEX "Setting_instanceId_idx" ON "Setting"("instanceId");
ALTER TABLE "Setting" ADD CONSTRAINT "Setting_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Rabbitmq
-- ============================================================
CREATE TABLE "Rabbitmq" (
    "id"         TEXT      NOT NULL,
    "enabled"    BOOLEAN   NOT NULL DEFAULT FALSE,
    "events"     JSONB     NOT NULL,
    "createdAt"  TIMESTAMP DEFAULT NOW(),
    "updatedAt"  TIMESTAMP NOT NULL,
    "instanceId" TEXT      NOT NULL,

    CONSTRAINT "Rabbitmq_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Rabbitmq_instanceId_key" ON "Rabbitmq"("instanceId");
ALTER TABLE "Rabbitmq" ADD CONSTRAINT "Rabbitmq_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Nats
-- ============================================================
CREATE TABLE "Nats" (
    "id"         TEXT      NOT NULL,
    "enabled"    BOOLEAN   NOT NULL DEFAULT FALSE,
    "events"     JSONB     NOT NULL,
    "createdAt"  TIMESTAMP DEFAULT NOW(),
    "updatedAt"  TIMESTAMP NOT NULL,
    "instanceId" TEXT      NOT NULL,

    CONSTRAINT "Nats_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Nats_instanceId_key" ON "Nats"("instanceId");
ALTER TABLE "Nats" ADD CONSTRAINT "Nats_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Sqs
-- ============================================================
CREATE TABLE "Sqs" (
    "id"         TEXT      NOT NULL,
    "enabled"    BOOLEAN   NOT NULL DEFAULT FALSE,
    "events"     JSONB     NOT NULL,
    "createdAt"  TIMESTAMP DEFAULT NOW(),
    "updatedAt"  TIMESTAMP NOT NULL,
    "instanceId" TEXT      NOT NULL,

    CONSTRAINT "Sqs_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Sqs_instanceId_key" ON "Sqs"("instanceId");
ALTER TABLE "Sqs" ADD CONSTRAINT "Sqs_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Kafka
-- ============================================================
CREATE TABLE "Kafka" (
    "id"         TEXT      NOT NULL,
    "enabled"    BOOLEAN   NOT NULL DEFAULT FALSE,
    "events"     JSONB     NOT NULL,
    "createdAt"  TIMESTAMP DEFAULT NOW(),
    "updatedAt"  TIMESTAMP NOT NULL,
    "instanceId" TEXT      NOT NULL,

    CONSTRAINT "Kafka_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Kafka_instanceId_key" ON "Kafka"("instanceId");
ALTER TABLE "Kafka" ADD CONSTRAINT "Kafka_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Websocket
-- ============================================================
CREATE TABLE "Websocket" (
    "id"         TEXT      NOT NULL,
    "enabled"    BOOLEAN   NOT NULL DEFAULT FALSE,
    "events"     JSONB     NOT NULL,
    "createdAt"  TIMESTAMP DEFAULT NOW(),
    "updatedAt"  TIMESTAMP NOT NULL,
    "instanceId" TEXT      NOT NULL,

    CONSTRAINT "Websocket_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Websocket_instanceId_key" ON "Websocket"("instanceId");
ALTER TABLE "Websocket" ADD CONSTRAINT "Websocket_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Pusher
-- ============================================================
CREATE TABLE "Pusher" (
    "id"         TEXT         NOT NULL,
    "enabled"    BOOLEAN      NOT NULL DEFAULT FALSE,
    "appId"      VARCHAR(100) NOT NULL,
    "key"        VARCHAR(100) NOT NULL,
    "secret"     VARCHAR(100) NOT NULL,
    "cluster"    VARCHAR(100) NOT NULL,
    "useTLS"     BOOLEAN      NOT NULL DEFAULT FALSE,
    "events"     JSONB        NOT NULL,
    "createdAt"  TIMESTAMP    DEFAULT NOW(),
    "updatedAt"  TIMESTAMP    NOT NULL,
    "instanceId" TEXT         NOT NULL,

    CONSTRAINT "Pusher_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Pusher_instanceId_key" ON "Pusher"("instanceId");
ALTER TABLE "Pusher" ADD CONSTRAINT "Pusher_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Typebot
-- ============================================================
CREATE TABLE "Typebot" (
    "id"              TEXT             NOT NULL,
    "enabled"         BOOLEAN          NOT NULL DEFAULT TRUE,
    "description"     VARCHAR(255),
    "url"             VARCHAR(500)     NOT NULL,
    "typebot"         VARCHAR(100)     NOT NULL,
    "expire"          INTEGER          DEFAULT 0,
    "keywordFinish"   VARCHAR(100),
    "delayMessage"    INTEGER,
    "unknownMessage"  VARCHAR(100),
    "listeningFromMe" BOOLEAN          DEFAULT FALSE,
    "stopBotFromMe"   BOOLEAN          DEFAULT FALSE,
    "keepOpen"        BOOLEAN          DEFAULT FALSE,
    "debounceTime"    INTEGER,
    "createdAt"       TIMESTAMP        DEFAULT NOW(),
    "updatedAt"       TIMESTAMP,
    "ignoreJids"      JSONB,
    "triggerType"     "TriggerType",
    "triggerOperator" "TriggerOperator",
    "triggerValue"    TEXT,
    "splitMessages"   BOOLEAN          DEFAULT FALSE,
    "timePerChar"     INTEGER          DEFAULT 50,
    "instanceId"      TEXT             NOT NULL,

    CONSTRAINT "Typebot_pkey" PRIMARY KEY ("id")
);
ALTER TABLE "Typebot" ADD CONSTRAINT "Typebot_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- TypebotSetting
-- ============================================================
CREATE TABLE "TypebotSetting" (
    "id"                TEXT         NOT NULL,
    "expire"            INTEGER      DEFAULT 0,
    "keywordFinish"     VARCHAR(100),
    "delayMessage"      INTEGER,
    "unknownMessage"    VARCHAR(100),
    "listeningFromMe"   BOOLEAN      DEFAULT FALSE,
    "stopBotFromMe"     BOOLEAN      DEFAULT FALSE,
    "keepOpen"          BOOLEAN      DEFAULT FALSE,
    "debounceTime"      INTEGER,
    "typebotIdFallback" VARCHAR(100),
    "ignoreJids"        JSONB,
    "splitMessages"     BOOLEAN      DEFAULT FALSE,
    "timePerChar"       INTEGER      DEFAULT 50,
    "createdAt"         TIMESTAMP    DEFAULT NOW(),
    "updatedAt"         TIMESTAMP    NOT NULL,
    "instanceId"        TEXT         NOT NULL,

    CONSTRAINT "TypebotSetting_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "TypebotSetting_instanceId_key" ON "TypebotSetting"("instanceId");
ALTER TABLE "TypebotSetting" ADD CONSTRAINT "TypebotSetting_typebotIdFallback_fkey"
    FOREIGN KEY ("typebotIdFallback") REFERENCES "Typebot"("id");
ALTER TABLE "TypebotSetting" ADD CONSTRAINT "TypebotSetting_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- OpenaiCreds
-- ============================================================
CREATE TABLE "OpenaiCreds" (
    "id"         TEXT         NOT NULL,
    "name"       VARCHAR(255),
    "apiKey"     VARCHAR(255),
    "createdAt"  TIMESTAMP    DEFAULT NOW(),
    "updatedAt"  TIMESTAMP    NOT NULL,
    "instanceId" TEXT         NOT NULL,

    CONSTRAINT "OpenaiCreds_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "OpenaiCreds_name_key" ON "OpenaiCreds"("name");
CREATE UNIQUE INDEX "OpenaiCreds_apiKey_key" ON "OpenaiCreds"("apiKey");
ALTER TABLE "OpenaiCreds" ADD CONSTRAINT "OpenaiCreds_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- OpenaiBot
-- ============================================================
CREATE TABLE "OpenaiBot" (
    "id"                TEXT              NOT NULL,
    "enabled"           BOOLEAN           NOT NULL DEFAULT TRUE,
    "description"       VARCHAR(255),
    "botType"           "OpenaiBotType"   NOT NULL,
    "assistantId"       VARCHAR(255),
    "functionUrl"       VARCHAR(500),
    "model"             VARCHAR(100),
    "systemMessages"    JSONB,
    "assistantMessages" JSONB,
    "userMessages"      JSONB,
    "maxTokens"         INTEGER,
    "expire"            INTEGER           DEFAULT 0,
    "keywordFinish"     VARCHAR(100),
    "delayMessage"      INTEGER,
    "unknownMessage"    VARCHAR(100),
    "listeningFromMe"   BOOLEAN           DEFAULT FALSE,
    "stopBotFromMe"     BOOLEAN           DEFAULT FALSE,
    "keepOpen"          BOOLEAN           DEFAULT FALSE,
    "debounceTime"      INTEGER,
    "splitMessages"     BOOLEAN           DEFAULT FALSE,
    "timePerChar"       INTEGER           DEFAULT 50,
    "ignoreJids"        JSONB,
    "triggerType"       "TriggerType",
    "triggerOperator"   "TriggerOperator",
    "triggerValue"      TEXT,
    "createdAt"         TIMESTAMP         DEFAULT NOW(),
    "updatedAt"         TIMESTAMP         NOT NULL,
    "openaiCredsId"     TEXT              NOT NULL,
    "instanceId"        TEXT              NOT NULL,

    CONSTRAINT "OpenaiBot_pkey" PRIMARY KEY ("id")
);
ALTER TABLE "OpenaiBot" ADD CONSTRAINT "OpenaiBot_openaiCredsId_fkey"
    FOREIGN KEY ("openaiCredsId") REFERENCES "OpenaiCreds"("id") ON DELETE CASCADE;
ALTER TABLE "OpenaiBot" ADD CONSTRAINT "OpenaiBot_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- OpenaiSetting
-- ============================================================
CREATE TABLE "OpenaiSetting" (
    "id"               TEXT         NOT NULL,
    "expire"           INTEGER      DEFAULT 0,
    "keywordFinish"    VARCHAR(100),
    "delayMessage"     INTEGER,
    "unknownMessage"   VARCHAR(100),
    "listeningFromMe"  BOOLEAN      DEFAULT FALSE,
    "stopBotFromMe"    BOOLEAN      DEFAULT FALSE,
    "keepOpen"         BOOLEAN      DEFAULT FALSE,
    "debounceTime"     INTEGER,
    "ignoreJids"       JSONB,
    "splitMessages"    BOOLEAN      DEFAULT FALSE,
    "timePerChar"      INTEGER      DEFAULT 50,
    "speechToText"     BOOLEAN      DEFAULT FALSE,
    "createdAt"        TIMESTAMP    DEFAULT NOW(),
    "updatedAt"        TIMESTAMP    NOT NULL,
    "openaiCredsId"    TEXT         NOT NULL,
    "openaiIdFallback" VARCHAR(100),
    "instanceId"       TEXT         NOT NULL,

    CONSTRAINT "OpenaiSetting_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "OpenaiSetting_openaiCredsId_key" ON "OpenaiSetting"("openaiCredsId");
CREATE UNIQUE INDEX "OpenaiSetting_instanceId_key" ON "OpenaiSetting"("instanceId");
ALTER TABLE "OpenaiSetting" ADD CONSTRAINT "OpenaiSetting_openaiCredsId_fkey"
    FOREIGN KEY ("openaiCredsId") REFERENCES "OpenaiCreds"("id");
ALTER TABLE "OpenaiSetting" ADD CONSTRAINT "OpenaiSetting_openaiIdFallback_fkey"
    FOREIGN KEY ("openaiIdFallback") REFERENCES "OpenaiBot"("id");
ALTER TABLE "OpenaiSetting" ADD CONSTRAINT "OpenaiSetting_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Template
-- ============================================================
CREATE TABLE "Template" (
    "id"         TEXT         NOT NULL,
    "templateId" VARCHAR(255) NOT NULL,
    "name"       VARCHAR(255) NOT NULL,
    "template"   JSONB        NOT NULL,
    "webhookUrl" VARCHAR(500),
    "createdAt"  TIMESTAMP    DEFAULT NOW(),
    "updatedAt"  TIMESTAMP    NOT NULL,
    "instanceId" TEXT         NOT NULL,

    CONSTRAINT "Template_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Template_templateId_key" ON "Template"("templateId");
CREATE UNIQUE INDEX "Template_name_key" ON "Template"("name");
ALTER TABLE "Template" ADD CONSTRAINT "Template_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Dify
-- ============================================================
CREATE TABLE "Dify" (
    "id"              TEXT             NOT NULL,
    "enabled"         BOOLEAN          NOT NULL DEFAULT TRUE,
    "description"     VARCHAR(255),
    "botType"         "DifyBotType"    NOT NULL,
    "apiUrl"          VARCHAR(255),
    "apiKey"          VARCHAR(255),
    "expire"          INTEGER          DEFAULT 0,
    "keywordFinish"   VARCHAR(100),
    "delayMessage"    INTEGER,
    "unknownMessage"  VARCHAR(100),
    "listeningFromMe" BOOLEAN          DEFAULT FALSE,
    "stopBotFromMe"   BOOLEAN          DEFAULT FALSE,
    "keepOpen"        BOOLEAN          DEFAULT FALSE,
    "debounceTime"    INTEGER,
    "ignoreJids"      JSONB,
    "splitMessages"   BOOLEAN          DEFAULT FALSE,
    "timePerChar"     INTEGER          DEFAULT 50,
    "triggerType"     "TriggerType",
    "triggerOperator" "TriggerOperator",
    "triggerValue"    TEXT,
    "createdAt"       TIMESTAMP        DEFAULT NOW(),
    "updatedAt"       TIMESTAMP        NOT NULL,
    "instanceId"      TEXT             NOT NULL,

    CONSTRAINT "Dify_pkey" PRIMARY KEY ("id")
);
ALTER TABLE "Dify" ADD CONSTRAINT "Dify_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- DifySetting
-- ============================================================
CREATE TABLE "DifySetting" (
    "id"              TEXT         NOT NULL,
    "expire"          INTEGER      DEFAULT 0,
    "keywordFinish"   VARCHAR(100),
    "delayMessage"    INTEGER,
    "unknownMessage"  VARCHAR(100),
    "listeningFromMe" BOOLEAN      DEFAULT FALSE,
    "stopBotFromMe"   BOOLEAN      DEFAULT FALSE,
    "keepOpen"        BOOLEAN      DEFAULT FALSE,
    "debounceTime"    INTEGER,
    "ignoreJids"      JSONB,
    "splitMessages"   BOOLEAN      DEFAULT FALSE,
    "timePerChar"     INTEGER      DEFAULT 50,
    "createdAt"       TIMESTAMP    DEFAULT NOW(),
    "updatedAt"       TIMESTAMP    NOT NULL,
    "difyIdFallback"  VARCHAR(100),
    "instanceId"      TEXT         NOT NULL,

    CONSTRAINT "DifySetting_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "DifySetting_instanceId_key" ON "DifySetting"("instanceId");
ALTER TABLE "DifySetting" ADD CONSTRAINT "DifySetting_difyIdFallback_fkey"
    FOREIGN KEY ("difyIdFallback") REFERENCES "Dify"("id");
ALTER TABLE "DifySetting" ADD CONSTRAINT "DifySetting_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- EvolutionBot
-- ============================================================
CREATE TABLE "EvolutionBot" (
    "id"              TEXT             NOT NULL,
    "enabled"         BOOLEAN          NOT NULL DEFAULT TRUE,
    "description"     VARCHAR(255),
    "apiUrl"          VARCHAR(255),
    "apiKey"          VARCHAR(255),
    "expire"          INTEGER          DEFAULT 0,
    "keywordFinish"   VARCHAR(100),
    "delayMessage"    INTEGER,
    "unknownMessage"  VARCHAR(100),
    "listeningFromMe" BOOLEAN          DEFAULT FALSE,
    "stopBotFromMe"   BOOLEAN          DEFAULT FALSE,
    "keepOpen"        BOOLEAN          DEFAULT FALSE,
    "debounceTime"    INTEGER,
    "ignoreJids"      JSONB,
    "splitMessages"   BOOLEAN          DEFAULT FALSE,
    "timePerChar"     INTEGER          DEFAULT 50,
    "triggerType"     "TriggerType",
    "triggerOperator" "TriggerOperator",
    "triggerValue"    TEXT,
    "createdAt"       TIMESTAMP        DEFAULT NOW(),
    "updatedAt"       TIMESTAMP        NOT NULL,
    "instanceId"      TEXT             NOT NULL,

    CONSTRAINT "EvolutionBot_pkey" PRIMARY KEY ("id")
);
ALTER TABLE "EvolutionBot" ADD CONSTRAINT "EvolutionBot_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- EvolutionBotSetting
-- ============================================================
CREATE TABLE "EvolutionBotSetting" (
    "id"              TEXT         NOT NULL,
    "expire"          INTEGER      DEFAULT 0,
    "keywordFinish"   VARCHAR(100),
    "delayMessage"    INTEGER,
    "unknownMessage"  VARCHAR(100),
    "listeningFromMe" BOOLEAN      DEFAULT FALSE,
    "stopBotFromMe"   BOOLEAN      DEFAULT FALSE,
    "keepOpen"        BOOLEAN      DEFAULT FALSE,
    "debounceTime"    INTEGER,
    "ignoreJids"      JSONB,
    "splitMessages"   BOOLEAN      DEFAULT FALSE,
    "timePerChar"     INTEGER      DEFAULT 50,
    "createdAt"       TIMESTAMP    DEFAULT NOW(),
    "updatedAt"       TIMESTAMP    NOT NULL,
    "botIdFallback"   VARCHAR(100),
    "instanceId"      TEXT         NOT NULL,

    CONSTRAINT "EvolutionBotSetting_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "EvolutionBotSetting_instanceId_key" ON "EvolutionBotSetting"("instanceId");
ALTER TABLE "EvolutionBotSetting" ADD CONSTRAINT "EvolutionBotSetting_botIdFallback_fkey"
    FOREIGN KEY ("botIdFallback") REFERENCES "EvolutionBot"("id");
ALTER TABLE "EvolutionBotSetting" ADD CONSTRAINT "EvolutionBotSetting_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Flowise
-- ============================================================
CREATE TABLE "Flowise" (
    "id"              TEXT             NOT NULL,
    "enabled"         BOOLEAN          NOT NULL DEFAULT TRUE,
    "description"     VARCHAR(255),
    "apiUrl"          VARCHAR(255),
    "apiKey"          VARCHAR(255),
    "expire"          INTEGER          DEFAULT 0,
    "keywordFinish"   VARCHAR(100),
    "delayMessage"    INTEGER,
    "unknownMessage"  VARCHAR(100),
    "listeningFromMe" BOOLEAN          DEFAULT FALSE,
    "stopBotFromMe"   BOOLEAN          DEFAULT FALSE,
    "keepOpen"        BOOLEAN          DEFAULT FALSE,
    "debounceTime"    INTEGER,
    "ignoreJids"      JSONB,
    "splitMessages"   BOOLEAN          DEFAULT FALSE,
    "timePerChar"     INTEGER          DEFAULT 50,
    "triggerType"     "TriggerType",
    "triggerOperator" "TriggerOperator",
    "triggerValue"    TEXT,
    "createdAt"       TIMESTAMP        DEFAULT NOW(),
    "updatedAt"       TIMESTAMP        NOT NULL,
    "instanceId"      TEXT             NOT NULL,

    CONSTRAINT "Flowise_pkey" PRIMARY KEY ("id")
);
ALTER TABLE "Flowise" ADD CONSTRAINT "Flowise_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- FlowiseSetting
-- ============================================================
CREATE TABLE "FlowiseSetting" (
    "id"                TEXT         NOT NULL,
    "expire"            INTEGER      DEFAULT 0,
    "keywordFinish"     VARCHAR(100),
    "delayMessage"      INTEGER,
    "unknownMessage"    VARCHAR(100),
    "listeningFromMe"   BOOLEAN      DEFAULT FALSE,
    "stopBotFromMe"     BOOLEAN      DEFAULT FALSE,
    "keepOpen"          BOOLEAN      DEFAULT FALSE,
    "debounceTime"      INTEGER,
    "ignoreJids"        JSONB,
    "splitMessages"     BOOLEAN      DEFAULT FALSE,
    "timePerChar"       INTEGER      DEFAULT 50,
    "createdAt"         TIMESTAMP    DEFAULT NOW(),
    "updatedAt"         TIMESTAMP    NOT NULL,
    "flowiseIdFallback" VARCHAR(100),
    "instanceId"        TEXT         NOT NULL,

    CONSTRAINT "FlowiseSetting_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "FlowiseSetting_instanceId_key" ON "FlowiseSetting"("instanceId");
ALTER TABLE "FlowiseSetting" ADD CONSTRAINT "FlowiseSetting_flowiseIdFallback_fkey"
    FOREIGN KEY ("flowiseIdFallback") REFERENCES "Flowise"("id");
ALTER TABLE "FlowiseSetting" ADD CONSTRAINT "FlowiseSetting_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- IsOnWhatsapp
-- ============================================================
CREATE TABLE "IsOnWhatsapp" (
    "id"         TEXT         NOT NULL,
    "remoteJid"  VARCHAR(100) NOT NULL,
    "jidOptions" TEXT         NOT NULL,
    "lid"        VARCHAR(100),
    "createdAt"  TIMESTAMP    NOT NULL DEFAULT NOW(),
    "updatedAt"  TIMESTAMP    NOT NULL,

    CONSTRAINT "IsOnWhatsapp_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "IsOnWhatsapp_remoteJid_key" ON "IsOnWhatsapp"("remoteJid");

-- ============================================================
-- N8n
-- ============================================================
CREATE TABLE "N8n" (
    "id"              TEXT             NOT NULL,
    "enabled"         BOOLEAN          NOT NULL DEFAULT TRUE,
    "description"     VARCHAR(255),
    "webhookUrl"      VARCHAR(255),
    "basicAuthUser"   VARCHAR(255),
    "basicAuthPass"   VARCHAR(255),
    "expire"          INTEGER          DEFAULT 0,
    "keywordFinish"   VARCHAR(100),
    "delayMessage"    INTEGER,
    "unknownMessage"  VARCHAR(100),
    "listeningFromMe" BOOLEAN          DEFAULT FALSE,
    "stopBotFromMe"   BOOLEAN          DEFAULT FALSE,
    "keepOpen"        BOOLEAN          DEFAULT FALSE,
    "debounceTime"    INTEGER,
    "ignoreJids"      JSONB,
    "splitMessages"   BOOLEAN          DEFAULT FALSE,
    "timePerChar"     INTEGER          DEFAULT 50,
    "triggerType"     "TriggerType",
    "triggerOperator" "TriggerOperator",
    "triggerValue"    TEXT,
    "createdAt"       TIMESTAMP        DEFAULT NOW(),
    "updatedAt"       TIMESTAMP        NOT NULL,
    "instanceId"      TEXT             NOT NULL,

    CONSTRAINT "N8n_pkey" PRIMARY KEY ("id")
);
ALTER TABLE "N8n" ADD CONSTRAINT "N8n_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- N8nSetting
-- ============================================================
CREATE TABLE "N8nSetting" (
    "id"              TEXT         NOT NULL,
    "expire"          INTEGER      DEFAULT 0,
    "keywordFinish"   VARCHAR(100),
    "delayMessage"    INTEGER,
    "unknownMessage"  VARCHAR(100),
    "listeningFromMe" BOOLEAN      DEFAULT FALSE,
    "stopBotFromMe"   BOOLEAN      DEFAULT FALSE,
    "keepOpen"        BOOLEAN      DEFAULT FALSE,
    "debounceTime"    INTEGER,
    "ignoreJids"      JSONB,
    "splitMessages"   BOOLEAN      DEFAULT FALSE,
    "timePerChar"     INTEGER      DEFAULT 50,
    "createdAt"       TIMESTAMP    DEFAULT NOW(),
    "updatedAt"       TIMESTAMP    NOT NULL,
    "n8nIdFallback"   VARCHAR(100),
    "instanceId"      TEXT         NOT NULL,

    CONSTRAINT "N8nSetting_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "N8nSetting_instanceId_key" ON "N8nSetting"("instanceId");
ALTER TABLE "N8nSetting" ADD CONSTRAINT "N8nSetting_n8nIdFallback_fkey"
    FOREIGN KEY ("n8nIdFallback") REFERENCES "N8n"("id");
ALTER TABLE "N8nSetting" ADD CONSTRAINT "N8nSetting_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Evoai
-- ============================================================
CREATE TABLE "Evoai" (
    "id"              TEXT             NOT NULL,
    "enabled"         BOOLEAN          NOT NULL DEFAULT TRUE,
    "description"     VARCHAR(255),
    "agentUrl"        VARCHAR(255),
    "apiKey"          VARCHAR(255),
    "expire"          INTEGER          DEFAULT 0,
    "keywordFinish"   VARCHAR(100),
    "delayMessage"    INTEGER,
    "unknownMessage"  VARCHAR(100),
    "listeningFromMe" BOOLEAN          DEFAULT FALSE,
    "stopBotFromMe"   BOOLEAN          DEFAULT FALSE,
    "keepOpen"        BOOLEAN          DEFAULT FALSE,
    "debounceTime"    INTEGER,
    "ignoreJids"      JSONB,
    "splitMessages"   BOOLEAN          DEFAULT FALSE,
    "timePerChar"     INTEGER          DEFAULT 50,
    "triggerType"     "TriggerType",
    "triggerOperator" "TriggerOperator",
    "triggerValue"    TEXT,
    "createdAt"       TIMESTAMP        DEFAULT NOW(),
    "updatedAt"       TIMESTAMP        NOT NULL,
    "instanceId"      TEXT             NOT NULL,

    CONSTRAINT "Evoai_pkey" PRIMARY KEY ("id")
);
ALTER TABLE "Evoai" ADD CONSTRAINT "Evoai_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- EvoaiSetting
-- ============================================================
CREATE TABLE "EvoaiSetting" (
    "id"              TEXT         NOT NULL,
    "expire"          INTEGER      DEFAULT 0,
    "keywordFinish"   VARCHAR(100),
    "delayMessage"    INTEGER,
    "unknownMessage"  VARCHAR(100),
    "listeningFromMe" BOOLEAN      DEFAULT FALSE,
    "stopBotFromMe"   BOOLEAN      DEFAULT FALSE,
    "keepOpen"        BOOLEAN      DEFAULT FALSE,
    "debounceTime"    INTEGER,
    "ignoreJids"      JSONB,
    "splitMessages"   BOOLEAN      DEFAULT FALSE,
    "timePerChar"     INTEGER      DEFAULT 50,
    "createdAt"       TIMESTAMP    DEFAULT NOW(),
    "updatedAt"       TIMESTAMP    NOT NULL,
    "evoaiIdFallback" VARCHAR(100),
    "instanceId"      TEXT         NOT NULL,

    CONSTRAINT "EvoaiSetting_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "EvoaiSetting_instanceId_key" ON "EvoaiSetting"("instanceId");
ALTER TABLE "EvoaiSetting" ADD CONSTRAINT "EvoaiSetting_evoaiIdFallback_fkey"
    FOREIGN KEY ("evoaiIdFallback") REFERENCES "Evoai"("id");
ALTER TABLE "EvoaiSetting" ADD CONSTRAINT "EvoaiSetting_instanceId_fkey"
    FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE;

-- ============================================================
-- Tabela de controle do Prisma Migrate
-- Necessária para o Prisma não tentar rodar migrations novamente
-- ============================================================
CREATE TABLE IF NOT EXISTS "_prisma_migrations" (
    "id"                    VARCHAR(36)  NOT NULL,
    "checksum"              VARCHAR(64)  NOT NULL,
    "finished_at"           TIMESTAMPTZ,
    "migration_name"        VARCHAR(255) NOT NULL,
    "logs"                  TEXT,
    "rolled_back_at"        TIMESTAMPTZ,
    "started_at"            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    "applied_steps_count"   INTEGER      NOT NULL DEFAULT 0,

    CONSTRAINT "_prisma_migrations_pkey" PRIMARY KEY ("id")
);
