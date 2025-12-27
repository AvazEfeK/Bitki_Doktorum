import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mime/mime.dart';

import '../models/chat_message.dart';

class GeminiService {
  final String apiKey;
  final String modelName;

  String? _cachedWorkingModel;

  GeminiService({required this.apiKey, required this.modelName});

  bool get isReady => apiKey.trim().isNotEmpty;

  String _normalizeModel(String raw) {
    final m = raw.trim();
    if (m.isEmpty) return m;
    if (m.startsWith('models/')) return m.substring('models/'.length);
    return m;
  }

  String _toGeminiRole(String role) {
    final r = role.trim().toLowerCase();
    if (r == 'assistant') return 'model';
    if (r == 'model') return 'model';
    return 'user';
  }

  bool _shouldTryNextModel(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('not found') ||
        s.contains('404') ||
        s.contains('not supported') ||
        s.contains('unsupported') ||
        s.contains('generatecontent');
  }

  Exception _friendlyException(Object e) {
    final s = e.toString();
    if (s.toLowerCase().contains('api key')) {
      return Exception('Gemini API anahtarı hatalı veya eksik.');
    }
    if (s.toLowerCase().contains('permission') || s.toLowerCase().contains('unauthorized')) {
      return Exception('Gemini API yetkisi yok. API key / proje izinlerini kontrol edin.');
    }
    if (s.toLowerCase().contains('quota') || s.toLowerCase().contains('resource')) {
      return Exception('Gemini kotası dolmuş olabilir. Bir süre sonra tekrar deneyin.');
    }
    if (s.toLowerCase().contains('timeout')) {
      return Exception('Bağlantı zaman aşımına uğradı. İnterneti kontrol edin.');
    }
    return Exception('Gemini işleminde hata: $s');
  }

  Future<List<String>> _fetchAvailableModels() async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models?key=${Uri.encodeComponent(apiKey.trim())}',
    );

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(url);
      final resp = await req.close().timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return <String>[];

      final body = await resp.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      final list = (decoded is Map) ? decoded['models'] : null;
      if (list is! List) return <String>[];

      final names = <String>[];
      for (final m in list) {
        if (m is! Map) continue;
        final name = (m['name'] as String?)?.trim() ?? '';
        final methods = m['supportedGenerationMethods'];
        final supported = (methods is List) ? methods.map((x) => '$x').toList() : <String>[];
        if (name.isEmpty) continue;
        if (!supported.contains('generateContent')) continue;
        names.add(_normalizeModel(name));
      }
      return names;
    } catch (_) {
      return <String>[];
    } finally {
      client.close(force: true);
    }
  }

  Future<List<String>> _candidateModels() async {
    final candidates = <String>[];
    if (_cachedWorkingModel != null && _cachedWorkingModel!.trim().isNotEmpty) {
      candidates.add(_cachedWorkingModel!.trim());
    }
    final envModel = _normalizeModel(modelName);
    if (envModel.isNotEmpty) candidates.add(envModel);

    if (isReady) {
      final available = await _fetchAvailableModels();
      if (available.isNotEmpty) {
        final flash = available.where((m) {
          final s = m.toLowerCase();
          return s.contains('gemini') &&
              s.contains('flash') &&
              !s.contains('embedding') &&
              !s.contains('aqa');
        }).toList();
        candidates.addAll(flash);
        candidates.addAll(available);
      }
    }
    candidates.addAll(const [
      'gemini-1.5-flash',
      'gemini-flash-latest',
      'gemini-2.0-flash',
    ]);

    final seen = <String>{};
    final uniq = <String>[];
    for (final c in candidates) {
      final v = _normalizeModel(c);
      if (v.isEmpty) continue;
      if (seen.add(v)) uniq.add(v);
    }
    return uniq;
  }

  Future<String> _generateWithModelFallback(List<Content> contents) async {
    if (!isReady) {
      throw Exception('Gemini API Key (.env) eksik. GEMINI_API_KEY ekleyin.');
    }

    Object? lastModelError;
    final modelsToTry = await _candidateModels();
    
    for (final m in modelsToTry) {
      try {
        final model = GenerativeModel(model: m, apiKey: apiKey.trim());
        final res = await model.generateContent(contents);
        final text = res.text?.trim() ?? '';
        _cachedWorkingModel = m; 
        return text.isNotEmpty ? text : 'Sonuç alınamadı.';
      } catch (e) {
        lastModelError = e;
        if (_shouldTryNextModel(e)) {
          continue;
        }
        throw _friendlyException(e);
      }
    }

    final msg = (lastModelError?.toString() ?? '').toLowerCase();
    if (msg.contains('not found') || msg.contains('404')) {
      throw Exception(
        'Seçilen Gemini modeli bulunamadı. Lütfen internet bağlantınızı kontrol edin veya farklı bir model deneyin.',
      );
    }
    throw _friendlyException(lastModelError ?? Exception('Bilinmeyen hata'));
  }

  Future<String> analyzePlant(File imageFile) async {
    if (!isReady) throw Exception('Gemini API Key (.env) eksik.');

    final bytes = await imageFile.readAsBytes();
    if (bytes.isEmpty) throw Exception('Fotoğraf okunamadı.');
    const maxBytes = 8 * 1024 * 1024; 
    if (bytes.lengthInBytes > maxBytes) {
      throw Exception('Fotoğraf çok büyük.');
    }

    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

    // --- GÜNCELLEME: Prompt artık yıldız yasaklıyor ve emoji istiyor ---
    final prompt = TextPart(
      'Bu bir bitki fotoğrafı. Bir bitki uzmanı gibi davran ama çok samimi ve neşeli ol. \n'
      'Şunları cevapla:\n'
      '1) Bu bitkinin adı ne? 🌿\n'
      '2) Bir hastalığı var mı, sağlıklı mı duruyor? 🧐\n'
      '3) Nasıl bakmalıyım? (Su, güneş vb.) 💧☀️\n\n'
      'KESİN KURALLAR:\n'
      '- Asla Markdown bold (yıldız *) karakterini KULLANMA.\n'
      '- Başlıkları BÜYÜK HARFLE yazarak ayır.\n'
      '- Bol bol emoji kullan.\n'
      '- Listeler için sadece tire (-) kullan.\n'
      '- Okuması çok kolay, ferah bir metin olsun.',
    );
    // ------------------------------------------------------------------

    final imagePart = DataPart(mimeType, bytes);

    final contents = <Content>[
      Content.multi([prompt, imagePart]),
    ];

    return _generateWithModelFallback(contents);
  }

  Future<String> chat({
    required String contextText,
    required String message,
    required List<ChatMessage> history,
  }) async {
    if (!isReady) throw Exception('Gemini API Key (.env) eksik.');

    final trimmedMsg = message.trim();
    if (trimmedMsg.isEmpty) return 'Lütfen bir mesaj yazın.';

    final recent = history.length > 6 ? history.sublist(history.length - 6) : history;

    final contents = <Content>[
      Content(
        'user',
        [
          TextPart(
            'BAĞLAM (Bitki Analizi):\n${contextText.trim().isEmpty ? "Yok" : contextText.trim()}\n\n'
            'Kurallar: Asla yıldız (*) kullanma. Emojilerle süsle. Kısa ve samimi cevap ver.',
          ),
        ],
      ),
      ...recent.map((m) => Content(_toGeminiRole(m.role), [TextPart(m.text)])),
      Content('user', [TextPart(trimmedMsg)]),
    ];

    return _generateWithModelFallback(contents);
  }
}