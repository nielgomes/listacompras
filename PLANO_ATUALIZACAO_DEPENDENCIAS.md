# Plano de Atualização de Dependências - ListaCompras2

## Data: 08/05/2026

## 📊 Resumo Executivo

O projeto possui **56 pacotes** com versões desatualizadas, sendo **5 dependências diretas** com atualizações maiores (major versions) que podem quebrar o código.

### Status Atual:
- ✅ **Dependências OK**: mobx, flutter_mobx, http, path_provider, shared_preferences, uuid
- ⚠️ **Atualizações Menores (Seguras)**: build_runner
- 🔴 **Atualizações Maiores (Quebram Código)**: cloud_firestore, firebase_auth, firebase_core, flutter_dotenv, intl

---

## 🎯 Análise de Risco Detalhada

### 🔴 CRÍTICO - Major Versions (Quebram Código)

#### 1. **cloud_firestore** (5.6.12 → 6.3.0)
- **Risco**: ALTO
- **O que pode quebrar**: 
  - Mudanças na API do Firestore
  - Possíveis alterações em métodos de query, snapshots, transações
  - Alterações em Settings (persistenceEnabled foi depreciado em versões recentes)
- **Arquivos afetados**:
  - `lib/repos/repo_firebase.dart` - Usa `FirebaseFirestore.instance`, `.collection()`, `.get()`, `.set()`
  - `lib/services/firestore_lists_service.dart` - Inicialização, configuração, Settings
- **Esforço estimado**: ALTO (4-6 horas)
- **Estratégia**: Atualizar por último, após atualizar firebase_core

#### 2. **firebase_core** (3.15.2 → 4.7.0)
- **Risco**: ALTO
- **O que pode quebrar**:
  - Mudanças na inicialização `Firebase.initializeApp()`
  - Possíveis alterações em FirebaseOptions
  - Alterações na forma de obter instâncias
- **Arquivos afetados**:
  - `lib/main.dart` - `FirestoreListsService.instance.initialize()`
  - `lib/services/firestore_lists_service.dart` - `Firebase.initializeApp()`, `FirebaseFirestore.instance`
- **Esforço estimado**: MÉDIO (2-3 horas)
- **Estratégia**: Atualizar primeiro (base para outros pacotes Firebase)

#### 3. **firebase_auth** (5.7.0 → 6.4.0)
- **Risco**: MÉDIO
- **O que pode quebrar**:
  - Mudanças na API de autenticação
  - Alterações em User, UserCredential
- **Arquivos afetados**: Pouco usado atualmente (sem login obrigatório)
- **Esforço estimado**: MÉDIO (2 horas)
- **Estratégia**: Atualizar junto com firebase_core

#### 4. **flutter_dotenv** (5.2.1 → 6.0.1)
- **Risco**: MÉDIO
- **O que pode quebrar**:
  - Possível mudança na API de carregamento (`dotenv.load()`)
  - Alterações no acesso às variáveis (`dotenv.env[]`)
- **Arquivos afetados**:
  - `lib/config/app_config.dart` - `dotenv.load()`, `dotenv.env[]`
  - `lib/main.dart` - `dotenv.load()`
  - `lib/services/openrouter_service.dart` - possível uso
- **Esforço estimado**: BAIXO/MÉDIO (1-2 horas)
- **Estratégia**: Atualizar separadamente, testar carregamento de .env

#### 5. **intl** (0.19.0 → 0.20.2)
- **Risco**: BAIXO/MÉDIO
- **O que pode quebrar**:
  - Mudanças na API de formatação de datas/números
  - Possíveis alterações em `DateFormat`, `NumberFormat`
- **Arquivos afetados**: Usado para formatação de datas (verificar onde é usado)
- **Esforço estimado**: BAIXO (1 hora)
- **Estratégia**: Atualizar separadamente, verificar uso no código

---

## ✅ SEGURO - Atualizações Menores/Patches

### Dependências de Desenvolvimento:
1. **build_runner** (2.13.1 → 2.15.0)
   - ✅ Seguro - apenas correções e melhorias menores
   - Esforço: BAIXO (15 minutos)
   - Ação: `flutter pub upgrade build_runner`

### Dependências Transativas:
- Atualizam automaticamente quando as diretas são atualizadas
- Não precisam de atenção separada

---

