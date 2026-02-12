#!/bin/bash
set -e

echo "=== Evolution API - Custom Entrypoint ==="
echo "=== Verificando banco de dados... ==="

# Extrai o host do DATABASE_CONNECTION_URI para checar conectividade
DB_URI="${DATABASE_CONNECTION_URI}"

# Verifica se as tabelas já foram criadas checando a tabela Instance no Supabase
# Usa o DATABASE_CONNECTION_URI (pooler) para a verificação — mais confiável
TABLE_EXISTS=$(node -e "
const { Client } = require('pg');
const client = new Client({ connectionString: process.env.DATABASE_CONNECTION_URI });
client.connect()
  .then(() => client.query(\"SELECT to_regclass('public.\\\"Instance\\\"') as exists\"))
  .then(res => {
    console.log(res.rows[0].exists ? 'yes' : 'no');
    client.end();
  })
  .catch(err => {
    console.log('no');
    client.end();
  });
" 2>/dev/null || echo "no")

echo "=== Tabelas existem: $TABLE_EXISTS ==="

if [ "$TABLE_EXISTS" = "yes" ]; then
  echo "=== Tabelas já existem — pulando migrate, rodando apenas db:generate ==="
  npm run db:generate
  if [ $? -ne 0 ]; then
    echo "Prisma generate failed"
    exit 1
  fi
  echo "=== Prisma generate OK ==="
else
  echo "=== Tabelas não encontradas — rodando migrate completo ==="
  # Tenta com DATABASE_URL (porta 5432 direta) se disponível
  if [ -n "$DATABASE_URL" ]; then
    export DATABASE_URL
  fi
  npm run db:deploy
  if [ $? -ne 0 ]; then
    echo "=== Migrate falhou — tentando gerar apenas o client Prisma ==="
    npm run db:generate || true
  else
    echo "=== Migrate OK ==="
    npm run db:generate
  fi
fi

echo "=== Iniciando Evolution API... ==="
exec npm run start:prod
