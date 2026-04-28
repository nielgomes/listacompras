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
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _showCreateListDialog,
              tooltip: 'Criar nova lista',
            ),
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () => _toggleAllItems(true),
              tooltip: 'Marcar todos',
            ),
            IconButton(
              icon: const Icon(Icons.remove_done),
              onPressed: () => _toggleAllItems(false),
              tooltip: 'Desmarcar todos',
            ),
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () {
                print('🔄 Sincronização automática via StreamBuilder');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dados sincronizados automaticamente!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              tooltip: 'Sincronizar',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'limpar') {
                  _showClearConfirmationDialog();
                } else if (value == 'testar') {
                  _testFirestoreConnection();
                }
              },
              itemBuilder: (BuildContext context) => [
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
              child: StreamBuilder<List<DocumentSnapshot>>(
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

                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: description.isNotEmpty
                              ? Text(description)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
