# listacompras
app Flutter Android base para lista de compras geral.

A ideia é implementar o app com listas pré progamadas (churrasco, compras do mês, etc), bem como, possibilidade de o usuário poder criar suas próprias listas personalizadas. 


Já fizemos um MVP com integração ao Google Firebase que já da para manusear os registro por meio de Coleções e Objetos do Firebase. O próximo passo será implementar o login por contas do Google e habilitar para salvar e comportilhar listas para dois ou mais users logados.

Por segurança eu inclui o arquivo /android/app/google-services.json no .gitignore, pois ele possui as configurações de configuração de integração da aplicação com o Firebase.



# listacompras English
Flutter Android app base for general shopping list.

The idea is to implement the app with pre-programmed lists (barbecue, monthly shopping, etc.), as well as the possibility for the user to create their own custom lists.

We have already made an MVP with integration to Google Firebase that can already handle records through Firebase Collections and Objects. The next step will be to implement login by Google accounts and enable saving and sharing lists for two or more logged-in users.

For security reasons, I included the file /android/app/google-services.json in .gitignore because it contains the application integration configuration settings with Firebase.

---

# 🐳 Docker Development Environment

This project includes a complete Docker environment for isolated Flutter development without polluting the host OS.

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Copy environment variables file
cp .env.example .env

# Edit .env with your Firebase credentials
nano .env
```

### 2. Start Docker Environment

```bash
# Start Flutter container
docker-compose up -d

# Check if running
docker-compose ps
```

### 3. Access Container

```bash
# Access terminal inside container
docker-compose exec flutter bash

# Inside container, install dependencies
flutter pub get

# Run app (debug mode)
flutter run
```

## 📋 Prerequisites

- Docker installed
- Firebase credentials (or use Firebase Emulator)

## 🔧 Firebase Configuration

### Option 1: Real Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Add an Android app
4. Copy credentials to `.env` file

### Option 2: Firebase Emulator (Local Development)

```bash
# Start with Firebase Emulator
docker-compose --profile firebase up -d

# Access Emulator UI at: http://localhost:4000
```

## 📁 Project Structure

```
listacompras/
├── lib/
│   ├── config/
│   │   └── app_config.dart      # Settings loaded from .env
│   ├── services/
│   │   └── firestore_lists_service.dart  # Firebase service
│   └── ...
├── firebase/
│   └── emulator-data/          # Emulator data (persistent)
├── Dockerfile                # Flutter environment definition
├── docker-compose.yml         # Services orchestration
├── .env.example               # Environment variables template
└── pubspec.yaml               # Flutter dependencies
```

---

## ✅ Testando a Aplicação

Após buildar e subir os containers, você pode testar com estes comandos:

```bash
# 1. Buildar os containers
docker compose build

# 2. Subir os containers em background
docker compose up -d

# 3. Verificar se o container está rodando
docker compose ps

# 4. Acessar o container Flutter
docker compose exec flutter bash

# 5. Dentro do container, verificar versão do Flutter
flutter --version

# 6. Verificar dependências
flutter pub get

# 7. Rodar análise do código (opcional)
flutter analyze

# 8. Rodar testes (se existirem)
flutter test
```

### Atalhos úteis

```bash
# Ver logs do container
docker compose logs -f flutter

# Parar os containers
docker compose down

# Reiniciar com rebuild
docker compose up -d --build
```

---

## 📱 Gerando APK para Android

Para gerar o APK e instalar no Android, você tem duas opções:

### Opção 1: Build de Debug (mais rápido)

```bash
# No container Flutter
flutter build apk --debug

