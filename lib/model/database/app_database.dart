import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'reference_seed_data.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance =
  AppDatabase._();

  static const String _databaseName =
      'tubilearn.db';

  static const int _databaseVersion = 7;

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
      },
    );
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
  // VERSION 3 - CONVERSATION TABLES
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