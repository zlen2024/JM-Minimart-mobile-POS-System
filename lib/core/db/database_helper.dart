import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_system.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNull = 'TEXT';
    const boolType = 'BOOLEAN NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const realTypeNull = 'REAL';

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType,
  color $textTypeNull
)
''');

    await db.execute('''
CREATE TABLE products (
  id $idType,
  category_id INTEGER,
  name $textType,
  sku $textTypeNull UNIQUE,
  barcode $textTypeNull,
  price $realType,
  cost_price $realTypeNull,
  stock_quantity INTEGER DEFAULT 0,
  low_stock_threshold INTEGER DEFAULT 5,
  image_path $textTypeNull,
  is_synced $boolType DEFAULT 0,
  last_updated $textTypeNull,
  FOREIGN KEY (category_id) REFERENCES categories (id)
)
''');

    await db.execute('''
CREATE TABLE sales (
  id $idType,
  total_amount $realType,
  discount_amount $realTypeNull,
  tax_amount $realTypeNull,
  payment_method $textTypeNull,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  is_synced $boolType DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE sale_items (
  id $idType,
  sale_id INTEGER,
  product_id INTEGER,
  quantity $integerType,
  unit_price $realType,
  FOREIGN KEY (sale_id) REFERENCES sales (id),
  FOREIGN KEY (product_id) REFERENCES products (id)
)
''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
