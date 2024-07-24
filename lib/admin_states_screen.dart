import 'package:flutter/material.dart';
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
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _confirmDeleteState(
                                      statesProvider, state['id']),
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
