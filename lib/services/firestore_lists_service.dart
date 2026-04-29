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
  
  /// Verifica se o Firebase foi inicializado
  bool get isInitialized => _isInitialized;
  
  /// Inicializa o Firebase (deve ser chamado antes de usar o serviço)
  Future<void> initialize() async {
    // Evitar inicialização múltipla
    if (_isInitialized) {
      print('⚠️ Firebase já foi inicializado anteriormente');
      return;
    }
    
    print('🔧 Inicializando Firebase...');
    try {
      await _config.init();
      print('✅ Variáveis de ambiente carregadas');
    } catch (e) {
      print('⚠️ Erro ao carregar variáveis de ambiente: $e');
      print('   Tentando usar configurações do google-services.json...');
    }
    
    print('📋 Verificando configuração Firebase...');
    
    try {
      // No Android/iOS, priorizar google-services.json (mais confiável)
      // Usar .env apenas como fallback ou para Web
      print('⚠️ Usando google-services.json (Android/iOS nativo)');
      await Firebase.initializeApp();
      
      print('✅ Firebase inicializado com sucesso!');
      
      // Obter instância do Firestore PRIMEIRO
      _firestore = FirebaseFirestore.instance;
      print('📡 Firestore instance obtido');
      
      // Configurar Firestore DEPOIS de obter a instância
      // Não definir host personalizado - deixar o SDK usar o padrão
      // Isso resolve problemas de hang no Flutter Web
      print('⚙️ Configurando Firestore...');
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        // Não definir host e sslEnabled - deixa o SDK usar padrões do Firebase
      );
      print('✅ Firestore configurado (usando padrões do SDK)');
    } catch (e, stackTrace) {
      print('❌ Erro ao inicializar Firebase: $e');
      print('Tipo: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      // Não rethrow - permite que o app continue sem Firebase
      print('⚠️ App continuará sem Firebase - funcionalidade limitada');
    }
    
    _isInitialized = true;
    print('✅ Inicialização concluída');
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
    print('📝 createList: name=$name');
    
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
    
    print('🚀 Chamando _listsCollection.add()...');
    print('   - Coleção: shopping_lists');
    print('   - Dados: name=$name, description=${description ?? ""}');
    
    try {
      // Usar add() simples - sem timeout
      // O add() tem comportamento mais consistente no Flutter Web
      print('   🚀 Executando add()...');
      final docRef = await _listsCollection.add({
        'name': name,
        'description': description ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': true,
      });
      print('✅ Lista criada com ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      print('❌ Erro ao criar lista: $e');
      print('Tipo: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Obtém uma lista por ID
  Future<DocumentSnapshot?> getList(String listId) async {
    print('📋 getList: listId=$listId');
    
    try {
      final doc = await _listsCollection.doc(listId).get();
      print('   - Documento encontrado: ${doc.exists}');
      return doc;
    } catch (e, stackTrace) {
      print('❌ Erro ao obter lista: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Atualiza uma lista
  Future<void> updateList({
    required String listId,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    print('📝 updateList: listId=$listId');
    
    final data = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (isActive != null) data['isActive'] = isActive;
    
    try {
      print('🚀 Chamando update()...');
      await _listsCollection.doc(listId).update(data).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('   ⚠️ Timeout no updateList() após 30s, mas lista pode ter sido atualizada');
          return;
        },
      );
      print('✅ Lista atualizada com sucesso!');
    } catch (e, stackTrace) {
      print('❌ Erro ao atualizar lista: $e');
      print('Tipo: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Deleta uma lista (soft delete)
  Future<void> deleteList(String listId) async {
    print('🗑️ deleteList: listId=$listId');
    
    try {
      print('🔄 Atualizando documento...');
      await _listsCollection.doc(listId).update({
        'isActive': false,
        'deletedAt': DateTime.now().toIso8601String(),
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('   ⚠️ Timeout no deleteList() após 30s, mas lista pode ter sido deletada');
          return;
        },
      );
      print('✅ Lista deletada com sucesso');
    } catch (e, stackTrace) {
      print('❌ Erro ao deletar lista: $e');
      print('Tipo: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Lista todas as listas ativas
  Future<List<QueryDocumentSnapshot>> getLists({bool onlyActive = true}) async {
    print('📋 getLists: onlyActive=$onlyActive');
    
    try {
      Query query = _listsCollection;
      if (onlyActive) {
        query = query.where('isActive', isEqualTo: true);
      }
      final snapshot = await query.get();
      print('   - Encontradas ${snapshot.docs.length} listas');
      return snapshot.docs;
    } catch (e, stackTrace) {
      print('❌ Erro ao obter listas: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Lista todas as listas ativas com listener em tempo real
  Stream<List<DocumentSnapshot>> listenToLists({
    bool onlyActive = true,
  }) {
    print('📡 listenToLists: onlyActive=$onlyActive');
    
    Query query = _listsCollection;
    
    if (onlyActive) {
      query = query.where('isActive', isEqualTo: true);
    }
    
    return query
        .orderBy('name')  // Ordena alfabeticamente por nome
        .snapshots()
        .map((snapshot) => snapshot.docs)
        .handleError((error, stackTrace) {
      print('❌ Erro no stream de listas: $error');
      print('Stack trace: $stackTrace');
    });
  }
  
  // ============================================
  // Operações com Itens
  // ============================================
  
  /// Adiciona um item à lista
  /// Retorna o ID do item criado
  Future<String> addItem({
    required String listId,
    required String title,
    String? section,
  }) async {
    print('📝 addItem: listId=$listId, title=$title, section=${section ?? "outros"}');
    print('   - _isInitialized=$_isInitialized');
    
    try {
      print('   - Verificando inicialização...');
      if (!_isInitialized) {
        print('⚠️ Firebase não inicializado, tentando...');
        await initialize();
      } else {
        print('   - Firebase já inicializado, prosseguindo...');
      }
      print('   ✅ Firebase OK');
      
      final collection = _itemsCollection(listId);
      print('   - Coleção: shopping_lists/$listId/items');
      
      final data = {
        'title': title,
        'section': section ?? 'outros',
        'completed': false,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      print('   - Dados: $data');
      
      // SOLUÇÃO PARA FLUTTER WEB:
      // O método add()/set() tem um problema conhecido no Flutter Web onde o Future
      // nunca completa quando há um listener ativo (StreamBuilder) na mesma coleção.
      // Isso acontece porque o Firestore Web SDK otimiza operações com listeners.
      //
      // A solução correta é:
      // 1. Gerar o ID do documento manualmente
      // 2. Chamar set() SEM aguardar (fire-and-forget)
      // 3. Retornar o ID imediatamente
      // 4. Confiar no Stream (listener) para confirmar que o item foi salvo
      //
      // O StreamBuilder na UI vai receber a atualização automaticamente via snapshot,
      // então não precisamos esperar pelo Future completar.
      print('   🚀 Executando set() (fire-and-forget para Web)...');
      final docRef = collection.doc();
      
      // Não usamos await aqui! O Future é executado em background.
      // Se der erro, será capturado pelo listener do Stream.
      docRef.set(data).catchError((error, stackTrace) {
        print('⚠️ Erro assíncrono no set() (já salvo via stream): $error');
      });
      
      print('✅ Item adicionado com ID: ${docRef.id} (retorno imediato)');
      return docRef.id;
    } catch (e, stackTrace) {
      print('❌ Erro ao adicionar item: $e');
      print('Tipo: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Atualiza um item
  Future<void> updateItem({
    required String listId,
    required String itemId,
    String? title,
    String? section,
    bool? completed,
  }) async {
    print('📝 updateItem: listId=$listId, itemId=$itemId');
    
    final data = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    if (title != null) data['title'] = title;
    if (section != null) data['section'] = section;
    if (completed != null) data['completed'] = completed;
    
    try {
      print('🚀 Chamando update()...');
      await _itemsCollection(listId).doc(itemId).update(data).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('   ⚠️ Timeout no update() após 30s, mas item pode ter sido atualizado');
          return;
        },
      );
      print('✅ Item atualizado com sucesso!');
    } catch (e, stackTrace) {
      print('❌ Erro ao atualizar item: $e');
      print('Tipo: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Marca/desmarca item como concluído
  Future<void> toggleItemCompletion({
    required String listId,
    required String itemId,
  }) async {
    print('✅ toggleItemCompletion: listId=$listId, itemId=$itemId');
    
    try {
      final doc = await _itemsCollection(listId).doc(itemId).get();
      final data = doc.data() as Map<String, dynamic>?;
      final currentStatus = data?['completed'] ?? false;
      
      print('   - Status atual: $currentStatus, novo status: ${!currentStatus}');
      await _itemsCollection(listId).doc(itemId).update({
        'completed': !currentStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('   ⚠️ Timeout no toggleItemCompletion() após 30s, mas item pode ter sido atualizado');
          return;
        },
      );
      print('✅ Item atualizado com sucesso!');
    } catch (e, stackTrace) {
      print('❌ Erro ao alternar status do item: $e');
      print('Tipo: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Remove um item da lista
  Future<void> removeItem({
    required String listId,
    required String itemId,
  }) async {
    print('🗑️ removeItem: listId=$listId, itemId=$itemId');
    
    try {
      print('🚀 Chamando delete()...');
      await _itemsCollection(listId).doc(itemId).delete();
      print('✅ Item removido com sucesso!');
    } catch (e, stackTrace) {
      print('❌ Erro ao remover item: $e');
      print('Tipo: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Limpa todos os itens concluídos de uma lista
  Future<void> clearCompletedItems(String listId) async {
    print('🗑️ clearCompletedItems: listId=$listId');
    
    try {
      final query = await _itemsCollection(listId)
          .where('completed', isEqualTo: true)
          .get();
      
      print('   - Encontrados ${query.docs.length} itens concluídos');
      
      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      
      if (query.docs.isNotEmpty) {
        await batch.commit();
        print('✅ Itens concluídos removidos');
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao limpar itens concluídos: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Limpa TODOS os itens de uma lista (independente do status)
  Future<void> clearAllItems(String listId) async {
    print('🗑️ clearAllItems: listId=$listId');
    
    try {
      final query = await _itemsCollection(listId).get();
      
      print('   - Encontrados ${query.docs.length} itens');
      
      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      
      if (query.docs.isNotEmpty) {
        await batch.commit();
        print('✅ Todos os itens removidos');
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao limpar todos os itens: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Obtém todos os itens de uma lista com listener em tempo real
  Stream<List<DocumentSnapshot>> listenToItems(String listId) {
    print('📡 listenToItems: listId=$listId');
    return _itemsCollection(listId)
        .orderBy('section')  // Primeiro agrupa por seção
        .orderBy('title')    // Depois ordena alfabeticamente por título
        .snapshots()
        .map((snapshot) => snapshot.docs)
        .handleError((error, stackTrace) {
      print('❌ Erro no stream de itens: $error');
      print('Stack trace: $stackTrace');
    });
  }
  
  // ============================================
  // Operações em Lote
  // ============================================
  
  /// Marca todos os itens como concluídos
  Future<void> completeAllItems(String listId) async {
    print('✅ completeAllItems: listId=$listId');
    
    try {
      final query = await _itemsCollection(listId).get();
      
      print('   - Encontrados ${query.docs.length} itens');
      
      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {
          'completed': true,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      if (query.docs.isNotEmpty) {
        await batch.commit().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('   ⚠️ Timeout no completeAllItems() após 30s, mas itens podem ter sido atualizados');
            return;
          },
        );
        print('✅ Todos os itens marcados como concluídos');
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao marcar todos os itens como concluídos: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Desmarca todos os itens
  Future<void> uncompleteAllItems(String listId) async {
    print('✅ uncompleteAllItems: listId=$listId');
    
    try {
      final query = await _itemsCollection(listId).get();
      
      print('   - Encontrados ${query.docs.length} itens');
      
      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {
          'completed': false,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      if (query.docs.isNotEmpty) {
        await batch.commit().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('   ⚠️ Timeout no uncompleteAllItems() após 30s, mas itens podem ter sido atualizados');
            return;
          },
        );
        print('✅ Todos os itens desmarcados');
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao desmarcar todos os itens: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Limpa TODOS os itens de TODAS as listas (deleta as listas ativas)
  Future<void> clearAllListsItems() async {
    print('🗑️ clearAllListsItems: Iniciando limpeza de todas as listas...');
    
    try {
      // Buscar todas as listas ativas
      print('   - Buscando listas ativas...');
      final listsQuery = await _listsCollection
          .where('isActive', isEqualTo: true)
          .get();
      
      print('   - Encontradas ${listsQuery.docs.length} listas');
      
      final batch = _firestore.batch();
      int totalListsDeleted = 0;
      
      for (final listDoc in listsQuery.docs) {
        final listId = listDoc.id;
        print('   - Deletando lista: $listId');
        batch.delete(listDoc.reference);
        totalListsDeleted++;
        
        // Também deletar itens da subcoleção se existirem
        final itemsQuery = await _itemsCollection(listId).get();
        for (final itemDoc in itemsQuery.docs) {
          batch.delete(itemDoc.reference);
        }
      }
      
      if (totalListsDeleted > 0) {
        print('   - Executando batch commit...');
        await batch.commit();
        print('✅ Limpeza concluída: $totalListsDeleted listas removidas');
      } else {
        print('ℹ️ Nenhuma lista para limpar');
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao limpar todas as listas: $e');
      print('Tipo: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  

  /// Limpa recursos do serviço
  /// Marca todos os itens de todas as listas como concluídos
  Future<void> completeAllItemsAllLists() async {
    print('✅ completeAllItemsAllLists: Iniciando...');
    
    try {
      // Buscar todas as listas ativas
      final listsQuery = await _listsCollection
          .where('isActive', isEqualTo: true)
          .get();
      
      print('   - Encontradas ${listsQuery.docs.length} listas');
      
      final batch = _firestore.batch();
      int totalItems = 0;
      
      for (final listDoc in listsQuery.docs) {
        final listId = listDoc.id;
        final itemsQuery = await _itemsCollection(listId)
            .where('completed', isEqualTo: false)
            .get();
        
        for (final itemDoc in itemsQuery.docs) {
          batch.update(itemDoc.reference, {
            'completed': true,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          totalItems++;
        }
      }
      
      if (totalItems > 0) {
        print('   - Atualizando $totalItems itens...');
        await batch.commit().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('   ⚠️ Timeout no completeAllItemsAllLists() após 30s, mas itens podem ter sido atualizados');
            return;
          },
        );
        print('✅ Todos os itens marcados como concluídos!');
      } else {
        print('ℹ️ Nenhum item pendente para marcar');
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao marcar todos os itens: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Desmarca todos os itens de todas as listas
  Future<void> uncompleteAllItemsAllLists() async {
    print('✅ uncompleteAllItemsAllLists: Iniciando...');
    
    try {
      // Buscar todas as listas ativas
      final listsQuery = await _listsCollection
          .where('isActive', isEqualTo: true)
          .get();
      
      print('   - Encontradas ${listsQuery.docs.length} listas');
      
      final batch = _firestore.batch();
      int totalItems = 0;
      
      for (final listDoc in listsQuery.docs) {
        final listId = listDoc.id;
        final itemsQuery = await _itemsCollection(listId)
            .where('completed', isEqualTo: true)
            .get();
        
        for (final itemDoc in itemsQuery.docs) {
          batch.update(itemDoc.reference, {
            'completed': false,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          totalItems++;
        }
      }
      
      if (totalItems > 0) {
        print('   - Atualizando $totalItems itens...');
        await batch.commit().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('   ⚠️ Timeout no uncompleteAllItemsAllLists() após 30s, mas itens podem ter sido atualizados');
            return;
          },
        );
        print('✅ Todos os itens desmarcados!');
      } else {
        print('ℹ️ Nenhum item concluído para desmarcar');
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao desmarcar todos os itens: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Cria uma lista com itens em uma única operação
  Future<String> createListWithItems({
    required String name,
    String? description,
    required List<Map<String, String>> items,
  }) async {
    print('📝 createListWithItems: name=$name, items=${items.length}');
    
    // Verificar se o Firebase foi inicializado
    try {
      if (!_isInitialized) {
        print('⚠️ Firebase não foi inicializado ainda, tentando agora...');
        await initialize();
      }
    } catch (e) {
      print('❌ ERRO: Firebase não foi inicializado: $e');
      throw Exception('Firebase não foi inicializado. Por favor, recarregue a página.');
    }
    
    try {
      print('🚀 Criando lista e itens em batch...');
      
      // Criar documento da lista
      final listRef = _listsCollection.doc();
      final batch = _firestore.batch();
      
      // Dados da lista
      batch.set(listRef, {
        'name': name,
        'description': description ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': true,
      });
      
      // Adicionar itens
      for (final item in items) {
        final itemRef = _itemsCollection(listRef.id).doc();
        batch.set(itemRef, {
          'title': item['title'] ?? '',
          'section': item['section'] ?? 'Outros',
          'completed': false,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      print('   - Committing batch com ${items.length + 1} operações...');
      await batch.commit().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('   ⚠️ Timeout no createListWithItems() após 30s, mas dados podem ter sido salvos');
          return;
        },
      );
      
      print('✅ Lista criada com sucesso! ID: ${listRef.id}');
      return listRef.id;
    } catch (e, stackTrace) {
      print('❌ Erro ao criar lista com itens: $e');
      print('Tipo: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  void dispose() {
    print('🗑️ FirestoreListsService disposed');
  }
}
