# ============================================
# Flutter Development Environment - Lista Compras
# ============================================
# Ambiente isolado para desenvolvimento Flutter
# sem poluir o sistema operacional host
#
# Uso:
#   docker-compose up -d
#   docker-compose exec flutter flutter pub get
#   docker-compose exec flutter flutter run
#
# Para Android SDK (build APK):
#   docker-compose --profile android up -d
# ============================================

# Imagem base com Flutter SDK (versão mais recente: 3.41.6)
FROM ghcr.io/cirruslabs/flutter:stable

# Definir variáveis de ambiente
ENV PUB_CACHE=/root/.pub-cache
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV GRADLE_USER_HOME=/root/.gradle

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    chromium \
    libgtk-3-0 \
    libx11-6 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxi6 \
    libxtst6 \
    && rm -rf /var/lib/apt/lists/*

# Configurar Chrome para Flutter Web
ENV CHROME_BIN=/usr/bin/chromium
ENV FLUTTER_WEB_USE_SKIA=false

# Configurar Android SDK (se necessário para build)
RUN mkdir -p ${ANDROID_SDK_ROOT} && \
    cd ${ANDROID_SDK_ROOT} && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip && \
    unzip -q cmdline-tools.zip && \
    mkdir -p cmdline-tools/latest && \
    mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true && \
    yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --licenses > /dev/null 2>&1 || true && \
    ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager \
        "platform-tools" \
        "platforms;android-36" \
        "build-tools;36.0.0" > /dev/null 2>&1 || true

# Criar diretório de trabalho
WORKDIR /workspace/listacompras

# Copiar arquivos de dependências primeiro (para cache)
COPY pubspec.yaml ./
COPY pubspec.lock ./

# Baixar dependências Flutter
RUN flutter pub get

# Copiar restante do projeto
COPY . .

# Configurar permissões
RUN chown -R root:root /workspace/listacompras

# Expor porta para debug Flutter
EXPOSE 50000

# Comando padrão
CMD ["/bin/bash"]