import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:listacompras2/services/firestore_lists_service.dart';
import 'package:listacompras2/services/openrouter_service.dart';

class ListItemsPage extends StatefulWidget {
  final String listId;
  final String listName;

  const ListItemsPage({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<ListItemsPage> createState() => _ListItemsPageState();
}

class _ListItemsPageState extends State<ListItemsPage> {
  final FirestoreListsService _firestoreService = FirestoreListsService.instance;
  final OpenRouterService _openRouterService = OpenRouterService();
  final TextEditingController _itemController = TextEditingController();
  bool _isAddingItem = false;
  bool _isClassifying = false;
  late final Stream<List<DocumentSnapshot>> _itemsStream;
  String _filterText = '';

  static const Map<String, String> sectionLabels = {
    'Bebidas': 'Bebidas',
    'Comidas': 'Comidas',
    'Frios e Congelados': 'Frios e Congelados',
    'Frutas, Verduras e folhas': 'Frutas, Verduras e folhas',
    'Produtos de Higiene': 'Produtos de Higiene',
    'Produtos de Limpeza': 'Produtos de Limpeza',
    'Outros': 'Outros',
  };

  @override
  void initState() {
    super.initState();
    _itemsStream = _firestoreService.listenToItems(widget.listId);
    _initializeOpenRouter();
    print('📥 ListItemsPageState criado — stream de itens inicializado para a lista: ${widget.listId}');
  }

  Future<void> _initializeOpenRouter() async {
    try {
      await _openRouterService.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('⚠️ Erro ao inicializar OpenRouterService: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.listName, style: const TextStyle(fontSize: 18)),
            StreamBuilder<List<DocumentSnapshot>>(
              stream: _itemsStream,
              builder: (context, snapshot) {
                int totalItems = 0;
                int completedItems = 0;
                if (snapshot.hasData) {
                  totalItems = snapshot.data!.length;
                  for (var doc in snapshot.data!) {
                    final data = doc.data() as Map<String, dynamic>?;
                    if (data?['completed'] == true) {
                      completedItems++;
                    }
                  }
                }
                return Text(
                  '$completedItems/$totalItems itens',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                );
              },
            ),
          ],
        ),
        actions: [
          StreamBuilder<List<DocumentSnapshot>>(
            stream: _itemsStream,
            builder: (context, snapshot) {
              int totalItems = 0;
              int completedItems = 0;
              if (snapshot.hasData) {
                totalItems = snapshot.data!.length;
                for (var doc in snapshot.data!) {
                  final data = doc.data() as Map<String, dynamic>?;
                  if (data?['completed'] == true) {
                    completedItems++;
                  }
                }
              }
              if (totalItems == 0) {
                return const SizedBox.shrink();
              }
              final allCompleted = totalItems > 0 && completedItems == totalItems;
              return IconButton(
                icon: Icon(
                  allCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                  color: allCompleted ? Colors.green : null,
                ),
                tooltip: allCompleted ? 'Desmarcar todos' : 'Marcar todos',
                onPressed: () => _toggleAllItems(allCompleted),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Formulário para adicionar item
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  TextField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      labelText: 'Nome do item',
                      hintText: 'Digite para buscar ou adicionar item...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _filterText.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _itemController.clear();
                                setState(() => _filterText = '');
                              },
                              tooltip: 'Limpar filtro',
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() => _filterText = value),
                    onSubmitted: (_) => _addItem(),
                  ),
                  if (_isClassifying)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Classificando com IA...', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isAddingItem ? null : _addItem,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: _isAddingItem
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Adicionar Item'),
                  ),
                ],
              ),
            ),
          ),
          // Indicador de filtragem (aparece apenas quando há filtro)
          if (_filterText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: StreamBuilder<List<DocumentSnapshot>>(
                stream: _itemsStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final totalItems = snapshot.data!.length;
                  final filteredCount = _filterText.isEmpty 
                      ? totalItems 
                      : snapshot.data!.where((item) {
                          final data = item.data() as Map<String, dynamic>;
                          final title = (data['title'] ?? '').toString().toLowerCase();
                          return title.contains(_filterText.toLowerCase());
                        }).length;
                  return Text(
                    '$filteredCount de $totalItems itens encontrados',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  );
                },
              ),
            ),
          // Lista de itens
          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: _itemsStream,
              builder: (context, snapshot) {
                print('📡 StreamBuilder connectionState: ${snapshot.connectionState}');
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print('   - Aguardando dados...');
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  print('   - Erro no stream: ${snapshot.error}');
                  return Center(
                    child: Text('Erro ao carregar itens: ${snapshot.error}'),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  print('   - Nenhum item nesta lista');
                  return const Center(
                    child: Text('Nenhum item nesta lista'),
                  );
                }
                
                final items = snapshot.data!;
                print('   - ${items.length} itens carregados');
                
                // Aplicar filtro dinâmico baseado no _filterText
                final filteredItems = _filterText.isEmpty 
                    ? items 
                    : items.where((item) {
                        final data = item.data() as Map<String, dynamic>;
                        final title = (data['title'] ?? '').toString().toLowerCase();
                        return title.contains(_filterText.toLowerCase());
                      }).toList();
                
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final data = item.data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Sem nome';
                    final section = data['section'] ?? 'Outros';
                    final completed = data['completed'] ?? false;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Checkbox(
                          value: completed,
                          onChanged: (value) {
                            print('   ✅ Alternando status do item: $title');
                            _firestoreService.toggleItemCompletion(
                              listId: widget.listId,
                              itemId: item.id,
                            );
                          },
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            decoration: completed ? TextDecoration.lineThrough : null,
                            color: completed ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Text(sectionLabels[section] ?? section),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteItem(item.id, title),
                          tooltip: 'Excluir item',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem() async {
    final title = _itemController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome do item')),
      );
      return;
    }

    // Desabilitar botão IMEDIATAMENTE antes de qualquer operação
    // Isso previne cliques múltiplos antes do setState atualizar a UI
    setState(() {
      _isAddingItem = true;
      _isClassifying = true;
    });
    
    // Limpar campo após desabilitar o botão
    final itemTitle = title;
    _itemController.clear();
    
    print('📝 Iniciando adição de item: $itemTitle');
    print('✅ Estados definidos: _isAddingItem=true, _isClassifying=true');
    
    String section = 'Outros';
    
    try {
      // Tentar classificar com IA se o serviço estiver configurado
      if (_openRouterService.isConfigured) {
        print('🤖 Tentando classificar item com IA...');
        setState(() => _isClassifying = true);
        
        final classifiedSection = await _openRouterService.classifyItem(itemTitle)
            .timeout(const Duration(seconds: 15), onTimeout: () {
          print('⚠️ Timeout na classificação IA, usando "Outros"');
          return 'Outros';
        });
        
        section = classifiedSection;
        print('✅ Classificação IA: "$itemTitle" -> "$section"');
      } else {
        print('ℹ️ OpenRouter não configurado, usando seção padrão "Outros"');
      }
    } catch (e) {
      print('⚠️ Erro na classificação IA: $e');
      print('Usando seção padrão "Outros"');
      section = 'Outros';
    } finally {
      setState(() => _isClassifying = false);
    }
    
    try {
      print('🚀 Chamando addItem no Firestore (seção: $section)...');
      await _firestoreService.addItem(
        listId: widget.listId,
        title: itemTitle,
        section: section,
      );
      print('✅ Item adicionado com sucesso!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item "$itemTitle" adicionado em $section')),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao adicionar item: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar: $e')),
        );
      }
    } finally {
      print('🔄 Executando finally - resetando estados');
      if (mounted) {
        setState(() {
          _isAddingItem = false;
          _isClassifying = false;
        });
        print('✅ Estados resetados para false');
      } else {
        print('⚠️ Widget não está mounted');
      }
    }
  }

  Future<void> _confirmDeleteItem(String itemId, String itemName) async {
    print('🗑️ _confirmDeleteItem: itemId=$itemId, itemName=$itemName');
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir item?'),
        content: Text('Deseja remover "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      print('   - Excluindo item...');
      try {
        await _firestoreService.removeItem(listId: widget.listId, itemId: itemId);
        print('   ✅ Item excluído com sucesso');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item excluído')),
          );
        }
      } catch (e, stackTrace) {
        print('❌ Erro ao excluir item: $e');
        print('Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir item: $e')),
          );
        }
      }
    }
  }


  Future<void> _toggleAllItems(bool allCompleted) async {
    print('🔄 _toggleAllItems: allCompleted=$allCompleted');
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(allCompleted ? 'Desmarcar todos?' : 'Marcar todos?'),
        content: Text(allCompleted 
            ? 'Deseja desmarcar todos os itens desta lista?'
            : 'Deseja marcar todos os itens desta lista como concluídos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: allCompleted ? Colors.orange : Colors.green,
            ),
            child: Text(allCompleted ? 'Desmarcar' : 'Marcar'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        if (allCompleted) {
          print('   - Desmarcando todos os itens...');
          await _firestoreService.uncompleteAllItems(widget.listId);
          print('   ✅ Todos os itens desmarcados');
        } else {
          print('   - Marcando todos os itens...');
          await _firestoreService.completeAllItems(widget.listId);
          print('   ✅ Todos os itens marcados');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(allCompleted ? 'Todos desmarcados' : 'Todos marcados')),
          );
        }
      } catch (e, stackTrace) {
        print('❌ Erro ao alternar todos os itens: $e');
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
  void dispose() {
    _itemController.dispose();
    print('🗑️ ListItemsPage disposed');
    super.dispose();
  }
}