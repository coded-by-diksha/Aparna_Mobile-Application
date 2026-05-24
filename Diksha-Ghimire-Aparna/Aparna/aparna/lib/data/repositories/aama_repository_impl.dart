import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/aama_repository.dart';
import '../datasources/aama_remote_datasource.dart';
import '../models/chatModel.dart';

class AamaRepositoryImpl implements AamaRepository {
  final AamaRemoteDataSource remoteDataSource;

  AamaRepositoryImpl(this.remoteDataSource);

  @override
  Future<String> sendMessage(String message, String token, {String language = 'en'}) async {
    return await remoteDataSource.sendMessage(message, token, language: language);
  }

  @override
  Future<String> getGreeting(String userName, String token, {String language = 'en'}) async {
    return await remoteDataSource.getGreeting(userName, token, language: language);
  }

  @override
  Future<void> storeChatMessage({
    required int userId,
    required String message,
    required String response,
    required String token,
  }) async {
    return await remoteDataSource.storeChatMessage(
      userId: userId,
      message: message,
      response: response,
      token: token,
    );
  }

  @override
  Future<List<ChatMessageEntity>> getChatHistory({
    required int userId,
    required String token,
  }) async {
    final models = await remoteDataSource.getChatHistory(
      userId: userId,
      token: token,
    );
    return models.map(_toEntity).toList();
  }

  ChatMessageEntity _toEntity(ChatMessage model) {
    return ChatMessageEntity(
      id: model.id,
      userId: model.userId,
      message: model.message,
      response: model.response,
      sender: model.sender,
      createdAt: model.createdAt,
    );
  }
}
