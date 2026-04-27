import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listacompras2/config/app_config.dart';

/// Serviço para gerenciar listas de compras no Firestore com suporte a listas nomeadas
class FirestoreListsService {
  FirestoreListsService._();
  
  static final FirestoreListsService instance = FirestoreListsService._();
  
  late final FirebaseFirestore _firestore;
  final AppConfig _config = AppConfig.instance;
  bool _isInitialized = false;
  
  /// Inicializa o Firebase (deve ser chamado antes de usar o serviço)
  Future<void> initialize() async {
    // Evitar inicialização múltipla
    if (_isInitialized) {
      print('⚠️ Firebase já foi inicializado anteriormente');
      return;
    }
    
    print('🔧 Inicializando Firebase...');
    await _config.init();
    
    print('📋 Verificando configuração Firebase...');
    
    if (_config.isFirebaseConfigured) {
      try {
        print('⚙️ Chamando Firebase.initializeApp()...');
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: _config.firebaseApiKey,
            appId: _config.firebaseAppId,
            messagingSenderId: _config.firebaseMessagingSenderId,
            projectId: _config.firebaseProjectId,
          ),
        );
        print('✅ Firebase inicializado com sucesso!');
        _firestore = FirebaseFirestore.instance;
        print('📡 Firestore instance criado');
        
        // Configurar Firestore para manter conexão ativa
        print('⚙️ Configurando Firestore...');
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        print('✅ Firestore configurado com persistência');
        
        // Não precisa testar conexão aqui - será testada naturalmente quando usar
        // O Firestore funciona offline com cache local
      } catch (e, stackTrace) {
        print('❌ Erro ao inicializar Firebase: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    } else {
      throw Exception('Firebase not configured. Check your .env file.');
    }
    
    _isInitialized = true;
  }
  
  /// Coleção principal das listas de compras
  CollectionReference get _listsCollection =>
      _firestore.collection('shopping_lists');
  
  /// Subcoleção de itens dentro de uma lista
  CollectionReference _itemsCollection(String listId) =>
      _listsCollection.doc(listId).collection('items');
  
  // ============================================
  // Operações com Listas
  // ============================================
  
