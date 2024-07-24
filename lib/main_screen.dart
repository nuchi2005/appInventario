import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:provider/provider.dart';
import 'database_helper.dart';
import 'listaEquipo.dart';
import 'states_provider.dart';
import 'types_provider.dart';
import 'equipments_provider.dart';

class MainScreen extends StatefulWidget {
  @override
  createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _orderNumberController = TextEditingController();
  final _initialFaultController = TextEditingController();
  final _technicalObservationController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _selectedType = 'TV Led';
  String _seen = 'No';
  String _selectedStatus = 'Ingreso nuevo';
  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('es', 'ES'), // Añadir soporte para español
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _scanBarcode() async {
    var result = await BarcodeScanner.scan();
    setState(() {
      _orderNumberController.text = result.rawContent;
    });
  }

  Future<void> _saveEquipment() async {
    final equipmentsProvider = context.read<EquipmentsProvider>();

    if (await _dbHelper.orderNumberExists(_orderNumberController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El número de orden ya existe')),
      );
      return;
    }

    final creationDate = DateTime.now(); // Guardar la fecha de creación
    await _dbHelper.insertEquipment({
      'orderNumber': _orderNumberController.text,
      'type': _selectedType,
      'initialFault': _initialFaultController.text,
      'technicalObservation': _technicalObservationController.text,
      'seen': _seen == 'Sí' ? 'true' : 'false',
      'status': _selectedStatus,
      'creationDate': DateFormat('yyyy-MM-dd').format(creationDate),
      'deliveryDate': _selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
          : '',
    });
    _resetFields(); // Restablecer todos los campos a su estado inicial
    // Actualizar la lista de equipos
    await equipmentsProvider.fetchEquipments();

    // Navegar a la lista de equipos
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ListScreen()),
    );
  }

  void _resetFields() {
    setState(() {
      _orderNumberController.clear();
      _initialFaultController.clear();
      _technicalObservationController.clear();
      final typesProvider = context.read<TypesProvider>();
      if (typesProvider.types.isNotEmpty) {
        _selectedType = typesProvider.types[0]['name'];
      } else {
        _selectedType = 'TV Led';
      }
      _seen = 'No';
      _selectedStatus = 'Ingreso nuevo';
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario SHELA'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _orderNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Numero de Orden',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: _scanBarcode,
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedType,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                  });
                },
                items: context
                    .watch<TypesProvider>()
                    .types
                    .map<DropdownMenuItem<String>>((type) {
                  return DropdownMenuItem<String>(
                    value: type['name'],
                    child: Text(type['name']),
                  );
                }).toList(),
                underline: SizedBox(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _initialFaultController,
              decoration: const InputDecoration(
                labelText: 'Falla Inicial',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _technicalObservationController,
              decoration: const InputDecoration(
                labelText: 'Observacion tecnica',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Visto',
                style: TextStyle(fontSize: 16.0, color: Colors.black54),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _seen,
                onChanged: (String? newValue) {
                  setState(() {
                    _seen = newValue!;
                  });
                },
                items: <String>['Sí', 'No']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                underline: SizedBox(),
              ),
            ),
            SizedBox(height: 16.0),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Estado',
                style: TextStyle(fontSize: 16.0, color: Colors.black54),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedStatus,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedStatus = newValue!;
                  });
                },
                items: context
                    .watch<StatesProvider>()
                    .states
                    .map<DropdownMenuItem<String>>((type) {
                  return DropdownMenuItem<String>(
                    value: type['name'],
                    child: Text(type['name']),
                  );
                }).toList(),
                underline: SizedBox(),
              ),
            ),
            SizedBox(height: 16.0),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Fecha de Entrega',
                    hintText: _selectedDate == null
                        ? 'No seleccionada'
                        : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ),
            if (_selectedDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Fecha seleccionada: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                  style: TextStyle(fontSize: 16.0, color: Colors.black54),
                ),
              ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _saveEquipment,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