## 🏗️ Arquitetura e Abordagem Recomendada

### Princípios:
1. **Segurança primeiro**: Fazer backup antes de qualquer alteração
2. **Incremental**: Uma alteração de cada vez, testar após cada uma
3. **Firebase em bloco**: Atualizar firebase_core, firebase_auth e cloud_firestore juntos (são interdependentes)
4. **Isolamento**: Atualizar flutter_dotenv e intl separadamente

### Estratégia de Branches:
```
main (produção)
 └── feature/atualizacao-dependencias
      ├── step-1-build-runner (menor)
      ├── step-2-flutter-dotenv (major isolado)
      ├── step-3-intl (major isolado)
      └── step-4-firebase-packages (majors juntos)
```

---

## 📋 Plano de Ação em Fases

### FASE 1: PREPARAÇÃO (30 minutos)
**Objetivo**: Garantir que temos um ponto de restauração seguro

1. ✅ Fazer backup/commit do estado atual
   ```bash
   git add -A
   git commit -m "Backup antes de atualizar dependências"
   ```

2. ✅ Criar branch para atualizações
   ```bash
   git checkout -b feature/atualizacao-dependencias
   ```

3. ✅ Rodar testes atuais (se houver)
   ```bash
   docker compose exec flutter flutter test
   ```

4. ✅ Documentar versões atuais
   - Já feito via `flutter pub outdated`

---

### FASE 2: ATUALIZAÇÕES SEGURAS (30 minutos)
**Objetivo**: Atualizar o que não quebra código

1. **Atualizar build_runner** (desenvolvimento)
   ```bash
   docker compose exec flutter flutter pub upgrade build_runner
   ```
   
