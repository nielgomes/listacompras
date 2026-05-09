import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  String? apiKey;
  try {
    final envFile = File('/workspace/listacompras/.env');
    if (await envFile.exists()) {
      final fileContent = await envFile.readAsString();
      for (final line in fileContent.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('BRAVE_API_KEY=')) {
          apiKey = trimmed.substring('BRAVE_API_KEY='.length).trim();
          break;
        }
      }
    }
  } catch (e) {
    print('Erro ao ler .env: $e');
  }
  
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ BRAVE_API_KEY não configurada');
    return;
  }
  
  print('✅ BRAVE_API_KEY: ${apiKey.substring(0, 10)}...');
  
  final query = 'ingredientes risoto funghi 3 pessoas';
  print('\n🔍 Buscando: "$query"');
  
  final client = http.Client();
  try {
    // Tentar com token na query string
    final url = 'https://api.search.brave.com/res/v1/search?q=${Uri.encodeComponent(query)}&count=5&token=$apiKey';
    print('URL: $url');
    
    var response = await client.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    ).timeout(const Duration(seconds: 15));
    
    print('Status: ${response.statusCode}');
    print('Content-Type: ${response.headers['content-type']}');
    final bodyLen = response.body.length;
    print('Body length: $bodyLen');
    print('Body (first 400): ${response.body.substring(0, bodyLen > 400 ? 400 : bodyLen)}');
    
  } finally {
    client.close();
  }
}