# O APK será gerado em: build/app/outputs/flutter-apk/app-debug.apk
```

### Opção 2: Build de Release (para distribuição)

```bash
flutter build apk --release
```

### Transferir para o celular

Depois de gerado, copie o APK para o celular:

```bash
# Copiar APK do container para o host
docker compose cp flutter:/workspace/listacompras/build/app/outputs/flutter-apk/app-debug.apk ./app-debug.apk
```

Depois é só transferir o arquivo `.apk` para o celular (por USB, email, WhatsApp, Google Drive, etc.) e instalar.

### Instalação direta via USB

```bash
# Conecte o celular via USB com depuração USB habilitada
flutter install
```

**Nota:** Para `flutter install` funcionar, você precisa habilitar "Depuração USB" nas opções de desenvolvedor do Android.

## 🔨 Useful Commands

### Docker

```bash
# Stop services
docker compose down

# Rebuild after Dockerfile changes
docker compose build --no-cache

# View logs
docker compose logs -f flutter

# Restart service
docker compose restart flutter
```

### Flutter (inside container)

```bash
# Update dependencies
flutter pub get

# Generate MobX code
flutter pub run build_runner build

# Build debug APK
flutter build apk --debug

# Code analysis
flutter analyze
```

## 🛠️ Troubleshooting

### "Firebase not configured"

Check if `.env` file exists and is properly configured:

```bash
cat .env
```

### "Permission denied" when creating files

Docker volumes may have permission issues. Recreate volumes:

```bash
docker compose down -v
docker compose up -d
```

## 📱 Firestore Data Structure

```
shopping_lists/
  ├── {listId}/
  │   ├── name: string
  │   ├── description: string
  │   ├── createdAt: timestamp
  │   ├── updatedAt: timestamp
  │   ├── isActive: boolean
  │   └── items/
  │       ├── {itemId}/
  │       │   ├── title: string
  │       │   ├── section: string
  │       │   ├── completed: boolean
  │       │   ├── createdAt: timestamp
  │       │   └── updatedAt: timestamp
```

## 🔐 Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `FIREBASE_PROJECT_ID` | Firebase Project ID | lista-compras-app |
| `FIREBASE_API_KEY` | Web API Key | AIzaSy... |
| `FIREBASE_AUTH_DOMAIN` | Auth Domain | app.firebaseapp.com |
| `FIREBASE_APP_ID` | App ID | 1:...:android:... |
| `ENVIRONMENT` | Environment | development |
| `DEBUG` | Debug mode | true |

## 🌐 Flutter Web - Development with Host Browser

This project supports Flutter Web development using the host machine's Chrome browser, without needing Chromium inside the container.

### Why use host browser?

- No need to install Chromium inside the container
- Uses the Chrome already installed on your host machine
- Faster development cycle
- Hot reload works perfectly

### Prerequisites

- Chrome (or any Chromium-based browser) installed on host machine
- Container running with `docker-compose up -d`

### Running Flutter Web

#### Option 1: Using web-server (Recommended)

This compiles Flutter in the container and serves the app via HTTP. Access it from your host browser.

```bash
# Enter the container
docker compose exec flutter bash

# Run Flutter Web server (compiles and serves on port 8080)
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
```

Then open in your host browser: **http://localhost:8080**

#### Option 2: Using port forwarding

If you prefer to use a different port or need more control:

```bash
# In the container (terminal 1)
flutter run -d web-server --web-port=4200 --web-hostname=0.0.0.0

# In another terminal (host machine), check the port
docker compose ps
# Look for the mapped port in docker-compose.yml (default: 4200)
```

Access: **http://localhost:4200**

### Hot Reload

Hot reload works automatically when using `flutter run -d web-server`. Just save your changes in VS Code and the browser will refresh.

### Troubleshooting

**"No supported devices found"**

If you see this error when running `flutter run -d chrome`, use `web-server` instead:

```bash
flutter run -d web-server
```

**Port already in use**

If port 8080 or 4200 is already in use, choose another port:

```bash
flutter run -d web-server --web-port=8888 --web-hostname=0.0.0.0
```

Then access http://localhost:8888

### Docker Configuration

The `docker-compose.yml` is already configured with:

- Port `50000`: Flutter debug
- Port `4200`: Flutter Web Server

Make sure these ports are available on your host machine.
