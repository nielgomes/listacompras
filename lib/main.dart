import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:listacompras2/pages/home.dart';
import 'package:listacompras2/pages/list_items.dart';
import 'package:listacompras2/pages/sections.dart';
import 'package:listacompras2/services/firestore_lists_service.dart';
import 'package:listacompras2/services/openrouter_service.dart';

void main() {
  // Capturar erros não tratados
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Carregar variáveis de ambiente com tratamento robusto
    try {
      await dotenv.load(fileName: '.env');
      print('✅ Arquivo .env carregado com sucesso');
    } catch (e, stackTrace) {
      print('⚠️ Aviso: Não foi possível carregar .env: $e');
      print('Stack trace: $stackTrace');
      // Continua mesmo sem .env - o app tentará usar valores padrão
    }

    // Inicializar Firebase
    try {
      await FirestoreListsService.instance.initialize();
    } catch (e, stackTrace) {
      print('❌ Erro crítico ao inicializar Firebase: $e');
      print('Stack trace: $stackTrace');
      // Não rethrow para permitir que o app inicie e mostre erro na UI
    }

    // Inicializar OpenRouterService
    try {
      await OpenRouterService().initialize();
    } catch (e, stackTrace) {
      print('⚠️ Erro ao inicializar OpenRouterService: $e');
      print('Stack trace: $stackTrace');
      // Não é crítico, o app pode funcionar sem IA
    }

    runApp(const MyApp());
  }, (error, stackTrace) {
    print('❌ Erro não tratado no app: $error');
    print('Stack trace: $stackTrace');
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    FirestoreListsService.instance.dispose();
    OpenRouterService().clearCache();
    print('🗑️ MyApp disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Compras',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const Home(),
        '/sections': (context) => const Sections(),
      },
    );
  }
}
