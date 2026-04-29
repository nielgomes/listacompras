import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configurações do aplicativo carregadas de variáveis de ambiente
/// 
/// Uso:
///   await dotenv.load(fileName: ".env");
///   final config = AppConfig.instance;
///   print(config.firebaseProjectId);
class AppConfig {
  AppConfig._();
  
  static final AppConfig instance = AppConfig._();
  
  /// Inicializa as variáveis de ambiente
  Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
      print('✅ AppConfig: .env carregado com sucesso');
    } catch (e) {
      print('⚠️ AppConfig: Não foi possível carregar .env: $e');
      print('   O app tentará usar valores padrão ou do google-services.json');
    }
  }
  
  // ============================================
  // Firebase Configuration
  // ============================================
  
  /// ID do projeto no Firebase
  String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  
  /// Chave da API Web
  String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  
  /// Domínio de autenticação
  String get firebaseAuthDomain => dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
  
  /// Bucket de armazenamento
  String get firebaseStorageBucket => dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  
  /// Sender ID para Messaging
  String get firebaseMessagingSenderId => 
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  
  /// App ID do Firebase
  String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';
  
  // ============================================
  // Environment Configuration
  // ============================================
  
  /// Ambiente atual (development | production)
  String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  
  /// Modo debug ativo
  bool get isDebug => (dotenv.env['DEBUG'] ?? 'false').toLowerCase() == 'true';
  
  /// Verifica se está em modo de desenvolvimento
  bool get isDevelopment => environment == 'development';
  
  /// Verifica se está em modo de produção
  bool get isProduction => environment == 'production';
  
  // ============================================
  // Firebase Options (para inicialização)
  // ============================================
  
  /// Retorna as opções do Firebase para inicialização
  FirebaseOptions get firebaseOptions => FirebaseOptions(
    apiKey: firebaseApiKey,
    appId: firebaseAppId,
    messagingSenderId: firebaseMessagingSenderId,
    projectId: firebaseProjectId,
    authDomain: firebaseAuthDomain,
    storageBucket: firebaseStorageBucket,
  );
  
  /// Verifica se as configurações do Firebase estão completas
  bool get isFirebaseConfigured =>
      firebaseProjectId.isNotEmpty &&
      firebaseApiKey.isNotEmpty &&
      firebaseAuthDomain.isNotEmpty &&
      firebaseAppId.isNotEmpty;
}