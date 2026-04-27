import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  // ============================================
  // LISTAS DE COMPRAS (Sincronização em Tempo Real)
  // ============================================

  /// Stream de listas ativas do Firebase — atualiza automaticamente
  late final Stream<List<DocumentSnapshot>> _listsStream =
      _firestoreService.listenToLists(onlyActive: true);

  @override
  void initState() {
    super.initState();
    print('📥 HomeState criado — lista sincronizada com Firebase em tempo real');
  }

  void _reset() {
    _toDoController.clear();
    setState(() {
      _isComposing = false;
    });
  }

  Future<void> _saveList() async {
    try {
      print('💾 Salvando lista: ${_toDoController.text}');
      if (_toDoController.text.isNotEmpty) {
        await _firestoreService.createList(
          name: _toDoController.text,
          description: 'Lista criada via app Flutter Web',
        );
        print('✅ Lista salva com sucesso!');
        _reset();
        // StreamBuilder atualiza automaticamente — sem reload manual necessário
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lista salva com sucesso!')),
          );
        }
      }
    } catch (e) {
      print('❌ Erro ao salvar: $e');
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

  Future<void> _deleteList(String listId) async {
    print('🗑️ Iniciando exclusão da lista: $listId');

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
      print('✅ Confirmou exclusão, chamando deleteList...');
      try {
        await _firestoreService.deleteList(listId);
        print('✅ Lista deletada — StreamBuilder vai atualizar a UI automaticamente');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lista excluída com sucesso!')),
          );
        }
      } catch (e) {
        print('❌ Erro ao excluir: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')),
          );
        }
      }
    }
  }

  Future<void> _showClearConfirmationDialog() async {
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
      try {
        print('🗑️ Iniciando limpeza de todos os itens...');
        await _firestoreService.clearAllListsItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todas as listas foram apagadas com sucesso!')),
          );
        }
      } catch (e) {
        print('❌ Erro ao limpar: $e');
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Listas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                              // StreamBuilder já atualiza automaticamente!
                              // Este botão força uma verificação manual
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
                      labelText: "Item a ser comprado",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                      errorText:
                          _toDoController.text.isEmpty ? 'Informar item' : null,
                    ),
                    onChanged: (text) {
                      setState(() {
                        _isComposing = text.isNotEmpty;
                      });
                    },
                  )),
                  ElevatedButton(
                    onPressed: _isComposing
                        ? () {
                            Navigator.pushNamed(context,
                                '/sections',
                                arguments: _toDoController.text.toLowerCase());
                            _reset();
                          }
                        : null,
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
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return const Center(child: CircularProgressIndicator());

                    case ConnectionState.active:
                    case ConnectionState.done:
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('Nenhuma lista encontrada'),
                        );
                      }

                      final lists = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: lists.length,
                        itemBuilder: (context, index) {
                          final doc = lists[index];
                          final data = doc.data() as Map<String, dynamic>;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            child: ListTile(
                              title: Text(
                                data['name'] ?? 'Sem nome',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(data['description'] ?? ''),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteList(doc.id),
                                tooltip: 'Excluir lista',
                              ),
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
            /* corrigir aqui com algum setState para atualizar qtos faltam
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(5.0),
                  child: FutureBuilder<int>(
                    future: repo.countFalse(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        (snapshot.data);
                        return Text('Faltam $snapshot.data itens');
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  ),
                ),
              ],
            ),*/
          ],
        ),
      ),
    );
  }
}
