import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/medicine.dart';
import '../models/patient.dart';
import '../models/sale.dart';
import '../models/user.dart';
import 'auth_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _ffiInitialized = false;

  DatabaseHelper._init();

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// sqflite's normal engine only works on Android/iOS. On Windows, Linux,
  /// and macOS we need the FFI-based engine instead
  /// (sqflite_common_ffi), which talks to a real native SQLite library.
  /// This must run once, before the first database is opened.
  static void _ensureDatabaseFactory() {
    if (_ffiInitialized) return;
    if (_isDesktop) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _ffiInitialized = true;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _ensureDatabaseFactory();
    _database = await _initDB('pharmacy.db');
    return _database!;
  }

  /// Where the .db file lives. On Android/iOS, sqflite's own default
  /// location is fine. On desktop, the FFI engine's default
  /// `getDatabasesPath()` just returns the current working directory
  /// (wherever the .exe happens to be launched from), which isn't a
  /// reliable place to keep real data — so we use the proper per-user
  /// "Application Support" folder instead (e.g.
  /// `C:\Users\<name>\AppData\Roaming\pharmacy_app\` on Windows).
  Future<String> _resolveDatabasesPath() async {
    if (_isDesktop) {
      final dir = await getApplicationSupportDirectory();
      return dir.path;
    }
    return getDatabasesPath();
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await _resolveDatabasesPath();
    final path = join(dbPath, fileName);
    final db = await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
    await _seedDefaultAdmin(db);
    return db;
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          passwordHash TEXT NOT NULL,
          fullName TEXT,
          createdAt TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      // Adds the optional medical reference fields used by the
      // Medicine & Patient Lookup feature. Existing rows default to ''.
      for (final column in ['usage', 'dosage', 'overdoseInfo', 'precautions']) {
        try {
          await db.execute(
              "ALTER TABLE medicines ADD COLUMN $column TEXT DEFAULT ''");
        } catch (_) {
          // Column already exists (e.g. fresh install hitting _createDB
          // directly) — safe to ignore.
        }
      }
    }
    if (oldVersion < 4) {
      // Adds email + a reversibly-encrypted copy of the password, needed
      // by the Forgot Password feature (see AuthHelper for why a separate
      // reversible copy exists alongside the original one-way hash).
      for (final column in ['email', 'passwordEncrypted']) {
        try {
          await db.execute("ALTER TABLE users ADD COLUMN $column TEXT DEFAULT ''");
        } catch (_) {
          // Column already exists — safe to ignore.
        }
      }
    }
  }

  /// Keeps the original admin/admin123 login working for existing users,
  /// but only creates it once and only if no accounts exist yet — anyone
  /// can also sign up for their own account from the login screen.
  Future _seedDefaultAdmin(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM users'),
        ) ??
        0;
    if (count == 0) {
      await db.insert('users', {
        'username': 'admin',
        'passwordHash': AuthHelper.hashPassword('admin123'),
        'passwordEncrypted': AuthHelper.encryptPassword('admin123'),
        'email': 'admin@studentpharmacentre.local',
        'fullName': 'Admin',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        genericName TEXT,
        category TEXT,
        batchNo TEXT,
        purchasePrice REAL,
        salePrice REAL,
        quantity INTEGER,
        unit TEXT,
        expiryDate TEXT,
        supplier TEXT,
        minStockAlert INTEGER,
        usage TEXT DEFAULT '',
        dosage TEXT DEFAULT '',
        overdoseInfo TEXT DEFAULT '',
        precautions TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER,
        gender TEXT,
        phone TEXT,
        address TEXT,
        allergies TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER,
        patientName TEXT,
        totalAmount REAL,
        discount REAL,
        paymentType TEXT,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER,
        medicineId INTEGER,
        medicineName TEXT,
        quantity INTEGER,
        priceAtSale REAL,
        FOREIGN KEY (saleId) REFERENCES sales (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        passwordHash TEXT NOT NULL,
        passwordEncrypted TEXT DEFAULT '',
        email TEXT DEFAULT '',
        fullName TEXT,
        createdAt TEXT
      )
    ''');
  }

  // ---------------- USERS / AUTH ----------------

  Future<bool> usernameExists(String username) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'LOWER(username) = ?',
      whereArgs: [username.trim().toLowerCase()],
    );
    return result.isNotEmpty;
  }

  Future<int> insertUser(AppUser user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<AppUser?> getUserByUsername(String username) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'LOWER(username) = ?',
      whereArgs: [username.trim().toLowerCase()],
    );
    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  Future<AppUser?> getUserById(int id) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  /// Looks a user up by username OR their registered email — used by the
  /// Forgot Password screen so the user can identify their account either
  /// way.
  Future<AppUser?> getUserByUsernameOrEmail(String identifier) async {
    final db = await instance.database;
    final normalized = identifier.trim().toLowerCase();
    final result = await db.query(
      'users',
      where: 'LOWER(username) = ? OR LOWER(email) = ?',
      whereArgs: [normalized, normalized],
    );
    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  /// Returns the logged-in user on success, or null if the username /
  /// password combination is invalid.
  Future<AppUser?> validateLogin(String username, String rawPassword) async {
    final user = await getUserByUsername(username);
    if (user == null) return null;
    final valid = AuthHelper.verifyPassword(rawPassword, user.passwordHash);
    return valid ? user : null;
  }

  // ---------------- MEDICINE CRUD ----------------

  Future<int> insertMedicine(Medicine m) async {
    final db = await instance.database;
    return await db.insert('medicines', m.toMap());
  }

  /// Inserts many medicines at once (used by the Excel/CSV bulk-upload
  /// screen). Runs inside a single transaction so a huge list is fast and
  /// either fully applied or not applied at all if something goes wrong.
  Future<int> insertMedicinesBulk(List<Medicine> medicines) async {
    final db = await instance.database;
    int inserted = 0;
    await db.transaction((txn) async {
      for (final m in medicines) {
        await txn.insert('medicines', m.toMap());
        inserted++;
      }
    });
    return inserted;
  }

  Future<List<Medicine>> getAllMedicines() async {
    final db = await instance.database;
    final result = await db.query('medicines', orderBy: 'name ASC');
    return result.map((m) => Medicine.fromMap(m)).toList();
  }

  Future<Medicine?> getMedicineById(int id) async {
    final db = await instance.database;
    final result = await db.query('medicines', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Medicine.fromMap(result.first);
  }

  Future<List<Medicine>> searchMedicines(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'medicines',
      where: 'name LIKE ? OR genericName LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return result.map((m) => Medicine.fromMap(m)).toList();
  }

  Future<int> updateMedicine(Medicine m) async {
    final db = await instance.database;
    return await db.update('medicines', m.toMap(),
        where: 'id = ?', whereArgs: [m.id]);
  }

  Future<int> deleteMedicine(int id) async {
    final db = await instance.database;
    return await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Medicine>> getLowStockMedicines() async {
    final all = await getAllMedicines();
    return all.where((m) => m.isLowStock).toList();
  }

  Future<List<Medicine>> getExpiringSoonMedicines() async {
    final all = await getAllMedicines();
    return all.where((m) => m.isExpiringSoon && !m.isExpired).toList();
  }

  Future<List<Medicine>> getExpiredMedicines() async {
    final all = await getAllMedicines();
    return all.where((m) => m.isExpired).toList();
  }

  // ---------------- PATIENT CRUD ----------------

  Future<int> insertPatient(Patient p) async {
    final db = await instance.database;
    return await db.insert('patients', p.toMap());
  }

  Future<List<Patient>> getAllPatients() async {
    final db = await instance.database;
    final result = await db.query('patients', orderBy: 'name ASC');
    return result.map((p) => Patient.fromMap(p)).toList();
  }

  Future<List<Patient>> searchPatients(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'patients',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return result.map((p) => Patient.fromMap(p)).toList();
  }

  Future<int> updatePatient(Patient p) async {
    final db = await instance.database;
    return await db.update('patients', p.toMap(),
        where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> deletePatient(int id) async {
    final db = await instance.database;
    return await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- SALES ----------------

  Future<int> createSale(Sale sale) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final saleId = await txn.insert('sales', sale.toMap());

      for (final item in sale.items) {
        await txn.insert('sale_items', {
          'saleId': saleId,
          'medicineId': item.medicineId,
          'medicineName': item.medicineName,
          'quantity': item.quantity,
          'priceAtSale': item.priceAtSale,
        });

        // Deduct stock
        final medRows = await txn.query('medicines',
            where: 'id = ?', whereArgs: [item.medicineId]);
        if (medRows.isNotEmpty) {
          final currentQty = medRows.first['quantity'] as int;
          final newQty = currentQty - item.quantity;
          await txn.update(
            'medicines',
            {'quantity': newQty < 0 ? 0 : newQty},
            where: 'id = ?',
            whereArgs: [item.medicineId],
          );
        }
      }
      return saleId;
    });
  }

  Future<List<Sale>> getAllSales() async {
    final db = await instance.database;
    final result = await db.query('sales', orderBy: 'date DESC');
    List<Sale> sales = [];
    for (final row in result) {
      final sale = Sale.fromMap(row);
      final itemRows = await db.query('sale_items',
          where: 'saleId = ?', whereArgs: [sale.id]);
      final items = itemRows.map((i) => SaleItem.fromMap(i)).toList();
      sales.add(Sale(
        id: sale.id,
        patientId: sale.patientId,
        patientName: sale.patientName,
        totalAmount: sale.totalAmount,
        discount: sale.discount,
        paymentType: sale.paymentType,
        date: sale.date,
        items: items,
      ));
    }
    return sales;
  }

  Future<List<Sale>> getSalesForPatient(int patientId) async {
    final all = await getAllSales();
    return all.where((s) => s.patientId == patientId).toList();
  }

  Future<double> getTodaysSalesTotal() async {
    final all = await getAllSales();
    final today = DateTime.now();
    final todaySales = all.where((s) =>
        s.date.year == today.year &&
        s.date.month == today.month &&
        s.date.day == today.day);
    double total = 0;
    for (final s in todaySales) {
      total += s.totalAmount;
    }
    return total;
  }
}
