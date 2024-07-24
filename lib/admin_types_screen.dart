import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'types_provider.dart';

class AdminTypesScreen extends StatefulWidget {
  @override
  _AdminTypesScreenState createState() => _AdminTypesScreenState();
}

class _AdminTypesScreenState extends State<AdminTypesScreen> {
  final _nameController = TextEditingController();
  bool _orderChanged = false;

  void _addType(TypesProvider typesProvider) {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      FocusScope.of(context).unfocus(); // Cerrar el teclado
      typesProvider.addType(name).then((_) {
        _nameController.clear();
        setState(() {});
      });
    }
  }

  void _deleteType(TypesProvider typesProvider, int id) async {
    await typesProvider.deleteType(id);
    setState(() {});
  }

  void _updatePositions(TypesProvider typesProvider) {
    typesProvider.updateTypePositions().then((_) {
      setState(() {
        _orderChanged = false;
      });
    });
  }

  void _onReorder(int oldIndex, int newIndex, TypesProvider typesProvider) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final List<Map<String, dynamic>> updatedTypes =
          List.from(typesProvider.types);
      final item = updatedTypes.removeAt(oldIndex);
      updatedTypes.insert(newIndex, item);
      typesProvider.updateTypesOrder(updatedTypes);
      _orderChanged = true;
    });
  }

  Future<void> _confirmDeleteType(TypesProvider typesProvider, int id) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar este tipo?'),
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
      _deleteType(typesProvider, id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Administrar Tipos'),
      ),
      body: Consumer<TypesProvider>(
        builder: (context, typesProvider, child) {
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
                              labelText: 'Nuevo Tipo',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () => _addType(typesProvider),
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
                    onPressed: () => _updatePositions(typesProvider),
                    child: Text('Guardar Orden'),
                  ),
                ),
              Expanded(
                child: typesProvider.types.isEmpty
                    ? Center(child: Text('No hay tipos disponibles.'))
                    : ReorderableListView(
                        onReorder: (oldIndex, newIndex) =>
                            _onReorder(oldIndex, newIndex, typesProvider),
                        children: [
                          for (final type in typesProvider.types)
                            Card(
                              key: ValueKey(type['id']),
                              child: ListTile(
                                leading: Icon(Icons.drag_handle),
                                title: Text(type['name'] ?? 'Sin nombre'),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _confirmDeleteType(
                                      typesProvider, type['id']),
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
