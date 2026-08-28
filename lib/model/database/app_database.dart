import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance =
  AppDatabase._();

  static const String _databaseName =
      'tubilearn.db';

  static const int _databaseVersion = 4;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();

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

      onConfigure: (db) async {
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
        await _createConversationTablesV3(
          db,
        );

        await _createSwapTablesV4(
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
      },
    );
  }

  // ============================================================
  // VERSION 3 - CONVERSATION TABLES
  //
  // No conversation schema change is required in v4.
  // ============================================================

  Future<void> _createConversationTablesV3(
      Database db,
      ) async {
    await db.execute(
      '''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY
          CHECK(length(trim(id)) > 0),

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
          CHECK(length(trim(status)) > 0)
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

    await _createMessageIndexes(
      db,
    );
  }

  // ============================================================
  // VERSION 2 - LEGACY SWAP TABLE
  //
  // Used only when upgrading directly from v1.
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
  // VERSION 3 - HARDENED SWAP TABLE
  // ============================================================

  Future<void> _createSwapTablesV3(
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

    await _createSwapIndexesV3(
      db,
    );
  }

  // ============================================================
  // VERSION 4 - ID-BASED SWAP TABLE
  //
  // Stable IDs become the relationship identity.
  //
  // Display names/titles remain stored as snapshots so historical
  // requests remain readable even if profiles or skill names
  // change later.
  //
  // Identity columns remain nullable specifically for legacy rows
  // that cannot be safely mapped during migration.
  // New requests are required by SwapService to provide all IDs.
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

  Future<void> _createSwapTablesV3WithoutIndexes(
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

    // ----------------------------------------------------------
    // Create v4 without indexes first.
    //
    // The old indexes are still attached to the renamed backup
    // table until that table is dropped.
    // ----------------------------------------------------------

    await _createSwapTablesV4WithoutIndexes(
      db,
    );

    // ----------------------------------------------------------
    // Backfill legacy identity.
    //
    // All swap requests created before v4 came from the current
    // local TubiLearn prototype user, so requester identity is
    // safely backfilled to user_joice_local.
    //
    // Provider and skill IDs are mapped only when the existing
    // display value matches one of our known normalized records.
    // Unknown legacy values remain NULL rather than losing data.
    // ----------------------------------------------------------

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
  //
  // Used during migration while legacy indexes still belong to
  // the backup table.
  // ============================================================

  Future<void> _createSwapTablesV4WithoutIndexes(
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
  // CLOSE DATABASE
  // ============================================================

  Future<void> close() async {
    final Database? db =
        _database;

    if (db != null) {
      await db.close();

      _database = null;
    }
  }
}