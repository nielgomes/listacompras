import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  // Teste 1: Salvar e carregar
  await prefs.setString('test_key', 'test_value');
  final loaded = prefs.getString('test_key');
  print('Teste 1 - Salvar/Carregar: $loaded');
  
  // Teste 2: Verificar se persiste
  final prefs2 = await SharedPreferences.getInstance();
  final loaded2 = prefs2.getString('test_key');
  print('Teste 2 - Persistência: $loaded2');
  
  // Limpeza
  await prefs.remove('test_key');
  print('Teste concluído!');
}