  /// Cria uma nova lista de compras
  Future<String> createList({
    required String name,
    String? description,
  }) async {
    print('📝 Criando lista: $name');
    print('🔍 Verificando conexão com Firestore...');
    
    // Verificar se o Firebase foi inicializado
    try {
      print('   - Verificando se Firebase foi inicializado...');
      if (!_isInitialized) {
        print('⚠️ Firebase não foi inicializado ainda, tentando agora...');
        await initialize();
      }
      print('   ✅ Firebase verificado');
    } catch (e) {
      print('❌ ERRO: Firebase não foi inicializado: $e');
      throw Exception('Firebase não foi inicializado. Por favor, recarregue a página.');
    }
    print('   - Firestore instance: OK');
    
    print('🚀 Chamando _listsCollection.add()...');
    print('   - Coleção: shopping_lists');
    print('   - Dados: name=$name, description=${description ?? ""}');
    print('   ⏳ AGUARDANDO RESPOSTA DO FIRESTORE...');
    
    // Timeout maior para evitar falsos positivos (operação pode ter sucesso mesmo com delay)
    final docRef = await _listsCollection.add({
      'name': name,
      'description': description ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
    }).timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        print('⚠️ TIMEOUT: Operação demorou > 60s, mas pode ter sido concluída');
        throw TimeoutException('Operação pode ter sido concluída, mas a resposta demorou demais');
      },
    );
    print('✅ Firestore respondeu com ID: ${docRef.id}');
    print('✅ Lista criada com ID: ${docRef.id}');
    return docRef.id;
  }
  
  /// Obtém uma lista por ID
  Future<DocumentSnapshot?> getList(String listId) async {
    return await _listsCollection.doc(listId).get();
  }
  
  /// Atualiza uma lista
  Future<void> updateList({
    required String listId,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (isActive != null) data['isActive'] = isActive;
    
    await _listsCollection.doc(listId).update(data);
  }
  
  /// Deleta uma lista (soft delete)
  Future<void> deleteList(String listId) async {
    print('🗑️ Deletando lista: $listId');
    
    try {
      print('🔄 Atualizando documento...');
      await _listsCollection.doc(listId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('⚠️ TIMEOUT: Operação de delete pode ter sido concluída');
          throw TimeoutException('Operação pode ter sido concluída, mas a resposta demorou demais');
        },
      );
      print('✅ Lista deletada com sucesso');
    } catch (e, stackTrace) {
      print('❌ Erro ao deletar lista: $e');
      print('Tipo: ${e.runtimeType}');
      print('Stack: $stackTrace');
      rethrow;
    }
  }
  
  /// Lista todas as listas ativas
  Future<List<QueryDocumentSnapshot>> getLists({bool onlyActive = true}) async {
    Query query = _listsCollection;
    if (onlyActive) {
      query = query.where('isActive', isEqualTo: true);
    }
    final snapshot = await query.get();
    return snapshot.docs;
  }

  /// Lista todas as listas ativas com listener em tempo real
  Stream<List<DocumentSnapshot>> listenToLists({
    bool onlyActive = true,
  }) {
    Query query = _listsCollection;
    
    if (onlyActive) {
      query = query.where('isActive', isEqualTo: true);
    }
    
    return query
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }
  
  // ============================================
  // Operações com Itens
  // ============================================
  
  /// Adiciona um item à lista
  Future<void> addItem({
    required String listId,
    required String title,
    String? section,
  }) async {
    await _itemsCollection(listId).add({
      'title': title,
      'section': section ?? 'outros',
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  /// Atualiza um item
  Future<void> updateItem({
    required String listId,
    required String itemId,
    String? title,
    String? section,
    bool? completed,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (title != null) data['title'] = title;
    if (section != null) data['section'] = section;
    if (completed != null) data['completed'] = completed;
    
    await _itemsCollection(listId).doc(itemId).update(data);
  }
  
  /// Marca/desmarca item como concluído
  Future<void> toggleItemCompletion({
    required String listId,
    required String itemId,
  }) async {
    final doc = await _itemsCollection(listId).doc(itemId).get();
    final data = doc.data() as Map<String, dynamic>?;
    final currentStatus = data?['completed'] ?? false;
    
    await _itemsCollection(listId).doc(itemId).update({
      'completed': !currentStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  /// Remove um item da lista
  Future<void> removeItem({
    required String listId,
    required String itemId,
  }) async {
    await _itemsCollection(listId).doc(itemId).delete();
  }
  
  /// Limpa todos os itens concluídos de uma lista
  Future<void> clearCompletedItems(String listId) async {
    final query = await _itemsCollection(listId)
        .where('completed', isEqualTo: true)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
  
  /// Limpa TODOS os itens de uma lista (independente do status)
  Future<void> clearAllItems(String listId) async {
    final query = await _itemsCollection(listId).get();
    
    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
  
  /// Obtém todos os itens de uma lista com listener em tempo real
  Stream<List<DocumentSnapshot>> listenToItems(String listId) {
    return _itemsCollection(listId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }
  
  // ============================================
  // Operações em Lote
  // ============================================
  
  /// Marca todos os itens como concluídos
  Future<void> completeAllItems(String listId) async {
    final query = await _itemsCollection(listId).get();
    
    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {
        'completed': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
  
  /// Desmarca todos os itens
  Future<void> uncompleteAllItems(String listId) async {
    final query = await _itemsCollection(listId).get();
    
    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {
        'completed': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
  
  /// Limpa TODOS os itens de TODAS as listas (deleta as listas ativas)
  Future<void> clearAllListsItems() async {
    try {
      print('🗑️ Iniciando limpeza de todas as listas...');
      
      // Buscar todas as listas ativas
      final listsQuery = await _listsCollection
          .where('isActive', isEqualTo: true)
          .get();
      
      final batch = _firestore.batch();
      int totalListsDeleted = 0;
      
      for (final listDoc in listsQuery.docs) {
        final listId = listDoc.id;
        print('🗑️ Deletando lista: $listId');
        batch.delete(listDoc.reference);
        totalListsDeleted++;
        
        // Também deletar itens da subcoleção se existirem
        final itemsQuery = await _itemsCollection(listId).get();
        for (final itemDoc in itemsQuery.docs) {
          batch.delete(itemDoc.reference);
        }
      }
      
      if (totalListsDeleted > 0) {
        await batch.commit();
        print('✅ Limpeza concluída: $totalListsDeleted listas removidas');
      } else {
        print('ℹ️ Nenhuma lista para limpar');
      }
    } catch (e) {
      print('❌ Erro ao limpar todas as listas: $e');
      rethrow;
    }
  }
}