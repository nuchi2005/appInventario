import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'database_helper.dart';
import 'equipments_provider.dart'; // Importa el provider de equipos
import 'listaEquipo.dart';
import 'states_provider.dart'; // Importa el provider de estados
import 'types_provider.dart'; // Importa el provider de tipos

class EditScreen extends StatefulWidget {
  final Map<String, dynamic> equipment;
  final int id;

  EditScreen({required this.equipment, required this.id});

  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late TextEditingController _orderNumberController;
  late TextEditingController _initialFaultController;
  late TextEditingController _technicalObservationController;
  late String _selectedType;
  late String _seen;
  late String _selectedStatus;
  DateTime? _selectedDate;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _orderNumberController =
        TextEditingController(text: widget.equipment['orderNumber']);
    _initialFaultController =
        TextEditingController(text: widget.equipment['initialFault']);
    _technicalObservationController =
        TextEditingController(text: widget.equipment['technicalObservation']);
    _selectedType = widget.equipment['type'];
    _seen = widget.equipment['seen'] == 'true' ? 'Sí' : 'No';
    _selectedStatus = widget.equipment['status'];
    _selectedDate = widget.equipment['deliveryDate'] != null &&
            widget.equipment['deliveryDate'].isNotEmpty
        ? DateFormat('yyyy-MM-dd').parse(widget.equipment['deliveryDate'])
        : null;
  }

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

  Future<void> _saveEdits() async {
    final updatedEquipment = {
      'orderNumber': _orderNumberController.text,
      'type': _selectedType,
      'initialFault': _initialFaultController.text,
      'technicalObservation': _technicalObservationController.text,
      'seen': _seen == 'Sí' ? 'true' : 'false',
      'status': _selectedStatus,
      'deliveryDate': _selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
          : '',
    };

    await _dbHelper.updateEquipment(widget.id, updatedEquipment);
    final equipmentsProvider =
        Provider.of<EquipmentsProvider>(context, listen: false);
    await equipmentsProvider.fetchEquipments();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ListScreen(), // Asegúrate de importar ListScreen
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Equipo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _orderNumberController,
              decoration: const InputDecoration(
                labelText: 'Numero de Orden',
                border: OutlineInputBorder(),
              ),
              enabled: false, // Deshabilitar el campo de número de orden
            ),
            SizedBox(height: 16.0),
            Consumer<TypesProvider>(
              builder: (context, typesProvider, child) {
                // Verificar si el tipo seleccionado está inactivo
                final bool isInactive = !typesProvider.alltypes.any((type) =>
                    type['name'] == _selectedType && type['isActive'] == 1);

                // Crear lista de DropdownMenuItems
                List<DropdownMenuItem<String>> dropdownItems = [
                  if (isInactive)
                    DropdownMenuItem<String>(
                      value: _selectedType,
                      child: Text(
                        _selectedType + ' (Inactivo)',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ...typesProvider.alltypes
                      .where((type) => type['isActive'] == 1)
                      .map<DropdownMenuItem<String>>((type) {
                    return DropdownMenuItem<String>(
                      value: type['name'],
                      child: Text(type['name']),
                    );
                  }).toList(),
                ];

                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
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
                    items: dropdownItems,
                    underline: SizedBox(),
                  ),
                );
              },
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
            Consumer<StatesProvider>(
              builder: (context, statesProvider, child) {
                // Verificar si el tipo seleccionado está inactivo
                final bool isInactive = !statesProvider.statesAll.any((type) =>
                    type['name'] == _selectedStatus && type['isActive'] == 1);

                // Crear lista de DropdownMenuItems
                List<DropdownMenuItem<String>> dropdownItems = [
                  if (isInactive)
                    DropdownMenuItem<String>(
                      value: _selectedStatus,
                      child: Text(
                        _selectedStatus + ' (Inactivo)',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ...statesProvider.statesAll
                      .where((type) => type['isActive'] == 1)
                      .map<DropdownMenuItem<String>>((type) {
                    return DropdownMenuItem<String>(
                      value: type['name'],
                      child: Text(type['name']),
                    );
                  }).toList(),
                ];
                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
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
                    items: dropdownItems,
                    underline: SizedBox(),
                  ),
                );
              },
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
              onPressed: _saveEdits,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
