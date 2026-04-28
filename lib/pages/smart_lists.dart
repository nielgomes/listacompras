import 'package:flutter/material.dart';
import 'package:listacompras2/services/firestore_lists_service.dart';
import 'package:listacompras2/services/openrouter_service.dart';

/// Tela para gerar listas de compras de forma inteligente usando IA
class SmartListsPage extends StatefulWidget {
  const SmartListsPage({super.key});

  @override
  State<SmartListsPage> createState() => _SmartListsPageState();
}

class _SmartListsPageState extends State<SmartListsPage> {
  final FirestoreListsService _firestoreService = FirestoreListsService.instance;
  final OpenRouterService _openRouterService = OpenRouterService();
  final TextEditingController _contextController = TextEditingController();
  
  bool _isGenerating = false;
  bool _isLoadingService = false;
  List<Map<String, dynamic>> _generatedItems = [];
  String _generationError = '';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    setState(() => _isLoadingService = true);
    try {
      await _openRouterService.initialize();
    } catch (e) {
      print('⚠️ Erro ao inicializar OpenRouterService: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingService = false);
      }
    }
  }

  Future<void> _generateList() async {
    final userContext = _contextController.text.trim();
    if (userContext.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o contexto para gerar a lista')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedItems = [];
      _generationError = '';
    });

    try {
      print('🤖 Gerando lista inteligente para contexto: "$userContext"');
      
      final items = await _openRouterService.generateList(userContext)
          .timeout(const Duration(seconds: 30), onTimeout: () {
        print('⚠️ Timeout na geração da lista');
        return [];
      });

      if (mounted) {
        setState(() {
          _generatedItems = items;
          _isGenerating = false;
        });

        if (items.isEmpty) {
          setState(() {
            _generationError = 'Não foi possível gerar itens. Tente outro contexto.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum item gerado. Tente outro contexto.')),
          );
        } else {
          print('✅ Lista gerada com ${items.length} itens');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao gerar lista: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generationError = 'Erro ao gerar lista: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar lista: $e')),
        );
      }
    }
  }

  Future<void> _confirmAndSaveList() async {
    if (_generatedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gere uma lista primeiro')),
      );
      return;
    }

    final nameController = TextEditingController();
    final listName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nome da Lista'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Digite o nome da lista',
            hintText: 'Ex: Churrasco do final de semana',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.dispose();
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              nameController.dispose();
              Navigator.pop(dialogContext, name.isEmpty ? null : name);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (listName == null || listName.isEmpty) {
      return;
    }

    try {
      print('💾 Salvando lista "$listName" com ${_generatedItems.length} itens...');
      
      final listId = await _firestoreService.createListWithItems(
        name: listName,
        items: _generatedItems.map((item) => {
          'title': item['title'] as String,
          'section': item['section'] as String,
        }).toList(),
      );

      print('✅ Lista salva com ID: $listId');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lista "$listName" criada com sucesso!')),
        );
        
        // Limpa o formulário
        setState(() {
          _generatedItems = [];
          _contextController.clear();
        });
        
        // Volta para a tela anterior
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao salvar lista: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar lista: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = _openRouterService.isConfigured;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Listas Inteligentes'),
            Text(
              'Gere listas automaticamente com IA',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Card de configuração/aviso
          Card(
            margin: const EdgeInsets.all(8),
            color: isConfigured ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    isConfigured ? Icons.check_circle : Icons.warning,
                    color: isConfigured ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isConfigured
                          ? 'IA configurada corretamente'
                          : '⚠️ API Key não configurada. Configure no arquivo .env',
                      style: TextStyle(
                        color: isConfigured ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Formulário de contexto
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Descreva o que você precisa comprar:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contextController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Churrasco para 10 pessoas, Café da manhã, Festa infantil...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: (_isGenerating || !isConfigured) ? null : _generateList,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.rocket_launch),
                      label: const Text('Gerar Lista com IA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Mensagem de erro
          if (_generationError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _generationError,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // Lista gerada
          if (_generatedItems.isNotEmpty)
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_generatedItems.length} itens gerados',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _confirmAndSaveList,
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar Lista'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _generatedItems.length,
                      itemBuilder: (context, index) {
                        final item = _generatedItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                (item['section'] as String)[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              item['title'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              item['section'] as String,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Estado de carregamento ou vazio
          if (_isLoadingService)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
          
          if (!_isLoadingService && _generatedItems.isEmpty && !_isGenerating && _generationError.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rocket_launch, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Descreva o que você precisa\ne a IA gera sua lista!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }
}
