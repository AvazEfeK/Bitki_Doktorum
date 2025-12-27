import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import '../models/chat_message.dart';
import '../utils/show_snack.dart';
import '../app_keys.dart';
import '../widgets/message_bubble.dart';
import 'chat_page.dart';

class AnalyzePage extends StatefulWidget {
  const AnalyzePage({super.key});

  @override
  State<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> with AutomaticKeepAliveClientMixin {
  File? _image;
  String? _resultText;
  bool _isLoading = false;
  
  // Chat geçmişi
  final List<ChatMessage> _chatHistory = [];
  late final GeminiService _geminiService;
  
  // Controller'ı state'te tutuyoruz
  final TextEditingController _miniChatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService(
      apiKey: dotenv.env[AppKeys.geminiApiKey] ?? '',
      modelName: dotenv.env[AppKeys.geminiModel] ?? 'gemini-1.5-flash',
    );
  }

  @override
  void dispose() {
    _miniChatController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_geminiService.isReady) {
      showSnack(context, "API Key eksik.", isError: true);
      return;
    }
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked == null) return;

      setState(() {
        _image = File(picked.path);
        _resultText = null;
        _chatHistory.clear();
      });

      await _analyze();

    } catch (e) {
      showSnack(context, "Resim hatası: $e", isError: true);
    }
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await _geminiService.analyzePlant(_image!);
      setState(() {
        _resultText = result;
      });
    } catch (e) {
      if(mounted) showSnack(context, "Analiz hatası: $e", isError: true);
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // Mesajı işle ve sohbeti aç
  void _handleMessageAndOpenChat(String message) {
    if (message.trim().isEmpty) return;

    // 1. Önce listeye ekle
    setState(() {
      _chatHistory.add(ChatMessage(role: 'user', text: message.trim(), createdAt: DateTime.now()));
      _miniChatController.clear(); 
    });

    // 2. Sonra sayfayı aç
    _openFullScreenChat();
  }

  void _openFullScreenChat() {
    if (_resultText == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          contextText: _resultText!,
          history: _chatHistory,
          geminiService: _geminiService,
        ),
      ),
    ).then((_) {
      setState(() {}); 
    });
  }

  Widget _buildMiniChat() {
    if (_chatHistory.isEmpty) return const SizedBox.shrink();
    final recent = _chatHistory.length > 2 ? _chatHistory.sublist(_chatHistory.length - 2) : _chatHistory;
    return Column(
      children: recent.map((m) => MessageBubble(text: m.text, isUser: m.role == 'user')).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Bitki Analizi")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fotoğraf Alanı
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    image: _image != null ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) : null,
                  ),
                  child: _image == null 
                    ? const Center(child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey)) 
                    : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text("Kamera")),
                ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo), label: const Text("Galeri")),
              ],
            ),
            const SizedBox(height: 20),
            
            if (_isLoading) 
              const Center(child: CircularProgressIndicator())
            else if (_resultText != null) ...[
               // Analiz Sonucu
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3), 
                   borderRadius: BorderRadius.circular(12)
                 ),
                 child: SelectableText(
                   _resultText!, 
                   style: const TextStyle(fontSize: 15, height: 1.4),
                 ),
               ),
               
               const SizedBox(height: 20),
               
               // Başlık ve Buton
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   const Text("Sohbet Geçmişi", style: TextStyle(fontWeight: FontWeight.bold)),
                   TextButton.icon(
                     onPressed: _openFullScreenChat, 
                     icon: const Icon(Icons.fullscreen), 
                     label: const Text("Tam Ekran")
                   )
                 ],
               ),
               
               _buildMiniChat(),
               
               // --- MİNİ CHAT GİRİŞİ ---
               Padding(
                 padding: const EdgeInsets.only(top: 12.0),
                 child: Row(
                   children: [
                     Expanded(
                       child: TextField(
                         controller: _miniChatController,
                         decoration: InputDecoration(
                           hintText: "Örn: Nasıl sularım?",
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                         ),
                         textInputAction: TextInputAction.send,
                         // Klavyeden Enter'a basınca
                         onSubmitted: (val) => _handleMessageAndOpenChat(val),
                       ),
                     ),
                     const SizedBox(width: 8),
                     // Yeşil Ok Butonu (Artık çalışıyor)
                     FloatingActionButton.small(
                       onPressed: () => _handleMessageAndOpenChat(_miniChatController.text),
                       backgroundColor: Colors.green,
                       child: const Icon(Icons.send, color: Colors.white),
                     ),
                   ],
                 ),
               )
            ]
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}