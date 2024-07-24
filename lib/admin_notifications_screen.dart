import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notifications_provider.dart';

class AdminNotificationsScreen extends StatelessWidget {
  final _daysController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final notificationsProvider = Provider.of<NotificationsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Administrar Notificaciones'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _daysController,
              decoration: InputDecoration(
                labelText: 'Días para notificación',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Cerrar el teclado virtual
                FocusScope.of(context).unfocus();

                // Obtener el valor ingresado
                int days = int.parse(_daysController.text);

                // Establecer los días de notificación
                notificationsProvider.setNotificationDays(days);

                // Mostrar mensaje de guardado exitoso
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Guardado exitoso: $days días para notificación'),
                    duration: Duration(seconds: 2),
                  ),
                );

                // Actualizar el estado para mostrar los días guardados
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Días para notificación configurados: $days'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Guardar'),
            ),
            SizedBox(height: 16.0),
            Consumer<NotificationsProvider>(
              builder: (context, provider, child) {
                return Text(
                  'Días actuales para notificación: ${provider.notificationDays}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
