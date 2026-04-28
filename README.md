# Lista de Compras - Flutter Web App

Aplicativo de lista de compras moderno e responsivo, construído com Flutter Web e Firebase Firestore, permitindo gerenciar listas de compras e itens em tempo real.

## 🚀 Funcionalidades

### Principais
- ✅ **Criar Listas** - Crie múltiplas listas de compras com nome e descrição
- ✅ **Gerenciar Itens** - Adicione, edite e exclua itens em cada lista
- ✅ **Organização por Seções** - Itens categorizados (Bebidas, Comidas, Frios, Frutas, Higiene, Limpeza, Outros)
- ✅ **Marcar/Desmarcar** - Controle de status de conclusão por item
- ✅ **Sincronização em Tempo Real** - Firebase Firestore mantém todos os dispositivos atualizados
- ✅ **Interface Moderna** - Design clean e responsivo para web

### Recursos Avançados
- 📊 **Contador de Itens** - Visualize quantos itens foram concluídos vs total
- 🎯 **Ações em Massa** - Marcar/desmarcar todos os itens de uma lista ou de todas as listas
- 🔍 **Ordenação Automática** - Listas ordenadas alfabeticamente, itens por seção + nome
- 🗑️ **Limpeza Completa** - Apague todas as listas e itens com confirmação
- 📱 **Responsivo** - Interface adaptável para diferentes tamanhos de tela

## 🛠️ Tecnologias Utilizadas

- **Flutter 3.41.7** - Framework UI para construção multiplataforma
- **Dart 3.11.5** - Linguagem de programação
- **Firebase Firestore** - Banco de dados NoSQL em tempo real
- **Docker** - Containerização do ambiente de desenvolvimento

## 📁 Estrutura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada da aplicação
├── config/
│   └── app_config.dart       # Configurações do app
├── mobx/                     # MobX state management (gerado)
├── pages/
│   ├── home.dart            # Tela principal (listas)
│   └── list_items.dart      # Tela de itens de uma lista
├── repos/
│   ├── cruds.dart           # Operações CRUD
│   ├── init_data_bases.dart # Inicialização
│   ├── repo_firebase.dart   # Repositório Firebase
│   └── repo_parse.dart      # Parse de dados
└── services/
    ├── firestore_lists_service.dart  # Serviço principal Firestore
    ├── firestore_test.dart          # Testes de conexão
    └── firestore_service.dart       # Serviço base
```

## 🚀 Começando

### Pré-requisitos

- Docker e Docker Compose instalados
- Portas 4200 (web) e 8080 disponíveis

### Instalação

1. Clone o repositório:
```bash
git clone <url-do-repositorio>
cd listacompras
```

2. Inicie o container Docker:
```bash
docker compose up -d
```

3. Acesse o terminal do container:
```bash
docker compose exec flutter bash
```

4. Instale as dependências:
```bash
flutter pub get
```

5. Execute a aplicação:
```bash
flutter run -d web-server --web-port 4200
```

6. Acesse no navegador:
```
http://localhost:4200
```

### Build para Produção

```bash
docker compose exec flutter flutter build web --release
```

O build estará disponível em `build/web/`

## 🔧 Configuração Firebase

O projeto utiliza Firebase Firestore em modo Cloud (não emulador).

### Variáveis de Ambiente

Configure as credenciais do Firebase no ambiente ou através do arquivo de configuração apropriado.

## 🎨 Interface do Usuário

### Tela Principal (Home)

- **Campo de texto** - Criar nova lista
- **Botão +** - Adicionar lista
- **Botão ✓** - Marcar todos os itens de todas as listas
- **Botão ⊘** - Desmarcar todos os itens de todas as listas
- **Botão ↻** - Sincronizar (atualizar)
- **Menu ⋮** - Opções adicionais (Limpar tudo, Testar conexão)
- **Lista de Listas** - Cards com nome, descrição e ações (editar/excluir)

### Tela de Itens (ListItems)

- **AppBar** - Nome da lista + contador (ex: "5/15 itens") + botão marcar/desmarcar todos
- **Formulário** - Adicionar novo item com seleção de seção
- **Lista de Itens** - Cards com checkbox, nome, seção e botão excluir
- **Checkboxes** - Alternar status de conclusão

## 🔍 Arquitetura

### Padrão de Projeto

- **StatefulWidget** - Gerenciamento de estado local
- **StreamBuilder** - Reatividade com Firestore
- **Repository Pattern** - Separação de camadas de dados
- **Service Layer** - Lógica de negócios centralizada

### Fluxo de Dados

1. UI → Service (operações CRUD)
2. Service → Firestore (persistência)
3. Firestore → Stream → UI (atualização em tempo real)

## ⚡ Performance

### Otimizações Implementadas

- **Firestore Web SDK** - Pattern fire-and-forget para evitar timeouts
- **Batch Writes** - Atualizações em massa eficientes
- **Tree Shaking** - Redução de tamanho de assets
- **Streams** - Atualizações seletivas (não recarrega tudo)

### Timeout Handling

Todas as operações Firestore possuem timeout de 30 segundos com tratamento adequado.

## 🐛 Troubleshooting

### Problemas Comuns

1. **Container não inicia**
   ```bash
   docker compose down
   docker compose up -d
   ```

2. **Dependências desatualizadas**
   ```bash
   docker compose exec flutter flutter pub upgrade
   ```

3. **Erro de conexão Firestore**
   - Verifique credenciais do Firebase
   - Confira regras do Firestore
   - Use o botão "Testar conexão"

4. **Build falha**
   ```bash
   docker compose exec flutter flutter clean
   docker compose exec flutter flutter pub get
   ```

## 📊 Análise de Código

```bash
# Analisar código
docker compose exec flutter flutter analyze

# Verificar dependências desatualizadas
docker compose exec flutter flutter pub outdated
```

## 🔄 Atualizações Recente

### v1.0.0 - Lançamento Inicial
- ✅ CRUD completo de listas e itens
- ✅ Sincronização em tempo real
- ✅ Interface web responsiva
- ✅ Ordenação automática
- ✅ Ações em massa
- ✅ Tratamento de erros robusto

## 📄 Licença

Este projeto está sob a licença MIT.

## 👥 Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para:
- Reportar bugs
- Sugerir novas funcionalidades
- Submeter pull requests

## 📞 Suporte

Para dúvidas ou suporte, por favor abra uma issue no repositório.

---

**Desenvolvido com ❤️ usando Flutter e Firebase**

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