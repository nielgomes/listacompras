import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:listacompras2/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para gerenciar listas de compras no Firestore com suporte a listas nomeadas
class FirestoreListsService {
  FirestoreListsService._();
  
  static final FirestoreListsService instance = FirestoreListsService._();
  
  late final FirebaseFirestore _firestore;
  final AppConfig _config = AppConfig.instance;
  bool _isInitialized = false;
  
  /// Verifica se o Firebase foi inicializado
  bool get isInitialized => _isInitialized;
  
  /// ID do usuário atual (simulado - em produção viria do Firebase Auth)
  String? _currentUserId;
  
  /// ID do usuário atual (público para leitura)
  String? get currentUserId => _currentUserId;
  
  /// Define o ID do usuário atual
  set currentUserId(String? id) => _currentUserId = id;
  
  /// Gera um ID de usuário simples baseado no timestamp
  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }
  
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
    
    // Adicionar timeout para evitar loading infinito
    try {
      await initializeInternal().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⚠️ Timeout na inicialização do Firebase (30s)');
          print('   App continuará sem Firebase - funcionalidade limitada');
        },
      );
    } catch (e) {
      print('⚠️ Erro na inicialização com timeout: $e');
    }
  }
  
  Future<void> initializeInternal() async {
    
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
    
    // Carregar ou gerar ID do usuário persistente
    await _loadOrCreateUserId();
    
    print('✅ Inicialização concluída');
  }
  
  /// Carrega o ID do usuário do SharedPreferences ou gera um novo
  Future<void> _loadOrCreateUserId() async {
    try {
      print('🔧 _loadOrCreateUserId: Iniciando...');
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('user_id');
      
      print('🔧 SharedPreferences carregado. user_id atual: $_currentUserId');
      
      if (_currentUserId == null) {
        _currentUserId = _generateUserId();
        await prefs.setString('user_id', _currentUserId!);
        print('👤 Novo ID do usuário gerado e salvo: $_currentUserId');
        
        // Verificar se salvou corretamente
        final verifyPrefs = await SharedPreferences.getInstance();
        final saved = verifyPrefs.getString('user_id');
        print('🔧 Verificação: userId salvo=$saved');
      } else {
        print('👤 ID do usuário carregado: $_currentUserId');
      }
    } catch (e, stackTrace) {
      print('⚠️ Erro ao carregar userId: $e');
      print('Stack trace: $stackTrace');
      // Fallback se SharedPreferences falhar
      _currentUserId = _generateUserId();
      print('⚠️ Gerado novo userId como fallback: $_currentUserId');
    }
  }
  
  /// Coleção principal das listas de compras (pública para acesso externo)
  CollectionReference get listsCollection => _firestore.collection('shopping_lists');
  
  /// Coleção principal das listas de compras (interna)
  CollectionReference get _listsCollection => listsCollection;
  
  /// Subcoleção de itens dentro de uma lista
  CollectionReference _itemsCollection(String listId) =>
      _listsCollection.doc(listId).collection('items');
  
  // ============================================
  // Operações com Listas
  // ============================================
  
  /// Gera um código aleatório para compartilhamento
  String _generateShareCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var code = '';
    var num = random;
    for (var i = 0; i < 6; i++) {
      code += chars[num % chars.length];
      num = num ~/ chars.length;
    }
    return code;
  }
  
  /// Gera um código único verificando se já existe no banco
  Future<String> _generateUniqueShareCode() async {
    String code = _generateShareCode(); // Valor padrão inicial
    bool exists = true;
    int attempts = 0;
    
    while (exists && attempts < 10) {
      code = _generateShareCode();
      final query = _listsCollection.where('shareCode', isEqualTo: code).limit(1);
      final snapshot = await query.get();
      exists = snapshot.docs.isNotEmpty;
      attempts++;
    }
    
    return code;
  }
  
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
      // Gerar código único para compartilhamento
      print('   - Gerando código único de compartilhamento...');
      final shareCode = await _generateUniqueShareCode();
      print('   - Código gerado: $shareCode');
      
      // Usar add() simples - sem timeout
      // O add() tem comportamento mais consistente no Flutter Web
      print('   🚀 Executando add()...');
      
      // Garantir que temos um userId e salvá-lo se for novo
      if (_currentUserId == null) {
        print('⚠️ _currentUserId é NULL no createList! Gerando novo...');
        _currentUserId = _generateUserId();
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', _currentUserId!);
          print('👤 Novo ID salvo no SharedPreferences: $_currentUserId');
          
          // Verificar se salvou
          final verifyPrefs = await SharedPreferences.getInstance();
          final saved = verifyPrefs.getString('user_id');
          print('🔧 Verificação: userId salvo=$saved');
        } catch (e) {
          print('⚠️ Erro ao salvar userId: $e');
        }
      }
      final userId = _currentUserId!;
      print('📝 Criando lista com ownerId=$userId, shareCode=$shareCode');
      
      final docRef = await _listsCollection.add({
        'name': name,
        'description': description ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': true,
        // Campos de compartilhamento
        'shareCode': shareCode,
        'ownerId': userId,
        'members': {userId: {'name': 'Proprietário', 'role': 'owner'}},
        'isShared': false,
      });
      print('✅ Lista criada com ID: ${docRef.id}, ownerId: $userId');
      
      // Verificar se salvou corretamente lendo o documento
      final verifyDoc = await docRef.get();
      final savedData = verifyDoc.data() as Map<String, dynamic>;
      print('🔧 Verificação: Lista salva com ownerId=${savedData['ownerId']}, members=${savedData['members']}');
      
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
      
      // Filtrar listas que pertencem ao usuário atual (owner ou membro)
      // Se _currentUserId for null, retornar lista vazia
      if (_currentUserId == null) {
        print('⚠️ getLists: _currentUserId é NULL! Retornando lista vazia.');
        return [];
      }
      
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final ownerId = data['ownerId'] as String?;
        final members = Map<String, dynamic>.from(data['members'] ?? {});
        
        // Se não tem ownerId (lista antiga ou corrompida), não mostrar para ninguém
        if (ownerId == null) {
          final listName = data['name'] ?? 'Sem nome';
          print('   - Lista "$listName": SEM ownerId (IGNORANDO)');
          return false;
        }
        
        // Mostrar se é proprietário ou membro
        return ownerId == _currentUserId || members.containsKey(_currentUserId);
      }).toList();
      
      return filteredDocs;
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
    print('📡 listenToLists: onlyActive=$onlyActive, _currentUserId=$_currentUserId');
    
    if (_currentUserId == null) {
      print('⚠️ ATENÇÃO: _currentUserId é NULL! Isso causará filtragem incorreta.');
    }
    
    Query query = _listsCollection;
    
    if (onlyActive) {
      query = query.where('isActive', isEqualTo: true);
    }
    
    // Removido orderBy('name') para não depender de índice composto
    // A ordenação será feita no cliente
    return query
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs;
          
          // Filtrar listas que pertencem ao usuário atual (owner ou membro)
          print('🔍 Filtrando listas para _currentUserId=$_currentUserId');
          
          // Verificar se _currentUserId está definido
          if (_currentUserId == null) {
            print('⚠️ ATENÇÃO: _currentUserId é NULL! Nenhuma lista será exibida.');
            return <DocumentSnapshot>[];
          }
          
          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final ownerId = data['ownerId'] as String?;
            final members = Map<String, dynamic>.from(data['members'] ?? {});
            final listName = data['name'] ?? 'Sem nome';
            
            // Se não tem ownerId (lista antiga ou corrompida), não mostrar para ninguém
            // Como o usuário informou que não existem listas antigas, isso não deve acontecer
            if (ownerId == null) {
              print('   - Lista "$listName": SEM ownerId (IGNORANDO - lista não será exibida)');
              return false;
            }
            
            // Verificar se é proprietário ou membro
            final isOwner = ownerId == _currentUserId;
            final isMember = members.containsKey(_currentUserId);
            
            print('   - Lista "$listName": ownerId=$ownerId, isOwner=$isOwner, isMember=$isMember');
            
            return isOwner || isMember;
          }).toList();
          
          // Ordenar por nome no cliente
          filteredDocs.sort((a, b) {
            final aName = (a.data() as Map<String, dynamic>)['name'] ?? '';
            final bName = (b.data() as Map<String, dynamic>)['name'] ?? '';
            return aName.compareTo(bName);
          });
          
          return filteredDocs;
        })
        .handleError((error, stackTrace) {
      print('❌ Erro no stream de listas: $error');
      print('Stack trace: $stackTrace');
    });
  }
  
  // ============================================
  // Operações de Compartilhamento
  // ============================================
  
  /// Busca lista pelo código de compartilhamento
  Future<DocumentSnapshot?> getListByShareCode(String shareCode) async {
    print('🔍 getListByShareCode: $shareCode');
    
    try {
      // Buscar lista pelo código, apenas listas ativas
      final query = _listsCollection
          .where('shareCode', isEqualTo: shareCode)
          .where('isActive', isEqualTo: true)
          .limit(1);
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        print('   - Lista não encontrada ou inativa');
        return null;
      }
      
      print('   ✅ Lista encontrada: ${snapshot.docs.first.id}');
      return snapshot.docs.first;
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar lista por código: $e');
      print('Stack trace: $stackTrace');
      // Se falhar por falta de índice, tentar busca alternativa
      try {
        print('   - Tentando busca alternativa sem filtro isActive...');
        final altQuery = _listsCollection.where('shareCode', isEqualTo: shareCode).limit(1);
        final altSnapshot = await altQuery.get();
        
        if (altSnapshot.docs.isEmpty) {
          print('   - Lista não encontrada (busca alternativa)');
          return null;
        }
        
        final doc = altSnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        
        // Verificar se está ativa manualmente
        if (data['isActive'] == false) {
          print('   - Lista encontrada mas está inativa');
          return null;
        }
        
        print('   ✅ Lista encontrada (busca alternativa): ${doc.id}');
        return doc;
      } catch (e2) {
        print('❌ Erro na busca alternativa: $e2');
        return null;
      }
    }
  }
  
  /// Entra em uma lista compartilhada usando o código
  /// Retorna true se entrou com sucesso
  Future<bool> joinSharedList({
    required String listId,
    required String userName,
  }) async {
    print('🤝 joinSharedList: listId=$listId, userName=$userName');
    
    try {
      // Verificar se a lista existe e está ativa
      final listDoc = await _listsCollection.doc(listId).get();
      if (!listDoc.exists) {
        print('   - Lista não encontrada');
        return false;
      }
      
      final data = listDoc.data() as Map<String, dynamic>;
      
      // Verificar se a lista está ativa
      if (data['isActive'] == false) {
        print('   - Lista está inativa/deletada');
        return false;
      }
      
      final members = Map<String, dynamic>.from(data['members'] ?? {});
      
      // Usar o ID do usuário atual (ou gerar um se não existir) e salvá-lo
      if (_currentUserId == null) {
        _currentUserId = _generateUserId();
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', _currentUserId!);
          print('👤 Novo ID salvo no SharedPreferences: $_currentUserId');
        } catch (e) {
          print('⚠️ Erro ao salvar userId: $e');
        }
      }
      final userId = _currentUserId!;
      
      // Adicionar usuário aos membros
      members[userId] = {
        'name': userName,
        'role': 'editor',
        'joinedAt': DateTime.now().toIso8601String(),
      };
      
      await _listsCollection.doc(listId).update({
        'members': members,
        'isShared': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      print('   ✅ Entrou na lista com sucesso como $userId');
      return true;
    } catch (e, stackTrace) {
      print('❌ Erro ao entrar na lista compartilhada: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Verifica se o usuário tem permissão para deletar a lista
  Future<bool> canUserDeleteList({
    required String listId,
    required String userId,
  }) async {
    print('🔐 canUserDeleteList: listId=$listId, userId=$userId');
    
    try {
      final listDoc = await _listsCollection.doc(listId).get();
      if (!listDoc.exists) return false;
      
      final data = listDoc.data() as Map<String, dynamic>;
      final members = Map<String, dynamic>.from(data['members'] ?? {});
      
      // Proprietário tem permissão
      if (data['ownerId'] == userId) return true;
      
      // Verificar se é membro com role 'owner'
      final member = members[userId];
      if (member != null && member['role'] == 'owner') return true;
      
      return false;
    } catch (e) {
      print('❌ Erro ao verificar permissão: $e');
      return false;
    }
  }
  
  /// Deleta uma lista com verificação de permissão
  Future<void> deleteSharedList({
    required String listId,
    required String userId,
  }) async {
    print('🗑️ deleteSharedList: listId=$listId, userId=$userId');
    
    final canDelete = await canUserDeleteList(listId: listId, userId: userId);
    if (!canDelete) {
      throw Exception('Você não tem permissão para excluir esta lista');
    }
    
    await deleteList(listId);
  }

  /// Faz o usuário sair de uma lista compartilhada (apenas remove dos membros)
  Future<bool> leaveList({
    required String listId,
    required String userId,
  }) async {
    print('🚪 leaveList: listId=$listId, userId=$userId');
    
    try {
      final listDoc = await _listsCollection.doc(listId).get();
      if (!listDoc.exists) {
        print('   - Lista não encontrada');
        return false;
      }
      
      final data = listDoc.data() as Map<String, dynamic>;
      final members = Map<String, dynamic>.from(data['members'] ?? {});
      
      // Verificar se o usuário é membro
      if (!members.containsKey(userId)) {
        print('   - Usuário não é membro desta lista');
        return false;
      }
      
      // Verificar se não é o owner (owner não pode "sair", apenas excluir)
      // Verifica tanto ownerId quanto role no mapa members
      final isOwnerById = data['ownerId'] == userId;
      final memberData = members[userId] as Map<String, dynamic>?;
      final isOwnerByRole = memberData?['role'] == 'owner';
      
      if (isOwnerById || isOwnerByRole) {
        print('   - Owner não pode sair da lista, deve excluí-la');
        throw Exception('Proprietário não pode sair da lista. Use "Excluir lista"');
      }
      
      // Remover usuário dos membros
      members.remove(userId);
      
      await _listsCollection.doc(listId).update({
        'members': members,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      print('   ✅ Usuário saiu da lista com sucesso');
      return true;
    } catch (e, stackTrace) {
      print('❌ Erro ao sair da lista: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
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
      
      // Usar add() com timeout para garantir que o item seja salvo
      print('   🚀 Executando add()...');
      final docRef = await collection.add(data).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('   ⚠️ Timeout no add() após 30s');
          throw Exception('Timeout ao adicionar item');
        },
      );
      
      print('✅ Item adicionado com ID: ${docRef.id}');
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
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs;
          // Ordenar por seção e depois por título no cliente
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aSection = aData['section'] ?? '';
            final bSection = bData['section'] ?? '';
            final aTitle = aData['title'] ?? '';
            final bTitle = bData['title'] ?? '';
            
            final sectionCompare = aSection.compareTo(bSection);
            if (sectionCompare != 0) return sectionCompare;
            return aTitle.compareTo(bTitle);
          });
          return docs;
        })
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
  /// Retorna um Map com 'id' e 'shareCode' da lista criada
  Future<Map<String, String>> createListWithItems({
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
      
      // Garantir que temos um userId e salvá-lo se for novo
      if (_currentUserId == null) {
        print('⚠️ _currentUserId é NULL no createListWithItems! Gerando novo...');
        _currentUserId = _generateUserId();
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', _currentUserId!);
          print('👤 Novo ID salvo no SharedPreferences: $_currentUserId');
          
          // Verificar se salvou
          final verifyPrefs = await SharedPreferences.getInstance();
          final saved = verifyPrefs.getString('user_id');
          print('🔧 Verificação: userId salvo=$saved');
        } catch (e) {
          print('⚠️ Erro ao salvar userId: $e');
        }
      }
      final userId = _currentUserId!;
      print('📝 Criando lista com itens - ownerId=$userId, shareCode será gerado');
      
      // Gerar código único para compartilhamento
      final shareCode = await _generateUniqueShareCode();
      print('   - Código gerado: $shareCode');
      
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
        // Campos de compartilhamento
        'shareCode': shareCode,
        'ownerId': userId,
        'members': {userId: {'name': 'Proprietário', 'role': 'owner'}},
        'isShared': false,
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
      
      print('✅ Lista criada com sucesso! ID: ${listRef.id}, ownerId: $userId');
      
      // Verificar se salvou corretamente lendo o documento
      final verifyDoc = await listRef.get();
      if (verifyDoc.exists) {
        final savedData = verifyDoc.data() as Map<String, dynamic>;
        print('🔧 Verificação: Lista salva com ownerId=${savedData['ownerId']}, members=${savedData['members']}, shareCode=${savedData['shareCode']}');
      } else {
        print('⚠️ Verificação falhou: documento não encontrado após criação!');
      }
      
      return {'id': listRef.id, 'shareCode': shareCode};
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
