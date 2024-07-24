import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'inventory.db');

    return await openDatabase(
      path,
      version: 7,
      onCreate: (db, version) async {
        await _createDb(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _upgradeDb(db, oldVersion, newVersion);
      },
    );
  }

  Future<void> _createDb(Database db) async {
    print("Creating database...");
    await db.execute('''
      CREATE TABLE IF NOT EXISTS equipment(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderNumber TEXT,
        type TEXT,
        initialFault TEXT,
        technicalObservation TEXT,
        seen TEXT,
        status TEXT,
        creationDate TEXT,
        deliveryDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS types(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        position INTEGER,
        isActive INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS states(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        position INTEGER,
        isActive INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Clean up duplicates
    await db.execute(
        'DELETE FROM types WHERE id NOT IN (SELECT MIN(id) FROM types GROUP BY name)');
    await db.execute(
        'DELETE FROM states WHERE id NOT IN (SELECT MIN(id) FROM states GROUP BY name)');

    // Insert default types if they don't exist
    List<String> defaultTypes = [
      'TV Led',
      'PlayStation',
      'Xbox',
      'Nintendo',
      'Otros'
    ];
    for (int i = 0; i < defaultTypes.length; i++) {
      final List<Map<String, dynamic>> existingTypes = await db.query(
        'types',
        where: 'name = ?',
        whereArgs: [defaultTypes[i]],
      );

      if (existingTypes.isEmpty) {
        await db.insert('types', {
          'name': defaultTypes[i],
          'position': i,
          'isActive': 1,
        });
      }
    }

    // Insert default states if they don't exist
    List<String> defaultStates = [
      'Ingreso nuevo',
      'Devolucion',
      'Facturada',
      'Finalizada'
    ];
    for (int i = 0; i < defaultStates.length; i++) {
      final List<Map<String, dynamic>> existingStates = await db.query(
        'states',
        where: 'name = ?',
        whereArgs: [defaultStates[i]],
      );

      if (existingStates.isEmpty) {
        await db.insert('states', {
          'name': defaultStates[i],
          'position': i,
          'isActive': 1,
        });
      }
    }
    print("Database created successfully.");
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from version $oldVersion to $newVersion...");
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE equipment ADD COLUMN deliveryDate TEXT');
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE equipment ADD COLUMN status TEXT DEFAULT "Ingreso nuevo"');
      await db.execute(
          'ALTER TABLE equipment ADD COLUMN creationDate TEXT DEFAULT "2024-07-20"');
      await db.rawUpdate(
          'UPDATE equipment SET status = "Ingreso nuevo" WHERE status IS NULL');
      await db.rawUpdate(
          'UPDATE equipment SET creationDate = "2024-07-20" WHERE creationDate IS NULL');
    }
    if (oldVersion < 8) {
      await _createDb(db);
    }
    print("Database upgraded successfully.");
  }

  Future<void> insertEquipment(Map<String, dynamic> equipment) async {
    final db = await database;
    await db.insert('equipment', equipment,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getEquipmentList() async {
    final db = await database;
    return await db.query('equipment');
  }

  Future<List<Map<String, dynamic>>> searchEquipment(String query) async {
    final db = await database;
    return await db.query(
      'equipment',
      where: 'orderNumber LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  Future<void> updateEquipment(int id, Map<String, dynamic> equipment) async {
    final db = await database;
    await db.update('equipment', equipment, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteEquipment(int id) async {
    final db = await database;
    await db.delete('equipment', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> orderNumberExists(String orderNumber) async {
    final db = await database;
    final result = await db.query('equipment',
        where: 'orderNumber = ?', whereArgs: [orderNumber], limit: 1);
    return result.isNotEmpty;
  }

  Future<int> getDatabaseVersion() async {
    final db = await database;
    var result = await db.rawQuery('PRAGMA user_version');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> insertType(String name) async {
    final db = await database;
    int maxPosition = Sqflite.firstIntValue(
            await db.rawQuery('SELECT MAX(position) FROM types')) ??
        0;
    await db.insert(
        'types', {'name': name, 'position': maxPosition + 1, 'isActive': 1});
  }

  Future<List<Map<String, dynamic>>> getTypes() async {
    final db = await database;
    return await db.query('types',
        orderBy: 'position', where: 'isActive = ?', whereArgs: [1]);
  }

  Future<List<Map<String, dynamic>>> getTypesall() async {
    final db = await database;
    return await db.query('types', orderBy: 'position');
  }

  Future<void> deleteType(int id) async {
    final db = await database;
    await db.update('types', {'isActive': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTypePosition(int id, int position) async {
    final db = await database;
    await db.update('types', {'position': position},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertState(String name) async {
    final db = await database;
    int maxPosition = Sqflite.firstIntValue(
            await db.rawQuery('SELECT MAX(position) FROM states')) ??
        0;
    await db.insert(
        'states', {'name': name, 'position': maxPosition + 1, 'isActive': 1});
  }

  Future<List<Map<String, dynamic>>> getStates() async {
    final db = await database;
    return await db.query('states',
        orderBy: 'position', where: 'isActive = ?', whereArgs: [1]);
  }

  Future<List<Map<String, dynamic>>> getStatesAll() async {
    final db = await database;
    return await db.query('states', orderBy: 'position');
  }

  Future<void> deleteState(int id) async {
    final db = await database;
    await db.update('states', {'isActive': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateStatePosition(int id, int position) async {
    final db = await database;
    await db.update('states', {'position': position},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getNotificationDays() async {
    final db = await database;
    var result = await db.rawQuery(
        'SELECT value FROM settings WHERE key = ?', ['notification_days']);
    if (result.isNotEmpty) {
      final value = result.first['value'];
      if (value is String) {
        return int.parse(value);
      } else {
        // Manejar el caso donde el valor no es un String
        return 0; // Default value
      }
    } else {
      return 0; // Default value
    }
  }

  Future<void> setNotificationDays(int days) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': 'notification_days', 'value': days.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
