import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'reference_seed_data.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance =
  AppDatabase._();

  static const String _databaseName =
      'tubilearn.db';

  static const int _databaseVersion = 10;

  Database? _database;

  Future<Database>? _openingFuture;
  Future<void>? _closingFuture;

  // ============================================================
  // DATABASE ACCESS
  // ============================================================

  Future<Database> get database async {
    final Future<void>? closing =
        _closingFuture;

    if (closing != null) {
      await closing;
    }

    final Database? existingDatabase =
        _database;

    if (existingDatabase != null &&
        existingDatabase.isOpen) {
      return existingDatabase;
    }

    final Future<Database>? existingOpening =
        _openingFuture;

    if (existingOpening != null) {
      return existingOpening;
    }

    late final Future<Database> opening;

    opening =
        _openAndValidateDatabase();

    _openingFuture =
        opening;

    try {
      final Database openedDatabase =
      await opening;

      _database =
          openedDatabase;

      return openedDatabase;
    } finally {
      if (identical(
        _openingFuture,
        opening,
      )) {
        _openingFuture =
        null;
      }
    }
  }

  // ============================================================
  // OPEN + VALIDATE DATABASE
  // ============================================================

  Future<Database>
  _openAndValidateDatabase() async {
    final Database db =
    await _openDatabase();

    try {
      await _verifyDatabaseIntegrity(
        db,
      );

      return db;
    } catch (_) {
      if (db.isOpen) {
        await db.close();
      }

      rethrow;
    }
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

      // ========================================================
      // FRESH INSTALL
      // ========================================================

      onCreate: (
          db,
          version,
          ) async {
        await _createReferenceTablesV5(
          db,
        );

        await _seedReferenceDataV5(
          db,
        );

        await _createConversationTablesV3(
          db,
        );

        await _createSwapTablesV4(
          db,
        );

        await _createSwapIndexesV6(
          db,
        );

        await _createSkillOwnershipIndexesV7(
          db,
        );

        await _createConversationIndexesV8(
          db,
        );

        await _createUserVisibilityTablesV10(
          db,
        );
      },

      // ========================================================
      // SEQUENTIAL UPGRADES
      // ========================================================

      onUpgrade: (
          db,
          oldVersion,
          newVersion,
          ) async {
        if (oldVersion < 2) {
          await _createSwapTablesV2(
            db,
          );
        }

        if (oldVersion < 3) {
          await _migrateToVersion3(
            db,
          );
        }

        if (oldVersion < 4) {
          await _migrateToVersion4(
            db,
          );
        }

        if (oldVersion < 5) {
          await _migrateToVersion5(
            db,
          );
        }

        if (oldVersion < 6) {
          await _migrateToVersion6(
            db,
          );
        }

        if (oldVersion < 7) {
          await _migrateToVersion7(
            db,
          );
        }

        if (oldVersion < 8) {
          await _migrateToVersion8(
            db,
          );
        }

        if (oldVersion < 9) {
          await _migrateToVersion9(
            db,
          );
        }

        if (oldVersion < 10) {
          await _migrateToVersion10(
            db,
          );
        }
      },
    );
  }

  // ============================================================
  // DATABASE INTEGRITY VERIFICATION
  // ============================================================

  Future<void> _verifyDatabaseIntegrity(
      Database db,
      ) async {
    await _verifyForeignKeysEnabled(
      db,
    );

    await _verifyDatabaseVersion(
      db,
    );

    await _verifyRequiredTables(
      db,
    );

    await _verifyCriticalColumns(
      db,
    );

    await _verifyCriticalIndexes(
      db,
    );

    await _verifyForeignKeyIntegrity(
      db,
    );

    await _verifyQuickCheck(
      db,
    );
  }

  // ============================================================
  // FOREIGN KEYS
  // ============================================================

  Future<void> _verifyForeignKeysEnabled(
      Database db,
      ) async {
    final List<Map<String, Object?>> rows =
    await db.rawQuery(
      'PRAGMA foreign_keys',
    );

    if (rows.length != 1 ||
        rows.first.isEmpty) {
      throw StateError(
        'Could not verify SQLite foreign-key enforcement.',
      );
    }

    final int? value =
    _readExactDatabaseInteger(
      rows.first.values.first,
    );

    if (value != 1) {
      throw StateError(
        'SQLite foreign-key enforcement is disabled.',
      );
    }
  }

  // ============================================================
  // DATABASE VERSION
  // ============================================================

  Future<void> _verifyDatabaseVersion(
      Database db,
      ) async {
    final List<Map<String, Object?>> rows =
    await db.rawQuery(
      'PRAGMA user_version',
    );

    if (rows.length != 1 ||
        rows.first.isEmpty) {
      throw StateError(
        'Could not verify the database version.',
      );
    }

    final int? version =
    _readExactDatabaseInteger(
      rows.first.values.first,
    );

    if (version != _databaseVersion) {
      throw StateError(
        'Unexpected database version. '
            'Expected $_databaseVersion but found $version.',
      );
    }
  }

  // ============================================================
  // REQUIRED TABLES
  // ============================================================

  Future<void> _verifyRequiredTables(
      Database db,
      ) async {
    const Set<String> requiredTables =
    <String>{
      'users',
      'skills',
      'skill_learnings',
      'user_skills',
      'conversations',
      'messages',
      'swap_requests',
      'conversation_user_visibility',
      'swap_request_user_visibility',
    };

    final List<Map<String, Object?>> rows =
    await db.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
      ''',
    );

    final Set<String> actualTables =
    <String>{};

    for (final Map<String, Object?> row
    in rows) {
      final Object? rawName =
      row['name'];

      if (rawName is String) {
        final String name =
        rawName.trim();

        if (name.isNotEmpty) {
          actualTables.add(
            name,
          );
        }
      }
    }

    final Set<String> missingTables =
    requiredTables.difference(
      actualTables,
    );

    if (missingTables.isNotEmpty) {
      throw StateError(
        'Database schema is missing required tables: '
            '${missingTables.join(', ')}.',
      );
    }
  }

  // ============================================================
  // CRITICAL COLUMNS
  // ============================================================

  Future<void> _verifyCriticalColumns(
      Database db,
      ) async {
    const Map<String, Set<String>>
    requiredColumns =
    <String, Set<String>>{
      'users': <String>{
        'id',
        'name',
      },

      'skills': <String>{
        'id',
        'owner_user_id',
        'title',
      },

      'skill_learnings': <String>{
        'skill_id',
        'position',
        'text',
      },

      'user_skills': <String>{
        'id',
        'user_id',
        'skill_id',
        'type',
      },

      'conversations': <String>{
        'id',
        'participant_user_id',
        'user_name',
      },

      'messages': <String>{
        'id',
        'conversation_id',
        'text',
        'sender_user_id',
        'sent_at',
      },

      'swap_requests': <String>{
        'id',
        'requester_user_id',
        'provider_user_id',
        'skill_to_learn_id',
        'skill_to_offer_id',
        'status',
      },

      'conversation_user_visibility':
      <String>{
        'conversation_id',
        'user_id',
        'is_hidden',
        'hidden_at',
      },

      'swap_request_user_visibility':
      <String>{
        'swap_request_id',
        'user_id',
        'is_hidden',
        'hidden_at',
      },
    };

    for (final MapEntry<String, Set<String>>
    entry
    in requiredColumns.entries) {
      final List<Map<String, Object?>> rows =
      await db.rawQuery(
        'PRAGMA table_info(${entry.key})',
      );

      if (rows.isEmpty) {
        throw StateError(
          'Could not inspect table "${entry.key}".',
        );
      }

      final Set<String> actualColumns =
      <String>{};

      for (final Map<String, Object?> row
      in rows) {
        final Object? rawName =
        row['name'];

        if (rawName is! String) {
          throw StateError(
            'Table "${entry.key}" contains '
                'an invalid column definition.',
          );
        }

        final String name =
        rawName.trim();

        if (name.isEmpty) {
          throw StateError(
            'Table "${entry.key}" contains '
                'an empty column name.',
          );
        }

        actualColumns.add(
          name,
        );
      }

      final Set<String> missingColumns =
      entry.value.difference(
        actualColumns,
      );

      if (missingColumns.isNotEmpty) {
        throw StateError(
          'Table "${entry.key}" is missing '
              'required columns: '
              '${missingColumns.join(', ')}.',
        );
      }
    }
  }

  // ============================================================
  // CRITICAL INDEXES
  // ============================================================

  Future<void> _verifyCriticalIndexes(
      Database db,
      ) async {
    const Set<String> requiredIndexes =
    <String>{
      'idx_messages_conversation',
      'idx_messages_sender_user',
      'idx_swap_requests_requester',
      'idx_swap_requests_provider',
      'idx_swap_requests_unique_active_exchange',
      'idx_skills_owner_user',
      'idx_conversations_participant_user',
      'idx_conversation_visibility_user_hidden',
      'idx_swap_visibility_user_hidden',
    };

    final List<Map<String, Object?>> rows =
    await db.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'index'
      ''',
    );

    final Set<String> actualIndexes =
    <String>{};

    for (final Map<String, Object?> row
    in rows) {
      final Object? rawName =
      row['name'];

      if (rawName is String) {
        final String name =
        rawName.trim();

        if (name.isNotEmpty) {
          actualIndexes.add(
            name,
          );
        }
      }
    }

    final Set<String> missingIndexes =
    requiredIndexes.difference(
      actualIndexes,
    );

    if (missingIndexes.isNotEmpty) {
      throw StateError(
        'Database schema is missing required indexes: '
            '${missingIndexes.join(', ')}.',
      );
    }
  }

  // ============================================================
  // FOREIGN KEY DATA CHECK
  // ============================================================

  Future<void> _verifyForeignKeyIntegrity(
      Database db,
      ) async {
    final List<Map<String, Object?>>
    violations =
    await db.rawQuery(
      'PRAGMA foreign_key_check',
    );

    if (violations.isNotEmpty) {
      throw StateError(
        'Database contains invalid foreign-key relationships.',
      );
    }
  }

  // ============================================================
  // SQLITE QUICK CHECK
  // ============================================================

  Future<void> _verifyQuickCheck(
      Database db,
      ) async {
    final List<Map<String, Object?>> rows =
    await db.rawQuery(
      'PRAGMA quick_check',
    );

    if (rows.length != 1 ||
        rows.first.isEmpty) {
      throw StateError(
        'SQLite database integrity could not be verified.',
      );
    }

    final Object? rawResult =
        rows.first.values.first;

    if (rawResult is! String ||
        rawResult.trim().toLowerCase() !=
            'ok') {
      throw StateError(
        'SQLite database integrity check failed.',
      );
    }
  }

  int? _readExactDatabaseInteger(
      Object? value,
      ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      final double number =
      value.toDouble();

      if (!number.isFinite ||
          number !=
              number.truncateToDouble()) {
        return null;
      }

      return number.toInt();
    }

    if (value is String) {
      return int.tryParse(
        value.trim(),
      );
    }

    return null;
  }

  // ============================================================
  // VERSION 5 - REFERENCE / PROFILE TABLES
  // ============================================================

  Future<void> _createReferenceTablesV5(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE TABLE users (
        id TEXT PRIMARY KEY
          CHECK(length(trim(id)) > 0),

        name TEXT NOT NULL
          CHECK(length(trim(name)) > 0),

        initials TEXT NOT NULL
          CHECK(length(trim(initials)) > 0),

        city TEXT NOT NULL
          CHECK(length(trim(city)) > 0),

        bio TEXT NOT NULL,

        rating REAL NOT NULL DEFAULT 0
          CHECK(rating >= 0 AND rating <= 5),

        review_count INTEGER NOT NULL DEFAULT 0
          CHECK(review_count >= 0),

        completed_swaps INTEGER NOT NULL DEFAULT 0
          CHECK(completed_swaps >= 0),

        response_rate INTEGER NOT NULL DEFAULT 0
          CHECK(
            response_rate >= 0
            AND response_rate <= 100
          ),

        member_since TEXT NOT NULL
          CHECK(length(trim(member_since)) > 0),

        availability TEXT NOT NULL
          CHECK(length(trim(availability)) > 0),

        language TEXT NOT NULL
          CHECK(length(trim(language)) > 0),

        preferred_mode TEXT NOT NULL
          CHECK(length(trim(preferred_mode)) > 0),

        teaching_style TEXT NOT NULL
          CHECK(length(trim(teaching_style)) > 0),

        email_verified INTEGER NOT NULL DEFAULT 0
          CHECK(email_verified IN (0, 1)),

        profile_completed INTEGER NOT NULL DEFAULT 0
          CHECK(profile_completed IN (0, 1))
      )
      ''',
    );

    await db.execute(
      '''
      CREATE TABLE skills (
        id TEXT PRIMARY KEY
          CHECK(length(trim(id)) > 0),

        owner_user_id TEXT,

        title TEXT NOT NULL
          CHECK(length(trim(title)) > 0),

        category TEXT NOT NULL
          CHECK(length(trim(category)) > 0),

        level TEXT NOT NULL
          CHECK(length(trim(level)) > 0),

        icon_code_point INTEGER NOT NULL
          CHECK(icon_code_point > 0),

        session_length TEXT NOT NULL
          CHECK(length(trim(session_length)) > 0),

        mode TEXT NOT NULL
          CHECK(length(trim(mode)) > 0),

        language TEXT NOT NULL
          CHECK(length(trim(language)) > 0),

        prerequisite TEXT NOT NULL,

        description TEXT NOT NULL
          CHECK(length(trim(description)) > 0),

        UNIQUE(title),

        FOREIGN KEY (owner_user_id)
        REFERENCES users(id)
        ON DELETE SET NULL
      )
      ''',
    );

    await db.execute(
      '''
      CREATE TABLE skill_learnings (
        skill_id TEXT NOT NULL
          CHECK(length(trim(skill_id)) > 0),

        position INTEGER NOT NULL
          CHECK(position >= 0),

        text TEXT NOT NULL
          CHECK(length(trim(text)) > 0),

        PRIMARY KEY (
          skill_id,
          position
        ),

        FOREIGN KEY (skill_id)
        REFERENCES skills(id)
        ON DELETE CASCADE
      )
      ''',
    );

    await db.execute(
      '''
      CREATE TABLE user_skills (
        id TEXT PRIMARY KEY
          CHECK(length(trim(id)) > 0),

        user_id TEXT NOT NULL
          CHECK(length(trim(user_id)) > 0),

        skill_id TEXT NOT NULL
          CHECK(length(trim(skill_id)) > 0),

        type TEXT NOT NULL
          CHECK(
            type IN (
              'offered',
              'wanted'
            )
          ),

        level TEXT NOT NULL
          CHECK(length(trim(level)) > 0),

        availability TEXT NOT NULL
          CHECK(length(trim(availability)) > 0),

        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

        FOREIGN KEY (skill_id)
        REFERENCES skills(id)
        ON DELETE CASCADE,

        UNIQUE(
          user_id,
          skill_id,
          type
        )
      )
      ''',
    );

    await _createReferenceIndexesV5(
      db,
    );
  }

  // ============================================================
  // VERSION 5 - INITIAL REFERENCE DATA
  // ============================================================

  Future<void> _seedReferenceDataV5(
      Database db,
      ) async {
    for (final Map<String, Object?> user
    in ReferenceSeedData.users) {
      await db.insert(
        'users',
        user,
        conflictAlgorithm:
        ConflictAlgorithm.ignore,
      );
    }

    for (final Map<String, Object?> skill
    in ReferenceSeedData.skills) {
      await db.insert(
        'skills',
        skill,
        conflictAlgorithm:
        ConflictAlgorithm.ignore,
      );
    }

    for (final Map<String, Object?> learning
    in ReferenceSeedData.skillLearnings) {
      await db.insert(
        'skill_learnings',
        learning,
        conflictAlgorithm:
        ConflictAlgorithm.ignore,
      );
    }

    for (final Map<String, Object?> userSkill
    in ReferenceSeedData.userSkills) {
      await db.insert(
        'user_skills',
        userSkill,
        conflictAlgorithm:
        ConflictAlgorithm.ignore,
      );
    }
  }

  // ============================================================
  // MIGRATION TO VERSION 5
  // ============================================================

  Future<void> _migrateToVersion5(
      Database db,
      ) async {
    await _createReferenceTablesV5(
      db,
    );

    await _seedReferenceDataV5(
      db,
    );
  }

  // ============================================================
  // VERSION 5 INDEXES
  // ============================================================

  Future<void> _createReferenceIndexesV5(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_users_name
      ON users(name)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_users_city
      ON users(city)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_skills_category
      ON skills(category)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_skill_learnings_skill
      ON skill_learnings(skill_id)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_user_skills_user
      ON user_skills(user_id)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_user_skills_skill
      ON user_skills(skill_id)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_user_skills_type
      ON user_skills(type)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_user_skills_skill_type
      ON user_skills(
        skill_id,
        type
      )
      ''',
    );
  }

  // ============================================================
  // CONVERSATION TABLES
  // ============================================================

  Future<void> _createConversationTablesV3(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY
          CHECK(length(trim(id)) > 0),

        participant_user_id TEXT
          CHECK(
            participant_user_id IS NULL
            OR length(trim(participant_user_id)) > 0
          ),

        user_name TEXT NOT NULL
          CHECK(length(trim(user_name)) > 0),

        initials TEXT NOT NULL
          CHECK(length(trim(initials)) > 0),

        city TEXT NOT NULL
          CHECK(length(trim(city)) > 0),

        skill_wanted TEXT NOT NULL
          CHECK(length(trim(skill_wanted)) > 0),

        skill_offered TEXT NOT NULL
          CHECK(length(trim(skill_offered)) > 0),

        status TEXT NOT NULL
          CHECK(length(trim(status)) > 0),

        FOREIGN KEY (participant_user_id)
        REFERENCES users(id)
        ON DELETE SET NULL
      )
      ''',
    );

    await db.execute(
      '''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY
          CHECK(length(trim(id)) > 0),

        conversation_id TEXT NOT NULL
          CHECK(length(trim(conversation_id)) > 0),

        text TEXT NOT NULL
          CHECK(length(trim(text)) > 0),

        sender_user_id TEXT
          CHECK(
            sender_user_id IS NULL
            OR length(trim(sender_user_id)) > 0
          ),

        sent_at INTEGER NOT NULL
          CHECK(sent_at > 0),

        FOREIGN KEY (conversation_id)
        REFERENCES conversations(id)
        ON DELETE CASCADE,

        FOREIGN KEY (sender_user_id)
        REFERENCES users(id)
        ON DELETE SET NULL
      )
      ''',
    );

    await _createMessageIndexes(
      db,
    );

    await _createMessageSenderIndexV9(
      db,
    );
  }

  // ============================================================
  // VERSION 2 - LEGACY SWAP TABLE
  // ============================================================

  Future<void> _createSwapTablesV2(
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

    await _createSwapIndexesV3(
      db,
    );
  }

  // ============================================================
  // VERSION 4 - ID-BASED SWAP TABLE
  // ============================================================

  Future<void> _createSwapTablesV4(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE TABLE swap_requests (
        id TEXT PRIMARY KEY
          CHECK(length(trim(id)) > 0),

        requester_user_id TEXT
          CHECK(
            requester_user_id IS NULL
            OR length(trim(requester_user_id)) > 0
          ),

        provider_user_id TEXT
          CHECK(
            provider_user_id IS NULL
            OR length(trim(provider_user_id)) > 0
          ),

        skill_to_learn_id TEXT
          CHECK(
            skill_to_learn_id IS NULL
            OR length(trim(skill_to_learn_id)) > 0
          ),

        skill_to_offer_id TEXT
          CHECK(
            skill_to_offer_id IS NULL
            OR length(trim(skill_to_offer_id)) > 0
          ),

        provider_name TEXT NOT NULL
          CHECK(length(trim(provider_name)) > 0),

        provider_initials TEXT NOT NULL
          CHECK(length(trim(provider_initials)) > 0),

        provider_city TEXT NOT NULL
          CHECK(length(trim(provider_city)) > 0),

        skill_to_learn TEXT NOT NULL
          CHECK(length(trim(skill_to_learn)) > 0),

        skill_to_offer TEXT NOT NULL
          CHECK(length(trim(skill_to_offer)) > 0),

        proposed_at INTEGER NOT NULL
          CHECK(proposed_at > 0),

        mode TEXT NOT NULL
          CHECK(
            mode IN (
              'Online',
              'In-person'
            )
          ),

        meeting_details TEXT
          CHECK(
            meeting_details IS NULL
            OR (
              length(trim(meeting_details)) > 0
              AND length(meeting_details) <= 150
            )
          ),

        note TEXT
          CHECK(
            note IS NULL
            OR length(note) <= 300
          ),

        status TEXT NOT NULL
          CHECK(
            status IN (
              'pending',
              'accepted',
              'declined',
              'scheduled',
              'completed',
              'cancelled'
            )
          ),

        created_at INTEGER NOT NULL
          CHECK(created_at > 0),

        updated_at INTEGER NOT NULL
          CHECK(updated_at > 0),

        CHECK(
          requester_user_id IS NULL
          OR provider_user_id IS NULL
          OR requester_user_id != provider_user_id
        ),

        CHECK(
          skill_to_learn_id IS NULL
          OR skill_to_offer_id IS NULL
          OR skill_to_learn_id != skill_to_offer_id
        )
      )
      ''',
    );

    await _createSwapIndexesV4(
      db,
    );
  }

  // ============================================================
  // MIGRATION TO VERSION 3
  // ============================================================

  Future<void> _migrateToVersion3(
      Database db,
      ) async {
    await _migrateMessagesToV3(
      db,
    );

    await _migrateSwapRequestsToV3(
      db,
    );
  }

  // ============================================================
  // MIGRATE MESSAGES TO V3
  // ============================================================

  Future<void> _migrateMessagesToV3(
      Database db,
      ) async {
    await db.execute(
      '''
      ALTER TABLE messages
      RENAME TO messages_v2_backup
      ''',
    );

    await db.execute(
      '''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY
          CHECK(length(trim(id)) > 0),

        conversation_id TEXT NOT NULL
          CHECK(length(trim(conversation_id)) > 0),

        text TEXT NOT NULL
          CHECK(length(trim(text)) > 0),

        is_me INTEGER NOT NULL
          CHECK(is_me IN (0, 1)),

        sent_at INTEGER NOT NULL
          CHECK(sent_at > 0),

        FOREIGN KEY (conversation_id)
        REFERENCES conversations(id)
        ON DELETE CASCADE
      )
      ''',
    );

    await db.execute(
      '''
      INSERT INTO messages (
        id,
        conversation_id,
        text,
        is_me,
        sent_at
      )
      SELECT
        id,
        conversation_id,
        text,
        is_me,
        sent_at
      FROM messages_v2_backup
      ''',
    );

    await db.execute(
      '''
      DROP TABLE messages_v2_backup
      ''',
    );

    await _createMessageIndexes(
      db,
    );
  }

  // ============================================================
  // MIGRATE SWAP REQUESTS TO V3
  // ============================================================

  Future<void> _migrateSwapRequestsToV3(
      Database db,
      ) async {
    await db.execute(
      '''
      ALTER TABLE swap_requests
      RENAME TO swap_requests_v2_backup
      ''',
    );

    await _createSwapTablesV3WithoutIndexes(
      db,
    );

    await db.execute(
      '''
      INSERT INTO swap_requests (
        id,
        provider_name,
        provider_initials,
        provider_city,
        skill_to_learn,
        skill_to_offer,
        proposed_at,
        mode,
        meeting_details,
        note,
        status,
        created_at,
        updated_at
      )
      SELECT
        id,
        provider_name,
        provider_initials,
        provider_city,
        skill_to_learn,
        skill_to_offer,
        proposed_at,
        mode,
        meeting_details,
        note,
        status,
        created_at,
        updated_at
      FROM swap_requests_v2_backup
      ''',
    );

    await db.execute(
      '''
      DROP TABLE swap_requests_v2_backup
      ''',
    );

    await _createSwapIndexesV3(
      db,
    );
  }

  Future<void>
  _createSwapTablesV3WithoutIndexes(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE TABLE swap_requests (
        id TEXT PRIMARY KEY
          CHECK(length(trim(id)) > 0),

        provider_name TEXT NOT NULL
          CHECK(length(trim(provider_name)) > 0),

        provider_initials TEXT NOT NULL
          CHECK(length(trim(provider_initials)) > 0),

        provider_city TEXT NOT NULL
          CHECK(length(trim(provider_city)) > 0),

        skill_to_learn TEXT NOT NULL
          CHECK(length(trim(skill_to_learn)) > 0),

        skill_to_offer TEXT NOT NULL
          CHECK(length(trim(skill_to_offer)) > 0),

        proposed_at INTEGER NOT NULL
          CHECK(proposed_at > 0),

        mode TEXT NOT NULL
          CHECK(
            mode IN (
              'Online',
              'In-person'
            )
          ),

        meeting_details TEXT
          CHECK(
            meeting_details IS NULL
            OR (
              length(trim(meeting_details)) > 0
              AND length(meeting_details) <= 150
            )
          ),

        note TEXT
          CHECK(
            note IS NULL
            OR length(note) <= 300
          ),

        status TEXT NOT NULL
          CHECK(
            status IN (
              'pending',
              'accepted',
              'declined',
              'scheduled',
              'completed',
              'cancelled'
            )
          ),

        created_at INTEGER NOT NULL
          CHECK(created_at > 0),

        updated_at INTEGER NOT NULL
          CHECK(updated_at > 0)
      )
      ''',
    );
  }

  // ============================================================
  // MIGRATION TO VERSION 4
  // ============================================================

  Future<void> _migrateToVersion4(
      Database db,
      ) async {
    await db.execute(
      '''
      ALTER TABLE swap_requests
      RENAME TO swap_requests_v3_backup
      ''',
    );

    await _createSwapTablesV4WithoutIndexes(
      db,
    );

    await db.execute(
      '''
      INSERT INTO swap_requests (
        id,
        requester_user_id,
        provider_user_id,
        skill_to_learn_id,
        skill_to_offer_id,
        provider_name,
        provider_initials,
        provider_city,
        skill_to_learn,
        skill_to_offer,
        proposed_at,
        mode,
        meeting_details,
        note,
        status,
        created_at,
        updated_at
      )
      SELECT
        id,

        'user_joice_local',

        CASE lower(trim(provider_name))
          WHEN 'mika santos'
            THEN 'user_mika_santos'
          WHEN 'paolo reyes'
            THEN 'user_paolo_reyes'
          WHEN 'alex rivera'
            THEN 'user_alex_rivera'
          WHEN 'bea mendoza'
            THEN 'user_bea_mendoza'
          WHEN 'carlo dela cruz'
            THEN 'user_carlo_dela_cruz'
          WHEN 'jamie garcia'
            THEN 'user_jamie_garcia'
          WHEN 'nico villanueva'
            THEN 'user_nico_villanueva'
          WHEN 'joshua lim'
            THEN 'user_joshua_lim'
          WHEN 'andrea flores'
            THEN 'user_andrea_flores'
          ELSE NULL
        END,

        CASE lower(trim(skill_to_learn))
          WHEN 'graphic design'
            THEN 'skill_graphic_design'
          WHEN 'photography'
            THEN 'skill_photography'
          WHEN 'video editing'
            THEN 'skill_video_editing'
          WHEN 'ui/ux design'
            THEN 'skill_ui_ux_design'
          WHEN 'basic web development'
            THEN 'skill_basic_web_development'
          WHEN 'english conversation'
            THEN 'skill_english_conversation'
          WHEN 'basic excel'
            THEN 'skill_basic_excel'
          WHEN 'public speaking'
            THEN 'skill_public_speaking'
          WHEN 'basic guitar'
            THEN 'skill_basic_guitar'
          WHEN 'canva design'
            THEN 'skill_canva_design'
          ELSE NULL
        END,

        CASE lower(trim(skill_to_offer))
          WHEN 'graphic design'
            THEN 'skill_graphic_design'
          WHEN 'photography'
            THEN 'skill_photography'
          WHEN 'video editing'
            THEN 'skill_video_editing'
          WHEN 'ui/ux design'
            THEN 'skill_ui_ux_design'
          WHEN 'basic web development'
            THEN 'skill_basic_web_development'
          WHEN 'english conversation'
            THEN 'skill_english_conversation'
          WHEN 'basic excel'
            THEN 'skill_basic_excel'
          WHEN 'public speaking'
            THEN 'skill_public_speaking'
          WHEN 'basic guitar'
            THEN 'skill_basic_guitar'
          WHEN 'canva design'
            THEN 'skill_canva_design'
          ELSE NULL
        END,

        provider_name,
        provider_initials,
        provider_city,

        skill_to_learn,
        skill_to_offer,

        proposed_at,

        mode,

        meeting_details,
        note,

        status,

        created_at,
        updated_at

      FROM swap_requests_v3_backup
      ''',
    );

    await db.execute(
      '''
      DROP TABLE swap_requests_v3_backup
      ''',
    );

    await _createSwapIndexesV4(
      db,
    );
  }

  // ============================================================
  // VERSION 4 TABLE WITHOUT INDEXES
  // ============================================================

  Future<void>
  _createSwapTablesV4WithoutIndexes(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE TABLE swap_requests (
        id TEXT PRIMARY KEY
          CHECK(length(trim(id)) > 0),

        requester_user_id TEXT
          CHECK(
            requester_user_id IS NULL
            OR length(trim(requester_user_id)) > 0
          ),

        provider_user_id TEXT
          CHECK(
            provider_user_id IS NULL
            OR length(trim(provider_user_id)) > 0
          ),

        skill_to_learn_id TEXT
          CHECK(
            skill_to_learn_id IS NULL
            OR length(trim(skill_to_learn_id)) > 0
          ),

        skill_to_offer_id TEXT
          CHECK(
            skill_to_offer_id IS NULL
            OR length(trim(skill_to_offer_id)) > 0
          ),

        provider_name TEXT NOT NULL
          CHECK(length(trim(provider_name)) > 0),

        provider_initials TEXT NOT NULL
          CHECK(length(trim(provider_initials)) > 0),

        provider_city TEXT NOT NULL
          CHECK(length(trim(provider_city)) > 0),

        skill_to_learn TEXT NOT NULL
          CHECK(length(trim(skill_to_learn)) > 0),

        skill_to_offer TEXT NOT NULL
          CHECK(length(trim(skill_to_offer)) > 0),

        proposed_at INTEGER NOT NULL
          CHECK(proposed_at > 0),

        mode TEXT NOT NULL
          CHECK(
            mode IN (
              'Online',
              'In-person'
            )
          ),

        meeting_details TEXT
          CHECK(
            meeting_details IS NULL
            OR (
              length(trim(meeting_details)) > 0
              AND length(meeting_details) <= 150
            )
          ),

        note TEXT
          CHECK(
            note IS NULL
            OR length(note) <= 300
          ),

        status TEXT NOT NULL
          CHECK(
            status IN (
              'pending',
              'accepted',
              'declined',
              'scheduled',
              'completed',
              'cancelled'
            )
          ),

        created_at INTEGER NOT NULL
          CHECK(created_at > 0),

        updated_at INTEGER NOT NULL
          CHECK(updated_at > 0),

        CHECK(
          requester_user_id IS NULL
          OR provider_user_id IS NULL
          OR requester_user_id != provider_user_id
        ),

        CHECK(
          skill_to_learn_id IS NULL
          OR skill_to_offer_id IS NULL
          OR skill_to_learn_id != skill_to_offer_id
        )
      )
      ''',
    );
  }

  // ============================================================
  // MIGRATION TO VERSION 6
  // ============================================================

  Future<void> _migrateToVersion6(
      Database db,
      ) async {
    await _assertNoDuplicateActiveSwaps(
      db,
    );

    await _createSwapIndexesV6(
      db,
    );
  }

  Future<void> _assertNoDuplicateActiveSwaps(
      Database db,
      ) async {
    final List<Map<String, Object?>> duplicates =
    await db.rawQuery(
      '''
      SELECT
        requester_user_id,
        provider_user_id,
        skill_to_learn_id,
        skill_to_offer_id,
        COUNT(*) AS duplicate_count
      FROM swap_requests
      WHERE
        requester_user_id IS NOT NULL
        AND provider_user_id IS NOT NULL
        AND skill_to_learn_id IS NOT NULL
        AND skill_to_offer_id IS NOT NULL
        AND status IN (
          'pending',
          'accepted',
          'scheduled'
        )
      GROUP BY
        requester_user_id,
        provider_user_id,
        skill_to_learn_id,
        skill_to_offer_id
      HAVING COUNT(*) > 1
      ''',
    );

    if (duplicates.isNotEmpty) {
      throw StateError(
        'Cannot migrate database to version 6 because '
            'duplicate active swap requests already exist. '
            'No records were deleted. Resolve the duplicates '
            'before retrying the migration.',
      );
    }
  }

  // ============================================================
  // MIGRATION TO VERSION 7
  // ============================================================

  Future<void> _migrateToVersion7(
      Database db,
      ) async {
    final List<Map<String, Object?>> columns =
    await db.rawQuery(
      '''
      PRAGMA table_info(skills)
      ''',
    );

    final bool alreadyHasOwner =
    columns.any(
          (column) =>
      column['name'] ==
          'owner_user_id',
    );

    if (!alreadyHasOwner) {
      await db.execute(
        '''
        ALTER TABLE skills
        ADD COLUMN owner_user_id TEXT
          REFERENCES users(id)
          ON DELETE SET NULL
        ''',
      );
    }

    await _createSkillOwnershipIndexesV7(
      db,
    );
  }

  // ============================================================
  // MIGRATION TO VERSION 8
  // ============================================================

  Future<void> _migrateToVersion8(
      Database db,
      ) async {
    final List<Map<String, Object?>> columns =
    await db.rawQuery(
      '''
      PRAGMA table_info(conversations)
      ''',
    );

    final bool alreadyHasParticipant =
    columns.any(
          (column) =>
      column['name'] ==
          'participant_user_id',
    );

    if (!alreadyHasParticipant) {
      await db.execute(
        '''
        ALTER TABLE conversations
        ADD COLUMN participant_user_id TEXT
          REFERENCES users(id)
          ON DELETE SET NULL
        ''',
      );
    }

    await db.execute(
      '''
      UPDATE conversations
      SET participant_user_id =
        CASE lower(trim(user_name))
          WHEN 'mika santos'
            THEN 'user_mika_santos'
          WHEN 'paolo reyes'
            THEN 'user_paolo_reyes'
          WHEN 'alex rivera'
            THEN 'user_alex_rivera'
          WHEN 'bea mendoza'
            THEN 'user_bea_mendoza'
          WHEN 'carlo dela cruz'
            THEN 'user_carlo_dela_cruz'
          WHEN 'jamie garcia'
            THEN 'user_jamie_garcia'
          WHEN 'nico villanueva'
            THEN 'user_nico_villanueva'
          WHEN 'joshua lim'
            THEN 'user_joshua_lim'
          WHEN 'andrea flores'
            THEN 'user_andrea_flores'
          ELSE participant_user_id
        END
      WHERE participant_user_id IS NULL
      ''',
    );

    await _createConversationIndexesV8(
      db,
    );
  }

  // ============================================================
  // MIGRATION TO VERSION 9
  // ============================================================

  Future<void> _migrateToVersion9(
      Database db,
      ) async {
    final List<Map<String, Object?>> columns =
    await db.rawQuery(
      '''
      PRAGMA table_info(messages)
      ''',
    );

    final bool alreadyHasSenderUserId =
    columns.any(
          (column) =>
      column['name'] ==
          'sender_user_id',
    );

    if (alreadyHasSenderUserId) {
      await _createMessageSenderIndexV9(
        db,
      );

      return;
    }

    final bool hasLegacyIsMe =
    columns.any(
          (column) =>
      column['name'] ==
          'is_me',
    );

    if (!hasLegacyIsMe) {
      throw StateError(
        'Cannot migrate messages to version 9 because '
            'neither sender_user_id nor legacy is_me exists.',
      );
    }

    await db.transaction(
          (
          txn,
          ) async {
        await txn.execute(
          '''
          ALTER TABLE messages
          RENAME TO messages_v8_backup
          ''',
        );

        await txn.execute(
          '''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY
              CHECK(length(trim(id)) > 0),

            conversation_id TEXT NOT NULL
              CHECK(length(trim(conversation_id)) > 0),

            text TEXT NOT NULL
              CHECK(length(trim(text)) > 0),

            sender_user_id TEXT
              CHECK(
                sender_user_id IS NULL
                OR length(trim(sender_user_id)) > 0
              ),

            sent_at INTEGER NOT NULL
              CHECK(sent_at > 0),

            FOREIGN KEY (conversation_id)
            REFERENCES conversations(id)
            ON DELETE CASCADE,

            FOREIGN KEY (sender_user_id)
            REFERENCES users(id)
            ON DELETE SET NULL
          )
          ''',
        );

        await txn.execute(
          '''
          INSERT INTO messages (
            id,
            conversation_id,
            text,
            sender_user_id,
            sent_at
          )
          SELECT
            legacy.id,
            legacy.conversation_id,
            legacy.text,

            CASE
              WHEN legacy.is_me = 1
                THEN 'user_joice_local'

              WHEN legacy.is_me = 0
                THEN conversations.participant_user_id

              ELSE NULL
            END,

            legacy.sent_at

          FROM messages_v8_backup AS legacy

          LEFT JOIN conversations
            ON conversations.id =
               legacy.conversation_id
          ''',
        );

        await txn.execute(
          '''
          DROP TABLE messages_v8_backup
          ''',
        );
      },
    );

    await _createMessageIndexes(
      db,
    );

    await _createMessageSenderIndexV9(
      db,
    );
  }

  // ============================================================
  // VERSION 10 - PER-USER VISIBILITY
  // ============================================================

  Future<void> _migrateToVersion10(
      Database db,
      ) async {
    await _createUserVisibilityTablesV10(
      db,
    );
  }

  Future<void> _createUserVisibilityTablesV10(
      Database db,
      ) async {
    // ----------------------------------------------------------
    // CONVERSATION VISIBILITY
    //
    // A conversation remains stored globally, but each user may
    // hide it independently.
    //
    // This is intentionally separate from the conversation row.
    // One participant hiding a conversation must never erase
    // another participant's history.
    // ----------------------------------------------------------

    await db.execute(
      '''
      CREATE TABLE IF NOT EXISTS
      conversation_user_visibility (
        conversation_id TEXT NOT NULL
          CHECK(length(trim(conversation_id)) > 0),

        user_id TEXT NOT NULL
          CHECK(length(trim(user_id)) > 0),

        is_hidden INTEGER NOT NULL DEFAULT 0
          CHECK(is_hidden IN (0, 1)),

        hidden_at INTEGER
          CHECK(
            hidden_at IS NULL
            OR hidden_at > 0
          ),

        PRIMARY KEY (
          conversation_id,
          user_id
        ),

        CHECK(
          (
            is_hidden = 0
            AND hidden_at IS NULL
          )
          OR
          (
            is_hidden = 1
            AND hidden_at IS NOT NULL
          )
        ),

        FOREIGN KEY (conversation_id)
        REFERENCES conversations(id)
        ON DELETE CASCADE,

        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
      )
      ''',
    );

    // ----------------------------------------------------------
    // SWAP VISIBILITY
    //
    // Swap records remain preserved for history/auditing.
    // Participants may hide the record from their own UI without
    // globally deleting the underlying swap.
    // ----------------------------------------------------------

    await db.execute(
      '''
      CREATE TABLE IF NOT EXISTS
      swap_request_user_visibility (
        swap_request_id TEXT NOT NULL
          CHECK(length(trim(swap_request_id)) > 0),

        user_id TEXT NOT NULL
          CHECK(length(trim(user_id)) > 0),

        is_hidden INTEGER NOT NULL DEFAULT 0
          CHECK(is_hidden IN (0, 1)),

        hidden_at INTEGER
          CHECK(
            hidden_at IS NULL
            OR hidden_at > 0
          ),

        PRIMARY KEY (
          swap_request_id,
          user_id
        ),

        CHECK(
          (
            is_hidden = 0
            AND hidden_at IS NULL
          )
          OR
          (
            is_hidden = 1
            AND hidden_at IS NOT NULL
          )
        ),

        FOREIGN KEY (swap_request_id)
        REFERENCES swap_requests(id)
        ON DELETE CASCADE,

        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
      )
      ''',
    );

    await _createUserVisibilityIndexesV10(
      db,
    );
  }

  Future<void> _createUserVisibilityIndexesV10(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_conversation_visibility_user_hidden
      ON conversation_user_visibility(
        user_id,
        is_hidden
      )
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_swap_visibility_user_hidden
      ON swap_request_user_visibility(
        user_id,
        is_hidden
      )
      ''',
    );
  }

  // ============================================================
  // MESSAGE INDEXES
  // ============================================================

  Future<void> _createMessageIndexes(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_messages_conversation
      ON messages(conversation_id)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_messages_sent_at
      ON messages(sent_at)
      ''',
    );
  }

  // ============================================================
  // VERSION 9 MESSAGE SENDER INDEX
  // ============================================================

  Future<void> _createMessageSenderIndexV9(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_messages_sender_user
      ON messages(sender_user_id)
      ''',
    );
  }

  // ============================================================
  // VERSION 3 SWAP INDEXES
  // ============================================================

  Future<void> _createSwapIndexesV3(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_swap_requests_status
      ON swap_requests(status)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_swap_requests_created_at
      ON swap_requests(created_at)
      ''',
    );
  }

  // ============================================================
  // VERSION 4 SWAP INDEXES
  // ============================================================

  Future<void> _createSwapIndexesV4(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_swap_requests_status
      ON swap_requests(status)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_swap_requests_created_at
      ON swap_requests(created_at)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_swap_requests_requester
      ON swap_requests(requester_user_id)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_swap_requests_provider
      ON swap_requests(provider_user_id)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_swap_requests_learn_skill
      ON swap_requests(skill_to_learn_id)
      ''',
    );

    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_swap_requests_offer_skill
      ON swap_requests(skill_to_offer_id)
      ''',
    );
  }

  // ============================================================
  // VERSION 6 SWAP INDEXES
  // ============================================================

  Future<void> _createSwapIndexesV6(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE UNIQUE INDEX IF NOT EXISTS
      idx_swap_requests_unique_active_exchange
      ON swap_requests (
        requester_user_id,
        provider_user_id,
        skill_to_learn_id,
        skill_to_offer_id
      )
      WHERE
        requester_user_id IS NOT NULL
        AND provider_user_id IS NOT NULL
        AND skill_to_learn_id IS NOT NULL
        AND skill_to_offer_id IS NOT NULL
        AND status IN (
          'pending',
          'accepted',
          'scheduled'
        )
      ''',
    );
  }

  // ============================================================
  // VERSION 7 SKILL OWNERSHIP INDEX
  // ============================================================

  Future<void> _createSkillOwnershipIndexesV7(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_skills_owner_user
      ON skills(owner_user_id)
      ''',
    );
  }

  // ============================================================
  // VERSION 8 CONVERSATION PARTICIPANT INDEX
  // ============================================================

  Future<void> _createConversationIndexesV8(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_conversations_participant_user
      ON conversations(participant_user_id)
      ''',
    );
  }

  // ============================================================
  // CLOSE DATABASE
  // ============================================================

  Future<void> close() {
    final Future<void>? existingClose =
        _closingFuture;

    if (existingClose != null) {
      return existingClose;
    }

    late final Future<void> closing;

    closing =
        _closeInternal();

    _closingFuture =
        closing;

    return closing.whenComplete(
          () {
        if (identical(
          _closingFuture,
          closing,
        )) {
          _closingFuture =
          null;
        }
      },
    );
  }

  Future<void> _closeInternal() async {
    final Future<Database>? opening =
        _openingFuture;

    if (opening != null) {
      try {
        await opening;
      } catch (_) {
        // Failed database opening already cleans up
        // its partially opened connection.
      }
    }

    final Database? db =
        _database;

    _database =
    null;

    if (db != null &&
        db.isOpen) {
      await db.close();
    }
  }
}