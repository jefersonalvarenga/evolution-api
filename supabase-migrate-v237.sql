-- ============================================================
-- Migrations pendentes: Evolution API v2.2.3 → v2.3.7
-- Execute este script no Supabase SQL Editor
-- ============================================================

-- 1. wavoip_token + unique index Chat
ALTER TABLE "Setting" ADD COLUMN IF NOT EXISTS "wavoipToken" VARCHAR(100);

-- 2. Nats integration
CREATE TABLE IF NOT EXISTS "Nats" (
    "id" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT false,
    "events" JSONB NOT NULL,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP NOT NULL,
    "instanceId" TEXT NOT NULL,
    CONSTRAINT "Nats_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "Nats_instanceId_key" ON "Nats"("instanceId");
ALTER TABLE "Nats" DROP CONSTRAINT IF EXISTS "Nats_instanceId_fkey";
ALTER TABLE "Nats" ADD CONSTRAINT "Nats_instanceId_fkey" FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- 3. N8n tables
CREATE TABLE IF NOT EXISTS "N8n" (
    "id" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "description" VARCHAR(255),
    "webhookUrl" VARCHAR(255),
    "basicAuthUser" VARCHAR(255),
    "basicAuthPass" VARCHAR(255),
    "expire" INTEGER DEFAULT 0,
    "keywordFinish" VARCHAR(100),
    "delayMessage" INTEGER,
    "unknownMessage" VARCHAR(100),
    "listeningFromMe" BOOLEAN DEFAULT false,
    "stopBotFromMe" BOOLEAN DEFAULT false,
    "keepOpen" BOOLEAN DEFAULT false,
    "debounceTime" INTEGER,
    "ignoreJids" JSONB,
    "splitMessages" BOOLEAN DEFAULT false,
    "timePerChar" INTEGER DEFAULT 50,
    "triggerType" "TriggerType",
    "triggerOperator" "TriggerOperator",
    "triggerValue" TEXT,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP NOT NULL,
    "instanceId" TEXT NOT NULL,
    CONSTRAINT "N8n_pkey" PRIMARY KEY ("id")
);
CREATE TABLE IF NOT EXISTS "N8nSetting" (
    "id" TEXT NOT NULL,
    "expire" INTEGER DEFAULT 0,
    "keywordFinish" VARCHAR(100),
    "delayMessage" INTEGER,
    "unknownMessage" VARCHAR(100),
    "listeningFromMe" BOOLEAN DEFAULT false,
    "stopBotFromMe" BOOLEAN DEFAULT false,
    "keepOpen" BOOLEAN DEFAULT false,
    "debounceTime" INTEGER,
    "ignoreJids" JSONB,
    "splitMessages" BOOLEAN DEFAULT false,
    "timePerChar" INTEGER DEFAULT 50,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP NOT NULL,
    "n8nIdFallback" VARCHAR(100),
    "instanceId" TEXT NOT NULL,
    CONSTRAINT "N8nSetting_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "N8nSetting_instanceId_key" ON "N8nSetting"("instanceId");
ALTER TABLE "N8n" DROP CONSTRAINT IF EXISTS "N8n_instanceId_fkey";
ALTER TABLE "N8n" ADD CONSTRAINT "N8n_instanceId_fkey" FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "N8nSetting" DROP CONSTRAINT IF EXISTS "N8nSetting_n8nIdFallback_fkey";
ALTER TABLE "N8nSetting" ADD CONSTRAINT "N8nSetting_n8nIdFallback_fkey" FOREIGN KEY ("n8nIdFallback") REFERENCES "N8n"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "N8nSetting" DROP CONSTRAINT IF EXISTS "N8nSetting_instanceId_fkey";
ALTER TABLE "N8nSetting" ADD CONSTRAINT "N8nSetting_instanceId_fkey" FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- 4. Evoai tables
CREATE TABLE IF NOT EXISTS "Evoai" (
    "id" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "description" VARCHAR(255),
    "agentUrl" VARCHAR(255),
    "apiKey" VARCHAR(255),
    "expire" INTEGER DEFAULT 0,
    "keywordFinish" VARCHAR(100),
    "delayMessage" INTEGER,
    "unknownMessage" VARCHAR(100),
    "listeningFromMe" BOOLEAN DEFAULT false,
    "stopBotFromMe" BOOLEAN DEFAULT false,
    "keepOpen" BOOLEAN DEFAULT false,
    "debounceTime" INTEGER,
    "ignoreJids" JSONB,
    "splitMessages" BOOLEAN DEFAULT false,
    "timePerChar" INTEGER DEFAULT 50,
    "triggerType" "TriggerType",
    "triggerOperator" "TriggerOperator",
    "triggerValue" TEXT,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP NOT NULL,
    "instanceId" TEXT NOT NULL,
    CONSTRAINT "Evoai_pkey" PRIMARY KEY ("id")
);
CREATE TABLE IF NOT EXISTS "EvoaiSetting" (
    "id" TEXT NOT NULL,
    "expire" INTEGER DEFAULT 0,
    "keywordFinish" VARCHAR(100),
    "delayMessage" INTEGER,
    "unknownMessage" VARCHAR(100),
    "listeningFromMe" BOOLEAN DEFAULT false,
    "stopBotFromMe" BOOLEAN DEFAULT false,
    "keepOpen" BOOLEAN DEFAULT false,
    "debounceTime" INTEGER,
    "ignoreJids" JSONB,
    "splitMessages" BOOLEAN DEFAULT false,
    "timePerChar" INTEGER DEFAULT 50,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP NOT NULL,
    "evoaiIdFallback" VARCHAR(100),
    "instanceId" TEXT NOT NULL,
    CONSTRAINT "EvoaiSetting_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "EvoaiSetting_instanceId_key" ON "EvoaiSetting"("instanceId");
ALTER TABLE "Evoai" DROP CONSTRAINT IF EXISTS "Evoai_instanceId_fkey";
ALTER TABLE "Evoai" ADD CONSTRAINT "Evoai_instanceId_fkey" FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "EvoaiSetting" DROP CONSTRAINT IF EXISTS "EvoaiSetting_evoaiIdFallback_fkey";
ALTER TABLE "EvoaiSetting" ADD CONSTRAINT "EvoaiSetting_evoaiIdFallback_fkey" FOREIGN KEY ("evoaiIdFallback") REFERENCES "Evoai"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "EvoaiSetting" DROP CONSTRAINT IF EXISTS "EvoaiSetting_instanceId_fkey";
ALTER TABLE "EvoaiSetting" ADD CONSTRAINT "EvoaiSetting_instanceId_fkey" FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- 5. Remove unique index de fileName em Media
DROP INDEX IF EXISTS "Media_fileName_key";

-- 6. Colunas splitMessages/timePerChar em Typebot
ALTER TABLE "Typebot" ADD COLUMN IF NOT EXISTS "splitMessages" BOOLEAN DEFAULT false;
ALTER TABLE "Typebot" ADD COLUMN IF NOT EXISTS "timePerChar" INTEGER DEFAULT 50;
ALTER TABLE "TypebotSetting" ADD COLUMN IF NOT EXISTS "splitMessages" BOOLEAN DEFAULT false;
ALTER TABLE "TypebotSetting" ADD COLUMN IF NOT EXISTS "timePerChar" INTEGER DEFAULT 50;

-- 7. lid em IsOnWhatsapp
ALTER TABLE "IsOnWhatsapp" ADD COLUMN IF NOT EXISTS "lid" VARCHAR(100);

-- 8. Kafka integration
CREATE TABLE IF NOT EXISTS "Kafka" (
    "id" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT false,
    "events" JSONB NOT NULL,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP NOT NULL,
    "instanceId" TEXT NOT NULL,
    CONSTRAINT "Kafka_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "Kafka_instanceId_key" ON "Kafka"("instanceId");
ALTER TABLE "Kafka" DROP CONSTRAINT IF EXISTS "Kafka_instanceId_fkey";
ALTER TABLE "Kafka" ADD CONSTRAINT "Kafka_instanceId_fkey" FOREIGN KEY ("instanceId") REFERENCES "Instance"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- 9. Unique index em Chat(instanceId, remoteJid)
DELETE FROM "Chat"
WHERE id IN (
  SELECT id FROM (
    SELECT id,
           ROW_NUMBER() OVER (
             PARTITION BY "instanceId", "remoteJid"
             ORDER BY "updatedAt" DESC
           ) as row_num
    FROM "Chat"
  ) t
  WHERE t.row_num > 1
);
CREATE UNIQUE INDEX IF NOT EXISTS "Chat_instanceId_remoteJid_key" ON "Chat"("instanceId", "remoteJid");

-- ============================================================
-- Registra migrations na tabela _prisma_migrations
-- ============================================================
INSERT INTO "_prisma_migrations" (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count)
VALUES
  (gen_random_uuid()::text, 'placeholder', NOW(), '20250116001415_add_wavoip_token_to_settings_table', NULL, NULL, NOW(), 1),
  (gen_random_uuid()::text, 'placeholder', NOW(), '20250225180031_add_nats_integration', NULL, NULL, NOW(), 1),
  (gen_random_uuid()::text, 'placeholder', NOW(), '20250514232744_add_n8n_table', NULL, NULL, NOW(), 1),
  (gen_random_uuid()::text, 'placeholder', NOW(), '20250515211815_add_evoai_table', NULL, NULL, NOW(), 1),
  (gen_random_uuid()::text, 'placeholder', NOW(), '20250516012152_remove_unique_atribute_for_file_name_in_media', NULL, NULL, NOW(), 1),
  (gen_random_uuid()::text, 'placeholder', NOW(), '20250612155048_add_coluns_trypebot_tables', NULL, NULL, NOW(), 1),
  (gen_random_uuid()::text, 'placeholder', NOW(), '20250613143000_add_lid_column_to_is_onwhatsapp', NULL, NULL, NOW(), 1),
  (gen_random_uuid()::text, 'placeholder', NOW(), '20250918182355_add_kafka_integration', NULL, NULL, NOW(), 1),
  (gen_random_uuid()::text, 'placeholder', NOW(), '20251122003044_add_chat_instance_remotejid_unique', NULL, NULL, NOW(), 1)
ON CONFLICT (migration_name) DO NOTHING;
