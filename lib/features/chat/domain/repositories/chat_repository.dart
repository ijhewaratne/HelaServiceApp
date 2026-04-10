import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';

/// Abstract repository for chat operations
abstract class ChatRepository {
  /// Create a new chat room for a booking
  Future<Either<Failure, Map<String, dynamic>>> createChatRoom({
    required String bookingId,
    required String customerId,
    required String workerId,
  });
  
  /// Get chat room by ID
  Future<Either<Failure, Map<String, dynamic>>> getChatRoom(String chatRoomId);
  
  /// Get chat room by booking ID
  Future<Either<Failure, Map<String, dynamic>?>> getChatRoomByBooking(String bookingId);
  
  /// Send message
  Future<Either<Failure, Map<String, dynamic>>> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String message,
    String? messageType,
    Map<String, dynamic>? metadata,
  });
  
  /// Get chat messages
  Future<Either<Failure, List<Map<String, dynamic>>>> getMessages(
    String chatRoomId, {
    int limit = 50,
    String? lastMessageId,
  });
  
  /// Stream chat messages
  Stream<Either<Failure, List<Map<String, dynamic>>>> watchMessages(String chatRoomId);
  
  /// Mark messages as read
  Future<Either<Failure, void>> markMessagesAsRead({
    required String chatRoomId,
    required String userId,
  });
  
  /// Get unread message count
  Future<Either<Failure, int>> getUnreadCount({
    required String chatRoomId,
    required String userId,
  });
  
  /// Get user's chat rooms
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserChatRooms(String userId);
}
