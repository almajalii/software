import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/model/chat_message.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get chat messages for a specific user (real-time stream)
  Stream<List<ChatMessage>> getChatMessages(String userId) {
    return _firestore
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessage.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  // Send a message from user
  Future<void> sendMessage(String userId, String userName, String message) async {
    await _firestore
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .add({
      'userId': userId,
      'userName': userName,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isFromUser': true,
    });

    // Update last message timestamp for admin to see
    await _firestore.collection('chats').doc(userId).set({
      'userId': userId,
      'userName': userName,
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadByAdmin': true,
    }, SetOptions(merge: true));
  }

  // Send reply from customer service (for testing, you can manually add these in Firebase Console)
  Future<void> sendCustomerServiceReply(String userId, String message) async {
    await _firestore
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .add({
      'userId': 'customer_service',
      'userName': 'Customer Service',
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isFromUser': false,
    });
  }
}