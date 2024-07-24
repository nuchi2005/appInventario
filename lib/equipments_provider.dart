import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database_helper.dart';
import 'notifications_provider.dart';

class EquipmentsProvider with ChangeNotifier {
  List<Map<String, dynamic>> _equipments = [];
  bool _isLoading = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Map<String, dynamic>> get equipments => _equipments;
  bool get isLoading => _isLoading;

  EquipmentsProvider() {
    fetchEquipments();
  }

  Future<void> fetchEquipments() async {
    _isLoading = true;
    notifyListeners();

    final dbHelper = DatabaseHelper();
    _equipments = await dbHelper.getEquipmentList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEquipment(Map<String, dynamic> equipment) async {
    await _dbHelper.insertEquipment(equipment);
    await fetchEquipments();
  }

  Future<void> deleteEquipment(int id) async {
    await _dbHelper.deleteEquipment(id);
    await fetchEquipments();
  }

  Future<void> updateEquipment(int id, Map<String, dynamic> equipment) async {
    await _dbHelper.updateEquipment(id, equipment);
    await fetchEquipments();
  }

  Future<bool> orderNumberExists(String orderNumber) async {
    return await _dbHelper.orderNumberExists(orderNumber);
  }

  List<Map<String, dynamic>> getExpiredEquipments(BuildContext context) {
    final now = DateTime.now();
    final notificationsProvider =
        Provider.of<NotificationsProvider>(context, listen: false);
    return _equipments.where((equipment) {
      final creationDate = DateTime.parse(equipment['creationDate']);
      final difference = now.difference(creationDate).inDays;
      final hasNoDeliveryDate = equipment['deliveryDate'] == null ||
          equipment['deliveryDate'].isEmpty;
      return hasNoDeliveryDate &&
          difference >= notificationsProvider.notificationDays;
    }).toList();
  }
}
