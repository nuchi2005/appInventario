import 'package:flutter/material.dart';
import 'package:inventory_app/notifications_provider.dart';
import 'package:provider/provider.dart';
import 'equipments_provider.dart';
import 'types_provider.dart';
import 'states_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'listaEquipo.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => EquipmentsProvider()),
        ChangeNotifierProvider(create: (_) => TypesProvider()),
        ChangeNotifierProvider(create: (_) => StatesProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: [
        const Locale('es', 'ES'), // Spanish, no country code
      ],
      home: ListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
