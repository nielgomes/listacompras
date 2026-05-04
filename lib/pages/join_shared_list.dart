import 'package:flutter/material.dart';
import '../services/firestore_lists_service.dart';

class JoinSharedListPage extends StatefulWidget {
  final FirestoreListsService listsService;
  
  const JoinSharedListPage({
    Key? key,
    required this.listsService,
  }) : super(key: key);

  @override
  State<JoinSharedListPage> createState() => _JoinSharedListPageState();
}

class _JoinSharedListPageState extends State<JoinSharedListPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _joinList() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Buscar lista pelo código
      final listDoc = await widget.listsService.getListByShareCode(
        _codeController.text.toUpperCase(),
      );

      if (listDoc == null) {
        setState(() {
          _errorMessage = 'Código de lista inválido. Verifique e tente novamente.';
        });
        return;
      }

      final listData = listDoc.data() as Map<String, dynamic>;
      final listId = listDoc.id;
      final listName = listData['name'] ?? 'Lista sem nome';

      // Entrar na lista
      final success = await widget.listsService.joinSharedList(
        listId: listId,
        userName: _nameController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Você entrou na lista "$listName"'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = 'Não foi possível entrar na lista. Tente novamente.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrar em Lista Compartilhada'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Ícone
              const Icon(
                Icons.group_add,
                size: 80,
                color: Colors.blue,
              ),
              
              const SizedBox(height: 30),
              
              // Campo de código
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Código da Lista',
                  hintText: 'Digite o código de 6 dígitos',
                  prefixIcon: Icon(Icons.qr_code),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o código da lista';
                  }
                  if (value.length != 6) {
                    return 'O código deve ter 6 caracteres';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Campo de nome
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Seu Nome',
                  hintText: 'Como deseja aparecer na lista',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite seu nome';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Mensagem de erro
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Botão
              ElevatedButton(
                onPressed: _isLoading ? null : _joinList,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Entrando...'),
                        ],
                      )
                    : const Text(
                        'Entrar na Lista',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              
              const SizedBox(height: 20),
              
              // Informações
              Card(
                color: Colors.blue.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Como funciona:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('• Peça o código de 6 dígitos ao dono da lista'),
                      Text('• Digite o código e seu nome'),
                      Text('• Você terá acesso para adicionar e editar itens'),
                      Text('• Apenas o dono pode excluir a lista'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}