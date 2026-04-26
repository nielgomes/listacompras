import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listacompras2/config/app_config.dart';

/// Teste de conexão com Firestore
class FirestoreTest {
  FirestoreTest._();
  
  static final FirestoreTest instance = FirestoreTest._();
  
  Future<void> testConnection() async {
    print('🧪 Iniciando teste de conexão com Firestore...');
    
    try {
      // Carregar config
      final config = AppConfig.instance;
      await config.init();
      
      print('📋 Verificando configuração Firebase...');
      
      // Inicializar Firebase
      print('\n⚙️ Inicializando Firebase...');
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: config.firebaseApiKey,
          appId: config.firebaseAppId,
          messagingSenderId: config.firebaseMessagingSenderId,
          projectId: config.firebaseProjectId,
        ),
      );
      print('✅ Firebase inicializado!');
      
      // Testar conexão
      print('\n🔍 Testando conexão com Firestore...');
      final firestore = FirebaseFirestore.instance;
      
      // Tentar ler dados (isso vai ativar as regras de segurança)
      print('📥 Tentando ler coleção "test_collection"...');
      try {
        final snapshot = await firestore.collection('test_collection').get();
        print('✅ Leitura bem-sucedida!');
        print('   - Documentos encontrados: ${snapshot.docs.length}');
      } catch (e) {
        print('❌ Erro ao ler: $e');
        print('   Tipo: ${e.runtimeType}');
      }
      
      // Tentar escrever dados
      print('\n📤 Tentando escrever na coleção "test_collection"...');
      try {
        final docRef = await firestore.collection('test_collection').add({
          'test': 'data',
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('✅ Escrita bem-sucedida!');
        print('   - ID do documento: ${docRef.id}');
        
        // Deletar o documento de teste
        await docRef.delete();
        print('🗑️ Documento de teste deletado');
      } catch (e) {
        print('❌ Erro ao escrever: $e');
        print('   Tipo: ${e.runtimeType}');
        
        if (e.toString().contains('permission-denied')) {
          print('\n⚠️ ERRO DE PERMISSÃO!');
          print('   As regras de segurança do Firestore estão bloqueando a escrita.');
          print('   Solução:');
          print('   1. Acesse https://console.firebase.google.com/');
          print('   2. Selecione seu projeto: ${config.firebaseProjectId}');
          print('   3. Vá em Firestore Database > Rules');
          print('   4. Publique as regras (botão "Publish Changes")');
          print('   5. Ou use regras temporárias para teste:');
          print('      match /databases/{database}/documents {');
          print('        match /{document=**} {');
          print('          allow read, write: if true;  // PERIGO: Apenas para teste!');
          print('        }');
          print('      }');
        } else if (e.toString().contains('network') || 
                   e.toString().contains('fetch') ||
                   e.toString().contains('connection')) {
          print('\n⚠️ ERRO DE REDE!');
          print('   Verifique:');
          print('   1. Conexão de internet');
          print('   2. Firewall não está bloqueando conexões do Firebase');
          print('   3. CORS no navegador');
        }
      }
      
    } catch (e, stackTrace) {
      print('\n❌ Erro crítico: $e');
      print('Stack trace: $stackTrace');
    }
  }
}
