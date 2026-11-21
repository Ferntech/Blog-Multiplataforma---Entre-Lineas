import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class SessionManager extends ChangeNotifier {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  UserModel? _currentUser;
  int _cartCount = 0;
  int _unreadMessagesCount = 0;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  int get userId => _currentUser?.id ?? 0;
  int get cartCount => _cartCount;
  int get unreadMessagesCount => _unreadMessagesCount;

  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void updateBadges({int? cartCount, int? unreadMessages}) {
    if (cartCount != null) _cartCount = cartCount;
    if (unreadMessages != null) _unreadMessagesCount = unreadMessages;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _cartCount = 0;
    _unreadMessagesCount = 0;
    notifyListeners();
  }
}
