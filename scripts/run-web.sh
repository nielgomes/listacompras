#!/bin/bash
# ============================================
# Script para rodar Flutter Web no Docker
# ============================================
# Este script:
# 1. Constrói o app Flutter Web
# 2. Copia o .env para o build
# 3. Inicia o servidor HTTP
# ============================================

set -e

echo "🔨 Buildando Flutter Web..."
docker compose exec flutter flutter build web

echo "📋 Copiando .env para build..."
docker compose exec flutter cp /workspace/listacompras/.env /workspace/listacompras/build/web/

echo "🚀 Iniciando servidor HTTP na porta 8080..."
echo "🌐 Acesse: http://localhost:8080"
echo "Pressione Ctrl+C para parar o servidor"

docker compose exec flutter dart run http_server --port 8080 --cors-all-origins --path /workspace/listacompras/build/web