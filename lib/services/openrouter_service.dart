import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Serviço para integração com OpenRouter API
/// 
/// Fornece classificação automática de itens e geração de listas inteligentes
/// usando LLMs com fallback automático entre múltiplos modelos.
class OpenRouterService {
  static final OpenRouterService _instance = OpenRouterService._internal();
  factory OpenRouterService() => _instance;
  OpenRouterService._internal();

  // Configuração da API
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const int _timeoutSeconds = 15;

  // Modelos configurados (ordem de fallback)
  late final List<String> _models;
  
  // Seções disponíveis para classificação
  static const List<String> _sections = [
    'Bebidas',
    'Comidas',
    'Frios e Congelados',
    'Frutas, Verduras e folhas',
    'Produtos de Higiene',
    'Produtos de Limpeza',
    'Outros',
  ];

  /// Inicializa o serviço carregando configurações do .env
  Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      
      final model1 = dotenv.env['OPENROUTER_MODEL1'] ?? 'openai/gpt-oss-120b:free';
      final model2 = dotenv.env['OPENROUTER_MODEL2'] ?? 'google/gemma-4-26b-a4b-it:free';
      final model3 = dotenv.env['OPENROUTER_MODEL3'] ?? 'deepseek/deepseek-v4-flash';
      
      _models = [model1, model2, model3].where((m) => m.isNotEmpty).toList();
      
