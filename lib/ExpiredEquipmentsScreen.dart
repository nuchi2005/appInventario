import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'equipments_provider.dart';
import 'detail_screen.dart';
import 'package:intl/intl.dart';

class ExpiredEquipmentsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final equipmentsProvider = Provider.of<EquipmentsProvider>(context);
    final expiredEquipments = equipmentsProvider.getExpiredEquipments(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Equipos Vencidos'),
      ),
      body: expiredEquipments.isEmpty
          ? Center(
              child: Text(
                'No hay equipos vencidos',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: expiredEquipments.length,
              itemBuilder: (context, index) {
                final equipment = expiredEquipments[index];
                final creationDate = DateTime.parse(equipment['creationDate']);
                final now = DateTime.now();
                final difference = now.difference(creationDate).inDays;

                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(equipment['orderNumber']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tipo: ${equipment['type']}'),
                        Text(
                            'Fecha de creación: ${DateFormat('dd/MM/yyyy').format(creationDate)}'),
                        Text('Vencido por: $difference días'),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(
                            equipment: equipment,
                            id: equipment['id'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
