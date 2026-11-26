import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:mebabl_core/mebabl_core.dart';

import 'models/chat_attachment.dart';
import 'models/chat_attachment_input.dart';
import 'models/chat_conversation.dart';
import 'models/chat_conversation_page.dart';
import 'models/chat_message.dart';
import 'models/chat_message_page.dart';
import 'models/chat_message_read.dart';
import 'models/chat_message_sync_page.dart';
import 'models/chat_participant.dart';
import 'models/chat_pinned_message.dart';
import 'models/chat_post_share.dart';
import 'models/chat_reaction.dart';
import 'models/chat_thread.dart';
import 'models/json_helpers.dart';

/// REST SDK for the current `/api/sdk/chat` backend contract.
///
/// This client intentionally mirrors SdkChatController request names and
/// routes. Files must be uploaded to Storage/Media before they are attached to
/// a message.
class MebablChatService {
  static const String defaultBasePath = '/api/sdk/chat';
  static const int maximumPageSize = 100;
  static const int maximumTextLength = 10000;
  static const int maximumAttachmentsPerMessage = 20;
  static const int maximumParticipantsPerConversation = 100;

  static final RegExp _guidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  final MebablCore core;
  final String basePath;

  MebablChatService({
    required this.core,
    this.basePath = defaultBasePath,
  }) {
    if (basePath.trim().isEmpty || !basePath.startsWith('/')) {
      throw ArgumentError.value(
        basePath,
        'basePath',
        'basePath must be a non-empty absolute API path.',
      );
    }
  }

