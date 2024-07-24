import 'package:flutter/material.dart';
import 'database_helper.dart';

class TypesProvider with ChangeNotifier {
  List<Map<String, dynamic>> _types = [];
  List<Map<String, dynamic>> _alltypes = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Map<String, dynamic>> get types => _types;
  List<Map<String, dynamic>> get alltypes => _alltypes;

  TypesProvider() {
    fetchTypes();
    fetchTypesall();
  }

  Future<void> fetchTypes() async {
    final data = await _dbHelper.getTypes();
    _types = data;
    notifyListeners();
  }

  Future<void> fetchTypesall() async {
    final data = await _dbHelper.getTypesall();
    _alltypes = data;
    notifyListeners();
  }

  Future<void> addType(String name) async {
    await _dbHelper.insertType(name);
    await fetchTypes();
    await fetchTypesall();
  }

  Future<void> deleteType(int id) async {
    await _dbHelper.deleteType(id);
    await fetchTypes();
    await fetchTypesall();
  }

  Future<void> updateTypePosition(int id, int position) async {
    await _dbHelper.updateTypePosition(id, position);
    await fetchTypes();
    await fetchTypesall();
  }

  Future<void> updateTypePositions() async {
    for (int i = 0; i < _types.length; i++) {
      await _dbHelper.updateTypePosition(_types[i]['id'], i);
    }
    await fetchTypes();
    await fetchTypesall();
  }

  void updateTypesOrder(List<Map<String, dynamic>> newTypes) {
    _types = newTypes;
    notifyListeners();
  }
}
