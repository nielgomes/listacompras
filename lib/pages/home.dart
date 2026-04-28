import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:listacompras2/pages/list_items.dart';
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

  bool _isComposing = false;

  late final Stream<List<DocumentSnapshot>> _listsStream =
      _firestoreService.listenToLists(onlyActive: true);

  @override
  void initState() {
    super.initState();
    print('📥 HomeState criado — lista sincronizada com Firebase em tempo real');
  }
  
  @override
  void dispose() {
    _toDoController.dispose();
    print('🗑️ HomeState disposed');
    super.dispose();
  }

  void _reset() {
    _toDoController.clear();
    setState(() {
      _isComposing = false;
    });
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
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                ),
                child: Text('Menu Lateral',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Listas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                    onPressed: _showCreateListDialog,
                    tooltip: 'Criar nova lista',
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.fromLTRB(8,4,8,4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 2),
                    borderRadius: BorderRadius.circular(15.0)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent),
                            onPressed: _saveList,
                            child: Text("Salvar",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              print('🔄 Sincronização automática via StreamBuilder');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Dados sincronizados automaticamente!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            child: Text("Sync",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent),
                            child: Text("Limpar",
                                style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              _showClearConfirmationDialog();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange),
                            child: Text("Testar",
                                style: TextStyle(color: Colors.white)),
                            onPressed: _testFirestoreConnection,
                          ),
                        )
                      ],
                    ),
                  )
                ),
              ),
            ],
          ),
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
                      labelText: "Lista de compra",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                      errorText:
                          _toDoController.text.isEmpty && _isComposing ? 'Informar nome da lista' : null,
                    ),
                    onChanged: (text) {
                      setState(() {
                        _isComposing = text.isNotEmpty;
                      });
                    },
                  )),
                  ElevatedButton(
                    onPressed: () {
                      _saveList();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent),
                    child: Text("ADD", style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<DocumentSnapshot>>(
                stream: _listsStream,
                builder: (context, snapshot) {
                  print('📡 Home StreamBuilder connectionState: ${snapshot.connectionState}');
                  
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                      print('   - Nenhum estado');
                      return const Center(child: CircularProgressIndicator());

                    case ConnectionState.waiting:
                      print('   - Aguardando dados...');
                      return const Center(child: CircularProgressIndicator());

                    case ConnectionState.active:
                    case ConnectionState.done:
                      if (snapshot.hasError) {
                        print('   - Erro no stream: ${snapshot.error}');
                        return Center(
                          child: Text('Erro ao carregar listas: ${snapshot.error}'),
                        );
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        print('   - Nenhuma lista encontrada');
                        return const Center(
                          child: Text('Nenhuma lista encontrada. Crie uma nova!'),
                        );
                      }

                      final lists = snapshot.data!;
                      print('   - ${lists.length} listas carregadas');
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: lists.length,
                        itemBuilder: (context, index) {
                          final doc = lists[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Sem nome';
                          final description = data['description'] ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            child: ListTile(
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(description),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_note, color: Colors.blue),
                                    onPressed: () => _showEditListDialog(doc.id, name),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteList(doc.id),
                                    tooltip: 'Excluir lista',
                                  ),
                                ],
                              ),
                              onTap: () {
                                print('📱 Navegando para lista: $name (ID: ${doc.id})');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ListItemsPage(
                                      listId: doc.id,
                                      listName: name,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );

                    default:
                      return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