  /// The backend is offset/limit based and returns a plain JSON array.
  /// [page]/[pageSize] remain accepted for source compatibility and are
  /// translated to the backend's offset/limit query parameters.
  Future<MebablChatConversationPage> getConversations({
    int? offset,
    int? limit,
    int? page,
    int? pageSize,
    String? cursor,
    bool includeArchived = false,
    CancelToken? cancelToken,
  }) async {
    if (cursor != null && cursor.trim().isNotEmpty) {
      throw ArgumentError('The current Chat API uses offset/limit, not cursors.');
    }
    final resolvedOffset = offset ?? (((page ?? 1) - 1) * (pageSize ?? 50));
    final resolvedLimit = limit ?? pageSize ?? 50;
    _validateOffsetLimit(resolvedOffset, resolvedLimit);

    final response = await core.http.get<Object>(
      '$basePath/conversations',
      queryParameters: {
        'offset': resolvedOffset,
        'limit': resolvedLimit,
        'includeArchived': includeArchived,
      },
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    final parsed = MebablChatConversationPage.fromJson(response.data);
    // GetConversations currently returns a plain array rather than a page
    // envelope. A full page may have more rows, so callers can request the
    // next offset without depending on a cursor the backend does not expose.
    return MebablChatConversationPage(
      items: parsed.items,
      hasMore: parsed.hasMore || parsed.items.length == resolvedLimit,
      nextCursor: null,
    );
  }

  /// Creates a direct or group conversation using CreateConversationCommand.
  /// The backend adds the current user as the creator automatically, so the
  /// supplied participant IDs must contain only the other users.
  Future<MebablChatConversation> createConversation({
    required String type,
    required Iterable<String> participantUserIds,
    String? title,
    CancelToken? cancelToken,
  }) async {
    final normalizedType = type.trim().toLowerCase();
    if (!const {'direct', 'group'}.contains(normalizedType)) {
      throw ArgumentError.value(type, 'type', 'Conversation type must be direct or group.');
    }

    final participants = participantUserIds
        .map((id) => _requireGuid(id, 'participantUserIds'))
        .toSet()
        .toList(growable: false);
    if (participants.isEmpty) {
      throw ArgumentError('At least one other participant is required.');
    }
    if (participants.length > maximumParticipantsPerConversation) {
      throw ArgumentError(
        'A conversation cannot contain more than $maximumParticipantsPerConversation invited participants.',
      );
    }
    if (normalizedType == 'direct' && participants.length != 1) {
      throw ArgumentError('A direct conversation requires exactly one other participant.');
    }

    final normalizedTitle = _normalizeOptionalText(title, maximumLength: 200);
    final response = await core.http.post<Object>(
      '$basePath/conversations',
      data: {
        'title': normalizedTitle,
        'isGroup': normalizedType == 'group',
        'participantUserIds': participants,
      },
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return MebablChatConversation.fromJson(
      _unwrapObject(response.data, const ['conversation', 'data']),
    );
  }

  Future<MebablChatConversation> getConversation({
    required String conversationId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(conversationId, 'conversationId');
    final response = await core.http.get<Object>(
      '$basePath/conversations/$id',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return MebablChatConversation.fromJson(
      _unwrapObject(response.data, const ['conversation', 'data']),
    );
  }

  /// Updates the conversation title using the backend's partial PATCH contract.
  Future<void> updateConversationDetails({
    required String conversationId,
    required String title,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(conversationId, 'conversationId');
    final normalizedTitle = _normalizeOptionalText(title, maximumLength: 200);
    if (normalizedTitle == null) {
      throw ArgumentError.value(title, 'title', 'A non-empty title is required.');
    }
    await core.http.patch<void>(
      '$basePath/conversations/$id',
      data: {'title': normalizedTitle},
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  /// Promotes or demotes a participant through the dedicated admin endpoint.
  Future<void> setParticipantAdmin({
    required String conversationId,
    required String userId,
    required bool isAdmin,
    CancelToken? cancelToken,
  }) async {
    final conversation = _requireGuid(conversationId, 'conversationId');
    final user = _requireGuid(userId, 'userId');
    await core.http.put<void>(
      '$basePath/conversations/$conversation/participants/$user/admin',
      data: {'isAdmin': isAdmin},
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  Future<List<MebablChatParticipant>> getParticipants({
    required String conversationId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(conversationId, 'conversationId');
    final response = await core.http.get<Object>(
      '$basePath/conversations/$id/participants',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return readItems(response.data, 'participants')
        .map(MebablChatParticipant.fromJson)
        .toList(growable: false);
  }

  Future<List<MebablChatParticipant>> getPresence({
    required String conversationId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(conversationId, 'conversationId');
    final response = await core.http.get<Object>(
      '$basePath/conversations/$id/presence',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return readItems(response.data, 'presence')
        .map(MebablChatParticipant.fromJson)
        .toList(growable: false);
  }

  Future<void> addParticipant({
    required String conversationId,
    required String userId,
    String role = 'member',
    CancelToken? cancelToken,
  }) async {
    final conversation = _requireGuid(conversationId, 'conversationId');
    final user = _requireGuid(userId, 'userId');
    final normalizedRole = role.trim().toLowerCase();
    await core.http.post<void>(
      '$basePath/conversations/$conversation/participants',
      data: {'userId': user, 'isAdmin': normalizedRole == 'admin'},
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  Future<void> removeParticipant({
    required String conversationId,
    required String userId,
    CancelToken? cancelToken,
  }) async {
    final conversation = _requireGuid(conversationId, 'conversationId');
    final user = _requireGuid(userId, 'userId');
    await core.http.delete<void>(
      '$basePath/conversations/$conversation/participants/$user',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  Future<void> leaveConversation({
    required String conversationId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(conversationId, 'conversationId');
    await core.http.post<void>(
      '$basePath/conversations/$id/leave',
      data: const <String, dynamic>{},
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  /// Offset-based endpoint exposed by SdkChatController.
  Future<MebablChatMessagePage> getMessages({
    required String conversationId,
    int offset = 0,
    int limit = 50,
    int? beforeSequence,
    int? afterSequence,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(conversationId, 'conversationId');
    if (beforeSequence != null && afterSequence != null) {
      throw ArgumentError('Use beforeSequence or afterSequence, not both.');
    }
    _validateOffsetLimit(offset, limit);

    if (beforeSequence != null) {
      return getMessagesPage(
        conversationId: id,
        beforeSequence: beforeSequence,
        limit: limit,
        cancelToken: cancelToken,
      );
    }
    if (afterSequence != null) {
      throw ArgumentError(
        'The current controller does not expose afterSequence. Use syncMessages for incremental updates.',
      );
    }

    final response = await core.http.get<Object>(
      '$basePath/conversations/$id/messages',
      queryParameters: {'offset': offset, 'limit': limit},
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return MebablChatMessagePage.fromJson(response.data);
  }

  /// Stable sequence-based page endpoint. The first page omits beforeSequence;
  /// older pages pass the sequence of the oldest locally loaded message.
  Future<MebablChatMessagePage> getMessagesPage({
    required String conversationId,
    int? beforeSequence,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(conversationId, 'conversationId');
    _validateLimit(limit);
    if (beforeSequence != null && beforeSequence <= 0) {
      throw ArgumentError.value(beforeSequence, 'beforeSequence');
    }
    final response = await core.http.get<Object>(
      '$basePath/conversations/$id/messages/page',
      queryParameters: {
        'limit': limit,
        if (beforeSequence != null) 'beforeSequence': beforeSequence,
      },
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return MebablChatMessagePage.fromJson(response.data);
  }

  Future<MebablChatMessageSyncPage> syncMessages({
    required String conversationId,
    int afterEventSequence = 0,
    int limit = 100,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(conversationId, 'conversationId');
    _validateLimit(limit);
    if (afterEventSequence < 0) {
      throw ArgumentError.value(afterEventSequence, 'afterEventSequence');
    }
    final response = await core.http.get<Object>(
      '$basePath/conversations/$id/messages/sync',
      queryParameters: {
        'afterEventSequence': afterEventSequence,
        'limit': limit,
      },
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return MebablChatMessageSyncPage.fromJson(response.data);
  }

  Future<MebablChatThread> getThread({
    required String messageId,
    int? beforeSequence,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(messageId, 'messageId');
    _validateLimit(limit);
    final response = await core.http.get<Object>(
      '$basePath/messages/$id/thread',
      queryParameters: {
        'limit': limit,
        if (beforeSequence != null) 'beforeSequence': beforeSequence,
      },
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return MebablChatThread.fromJson(response.data);
  }

  Future<MebablChatMessagePage> searchMessages({
    required String conversationId,
    required String query,
    String? senderId,
    String? messageType,
    int? beforeSequence,
    int limit = 30,
    CancelToken? cancelToken,
  }) async {
    final conversation = _requireGuid(conversationId, 'conversationId');
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 3 || normalizedQuery.length > 128) {
      throw ArgumentError.value(
        query,
        'query',
        'Search text must contain 3 to 128 characters.',
      );
    }
    _validateLimit(limit);
    final response = await core.http.get<Object>(
      '$basePath/conversations/$conversation/messages/search',
      queryParameters: {
        'query': normalizedQuery,
        'limit': limit,
        if (senderId != null) 'senderId': _requireGuid(senderId, 'senderId'),
        if (messageType != null && messageType.trim().isNotEmpty)
          'messageType': messageType.trim(),
        if (beforeSequence != null) 'beforeSequence': beforeSequence,
      },
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return MebablChatMessagePage.fromJson(response.data);
  }

  /// Sends text or a typed message. The backend accepts attachments through a
  /// separate endpoint, so attachment references are attached after the text
  /// message has been persisted.
  Future<MebablChatMessage> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    String? clientMessageId,
    String? replyToMessageId,
    String? threadRootMessageId,
    Iterable<MebablChatAttachmentInput> attachments = const [],
    CancelToken? cancelToken,
  }) async {
    final conversation = _requireGuid(conversationId, 'conversationId');
    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty || normalizedContent.length > maximumTextLength) {
      throw ArgumentError.value(
        content,
        'content',
        'Message text must contain 1 to $maximumTextLength characters.',
      );
    }
    if (threadRootMessageId != null) {
      throw ArgumentError(
        'The backend derives ThreadRootMessageId from ReplyToMessageId; do not send it separately.',
      );
    }

    final attachmentList = attachments.toList(growable: false);
    if (attachmentList.length > maximumAttachmentsPerMessage) {
      throw ArgumentError.value(attachments, 'attachments', 'Too many attachments.');
    }
    final messageKey = clientMessageId == null || clientMessageId.trim().isEmpty
        ? createClientMessageId()
        : _requireGuid(clientMessageId, 'clientMessageId');
    final normalizedType = type.trim().isEmpty ? 'text' : type.trim();

    final response = await core.http.post<Object>(
      '$basePath/conversations/$conversation/messages',
      data: {
        'content': normalizedContent,
        'messageType': normalizedType,
        'clientMessageId': messageKey,
        if (replyToMessageId != null)
          'replyToMessageId': _requireGuid(replyToMessageId, 'replyToMessageId'),
      },
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );

    var message = MebablChatMessage.fromJson(
      _unwrapObject(response.data, const ['message', 'data']),
    );

    for (final attachment in attachmentList) {
      _validateAttachmentInput(attachment);
      await attachFileToMessage(
        messageId: message.id,
        storedFileId: attachment.storedFileId,
        kind: attachment.kind,
        caption: attachment.caption,
        durationMilliseconds: attachment.durationMilliseconds,
        waveform: attachment.waveform,
        cancelToken: cancelToken,
      );
    }

    if (attachmentList.isNotEmpty) {
      final loaded = await getMessageAttachments(
        messageId: message.id,
        cancelToken: cancelToken,
      );
      message = message.copyWith(attachments: loaded);
    }
    return message;
  }

  Future<MebablChatMessage> sendPostShare({
    required String conversationId,
    required String postId,
    String? clientMessageId,
    String? replyToMessageId,
    CancelToken? cancelToken,
  }) {
    final payload = MebablChatPostSharePayload(
      postId: _requireGuid(postId, 'postId'),
    );
    return sendMessage(
      conversationId: conversationId,
      content: jsonEncode(payload.toJson()),
      type: MebablChatPostSharePayload.messageType,
      clientMessageId: clientMessageId,
      replyToMessageId: replyToMessageId,
      cancelToken: cancelToken,
    );
  }

  Future<MebablChatMessage> sendVoiceMessage({
    required String conversationId,
    required String storedFileId,
    required int durationMilliseconds,
    Iterable<double> waveform = const [],
    String? clientMessageId,
    String? caption,
    CancelToken? cancelToken,
  }) async {
    final conversation = _requireGuid(conversationId, 'conversationId');
    final fileId = _requireGuid(storedFileId, 'storedFileId');
    if (durationMilliseconds <= 0) {
      throw ArgumentError.value(durationMilliseconds, 'durationMilliseconds');
    }
    final points = waveform.toList(growable: false);
    if (points.length > 256 || points.any((v) => !v.isFinite || v < 0 || v > 1)) {
      throw ArgumentError.value(waveform, 'waveform', 'Invalid normalized waveform.');
    }
    final messageKey = clientMessageId == null || clientMessageId.trim().isEmpty
        ? createClientMessageId()
        : _requireGuid(clientMessageId, 'clientMessageId');
    final normalizedCaption = _normalizeOptionalText(caption, maximumLength: maximumTextLength);

    final response = await core.http.post<Object>(
      '$basePath/conversations/$conversation/voice-messages',
      data: {
        'storedFileId': fileId,
        'durationMilliseconds': durationMilliseconds,
        'caption': normalizedCaption,
        'waveformJson': points.isEmpty ? null : jsonEncode(points),
        'clientMessageId': messageKey,
      },
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return MebablChatMessage.fromJson(
      _unwrapObject(response.data, const ['message', 'data']),
    );
  }

  Future<MebablChatMessage> editMessage({
    required String messageId,
    required String content,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(messageId, 'messageId');
    final normalized = content.trim();
    if (normalized.isEmpty || normalized.length > maximumTextLength) {
      throw ArgumentError.value(content, 'content', 'Invalid message content.');
    }
    final response = await core.http.put<Object>(
      '$basePath/messages/$id',
      data: {'content': normalized},
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return MebablChatMessage.fromJson(
      _unwrapObject(response.data, const ['message', 'data']),
    );
  }

  Future<void> deleteMessage({
    required String messageId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(messageId, 'messageId');
    await core.http.delete<void>(
      '$basePath/messages/$id',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  Future<void> markDelivered({
    required String conversationId,
    required int throughSequence,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(conversationId, 'conversationId');
    if (throughSequence < 0) throw ArgumentError.value(throughSequence, 'throughSequence');
    await core.http.put<void>(
      '$basePath/conversations/$id/delivered',
      data: {'throughSequence': throughSequence},
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  Future<void> markMessageAsRead({
    required String messageId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(messageId, 'messageId');
    await core.http.put<void>(
      '$basePath/messages/$id/read',
      data: const <String, dynamic>{},
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  /// Lists read receipts for a message. The backend applies each user's
  /// read-receipt privacy setting before returning the result.
  Future<List<MebablChatMessageRead>> getMessageReads({
    required String messageId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(messageId, 'messageId');
    final response = await core.http.get<Object>(
      '$basePath/messages/$id/reads',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return readItems(response.data, 'message reads')
        .map(MebablChatMessageRead.fromJson)
        .toList(growable: false);
  }

  Future<void> markConversationAsRead({
    required String conversationId,
    required String throughMessageId,
    CancelToken? cancelToken,
  }) async {
    final conversation = _requireGuid(conversationId, 'conversationId');
    final message = _requireGuid(throughMessageId, 'throughMessageId');
    await core.http.put<void>(
      '$basePath/conversations/$conversation/read',
      data: {'throughMessageId': message},
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  /// Compatibility wrapper. The current backend requires a message GUID, not
  /// a numeric read sequence; pass [throughMessageId].
  @Deprecated('Use markConversationAsRead with throughMessageId.')
  Future<void> markRead({
    required String conversationId,
    String? throughMessageId,
    int? lastReadSequence,
    CancelToken? cancelToken,
  }) async {
    if (throughMessageId == null) {
      throw ArgumentError(
        'The current API requires throughMessageId. Numeric lastReadSequence is not accepted.',
      );
    }
    await markConversationAsRead(
      conversationId: conversationId,
      throughMessageId: throughMessageId,
      cancelToken: cancelToken,
    );
  }

  Future<void> addReaction({
    required String messageId,
    required String reaction,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(messageId, 'messageId');
    final normalized = reaction.trim();
    if (normalized.isEmpty || normalized.length > 50) {
      throw ArgumentError.value(reaction, 'reaction', 'Invalid reaction value.');
    }
    await core.http.post<void>(
      '$basePath/messages/$id/reactions',
      data: {'reaction': normalized},
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  Future<void> removeReaction({
    required String messageId,
    String? reaction,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(messageId, 'messageId');
    final normalized = reaction?.trim();
    await core.http.delete<void>(
      '$basePath/messages/$id/reactions',
      queryParameters: {
        if (normalized != null && normalized.isNotEmpty) 'reaction': normalized,
      },
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  Future<List<MebablChatReaction>> getMessageReactions({
    required String messageId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(messageId, 'messageId');
    final response = await core.http.get<Object>(
      '$basePath/messages/$id/reactions',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return readItems(response.data, 'message reactions')
        .map(MebablChatReaction.fromJson)
        .toList(growable: false);
  }

  Future<void> pinMessage({
    required String conversationId,
    required String messageId,
    DateTime? expiresAtUtc,
    CancelToken? cancelToken,
  }) async {
    final conversation = _requireGuid(conversationId, 'conversationId');
    final message = _requireGuid(messageId, 'messageId');
    final expiry = expiresAtUtc?.toUtc();
    if (expiry != null && !expiry.isAfter(DateTime.now().toUtc())) {
      throw ArgumentError.value(expiresAtUtc, 'expiresAtUtc', 'Expiry must be in the future.');
    }
    await core.http.post<void>(
      '$basePath/conversations/$conversation/messages/$message/pin',
      data: {if (expiry != null) 'expiresAtUtc': expiry.toIso8601String()},
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  Future<void> unpinMessage({
    required String conversationId,
    required String messageId,
    CancelToken? cancelToken,
  }) async {
    final conversation = _requireGuid(conversationId, 'conversationId');
    final message = _requireGuid(messageId, 'messageId');
    await core.http.delete<void>(
      '$basePath/conversations/$conversation/messages/$message/pin',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  Future<List<MebablChatPinnedMessage>> getPinnedMessages({
    required String conversationId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(conversationId, 'conversationId');
    final response = await core.http.get<Object>(
      '$basePath/conversations/$id/pinned-messages',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return readItems(response.data, 'pinned messages')
        .map(MebablChatPinnedMessage.fromJson)
        .toList(growable: false);
  }

  Future<List<MebablChatMessage>> forwardMessage({
    required String messageId,
    required Iterable<String> targetConversationIds,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(messageId, 'messageId');
    final targets = targetConversationIds
        .map((value) => _requireGuid(value, 'targetConversationIds'))
        .toSet()
        .toList(growable: false);
    if (targets.isEmpty) throw ArgumentError('At least one target conversation is required.');

    final forwarded = <MebablChatMessage>[];
    for (final target in targets) {
      final response = await core.http.post<Object>(
        '$basePath/messages/$id/forward',
        data: {
          'targetConversationId': target,
          'clientMessageId': createClientMessageId(),
        },
        authMode: MebablAuthMode.user,
        cancelToken: cancelToken,
      );
      forwarded.add(
        MebablChatMessage.fromJson(
          _unwrapObject(response.data, const ['message', 'data']),
        ),
      );
    }
    return forwarded;
  }

  Future<void> updateConversationPreferences({
    required String conversationId,
    bool? isArchived,
    DateTime? mutedUntilUtc,
    bool clearMute = false,
    bool? isPinned,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(conversationId, 'conversationId');
    if (clearMute && mutedUntilUtc != null) {
      throw ArgumentError('Do not set mutedUntilUtc while clearMute is true.');
    }

    // The backend replaces all three preference values in one PUT. Resolve
    // unspecified values first so changing one option never clears the others.
    MebablChatConversation? current;
    if (isArchived == null || isPinned == null ||
        (!clearMute && mutedUntilUtc == null)) {
      current = await _loadConversationPreferenceSnapshot(
        id,
        cancelToken: cancelToken,
      );
    }

    final resolvedArchived = isArchived ?? current!.isArchived;
    final resolvedPinned = isPinned ?? current!.isPinned;
    final resolvedMute = clearMute
        ? null
        : (mutedUntilUtc ?? current?.mutedUntilUtc);

    await core.http.put<void>(
      '$basePath/conversations/$id/preferences',
      data: {
        'isArchived': resolvedArchived,
        'isPinnedInInbox': resolvedPinned,
        'mutedUntilUtc': resolvedMute?.toUtc().toIso8601String(),
      },
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  Future<MebablChatConversation> _loadConversationPreferenceSnapshot(
    String conversationId, {
    CancelToken? cancelToken,
  }) async {
    const pageSize = maximumPageSize;
    for (var offset = 0; offset < pageSize * 100; offset += pageSize) {
      final page = await getConversations(
        offset: offset,
        limit: pageSize,
        includeArchived: true,
        cancelToken: cancelToken,
      );
      for (final conversation in page.items) {
        if (conversation.id.toLowerCase() == conversationId.toLowerCase()) {
          return conversation;
        }
      }
      if (page.items.length < pageSize) break;
    }
    throw StateError(
      'The conversation was not found in the current user inbox; preferences were not changed.',
    );
  }

  Future<void> attachFileToMessage({
    required String messageId,
    required String storedFileId,
    String kind = 'file',
    String? caption,
    int? durationMilliseconds,
    Iterable<double> waveform = const [],
    CancelToken? cancelToken,
  }) async {
    final message = _requireGuid(messageId, 'messageId');
    final file = _requireGuid(storedFileId, 'storedFileId');
    final normalizedKind = kind.trim();
    if (normalizedKind.isEmpty || normalizedKind.length > 20) {
      throw ArgumentError.value(kind, 'kind', 'Invalid attachment kind.');
    }
    if (durationMilliseconds != null && durationMilliseconds <= 0) {
      throw ArgumentError.value(durationMilliseconds, 'durationMilliseconds');
    }
    final points = waveform.toList(growable: false);
    if (points.length > 256 || points.any((v) => !v.isFinite || v < 0 || v > 1)) {
      throw ArgumentError.value(waveform, 'waveform');
    }
    await core.http.post<void>(
      '$basePath/messages/$message/attachments',
      data: {
        'storedFileId': file,
        'kind': normalizedKind,
        'caption': _normalizeOptionalText(caption, maximumLength: 500),
        'durationMilliseconds': durationMilliseconds,
        'waveformJson': points.isEmpty ? null : jsonEncode(points),
      },
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  Future<List<MebablChatAttachment>> getMessageAttachments({
    required String messageId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(messageId, 'messageId');
    final response = await core.http.get<Object>(
      '$basePath/messages/$id/attachments',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return readItems(response.data, 'message attachments')
        .map(MebablChatAttachment.fromJson)
        .toList(growable: false);
  }

  Future<void> deleteMessageAttachment({
    required String attachmentId,
    CancelToken? cancelToken,
  }) async {
    final id = _requireGuid(attachmentId, 'attachmentId');
    await core.http.delete<void>(
      '$basePath/attachments/$id',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  Future<void> blockUser({required String userId, CancelToken? cancelToken}) async {
    final id = _requireGuid(userId, 'userId');
    await core.http.post<void>(
      '$basePath/users/$id/block',
      data: const <String, dynamic>{},
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  Future<void> unblockUser({required String userId, CancelToken? cancelToken}) async {
    final id = _requireGuid(userId, 'userId');
    await core.http.delete<void>(
      '$basePath/users/$id/block',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  Future<List<Map<String, dynamic>>> getBlockedUsers({CancelToken? cancelToken}) async {
    final response = await core.http.get<Object>(
      '$basePath/blocked-users',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return readItems(response.data, 'blocked users');
  }

  Future<Map<String, dynamic>> getPrivacy({CancelToken? cancelToken}) async {
    final response = await core.http.get<Object>(
      '$basePath/privacy',
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
    return asJsonMap(response.data, 'chat privacy');
  }

  Future<void> updatePrivacy({
    required bool allowDirectMessages,
    required bool shareReadReceipts,
    required bool shareTypingStatus,
    required bool shareOnlineStatus,
    bool? shareLastSeenStatus,
    CancelToken? cancelToken,
  }) async {
    await core.http.put<void>(
      '$basePath/privacy',
      data: {
        'allowDirectMessages': allowDirectMessages,
        'shareReadReceipts': shareReadReceipts,
        'shareTypingStatus': shareTypingStatus,
        'shareOnlineStatus': shareOnlineStatus,
        if (shareLastSeenStatus != null) 'shareLastSeenStatus': shareLastSeenStatus,
      },
      authMode: MebablAuthMode.user,
      cancelToken: cancelToken,
    );
  }

  static String createClientMessageId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  void _validateAttachmentInput(MebablChatAttachmentInput attachment) {
    final kind = attachment.kind.trim();
    if (kind.isEmpty || kind.length > 20) {
      throw ArgumentError.value(attachment.kind, 'kind', 'Invalid attachment kind.');
    }
    if (attachment.durationMilliseconds != null && attachment.durationMilliseconds! <= 0) {
      throw ArgumentError.value(attachment.durationMilliseconds, 'durationMilliseconds');
    }
    if (attachment.waveform.length > 256 ||
        attachment.waveform.any((sample) => !sample.isFinite || sample < 0 || sample > 1)) {
      throw ArgumentError.value(attachment.waveform, 'waveform');
    }
  }

  void _validateOffsetLimit(int offset, int limit) {
    if (offset < 0 || limit < 1 || limit > maximumPageSize) {
      throw ArgumentError('offset must be >= 0 and limit must be 1..$maximumPageSize.');
    }
  }

  void _validateLimit(int limit) {
    if (limit < 1 || limit > maximumPageSize) {
      throw ArgumentError.value(limit, 'limit', 'Limit must be between 1 and $maximumPageSize.');
    }
  }

  String _requireGuid(String value, String name) {
    final normalized = value.trim();
    if (!_guidPattern.hasMatch(normalized) ||
        normalized.toLowerCase() == '00000000-0000-0000-0000-000000000000') {
      throw ArgumentError.value(value, name, 'A valid GUID identifier is required.');
    }
    return normalized;
  }

  String? _normalizeOptionalText(String? value, {required int maximumLength}) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim();
    if (normalized.length > maximumLength) {
      throw ArgumentError.value(value, 'text', 'Text exceeds $maximumLength characters.');
    }
    return normalized;
  }

  Map<String, dynamic> _unwrapObject(Object? value, List<String> keys) {
    var current = asJsonMap(value, 'response');
    for (final key in keys) {
      final nested = current[key];
      if (nested is Map) {
        current = Map<String, dynamic>.from(nested);
        break;
      }
    }
    return current;
  }
}
