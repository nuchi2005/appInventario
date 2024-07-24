import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'database_helper.dart';
import 'edit_screen.dart';
import 'equipments_provider.dart';
import 'listaEquipo.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> equipment;
  final int id;

  DetailScreen({required this.equipment, required this.id});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Map<String, dynamic> _equipment;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _equipment = widget.equipment;
  }

  void _refreshEquipment() async {
    final data = await _dbHelper.getEquipmentList();
    setState(() {
      _equipment = data.firstWhere((item) => item['id'] == widget.id);
    });
  }

  Future<void> _confirmDelete() async {
    final equipmentsProvider = context.read<EquipmentsProvider>();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Estás seguro de que deseas eliminar este equipo?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Eliminar'),
              onPressed: () async {
                await _dbHelper.deleteEquipment(widget.id);
                await equipmentsProvider.fetchEquipments();

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ListScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedCreationDate = 'No especificada';
    if (_equipment['creationDate'] != null &&
        _equipment['creationDate'].isNotEmpty) {
      try {
        DateTime creationDate =
            DateFormat('yyyy-MM-dd').parse(_equipment['creationDate']);
        formattedCreationDate = DateFormat('dd/MM/yyyy').format(creationDate);
      } catch (e) {
        formattedCreationDate = 'Formato inválido';
      }
    }

    String formattedDeliveryDate = 'No especificada';
    if (_equipment['deliveryDate'] != null &&
        _equipment['deliveryDate'].isNotEmpty) {
      try {
        DateTime deliveryDate =
            DateFormat('yyyy-MM-dd').parse(_equipment['deliveryDate']);
        formattedDeliveryDate = DateFormat('dd/MM/yyyy').format(deliveryDate);
      } catch (e) {
        formattedDeliveryDate = 'Formato inválido';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del Equipo'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditScreen(equipment: _equipment, id: widget.id),
                ),
              );
              if (result == true) {
                _refreshEquipment();
                Navigator.pop(
                    context, true); // Return true to indicate data changed
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildDetailCard('Numero de Orden', _equipment['orderNumber']),
            _buildDetailCard('Tipo', _equipment['type']),
            _buildDetailCard('Falla Inicial', _equipment['initialFault']),
            _buildDetailCard(
                'Observacion tecnica', _equipment['technicalObservation']),
            _buildDetailCard(
                'Visto', _equipment['seen'] == 'true' ? 'Sí' : 'No'),
            _buildDetailCard('Estado', _equipment['status']),
            _buildDetailCard('Fecha de Creación', formattedCreationDate),
            _buildDetailCard('Fecha de Entrega', formattedDeliveryDate),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text(
                value,
                style: TextStyle(fontSize: 16.0, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
