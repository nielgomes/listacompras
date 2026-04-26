# Flutter Web - Lista Compras

## Configuração Docker para Flutter Web

### Pré-requisitos
- Docker e Docker Compose instalados
- Projeto configurado com Firebase

### Inicialização

1. **Configurar ambiente:**
```bash
docker compose up -d
docker compose exec flutter bash
./scripts/setup-web.sh
```

2. **Rodar no Chrome:**
```bash
docker compose exec flutter flutter run -d chrome
```

3. **Acessar no navegador:**
- O app estará disponível em: `http://localhost:4200`

### Comandos Úteis

```bash
# Verificar dispositivos disponíveis
docker compose exec flutter flutter devices

# Rodar no modo web-server (mais leve)
docker compose exec flutter flutter run -d web-server --web-port=4200

# Build para produção
docker compose exec flutter flutter build web

# Ver logs
docker compose logs -f flutter
```

### Configuração Firebase para Web

#### Regras de Segurança (firestore.rules)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      // Permitir apenas usuários autenticados
      allow read, write: if request.auth != null;
    }
  }
}
```

#### Firebase Emulator (Opcional)
```bash
# Iniciar emuladores
docker compose exec flutter firebase emulators:start

# Acessar UI dos emuladores
# http://localhost:4000
```

### Portas Utilizadas
- `4200` - Flutter Web Server
- `50000` - Flutter Debug
- `8080` - Firestore Emulator
- `9099` - Firebase Auth Emulator
- `4000` - Firebase Emulator UI

### Solução de Problemas

#### Chrome não inicia
```bash
# Aumentar limite de arquivos
ulimit -n 100000

# Ou usar web-server em vez de chrome
flutter run -d web-server --web-port=4200
```

#### Firebase não conecta
1. Verificar variáveis de ambiente no `.env`
2. Confirmar que o Firebase está configurado corretamente
3. Verificar regras de segurança do Firestore

#### Memória insuficiente
Aumentar `shm_size` no `docker-compose.yml`:
```yaml
shm_size: '4gb'
```

### Notas Importantes

⚠️ **Regras de Segurança**: As regras de segurança do Firebase estão configuradas para permitir acesso apenas de usuários autenticados. Para desenvolvimento local, crie um usuário com `allowLocalDevelopment: true`.

🔒 **Produção**: Nunca use as regras de segurança de desenvolvimento em produção!
