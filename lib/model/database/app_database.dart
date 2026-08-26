import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance =
  AppDatabase._();

  static const String _databaseName =
      'tubilearn.db';

  static const int _databaseVersion =
  2;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database =
    await _openDatabase();

    return _database!;
  }

  Future<Database> _openDatabase() async {
    final String databasePath =
    await getDatabasesPath();

    final String path = join(
      databasePath,
      _databaseName,
    );

    return openDatabase(
      path,
      version: _databaseVersion,

      onConfigure: (
          db,
          ) async {
        await db.execute(
          'PRAGMA foreign_keys = ON',
        );
      },

      onCreate: (
          db,
          version,
          ) async {
        await _createConversationTables(
          db,
        );

        await _createSwapTables(
          db,
        );
      },

      onUpgrade: (
          db,
          oldVersion,
          newVersion,
          ) async {
        if (oldVersion < 2) {
          await _createSwapTables(
            db,
          );
        }
      },
    );
  }

  Future<void>
  _createConversationTables(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        user_name TEXT NOT NULL,
        initials TEXT NOT NULL,
        city TEXT NOT NULL,
        skill_wanted TEXT NOT NULL,
        skill_offered TEXT NOT NULL,
        status TEXT NOT NULL
      )
      ''',
    );

    await db.execute(
      '''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        text TEXT NOT NULL,
        is_me INTEGER NOT NULL,
        sent_at INTEGER NOT NULL,

        FOREIGN KEY (conversation_id)
        REFERENCES conversations(id)
        ON DELETE CASCADE
      )
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX idx_messages_conversation
      ON messages(conversation_id)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX idx_messages_sent_at
      ON messages(sent_at)
      ''',
    );
  }

  Future<void> _createSwapTables(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE TABLE swap_requests (
        id TEXT PRIMARY KEY,

        provider_name TEXT NOT NULL,
        provider_initials TEXT NOT NULL,
        provider_city TEXT NOT NULL,

        skill_to_learn TEXT NOT NULL,
        skill_to_offer TEXT NOT NULL,

        proposed_at INTEGER NOT NULL,

        mode TEXT NOT NULL,

        meeting_details TEXT,

        note TEXT,

        status TEXT NOT NULL,

        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX idx_swap_requests_status
      ON swap_requests(status)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX idx_swap_requests_created_at
      ON swap_requests(created_at)
      ''',
    );
  }

  Future<void> close() async {
    final Database? db =
        _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}