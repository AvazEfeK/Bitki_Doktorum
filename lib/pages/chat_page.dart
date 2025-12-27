import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';
import '../widgets/message_bubble.dart';
import '../utils/show_snack.dart';

class ChatPage extends StatefulWidget {
  final String contextText;
  final List<ChatMessage> history;
  final GeminiService geminiService;

  const ChatPage({
    super.key,
    required this.contextText,
    required this.history,
    required this.geminiService,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında, eğer son mesaj kullanıcıdansa (yani AnalyzePage'den geldiyse)
    // ve henüz cevaplanmadıysa (arkasında model cevabı yoksa), otomatik cevapla.
    if (widget.history.isNotEmpty && widget.history.last.role == 'user') {
      // Kullanıcı mesajı zaten listede, tekrar ekleme yapmadan sadece API'ye gönder.
      _sendToApiOnly(widget.history.last.text);
    }
    
    // Açılışta en alta kaydır
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Normal mesaj gönderme (Bu sayfadan yazılanlar)
  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      widget.history.add(ChatMessage(role: 'user', text: text, createdAt: DateTime.now()));
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    await _sendToApiOnly(text);
  }

  // Sadece API çağrısı yapan ve cevabı ekleyen yardımcı fonksiyon
  Future<void> _sendToApiOnly(String userMessage) async {
    setState(() => _isLoading = true);
    try {
      final response = await widget.geminiService.chat(
        contextText: widget.contextText,
        message: userMessage,
        // Kendisi hariç geçmişi gönder (son eklenen hariç)
        history: widget.history.length > 1 
            ? widget.history.sublist(0, widget.history.length - 1) 
            : [],
      );

      if (mounted) {
        setState(() {
          widget.history.add(ChatMessage(role: 'model', text: response, createdAt: DateTime.now()));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) showSnack(context, "Hata: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bitki Asistanı")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: widget.history.length,
              itemBuilder: (ctx, index) {
                final msg = widget.history[index];
                return MessageBubble(text: msg.text, isUser: msg.role == 'user');
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Soru sor...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _handleSend,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}