class ChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime timestamp;
  final bool isFromUser; // true = user, false = customer service

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.timestamp,
    required this.isFromUser,
  });

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'message': message,
      'timestamp': timestamp,
      'isFromUser': isFromUser,
    };
  }

  // Convert from Firestore
  factory ChatMessage.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'User',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as dynamic).toDate(),
      isFromUser: data['isFromUser'] ?? true,
    );
  }
}