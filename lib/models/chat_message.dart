class ChatMessage {
  final String role; // 'user' or 'model'
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.role,
    required this.text,
    required this.createdAt,
  });
}