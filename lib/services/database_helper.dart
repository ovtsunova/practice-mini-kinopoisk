import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/movie.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'movies.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE movies(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        director TEXT NOT NULL,
        releaseDate TEXT NOT NULL,
        genre TEXT NOT NULL,
        rating REAL NOT NULL,
        imagePath TEXT,
        notes TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS movies');
      await _onCreate(db, newVersion);
    }
  }

  Future<int> insertMovie(Movie movie) async {
    Database db = await database;
    return await db.insert('movies', movie.toMap());
  }

  Future<List<Movie>> getMovies() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('movies', orderBy: 'title');
    return List.generate(maps.length, (i) => Movie.fromMap(maps[i]));
  }

  Future<int> updateMovie(Movie movie) async {
    Database db = await database;
    return await db.update(
      'movies',
      movie.toMap(),
      where: 'id = ?',
      whereArgs: [movie.id],
    );
  }

  Future<int> deleteMovie(int id) async {
    Database db = await database;
    return await db.delete(
      'movies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}