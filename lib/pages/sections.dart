import 'package:flutter/material.dart';
import 'package:listacompras2/services/firestore_lists_service.dart';

class Sections extends StatefulWidget {
  const Sections({super.key});

  @override
  State<Sections> createState() => _SectionsState();
}

class _SectionsState extends State<Sections> {
  String _selectedSection = 'Outros';
  String _itemName = '';
  final FirestoreListsService _firestoreService = FirestoreListsService.instance;
  bool _isSaving = false;

  // Lista de seções
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null) {
      _itemName = args.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Lista de Compras",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.1),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _itemName = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Item: $_itemName",
                        labelStyle: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17.0),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedSection,
                decoration: const InputDecoration(
                  labelText: 'Selecione a seção',
                  labelStyle: TextStyle(color: Colors.blue),
                ),
                items: sectionLabels.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSection = value ?? 'Outros';
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _addItem,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Adicionar à Lista'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: sectionLabels.entries.map((e) {
                  return ListTile(
                    title: Container(
                      alignment: Alignment.center,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.blueAccent,
                      ),
                      child: Text(
                        e.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedSection = e.key;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addItem() async {
    print('🚀 _addItem iniciado');
    
    if (_itemName.isEmpty) {
      print('⚠️ Nome do item vazio');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome do item não pode ser vazio')),
      );
      return;
    }

    // Optimistic UI: retornar imediatamente e salvar em background
    print('✅ Optimistic UI: fechando tela imediatamente');
    Navigator.pop(context);
    
    // Salvar em background (sem await - não bloqueia UI)
    _firestoreService.createList(
      name: '$_itemName - $_selectedSection',
      description: 'Item adicionado via Flutter Web',
    ).then((listId) {
      print('✅ Item salvo em background com ID: $listId');
    }).catchError((e) {
      print('❌ Erro ao salvar em background: $e');
      // Mostrar erro apenas se algo falhar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    });
  }
  
  @override
  void dispose() {
    print('🗑️ Sections disposed');
    super.dispose();
  }
}
