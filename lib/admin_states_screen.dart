import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'states_provider.dart';

class AdminStatesScreen extends StatefulWidget {
  @override
  _AdminStatesScreenState createState() => _AdminStatesScreenState();
}

class _AdminStatesScreenState extends State<AdminStatesScreen> {
  final _nameController = TextEditingController();
  bool _orderChanged = false;

  void _addState(StatesProvider statesProvider) {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      FocusScope.of(context).unfocus(); // Cerrar el teclado
      statesProvider.addState(name).then((_) {
        _nameController.clear();
        setState(() {});
      });
    }
  }

  void _deleteState(StatesProvider statesProvider, int id) async {
    await statesProvider.deleteState(id);
    setState(() {});
  }

  void _updatePositions(StatesProvider statesProvider) {
    statesProvider.updateStatePositions().then((_) {
      setState(() {
        _orderChanged = false;
      });
    });
  }

  void _onReorder(int oldIndex, int newIndex, StatesProvider statesProvider) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final List<Map<String, dynamic>> updatedStates =
          List.from(statesProvider.states);
      final item = updatedStates.removeAt(oldIndex);
      updatedStates.insert(newIndex, item);
      statesProvider.updateStatesOrder(updatedStates);
      _orderChanged = true;
    });
  }

  Future<void> _confirmDeleteState(
      StatesProvider statesProvider, int id) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar este estado?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Eliminar'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed) {
      _deleteState(statesProvider, id);
    }
  }

  void _changeColor(int id, StatesProvider statesProvider) {
    Color initialColor = Colors.white;
    const List<Color> availableColors = [
      Color(0x80FFFFFF), // Blanco translúcido
      Color(0x80FFEBEE), // Rosa claro translúcido
      Color(0x80FCE4EC), // Rosa translúcido
      Color(0x80E1F5FE), // Azul claro translúcido
      Color(0x80E3F2FD), // Azul translúcido
      Color(0x80E8F5E9), // Verde claro translúcido
      Color(0x80F1F8E9), // Verde translúcido
      Color(0x80FFF3E0), // Naranja claro translúcido
      Color(0x80FFF8E1), // Amarillo translúcido
      Color(0x80E0F7FA), // Cian claro translúcido
      Color(0x80F3E5F5), // Violeta claro translúcido
      Color(0x80FFCDD2), // Rojo claro translúcido
      Color(0x80D1C4E9), // Púrpura translúcido
      Color(0x80C5CAE9), // Azul translúcido
      Color(0x80BBDEFB), // Azul cielo translúcido
      Color(0x80B3E5FC), // Azul celeste translúcido
    ];
    for (var state in statesProvider.states) {
      if (state['id'] == id) {
        initialColor = Color(
            int.parse(state['color'].substring(1, 7), radix: 16) + 0xFF000000);
        break;
      }
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color pickedColor = initialColor;
        return AlertDialog(
          title: Text('Selecciona un color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: pickedColor,
              availableColors: availableColors,
              onColorChanged: (Color color) {
                pickedColor = color;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Guardar'),
              onPressed: () {
                statesProvider.updateStateColor(id, pickedColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Administrar Estados'),
      ),
      body: Consumer<StatesProvider>(
        builder: (context, statesProvider, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nuevo Estado',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () => _addState(statesProvider),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Mantén presionado un elemento durante 1 segundo para ordenar la lista.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              if (_orderChanged)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () => _updatePositions(statesProvider),
                    child: Text('Guardar Orden'),
                  ),
                ),
              Expanded(
                child: statesProvider.states.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : ReorderableListView(
                        onReorder: (oldIndex, newIndex) =>
                            _onReorder(oldIndex, newIndex, statesProvider),
                        children: [
                          for (final state in statesProvider.states)
                            Card(
                              key: ValueKey(state['id']),
                              child: ListTile(
                                leading: Icon(Icons.drag_handle),
                                title: Text(state['name'] ?? 'Sin nombre'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _changeColor(
                                          state['id'], statesProvider),
                                      child: Container(
                                        width: 40,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Color(int.parse(
                                              state['color'].substring(1),
                                              radix: 16)),
                                          border: Border.all(
                                              color:
                                                  Colors.black), // Borde negro
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () => _confirmDeleteState(
                                          statesProvider, state['id']),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
