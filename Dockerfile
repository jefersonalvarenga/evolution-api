FROM evoapicloud/evolution-api:v2.3.7

# Instala o driver pg para o script de verificação de tabelas
RUN apk add --no-cache postgresql-client python3 && \
    npm install pg --no-save 2>/dev/null || true

# Copia nosso entrypoint customizado
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Substitui o entrypoint original
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
