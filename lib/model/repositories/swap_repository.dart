import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../swap_request.dart';

class SwapRepository {
  final AppDatabase _appDatabase =
      AppDatabase.instance;

  Future<List<SwapRequest>>
  getAllSwapRequests() async {
    final Database db =
    await _appDatabase.database;

    final rows = await db.query(
      'swap_requests',
      orderBy: 'created_at DESC',
    );

    return rows.map(
          (row) {
        return SwapRequest(
          id: row['id'] as String,

          providerName:
          row['provider_name'] as String,

          providerInitials:
          row['provider_initials'] as String,

          providerCity:
          row['provider_city'] as String,

          skillToLearn:
          row['skill_to_learn'] as String,

          skillToOffer:
          row['skill_to_offer'] as String,

          proposedAt:
          DateTime.fromMillisecondsSinceEpoch(
            row['proposed_at'] as int,
          ),

          mode:
          row['mode'] as String,

          meetingDetails:
          row['meeting_details'] as String?,

          note:
          row['note'] as String?,

          status:
          SwapRequestStatusExtension.fromDatabase(
            row['status'] as String,
          ),

          createdAt:
          DateTime.fromMillisecondsSinceEpoch(
            row['created_at'] as int,
          ),

          updatedAt:
          DateTime.fromMillisecondsSinceEpoch(
            row['updated_at'] as int,
          ),
        );
      },
    ).toList();
  }

  Future<void> saveSwapRequest(
      SwapRequest request,
      ) async {
    final Database db =
    await _appDatabase.database;

    await db.insert(
      'swap_requests',
      {
        'id':
        request.id,

        'provider_name':
        request.providerName,

        'provider_initials':
        request.providerInitials,

        'provider_city':
        request.providerCity,

        'skill_to_learn':
        request.skillToLearn,

        'skill_to_offer':
        request.skillToOffer,

        'proposed_at':
        request.proposedAt
            .millisecondsSinceEpoch,

        'mode':
        request.mode,

        'meeting_details':
        request.meetingDetails,

        'note':
        request.note,

        'status':
        request.status.databaseValue,

        'created_at':
        request.createdAt
            .millisecondsSinceEpoch,

        'updated_at':
        request.updatedAt
            .millisecondsSinceEpoch,
      },
      conflictAlgorithm:
      ConflictAlgorithm.replace,
    );
  }

  Future<void> updateStatus({
    required String requestId,
    required SwapRequestStatus status,
  }) async {
    final Database db =
    await _appDatabase.database;

    await db.update(
      'swap_requests',
      {
        'status':
        status.databaseValue,

        'updated_at':
        DateTime.now()
            .millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [
        requestId,
      ],
    );
  }

  Future<void> deleteSwapRequest(
      String requestId,
      ) async {
    final Database db =
    await _appDatabase.database;

    await db.delete(
      'swap_requests',
      where: 'id = ?',
      whereArgs: [
        requestId,
      ],
    );
  }
}