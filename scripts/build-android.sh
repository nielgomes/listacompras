#!/bin/bash
# ============================================
# Script para build do APK Android no Docker
# ============================================
# Este script:
# 1. Inicia o container Flutter via docker compose
# 2. Limpa builds anteriores
# 3. Atualiza dependências
# 4. Gera código MobX
# 5. Constrói o APK release
# ============================================

set -e

echo "🐳 Iniciando container Flutter via docker compose..."
docker compose up -d

echo "⏳ Aguardando container inicializar..."
sleep 5

echo "🧹 Limpando builds anteriores..."
docker compose exec flutter flutter clean

echo "📦 Atualizando dependências..."
docker compose exec flutter flutter pub get

echo "🔨 Gerando código MobX..."
docker compose exec flutter flutter pub run build_runner build --delete-conflicting-outputs

echo "📱 Construindo APK release..."
docker compose exec flutter flutter build apk --release

echo "✅ APK gerado em: build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "📋 Para copiar o APK do container para o host:"
echo "   docker compose cp flutter:/workspace/listacompras/build/app/outputs/flutter-apk/app-release.apk ./app-release.apk"
echo ""
echo "📋 Para parar o container:"
echo "   docker compose down"