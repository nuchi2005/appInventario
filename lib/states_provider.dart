import 'package:flutter/material.dart';
import 'database_helper.dart';

class StatesProvider with ChangeNotifier {
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _statesAll = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Map<String, dynamic>> get states => _states;
  List<Map<String, dynamic>> get statesAll => _statesAll;

  StatesProvider() {
    fetchStates();
    fetchStatesAll();
  }

  Future<void> fetchStates() async {
    final data = await _dbHelper.getStates();
    _states = data;
    notifyListeners();
  }

  Future<void> fetchStatesAll() async {
    final data = await _dbHelper.getStatesAll();
    _statesAll = data;
    notifyListeners();
  }

  Future<void> addState(String name) async {
    await _dbHelper.insertState(name);
    await fetchStates();
    await fetchStatesAll();
  }

  Future<void> deleteState(int id) async {
    await _dbHelper.deleteState(id);
    await fetchStates();
    await fetchStatesAll();
  }

  Future<void> updateStatePosition(int id, int position) async {
    await _dbHelper.updateStatePosition(id, position);
    await fetchStates();
    await fetchStatesAll();
  }

  Future<void> updateStatePositions() async {
    for (int i = 0; i < _states.length; i++) {
      await _dbHelper.updateStatePosition(_states[i]['id'], i);
    }
    await fetchStates();
    await fetchStatesAll();
  }

  void updateStatesOrder(List<Map<String, dynamic>> newStates) {
    _states = newStates;
    notifyListeners();
  }

  Future<void> updateStateColor(int id, Color color) async {
    String colorString = color.value.toRadixString(16).padLeft(8, '0');
    await _dbHelper.updateStateColor(id, '#$colorString');
    await fetchStates();
    await fetchStatesAll();
  }
}
