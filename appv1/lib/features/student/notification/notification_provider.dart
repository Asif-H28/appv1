import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  void setCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }

  void clearCount() {
    _unreadCount = 0;
    notifyListeners();
  }

  void increment() {
    _unreadCount++;
    notifyListeners();
  }
}