      print('✅ OpenRouterService inicializado com ${_models.length} modelos');
    } catch (e) {
      print('❌ Erro ao inicializar OpenRouterService: $e');
      _models = ['openai/gpt-oss-120b:free', 'google/gemma-4-26b-a4b-it:free'];
    }
  }

  /// Obtém a API key do .env
  String? _getApiKey() {
    final key = dotenv.env['OPENROUTER_API_KEY'];
    if (key == null || key.isEmpty || key == 'sk-or') {
      print('⚠️ OPENROUTER_API_KEY não configurada no .env');
      return null;
    }
    return key;
  }

  /// Cria o prompt para classificação de item
  String _buildClassificationPrompt(String itemName) {
    final sectionsList = _sections.map((s) => '- $s').join('\n');
    return 'Você é um assistente de organização de compras.\n'
        'Classifique o item na seção correta:\n\n'
        'Seções disponíveis:\n'
        '$sectionsList\n\n'
        'Item: "$itemName"\n\n'
        'Responda APENAS com o nome da seção exata da lista acima. Não adicione explicações.';
  }

  /// Cria o prompt para geração de lista
  String _buildListGenerationPrompt(String context) {
    final sectionsStr = _sections.join(', ');
    return 'Você é um assistente de compras. Crie uma lista de compras para: $context\n\n'
        'Use APENAS estas seções: $sectionsStr\n\n'
        'Formato de saída EXATO (não adicione nada além disso):\n'
        '- [Bebidas]\n'
        '  * Suco\n'
        '  * Refrigerante\n'
        '- [Comidas]\n'
        '  * Arroz\n'
        '  * Feijão\n\n'
        'IMPORTANTE: Responda APENAS com o formato acima. Não explique, não adicione texto extra.';
  }

  /// Envia requisição para OpenRouter
  Future<String?> _sendRequest(String prompt, {String? modelOverride, int maxTokens = 500}) async {
    final apiKey = _getApiKey();
    if (apiKey == null) {
      print('❌ API Key não disponível');
      return null;
    }

    final modelsToTry = modelOverride != null 
        ? [modelOverride]
        : _models;

    for (final model in modelsToTry) {
      try {
        print('🚀 Enviando requisição para modelo: $model (max_tokens: $maxTokens)');
        
        final response = await http
            .post(
              Uri.parse(_baseUrl),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'HTTP-Referer': 'https://listacompras.app',
                'X-Title': 'Lista de Compras App',
              },
              body: json.encode({
                'model': model,
                'messages': [
                  {
                    'role': 'user',
                    'content': prompt,
                  },
                ],
                'max_tokens': maxTokens,
                'temperature': 0.3,
                'stream': false,
              }),
            )
            .timeout(const Duration(seconds: _timeoutSeconds));

        print('📡 Resposta HTTP: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final content = data['choices']?[0]?['message']?['content']?.toString().trim();
          
          if (content != null && content.isNotEmpty) {
            print('✅ Resposta recebida do modelo $model');
            return content;
          }
        } else if (response.statusCode == 429) {
          print('⚠️ Rate limit atingido para $model, tentando próximo...');
          continue;
        } else {
          print('⚠️ Erro HTTP ${response.statusCode} para $model: ${response.body}');
          continue;
        }
      } catch (e) {
        print('⚠️ Erro na requisição para $model: $e');
        continue;
      }
    }

    print('❌ Todos os modelos falharam');
    return null;
  }

  /// Classifica um item em uma seção usando IA
  /// 
  /// Retorna o nome da seção ou 'Outros' em caso de erro
  Future<String> classifyItem(String itemName) async {
    if (itemName.trim().isEmpty) {
      return 'Outros';
    }

    try {
      final prompt = _buildClassificationPrompt(itemName);
      final response = await _sendRequest(prompt);

      if (response != null && response.isNotEmpty) {
        // Limpa a resposta
        var section = response.trim();
        
        // Remove prefixos comuns
        section = section.replaceAll(RegExp(r'^[\-\*]\s*'), '');
        section = section.replaceAll(RegExp(r'^Seção:\s*'), '');
        section = section.replaceAll(RegExp(r'^\d+\.\s*'), '');
        section = section.trim();

        // Verifica se é uma seção válida
        if (_sections.any((s) => s.toLowerCase() == section.toLowerCase())) {
          // Retorna a versão canônica
          return _sections.firstWhere(
            (s) => s.toLowerCase() == section.toLowerCase(),
            orElse: () => 'Outros',
          );
        }
        
        print('⚠️ Seção não reconhecida: "$section", usando "Outros"');
      }
    } catch (e, stack) {
      print('❌ Erro ao classificar item "$itemName": $e');
      print('Stack: $stack');
    }

    return 'Outros';
  }

  /// Gera uma lista de compras a partir de um contexto
  /// 
  /// Retorna uma lista de mapas com 'section' e 'title'
  Future<List<Map<String, String>>> generateList(String context) async {
    if (context.trim().isEmpty) {
      return [];
    }

    try {
      final prompt = _buildListGenerationPrompt(context);
      // Aumenta max_tokens para listas mais longas
      final response = await _sendRequest(prompt, maxTokens: 1000);

      if (response != null && response.isNotEmpty) {
        print('📝 Resposta bruta da IA:\n$response');
        final items = _parseListResponse(response);
        if (items.isEmpty) {
          print('⚠️ Parser primário não encontrou itens, tentando parser alternativo...');
          final fallbackItems = _parseListResponseFallback(response);
          if (fallbackItems.isEmpty) {
            print('⚠️ Nenhum item encontrado em nenhum parser');
          }
          return fallbackItems;
        }
        return items;
      }
    } catch (e, stack) {
      print('❌ Erro ao gerar lista: $e');
      print('Stack: $stack');
    }

    return [];
  }

  /// Parseia a resposta da IA em uma lista estruturada
  List<Map<String, String>> _parseListResponse(String response) {
    final items = <Map<String, String>>[];
    String? currentSection;

    final lines = response.split('\n');
    
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Verifica se é uma seção: - [Nome da Seção] ou - Nome da Seção
      final sectionMatch = RegExp(r'^\-\s*\[?([^\]\n]+)\]?').firstMatch(line);
      if (sectionMatch != null) {
        final sectionName = sectionMatch.group(1)?.trim();
        if (sectionName != null && !sectionName.contains('*') && !sectionName.contains('•')) {
          currentSection = sectionName;
          continue;
        }
      }

      // Verifica se é um item: * Nome do Item ou - Nome do Item ou • Nome do Item
      final itemMatch = RegExp(r'^[\*\-\•]\s*(.+)').firstMatch(line);
      if (itemMatch != null && currentSection != null) {
        final itemTitle = itemMatch.group(1)?.trim();
        if (itemTitle != null && itemTitle.isNotEmpty) {
          items.add({
            'section': currentSection!,
            'title': itemTitle,
          });
        }
      }
    }

    print('✅ Parseou ${items.length} itens da resposta');
    return items;
  }

  /// Parser alternativo para formatos não reconhecidos
  List<Map<String, String>> _parseListResponseFallback(String response) {
    final items = <Map<String, String>>[];
    String? currentSection;
    
    // Tenta extrair seções e itens usando regex mais flexível
    final sectionRegex = RegExp(r'(?:^|\n)\s*(?:-\s*)?\[?([A-Za-zÀ-ÿ\s,]+)\]?(?:\s*\]|\n)');
    final itemRegex = RegExp(r'(?:^|\n)\s*[\*\-\•]\s*([^\n]+)');
    
    // Primeiro tenta encontrar seções
    final sectionMatches = sectionRegex.allMatches(response);
    final foundSections = <String>[];
    
    for (final match in sectionMatches) {
      final section = match.group(1)?.trim();
      if (section != null && section.isNotEmpty && !section.contains('*')) {
        foundSections.add(section);
      }
    }
    
    // Se encontrou seções, tenta associar itens
    if (foundSections.isNotEmpty) {
      for (final section in foundSections) {
        currentSection = section;
        // Procura itens após esta seção
        final sectionIndex = response.indexOf(section);
        if (sectionIndex != -1) {
          final remaining = response.substring(sectionIndex + section.length);
          final itemMatches = itemRegex.allMatches(remaining);
          for (final match in itemMatches) {
            final item = match.group(1)?.trim();
            if (item != null && item.isNotEmpty && !item.contains('[')) {
              items.add({
                'section': currentSection!,
                'title': item,
              });
            }
          }
        }
      }
    }
    
    // Se ainda não encontrou nada, tenta extrair qualquer item listado
    if (items.isEmpty) {
      final allItems = itemRegex.allMatches(response);
      for (final match in allItems) {
        final item = match.group(1)?.trim();
        if (item != null && item.isNotEmpty) {
          items.add({
            'section': 'Outros',
            'title': item,
          });
        }
      }
    }
    
    print('✅ Fallback parseou ${items.length} itens');
    return items;
  }

  /// Retorna a lista de seções disponíveis
  List<String> get sections => List.unmodifiable(_sections);

  /// Limpa o cache (se houver)
  void clearCache() {
    print('🧹 Cache limpo');
  }

  /// Verifica se o serviço está configurado corretamente
  bool get isConfigured {
    final key = _getApiKey();
    return key != null && key.isNotEmpty && key != 'sk-or';
  }
}
