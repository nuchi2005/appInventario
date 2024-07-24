import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'ExpiredEquipmentsScreen.dart';
import 'detail_screen.dart';
import 'edit_screen.dart';
import 'photo_screen.dart';
import 'equipments_provider.dart';
import 'main_screen.dart';
import 'admin_states_screen.dart';
import 'admin_types_screen.dart';
import 'admin_notifications_screen.dart';
import 'states_provider.dart';

class ListScreen extends StatefulWidget {
  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _filteredEquipmentList = [];
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _selectedStatusFilter = 'Todos';
  String _selectedSeenFilter = 'Todos';
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<EquipmentsProvider>(context, listen: false)
          .fetchEquipments();
      _filterList();
    });
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.removeListener(_performSearch);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final keyboardHeight = WidgetsBinding.instance.window.viewInsets.bottom;
    setState(() {
      _isKeyboardVisible = keyboardHeight > 0;
      print('Keyboard is ${_isKeyboardVisible ? 'visible' : 'hidden'}');
    });
  }

  void _performSearch() {
    _filterList();
  }

  Color _getStatusColor(String status, StatesProvider statesProvider) {
    final state = statesProvider.states.firstWhere(
      (state) => state['name'] == status,
      orElse: () => {'color': '#FFFFFF'},
    );
    return Color(
        int.parse(state['color'].substring(1), radix: 16) + 0xFF000000);
  }

  void _filterList() {
    final equipmentsProvider =
        Provider.of<EquipmentsProvider>(context, listen: false);
    final allData = equipmentsProvider.equipments;

    if (_selectedStatusFilter == 'Todos' &&
        _selectedSeenFilter == 'Todos' &&
        _searchController.text.isEmpty) {
      setState(() {
        _filteredEquipmentList = allData;
      });
    } else {
      setState(() {
        _filteredEquipmentList = allData.where((equipment) {
          final statusMatch = _selectedStatusFilter == 'Todos' ||
              equipment['status'] == _selectedStatusFilter;
          final seenMatch = _selectedSeenFilter == 'Todos' ||
              (equipment['seen'] == 'true' ? 'Sí' : 'No') ==
                  _selectedSeenFilter;
          final searchMatch = _searchController.text.isEmpty ||
              equipment['orderNumber']
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase());
          return statusMatch && seenMatch && searchMatch;
        }).toList();
      });
    }
  }

  Future<void> _scanBarcode() async {
    var result = await BarcodeScanner.scan();
    setState(() {
      _searchController.text = result.rawContent;
      _performSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de equipos'),
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 199, 227, 250),
                Color.fromARGB(255, 245, 245, 247)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30.0,
                      backgroundImage: AssetImage('assets/icon/app_icon.png'),
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      'Admin de equipos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Alta de Equipos'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MainScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Administrar Estados'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AdminStatesScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.category),
                title: Text('Administrar Tipos'),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminTypesScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.notifications),
                title: Text('Administrar Notificaciones'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AdminNotificationsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Buscar por número orden',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: _performSearch,
                      ),
                    ),
                    onSubmitted: (value) {
                      _performSearch();
                    },
                  ),
                ),
              ],
            ),
          ),
          Consumer<StatesProvider>(
            builder: (context, statesProvider, child) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: [
                      FilterChip(
                        label: Text('Todos'),
                        selected: _selectedStatusFilter == 'Todos',
                        backgroundColor: Color.fromARGB(255, 178, 247, 214),
                        selectedColor: Color.fromARGB(255, 178, 247, 214),
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedStatusFilter = 'Todos';
                            _filterList();
                          });
                        },
                      ),
                      ...statesProvider.states.map((state) {
                        return FilterChip(
                          label: Text(state['name']),
                          selected: _selectedStatusFilter == state['name'],
                          backgroundColor: Color(int.parse(
                                  state['color'].substring(1),
                                  radix: 16) +
                              0xFF000000),
                          selectedColor: Color(int.parse(
                                  state['color'].substring(1),
                                  radix: 16) +
                              0xFF000000),
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedStatusFilter =
                                  selected ? state['name'] : 'Todos';
                              _filterList();
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Wrap(
                spacing: 8.0,
                children: [
                  FilterChip(
                    label: Text('Todos'),
                    backgroundColor: Color.fromARGB(255, 178, 247, 214),
                    selectedColor: Color.fromARGB(255, 178, 247, 214),
                    selected: _selectedSeenFilter == 'Todos',
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedSeenFilter = 'Todos';
                        _filterList();
                      });
                    },
                  ),
                  FilterChip(
                    label: Text('Sí'),
                    backgroundColor: Color.fromARGB(255, 189, 227, 245),
                    selectedColor: Color.fromARGB(255, 189, 227, 245),
                    selected: _selectedSeenFilter == 'Sí',
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedSeenFilter = selected ? 'Sí' : 'Todos';
                        _filterList();
                      });
                    },
                  ),
                  FilterChip(
                    label: Text('No'),
                    backgroundColor: Color.fromARGB(255, 248, 206, 206),
                    selectedColor: Color.fromARGB(255, 248, 206, 206),
                    selected: _selectedSeenFilter == 'No',
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedSeenFilter = selected ? 'No' : 'Todos';
                        _filterList();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer2<EquipmentsProvider, StatesProvider>(
              builder: (context, equipmentsProvider, statesProvider, child) {
                if (_filteredEquipmentList.isEmpty) {
                  return Center(
                    child: Text('No se encontraron resultados.'),
                  );
                }
                return ListView.builder(
                  itemCount: _filteredEquipmentList.length,
                  itemBuilder: (context, index) {
                    final equipment = _filteredEquipmentList[index];
                    final id = equipment['id'];

                    String formattedCreationDate = 'No especificada';
                    if (equipment['creationDate'] != null &&
                        equipment['creationDate'].isNotEmpty) {
                      try {
                        DateTime creationDate = DateFormat('yyyy-MM-dd')
                            .parse(equipment['creationDate']);
                        formattedCreationDate =
                            DateFormat('dd/MM/yyyy').format(creationDate);
                      } catch (e) {
                        formattedCreationDate = 'Formato inválido';
                      }
                    }

                    String formattedDeliveryDate = 'No seleccionada';
                    if (equipment['deliveryDate'] != null &&
                        equipment['deliveryDate'].isNotEmpty) {
                      try {
                        DateTime deliveryDate = DateFormat('yyyy-MM-dd')
                            .parse(equipment['deliveryDate']);
                        formattedDeliveryDate =
                            DateFormat('dd/MM/yyyy').format(deliveryDate);
                      } catch (e) {
                        formattedDeliveryDate = 'Formato inválido';
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 2.0),
                      color:
                          _getStatusColor(equipment['status'], statesProvider),
                      child: ListTile(
                        title: Text(equipment['orderNumber']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tipo: ${equipment['type']}'),
                            Text('Estado: ${equipment['status']}'),
                            Text('Fecha de Creación: $formattedCreationDate'),
                            Text('Fecha de Entrega: $formattedDeliveryDate'),
                            Text(
                                'Visto: ${equipment['seen'] == 'true' ? 'Sí' : 'No'}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.photo),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PhotoScreen(equipmentId: id),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditScreen(
                                        equipment: equipment, id: id),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailScreen(equipment: equipment, id: id),
                            ),
                          );
                          if (result == true) {
                            equipmentsProvider.fetchEquipments();
                            _filterList(); // Refrescar la lista
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Offstage(
        offstage: _isKeyboardVisible,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
            );
          },
          child: Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Container(
          height: 60.0,
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.camera_alt_outlined),
                    onPressed: () {
                      _scanBarcode();
                    },
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ExpiredEquipmentsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
