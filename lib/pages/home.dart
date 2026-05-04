import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:listacompras2/pages/join_shared_list.dart';
import 'package:listacompras2/pages/list_items.dart';
import 'package:listacompras2/pages/smart_lists.dart';
import 'package:listacompras2/services/firestore_lists_service.dart';
import 'package:listacompras2/services/firestore_test.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _toDoController = TextEditingController();
  final FirestoreListsService _firestoreService = FirestoreListsService.instance;

  bool _firebaseReady = false;
  String? _errorMessage;

  Stream<List<DocumentSnapshot>>? _listsStream;

  @override
  void initState() {
    super.initState();
    print('📥 HomeState criado — verificando Firebase...');
    _checkFirebase();
  }

  Future<void> _checkFirebase() async {
    try {
      // Verificar se Firebase está inicializado
      if (!_firestoreService.isInitialized) {
        print('⚠️ Firebase não inicializado, tentando inicializar...');
        await _firestoreService.initialize();
      }
      _listsStream = _firestoreService.listenToLists(onlyActive: true);
      setState(() {
        _firebaseReady = true;
      });
    } catch (e, stackTrace) {
      print('❌ Erro ao verificar Firebase: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _firebaseReady = true;
        _errorMessage = 'Não foi possível conectar ao Firebase. Verifique sua conexão.';
      });
    }
  }
  
  @override
  void dispose() {
    _toDoController.dispose();
    print('🗑️ HomeState disposed');
    super.dispose();
  }

  void _reset() {
    _toDoController.clear();
  }

  Future<void> _saveList() async {
    final text = _toDoController.text.trim();
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, informe o nome da lista')),
        );
      }
      return;
    }
    
    print('💾 _saveList: name=$text');
    
    try {
      print('   - Criando lista...');
      await _firestoreService.createList(
        name: text,
        description: 'Lista criada via app Flutter Web',
      );
      print('   ✅ Lista criada com sucesso!');
      _reset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lista salva com sucesso!')),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao salvar lista: $e');
      print('Tipo: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  Future<void> _testFirestoreConnection() async {
    try {
      print('🧪 Testando conexão com Firestore...');
      await FirestoreTest.instance.testConnection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teste de conexão iniciado! Verifique o console.')),
        );
      }
    } catch (e) {
      print('❌ Erro ao testar conexão: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao testar: $e')),
        );
      }
    }
  }

  Future<void> _showCreateListDialog() async {
    print('📝 _showCreateListDialog');
    
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar nova lista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da lista',
                hintText: 'Ex: Supermercado Sábado',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Ex: Compras para o fim de semana',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final name = nameController.text.trim();
      if (name.isNotEmpty) {
        print('   - Criando lista: $name');
        try {
          await _firestoreService.createList(
            name: name,
            description: descController.text.trim(),
          );
          print('   ✅ Lista criada com sucesso!');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lista "$name" criada com sucesso!')),
            );
          }
        } catch (e, stackTrace) {
          print('❌ Erro ao criar lista: $e');
          print('Stack trace: $stackTrace');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao criar lista: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _showEditListDialog(String listId, String currentName) async {
    print('✏️ _showEditListDialog: listId=$listId, currentName=$currentName');
    
    final controller = TextEditingController(text: currentName);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar lista'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome da lista',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newName = controller.text.trim();
      if (newName.isNotEmpty) {
        print('   - Atualizando lista: $newName');
        try {
          await _firestoreService.updateList(
            listId: listId,
            name: newName,
            description: 'Lista atualizada',
          );
          print('   ✅ Lista atualizada com sucesso!');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lista atualizada!')),
            );
          }
        } catch (e, stackTrace) {
          print('❌ Erro ao atualizar lista: $e');
          print('Stack trace: $stackTrace');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao atualizar: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _deleteList(String listId) async {
    print('🗑️ _deleteList: listId=$listId');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lista?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      print('   - Confirmou exclusão, chamando deleteList...');
      try {
        await _firestoreService.deleteList(listId);
        print('   ✅ Lista deletada — StreamBuilder vai atualizar a UI automaticamente');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lista excluída com sucesso!')),
          );
        }
      } catch (e, stackTrace) {
        print('❌ Erro ao excluir lista: $e');
        print('Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')),
          );
        }
      }
    }
  }

  Future<void> _showClearConfirmationDialog() async {
    print('🗑️ _showClearConfirmationDialog');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar tudo?'),
        content: const Text('Deseja apagar todas as listas e seus itens?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      print('   - Iniciando limpeza de todos os itens...');
      try {
        await _firestoreService.clearAllListsItems();
        print('   ✅ Limpeza concluída com sucesso!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todas as listas foram apagadas com sucesso!')),
          );
        }
      } catch (e, stackTrace) {
        print('❌ Erro ao limpar: $e');
        print('Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao limpar: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleAllItems(bool complete) async {
    print('✅ _toggleAllItems: complete=$complete');
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(complete ? 'Marcar todos?' : 'Desmarcar todos?'),
        content: Text(complete
            ? 'Deseja marcar TODOS os itens de TODAS as listas como concluídos?'
            : 'Deseja desmarcar TODOS os itens de TODAS as listas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: complete ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(complete ? 'Marcar todos' : 'Desmarcar todos'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (complete) {
          await _firestoreService.completeAllItemsAllLists();
        } else {
          await _firestoreService.uncompleteAllItemsAllLists();
        }
        print('   ✅ Operação concluída com sucesso!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(complete
                  ? 'Todos os itens marcados como concluídos!'
                  : 'Todos os itens desmarcados!'),
            ),
          );
        }
      } catch (e, stackTrace) {
        print('❌ Erro: $e');
        print('Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Lista de Compras",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
          actions: [
            // Ícone de Listas Inteligentes (mantido na barra)
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: () {
                print('🤖 Navegando para Listas Inteligentes');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SmartListsPage(),
                  ),
                );
              },
              tooltip: 'Listas Inteligentes',
            ),
            // Menu lateral com as demais opções
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'nova_lista':
                    _showCreateListDialog();
                    break;
                  case 'entrar_lista':
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JoinSharedListPage(
                          listsService: _firestoreService,
                        ),
                      ),
                    );
                    if (result == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lista compartilhada adicionada!')),
                      );
                    }
                    break;
                  case 'sincronizar':
                    print('🔄 Sincronização automática via StreamBuilder');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dados sincronizados automaticamente!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    break;
                  case 'marcar_todos':
                    _toggleAllItems(true);
                    break;
                  case 'desmarcar_todos':
                    _toggleAllItems(false);
                    break;
                  case 'limpar':
                    _showClearConfirmationDialog();
                    break;
                  case 'testar':
                    _testFirestoreConnection();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'nova_lista',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Nova lista'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'entrar_lista',
                  child: Row(
                    children: [
                      Icon(Icons.group_add, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('Entrar em lista'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'sincronizar',
                  child: Row(
                    children: [
                      Icon(Icons.sync, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Sincronizar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'marcar_todos',
                  child: Row(
                    children: [
                      Icon(Icons.checklist, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Marcar todos'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'desmarcar_todos',
                  child: Row(
                    children: [
                      Icon(Icons.remove_done, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Desmarcar todos'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'limpar',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Limpar tudo'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'testar',
                  child: Row(
                    children: [
                      Icon(Icons.science, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Testar conexão'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.1),
              child: Row(
                children: <Widget>[
                  Expanded(
                      child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                      labelText: 'Nova Lista',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _saveList(),
                  )),
                  SizedBox(width: 5),
                  ElevatedButton(
                    onPressed: _saveList,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Salvar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: !_firebaseReady
                  ? Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 64, color: Colors.red),
                              SizedBox(height: 16),
                              Text(_errorMessage!,
                                  style: TextStyle(fontSize: 16, color: Colors.red),
                                  textAlign: TextAlign.center),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _firebaseReady = false;
                                    _errorMessage = null;
                                  });
                                  _checkFirebase();
                                },
                                child: Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        )
                      : StreamBuilder<List<DocumentSnapshot>>(
                          stream: _listsStream,
                          builder: (context, snapshot) {
                            print('📡 StreamBuilder connectionState: ${snapshot.connectionState}');

                            if (snapshot.connectionState == ConnectionState.waiting) {
                              print('   - Aguardando dados...');
                              return Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              print('   - Erro no stream: ${snapshot.error}');
                              return Center(
                                child: Text('Erro ao carregar listas: ${snapshot.error}'),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              print('   - Nenhuma lista encontrada');
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('Nenhuma lista ainda',
                                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                                    SizedBox(height: 8),
                                    Text('Crie sua primeira lista!',
                                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                                  ],
                                ),
                              );
                            }

                  final lists = snapshot.data!;
                  print('   - ${lists.length} listas carregadas');

                  return ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: lists.length,
                    itemBuilder: (context, index) {
                      final list = lists[index];
                      final data = list.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Sem nome';
                      final description = data['description'] ?? '';

                      final shareCode = data['shareCode'] as String?;
                      final isShared = data['isShared'] as bool? ?? false;
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (description.isNotEmpty) Text(description),
                              // Mostrar código de compartilhamento sempre que existir (não apenas quando isShared=true)
                              if (shareCode != null)
                                Container(
                                  margin: EdgeInsets.only(top: 4),
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.purple.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.share, size: 14, color: Colors.purple),
                                      SizedBox(width: 4),
                                      Text(
                                        '$shareCode',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.purple.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botão de compartilhar (apenas ícone)
                              if (shareCode != null)
                                IconButton(
                                  icon: Icon(Icons.share, color: Colors.purple),
                                  tooltip: 'Copiar código: $shareCode',
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(text: shareCode));
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Código $shareCode copiado!'),
                                          backgroundColor: Colors.purple,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              SizedBox(width: 4),
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () =>
                                    _showEditListDialog(list.id, name),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteList(list.id),
                                tooltip: 'Excluir',
                              ),
                            ],
                          ),
                          onTap: () {
                            print('📄 Navegando para itens da lista: $name');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ListItemsPage(
                                  listId: list.id,
                                  listName: name,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
