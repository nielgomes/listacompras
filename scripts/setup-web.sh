#!/bin/bash
# ============================================
# Script de Inicialização - Flutter Web
# ============================================
# Configura o projeto para suportar Web
# ============================================

echo "🚀 Configurando Flutter Web..."

# Habilitar web platform (se ainda não estiver habilitado)
flutter create . --platforms web 2>/dev/null || echo "Web platform já habilitado"

# Instalar dependências
flutter pub get

# Verificar se o web está disponível
flutter devices

echo "✅ Flutter Web configurado!"
echo ""
echo "Para rodar o app no navegador:"
echo "  docker compose exec flutter flutter run -d chrome"
echo ""
echo "Ou usar o web-server:"
echo "  docker compose exec flutter flutter run -d web-server --web-port=4200"
