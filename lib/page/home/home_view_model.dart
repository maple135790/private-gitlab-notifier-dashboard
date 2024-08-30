import 'dart:js_interop';
import 'package:web/web.dart';

import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  bool _canSentNotification = false;
  bool get canSentNotificatiod => _canSentNotification;

  void requestNotificationPermission() async {
    final permission = await Notification.requestPermission().toDart;
    _canSentNotification = permission.toDart == 'granted';
    notifyListeners();
  }

  void revokeNotificationPermission() {
    _canSentNotification = false;
    notifyListeners();
  }
}
