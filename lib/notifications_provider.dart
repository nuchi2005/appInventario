import 'package:flutter/material.dart';
import 'database_helper.dart';

class NotificationsProvider with ChangeNotifier {
  int _notificationDays = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  int get notificationDays => _notificationDays;

  NotificationsProvider() {
    _loadNotificationDays();
  }

  Future<void> _loadNotificationDays() async {
    // Carga el número de días de notificación desde la base de datos o preferencias
    // Aquí deberías implementar la lógica para cargar este valor
    _notificationDays = await _dbHelper.getNotificationDays();
    notifyListeners();
  }

  Future<void> setNotificationDays(int days) async {
    _notificationDays = days;
    await _dbHelper.setNotificationDays(days);
    notifyListeners();
  }
}
