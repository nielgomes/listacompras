import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Serviço para integração com Brave Search API
/// 
/// Busca informações na web para auxiliar o LLM na geração de listas de compras
/// com dados mais recentes e precisos.
class BraveSearchService {
  static final BraveSearchService _instance = BraveSearchService._internal();
  factory BraveSearchService() => _instance;
  BraveSearchService._internal();

  // Configuração da API
  static const String _baseUrl = 'https://api.search.brave.com/res/v1/web';
  static const int _timeoutSeconds = 15;

  /// Inicializa o serviço carregando configurações do .env
  Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      print('✅ BraveSearchService inicializado');
    } catch (e) {
      print('❌ Erro ao inicializar BraveSearchService: $e');
    }
  }

  /// Obtém a API key do .env
  String? _getApiKey() {
    final key = dotenv.env['BRAVE_API_KEY'];
    if (key == null || key.isEmpty || key == 'CHANGE_ME') {
      print('⚠️ BRAVE_API_KEY não configurada no .env');
      return null;
    }
    return key;
  }

  /// Busca na web usando Brave Search API
  Future<String?> search(String query) async {
    final apiKey = _getApiKey();
    if (apiKey == null) {
      print('❌ Brave API Key não disponível');
      return null;
    }

    try {
      print('🔍 Buscando no Brave Search: "$query"');

      final response = await http
          .get(
            Uri.parse('$_baseUrl/search?q=${Uri.encodeComponent(query)}&count=5'),
            headers: {
              'Accept': 'application/json',
              'X-Subscription-Token': apiKey,
            },
          )
          .timeout(const Duration(seconds: _timeoutSeconds));

      print('📡 Resposta HTTP: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final web = data['web'] as Map?;
        final results = web?['results'] as List?;
        
        if (results != null && results.isNotEmpty) {
          // Extrai descriptions relevantes
          final snippets = results
              .whereType<Map>()
              .map((r) => r['description'] as String?)
              .where((s) => s != null && s.isNotEmpty)
              .take(5)
              .join('\n\n');
          
          print('✅ ${results.length} resultados encontrados');
          return snippets;
        }
      } else {
        print('⚠️ Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Erro na busca Brave Search: $e');
    }

    return null;
  }

  /// Busca receitas específicas
  Future<String?> searchRecipes(String dishName, int servings) async {
    final query = 'lista compras $dishName $servings pessoas ingredientes';
    return search(query);
  }

  /// Busca listas para eventos
  Future<String?> searchEventList(String eventDescription) async {
    final query = 'lista compras $eventDescription o que comprar';
    return search(query);
  }

  /// Verifica se o serviço está configurado
  bool get isConfigured {
    final key = _getApiKey();
    return key != null && key.isNotEmpty && key != 'CHANGE_ME';
  }
}

void main() async {
  final service = BraveSearchService();
  await service.initialize();
  
  if (service.isConfigured) {
    print('\n🧪 Testando busca...');
    final result = await service.search('risoto funghi ingredientes 3 pessoas');
    if (result != null) {
      print('\n📋 Resultado:');
      print('=' * 50);
      print(result);
      print('=' * 50);
    } else {
      print('❌ Nenhum resultado retornado');
    }
  } else {
    print('❌ Serviço não configurado corretamente');
  }
}