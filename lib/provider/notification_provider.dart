import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:private_gitlab_notifier_dashboard/model/mixed_changes.dart';
import 'package:private_gitlab_notifier_dashboard/model/response_type.dart';
import 'package:web/web.dart';
import 'package:flutter/foundation.dart';
import 'package:private_gitlab_notifier_dashboard/model/merge_request.dart';
import 'dart:js_interop';
import 'package:private_gitlab_notifier_dashboard/model/mr_comment.dart';
import 'package:private_gitlab_notifier_dashboard/model/multi_comment.dart';
import 'package:private_gitlab_notifier_dashboard/model/multi_mr.dart';
import 'package:private_gitlab_notifier_dashboard/model/server_response.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef NotificationHistory = ({
  MRResponseType type,
  String title,
  String body,
});

class NotificationProvider extends ChangeNotifier {
  final int localPort;

  NotificationProvider({required this.localPort});

  WebSocketChannel? _wsChannel;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  List<NotificationHistory> historyList = [];

  Future<bool> listenBroadcast() async {
    if (_isConnected) return true;

    final wsUrl = Uri.parse('ws://localhost:$localPort');
    final initChannel = WebSocketChannel.connect(wsUrl);
    try {
      await initChannel.ready;
    } on SocketException catch (e) {
      log('Failed to connect to $wsUrl');
      log(e.toString());
      return false;
    } on WebSocketChannelException catch (e) {
      log('Failed to connect to $wsUrl');
      log(e.inner.toString());
      return false;
    }
    await initChannel.ready;

    initChannel.sink.add('established!#$hashCode');
    initChannel.stream.listen(_onMessage);
    _wsChannel = initChannel;
    _isConnected = true;

    notifyListeners();
    return true;
  }

  void _onMessage(dynamic message) {
    if (message is! String) return;

    final rawJson = jsonDecode(message);
    final responseType = MRResponseType.fromRawJson(rawJson);

    switch (responseType) {
      case MRResponseType.nothingToNotify:
        // Nothing to notify
        break;
      case MRResponseType.mergeRequest:
        _handleMergeRequest(jsonDecode(message));
        break;
      case MRResponseType.multipleMergeRequests:
        _handleMultiMRs(jsonDecode(message));
        break;
      case MRResponseType.comment:
        _handleComment(jsonDecode(message));
        break;
      case MRResponseType.multipleComments:
        _handleMultiComments(jsonDecode(message));
        break;
      case MRResponseType.mixed:
        _handleMixed(jsonDecode(message));
        break;
    }
  }

  void _addHistory(
    MRResponseType type,
    String title, {
    String body = '',
  }) {
    historyList = List.from(historyList)
      ..add((
        type: type,
        title: title,
        body: body,
      ));

    notifyListeners();
  }

  static void testNotification() {
    _showNotification(
      title: 'Test Notification',
      body: 'This is a test notification',
    );
  }

  static void _notificaionHandler(Event event) {
    event.preventDefault();
    final notification = event.target;
    if (!notification.isA<Notification>()) return;
    notification as Notification;

    final url = notification.data;
    if (url == null) return;
    window.open(url as String, '_blank');
  }

  static void _showNotification({
    required String title,
    required String body,
    String? openUrl,
  }) async {
    final permission = await Notification.requestPermission().toDart;

    if (permission.toDart != 'granted') return;

    final a = Notification(
      'Gitlab Notify - $title',
      NotificationOptions(
        body: body,
        data: openUrl?.toJS,
      ),
    );

    a.onclick = _notificaionHandler.toJS;
  }

  void _handleMergeRequest(Map<String, dynamic> rawJson) {
    final response = ServerResponse<MergeRequest>.fromJson(
      rawJson,
      (inner) => MergeRequest.fromJson(inner as Map<String, dynamic>),
    );
    final mr = response.data;
    _showNotification(
      title: "New MR: ${mr.title}",
      body: 'by ${mr.author.username}',
      openUrl: mr.webUrl,
    );

    _addHistory(
      MRResponseType.mergeRequest,
      "New MR: ${mr.title}",
      body: 'by ${mr.author.username}',
    );
  }

  void _handleMultiMRs(Map<String, dynamic> rawJson) {
    final response = ServerResponse<MultiMR>.fromJson(
      rawJson,
      (inner) => MultiMR.fromJson(inner as Map<String, dynamic>),
    );
    final multiMR = response.data;
    _showNotification(
      title: "New MRs: ${multiMR.iids}",
      body: '',
      openUrl: multiMR.url,
    );

    _addHistory(
      MRResponseType.multipleMergeRequests,
      "New MRs: ${multiMR.iids}",
    );
  }

  void _handleComment(Map<String, dynamic> rawJson) {
    final response = ServerResponse<MRComment>.fromJson(
      rawJson,
      (inner) => MRComment.fromJson(inner as Map<String, dynamic>),
    );
    final comment = response.data;

    _showNotification(
      title: "New comment : ${comment.title}",
      body: "${comment.note.author.username} ${comment.note.body}",
      openUrl: '${comment.webUrl}#note_${comment.note.id}',
    );

    _addHistory(
      MRResponseType.comment,
      "New comment : ${comment.title}",
      body: "(${comment.note.author.username}): ${comment.note.body}",
    );
  }

  void _handleMultiComments(Map<String, dynamic> rawJson) {
    final response = ServerResponse<MultiComment>.fromJson(
      rawJson,
      (inner) => MultiComment.fromJson(inner as Map<String, dynamic>),
    );
    final comments = response.data;
    _showNotification(
      title: "New comments!",
      body: "",
      openUrl: comments.url,
    );

    _addHistory(
      MRResponseType.multipleComments,
      "New comments!",
    );
  }

  void _handleMixed(Map<String, dynamic> rawJson) {
    final response = ServerResponse<MixedChanges>.fromJson(
      rawJson,
      (inner) => MixedChanges.fromJson(inner as Map<String, dynamic>),
    );
    final mixed = response.data;
    _showNotification(
      title: "Mixed!",
      body: "",
      openUrl: mixed.url,
    );

    _addHistory(
      MRResponseType.mixed,
      "Mixed!",
    );
  }

  void closeWS() async {
    if (_wsChannel == null || !_isConnected) return;
    await _wsChannel!.ready;
    _wsChannel!.sink.add('disconnected!#$hashCode');
    await _wsChannel!.sink.close();
    _isConnected = false;
    notifyListeners();
  }
}