2. **Verificar se código MobX ainda compila**
   ```bash
   docker compose exec flutter flutter pub get
   docker compose exec flutter flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

3. **Testar se nada quebrou**
   ```bash
   docker compose exec flutter flutter build apk --debug
   ```

4. **Commit das alterações seguras**
   ```bash
   git add pubspec.yaml pubspec.lock
   git commit -m "Atualiza build_runner para versão compatível"
   ```

---

### FASE 3: FLUTTER_DOTENV (1-2 horas)
**Objetivo**: Atualizar flutter_dotenv 5.x → 6.x

1. **Atualizar versão no pubspec.yaml**
   ```yaml
   flutter_dotenv: ^6.0.1
   ```

2. **Atualizar dependências**
   ```bash
   docker compose exec flutter flutter pub get
   ```

3. **Verificar breaking changes na documentação**
   - Consultar: https://pub.dev/packages/flutter_dotenv/changelog

4. **Ajustar código se necessário**
   - Arquivos: `lib/config/app_config.dart`, `lib/main.dart`
   - Possível mudança: `dotenv.load()` pode ter nova API

5. **Testar carregamento de variáveis**
   ```bash
   docker compose exec flutter flutter run -d web-server --web-port 5555
   # Verificar logs se .env foi carregado
   ```

6. **Commit**
   ```bash
   git add -A
   git commit -m "Atualiza flutter_dotenv para 6.0.1 e ajusta código"
   ```

---

### FASE 4: INTL (1 hora)
**Objetivo**: Atualizar intl 0.19.x → 0.20.x

1. **Atualizar versão no pubspec.yaml**
   ```yaml
   intl: ^0.20.2
   ```

2. **Atualizar dependências**
   ```bash
   docker compose exec flutter flutter pub get
   ```

3. **Verificar onde intl é usado**
   ```bash
   grep -r "import 'package:intl/intl.dart'" lib/
   grep -r "DateFormat\|NumberFormat" lib/
   ```

4. **Ajustar código se necessário**
   - Verificar breaking changes no changelog do intl

5. **Testar formatação de datas**
   - Verificar funcionalidades que usam datas

6. **Commit**
   ```bash
   git add -A
   git commit -m "Atualiza intl para 0.20.2 e ajusta código"
   ```

---

### FASE 5: FIREBASE PACKAGES (4-6 horas)
**Objetivo**: Atualizar firebase_core, firebase_auth, cloud_firestore

Esta é a fase mais crítica e deve ser feita com cuidado.

#### 5.1: Atualizar versões no pubspec.yaml
```yaml
firebase_core: ^4.7.0
firebase_auth: ^6.4.0
cloud_firestore: ^6.3.0
```

#### 5.2: Atualizar dependências
```bash
docker compose exec flutter flutter pub get
```

#### 5.3: Consultar Breaking Changes
- firebase_core: https://pub.dev/packages/firebase_core/changelog
- cloud_firestore: https://pub.dev/packages/cloud_firestore/changelog
- firebase_auth: https://pub.dev/packages/firebase_auth/changelog

#### 5.4: Ajustar Código Firebase

**Arquivo: `lib/services/firestore_lists_service.dart`**
- Verificar `Firebase.initializeApp()` - pode precisar de `FirebaseOptions`
- Verificar `Settings` - `persistenceEnabled` pode ter mudado
- Verificar se `FirebaseFirestore.instance` ainda funciona igual

**Arquivo: `lib/repos/repo_firebase.dart`**
- Verificar `FirebaseFirestore.instance.collection().get()`
- Verificar `document['field']` vs `document.get('field')`
- Verificar se `reference.delete()` ainda funciona

**Arquivo: `lib/main.dart`**
- Verificar inicialização do Firebase

#### 5.5: Regenerar código MobX (pode ter conflitos)
```bash
docker compose exec flutter flutter packages pub run build_runner build --delete-conflicting-outputs
```

#### 5.6: Testar compilação
```bash
docker compose exec flutter flutter build apk --debug
docker compose exec flutter flutter build web
```

#### 5.7: Testar em execução
```bash
docker compose exec flutter flutter run -d web-server --web-port 5555
```

#### 5.8: Verificar funcionalidades Firebase
- [ ] Criar lista
- [ ] Adicionar item
- [ ] Marcar como comprado
- [ ] Deletar item
- [ ] Sincronização em tempo real

#### 5.9: Commit
```bash
git add -A
git commit -m "Atualiza pacotes Firebase para versões 4.x/6.x e ajusta código"
```

---

### FASE 6: TESTES FINAIS E LIMPEZA (1 hora)

1. **Rodar todos os testes**
   ```bash
   docker compose exec flutter flutter test
   ```

2. **Verificar se não há warnings de deprecated**
   ```bash
   docker compose exec flutter flutter analyze
   ```

3. **Limpar arquivos temporários**
   ```bash
   docker compose exec flutter flutter clean
   docker compose exec flutter flutter pub get
   ```

4. **Build final de produção**
   ```bash
   docker compose exec flutter flutter build apk --release
   docker compose exec flutter flutter build web --release
   ```

5. **Commit final**
   ```bash
   git add -A
   git commit -m "Conclui atualização de dependências - versões atualizadas com sucesso"
   ```

---

## 🚨 Pontos de Atenção

### Durante a atualização Firebase:
1. **Settings persistenceEnabled**: Em versões recentes do Firestore, `persistenceEnabled` foi substituído por `Persistence.enabled`
2. **Firebase.initializeApp()**: Pode precisar de parâmetros explícitos agora
3. **DocumentSnapshot**: Acesso a campos pode ter mudado de `doc['field']` para `doc.get('field')` ou `doc.data()?['field']`

### Como reverter se algo quebrar:
```bash
# Se algo quebrar e precisar reverter
git log --oneline -10  # ver commits
git reset --hard <commit-hash-anterior>
```

---

## 📈 Benefícios Esperados

1. **Segurança**: Correção de vulnerabilidades em pacotes antigos
2. **Performance**: Melhorias nas versões novas do Firebase
3. **Compatibilidade**: Preparado para futuras versões do Flutter/Dart
4. **Manutenção**: Menos dívida técnica

---

## ✅ Critérios de Sucesso

- [ ] Todas as dependências atualizadas conforme planejado
- [ ] App compila sem erros (`flutter build apk/web`)
- [ ] Funcionalidades Firebase funcionam (CRUD, tempo real)
- [ ] Variáveis de ambiente carregam corretamente
- [ ] Sem warnings de deprecated no analyze
- [ ] Testes passando

---

## 🚦 Próximos Passos

1. **Aguardar sua autorização** para iniciar a Fase 1 (Preparação)
2. Após autorização, executarei passo a passo, relatando progresso
3. Se houver erro em qualquer fase, paro e reporto para decisão

---

**Documento preparado por**: GitHub Copilot  
**Data**: 08/05/2026  
**Versão**: 1.0
