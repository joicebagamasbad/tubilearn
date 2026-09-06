import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../review.dart';

class ReviewRepositoryException
    implements Exception {
  final String message;

  const ReviewRepositoryException(
      this.message,
      );

  @override
  String toString() => message;
}

class ReviewRepository {
  ReviewRepository._();

  static final ReviewRepository instance =
  ReviewRepository._();

  final AppDatabase _appDatabase =
      AppDatabase.instance;

  // ============================================================
  // CREATE REVIEW
  // ============================================================

  Future<Review> createReview({
    required String id,
    required String swapRequestId,
    required String reviewerUserId,
    required String revieweeUserId,
    required int rating,
    String? comment,
    required DateTime createdAt,
  }) async {
    final String cleanId =
    _requireText(
      id,
      'Review ID',
    );

    final String cleanSwapRequestId =
    _requireText(
      swapRequestId,
      'Swap request ID',
    );

    final String cleanReviewerUserId =
    _requireText(
      reviewerUserId,
      'Reviewer user ID',
    );

    final String cleanRevieweeUserId =
    _requireText(
      revieweeUserId,
      'Reviewee user ID',
    );

    if (cleanReviewerUserId ==
        cleanRevieweeUserId) {
      throw const ReviewRepositoryException(
        'You cannot review yourself.',
      );
    }

    if (rating < 1 ||
        rating > 5) {
      throw const ReviewRepositoryException(
        'Rating must be between 1 and 5 stars.',
      );
    }

    final String? cleanComment =
    _normalizeNullable(
      comment,
    );

    if (cleanComment != null &&
        cleanComment.length > 500) {
      throw const ReviewRepositoryException(
        'Review comment must be 500 characters or less.',
      );
    }

    final int cleanCreatedAt =
    _dateTimeToMilliseconds(
      createdAt,
      'Review timestamp',
    );

    try {
      final Database db =
      await _appDatabase.database;

      await db.transaction(
            (
            Transaction txn,
            ) async {
          // ====================================================
          // VERIFY COMPLETED SWAP
          // ====================================================

          final List<Map<String, Object?>>
          swapRows =
          await txn.query(
            'swap_requests',
            columns:
            <String>[
              'requester_user_id',
              'provider_user_id',
              'status',
            ],
            where:
            'id = ?',
            whereArgs:
            <Object?>[
              cleanSwapRequestId,
            ],
            limit:
            1,
          );

          if (swapRows.length != 1) {
            throw const ReviewRepositoryException(
              'Completed swap could not be found.',
            );
          }

          final Map<String, Object?> swapRow =
              swapRows.single;

          final String? requesterUserId =
          _readNullableString(
            swapRow,
            'requester_user_id',
          );

          final String? providerUserId =
          _readNullableString(
            swapRow,
            'provider_user_id',
          );

          final String status =
          _requireStoredText(
            swapRow,
            'status',
            'Swap status',
          );

          if (status != 'completed') {
            throw const ReviewRepositoryException(
              'Only completed swaps can be reviewed.',
            );
          }

          if (requesterUserId == null ||
              providerUserId == null) {
            throw const ReviewRepositoryException(
              'This completed swap does not have stable participant identity.',
            );
          }

          if (requesterUserId ==
              providerUserId) {
            throw const ReviewRepositoryException(
              'This completed swap has invalid participant identity.',
            );
          }

          // ====================================================
          // VERIFY REVIEWER / REVIEWEE
          // ====================================================

          final bool reviewerIsRequester =
              cleanReviewerUserId ==
                  requesterUserId;

          final bool reviewerIsProvider =
              cleanReviewerUserId ==
                  providerUserId;

          if (!reviewerIsRequester &&
              !reviewerIsProvider) {
            throw const ReviewRepositoryException(
              'You are not a participant in this swap.',
            );
          }

          final String expectedRevieweeUserId =
          reviewerIsRequester
              ? providerUserId
              : requesterUserId;

          if (cleanRevieweeUserId !=
              expectedRevieweeUserId) {
            throw const ReviewRepositoryException(
              'The selected review recipient is not the other participant in this swap.',
            );
          }

          // ====================================================
          // DUPLICATE REVIEW PROTECTION
          // ====================================================

          final List<Map<String, Object?>>
          existingReviews =
          await txn.query(
            'reviews',
            columns:
            <String>[
              'id',
            ],
            where:
            'swap_request_id = ? '
                'AND reviewer_user_id = ?',
            whereArgs:
            <Object?>[
              cleanSwapRequestId,
              cleanReviewerUserId,
            ],
            limit:
            1,
          );

          if (existingReviews.isNotEmpty) {
            throw const ReviewRepositoryException(
              'You already reviewed this completed swap.',
            );
          }

          // ====================================================
          // READ EXISTING USER RATING
          //
          // Existing seeded users may already have community
          // rating data even though those historical reviews do
          // not exist as individual rows in the new reviews table.
          //
          // We therefore preserve that aggregate and incorporate
          // the new review using a weighted average.
          // ====================================================

          final List<Map<String, Object?>>
          revieweeRows =
          await txn.query(
            'users',
            columns:
            <String>[
              'rating',
              'review_count',
            ],
            where:
            'id = ?',
            whereArgs:
            <Object?>[
              cleanRevieweeUserId,
            ],
            limit:
            1,
          );

          if (revieweeRows.length != 1) {
            throw const ReviewRepositoryException(
              'Reviewed user could not be found.',
            );
          }

          final Map<String, Object?>
          revieweeRow =
              revieweeRows.single;

          final double oldRating =
          _readRequiredDouble(
            revieweeRow[
            'rating'],
            'Existing user rating',
          );

          final int oldReviewCount =
          _readRequiredInteger(
            revieweeRow[
            'review_count'],
            'Existing review count',
          );

          if (oldRating < 0 ||
              oldRating > 5) {
            throw const ReviewRepositoryException(
              'Existing user rating is invalid.',
            );
          }

          if (oldReviewCount < 0) {
            throw const ReviewRepositoryException(
              'Existing review count is invalid.',
            );
          }

          if (oldReviewCount == 0 &&
              oldRating != 0) {
            throw const ReviewRepositoryException(
              'Existing user review totals are inconsistent.',
            );
          }

          // ====================================================
          // INSERT REVIEW
          // ====================================================

          final int insertedRowId =
          await txn.insert(
            'reviews',
            <String, Object?>{
              'id':
              cleanId,
              'swap_request_id':
              cleanSwapRequestId,
              'reviewer_user_id':
              cleanReviewerUserId,
              'reviewee_user_id':
              cleanRevieweeUserId,
              'rating':
              rating,
              'comment':
              cleanComment,
              'created_at':
              cleanCreatedAt,
            },
            conflictAlgorithm:
            ConflictAlgorithm.abort,
          );

          if (insertedRowId <= 0) {
            throw const ReviewRepositoryException(
              'Review could not be saved.',
            );
          }

          // ====================================================
          // WEIGHTED RATING UPDATE
          // ====================================================

          final int newReviewCount =
              oldReviewCount + 1;

          final double newRating;

          if (oldReviewCount == 0) {
            newRating =
                rating.toDouble();
          } else {
            newRating =
                ((oldRating *
                    oldReviewCount) +
                    rating) /
                    newReviewCount;
          }

          if (!newRating.isFinite ||
              newRating < 1 ||
              newRating > 5) {
            throw const ReviewRepositoryException(
              'Calculated user rating is invalid.',
            );
          }

          final int updatedUsers =
          await txn.update(
            'users',
            <String, Object?>{
              'rating':
              newRating,
              'review_count':
              newReviewCount,
            },
            where:
            'id = ?',
            whereArgs:
            <Object?>[
              cleanRevieweeUserId,
            ],
          );

          if (updatedUsers != 1) {
            throw const ReviewRepositoryException(
              'Reviewed user could not be updated.',
            );
          }
        },
      );

      return Review(
        id:
        cleanId,
        swapRequestId:
        cleanSwapRequestId,
        reviewerUserId:
        cleanReviewerUserId,
        revieweeUserId:
        cleanRevieweeUserId,
        rating:
        rating,
        comment:
        cleanComment,
        createdAt:
        createdAt,
      );
    } on ReviewRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const ReviewRepositoryException(
        'Review could not be saved.',
      );
    } catch (_) {
      throw const ReviewRepositoryException(
        'Review could not be saved.',
      );
    }
  }

  // ============================================================
  // REVIEW LOOKUP
  // ============================================================

  Future<Review?> findReviewForSwapByReviewer({
    required String swapRequestId,
    required String reviewerUserId,
  }) async {
    final String cleanSwapRequestId =
    _requireText(
      swapRequestId,
      'Swap request ID',
    );

    final String cleanReviewerUserId =
    _requireText(
      reviewerUserId,
      'Reviewer user ID',
    );

    try {
      final Database db =
      await _appDatabase.database;

      final List<Map<String, Object?>> rows =
      await db.query(
        'reviews',
        where:
        'swap_request_id = ? '
            'AND reviewer_user_id = ?',
        whereArgs:
        <Object?>[
          cleanSwapRequestId,
          cleanReviewerUserId,
        ],
        limit:
        1,
      );

      if (rows.isEmpty) {
        return null;
      }

      if (rows.length != 1) {
        throw const ReviewRepositoryException(
          'Stored review data is inconsistent.',
        );
      }

      return _reviewFromMap(
        rows.single,
      );
    } on ReviewRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const ReviewRepositoryException(
        'Review could not be loaded.',
      );
    } catch (_) {
      throw const ReviewRepositoryException(
        'Review could not be loaded.',
      );
    }
  }

  // ============================================================
  // REVIEWS FOR USER
  // ============================================================

  Future<List<Review>> getReviewsForUser(
      String revieweeUserId,
      ) async {
    final String cleanRevieweeUserId =
    _requireText(
      revieweeUserId,
      'User ID',
    );

    try {
      final Database db =
      await _appDatabase.database;

      final List<Map<String, Object?>> rows =
      await db.query(
        'reviews',
        where:
        'reviewee_user_id = ?',
        whereArgs:
        <Object?>[
          cleanRevieweeUserId,
        ],
        orderBy:
        'created_at DESC',
      );

      return List<Review>.unmodifiable(
        rows.map(
          _reviewFromMap,
        ),
      );
    } on ReviewRepositoryException {
      rethrow;
    } on DatabaseException catch (_) {
      throw const ReviewRepositoryException(
        'Reviews could not be loaded.',
      );
    } catch (_) {
      throw const ReviewRepositoryException(
        'Reviews could not be loaded.',
      );
    }
  }

  // ============================================================
  // PARSE REVIEW
  // ============================================================

  Review _reviewFromMap(
      Map<String, Object?> row,
      ) {
    final String id =
    _requireStoredText(
      row,
      'id',
      'Review ID',
    );

    final String swapRequestId =
    _requireStoredText(
      row,
      'swap_request_id',
      'Swap request ID',
    );

    final String reviewerUserId =
    _requireStoredText(
      row,
      'reviewer_user_id',
      'Reviewer user ID',
    );

    final String revieweeUserId =
    _requireStoredText(
      row,
      'reviewee_user_id',
      'Reviewee user ID',
    );

    if (reviewerUserId ==
        revieweeUserId) {
      throw const ReviewRepositoryException(
        'Stored review has invalid participants.',
      );
    }

    final int rating =
    _readRequiredInteger(
      row[
      'rating'],
      'Review rating',
    );

    if (rating < 1 ||
        rating > 5) {
      throw const ReviewRepositoryException(
        'Stored review has an invalid rating.',
      );
    }

    final String? comment =
    _readNullableString(
      row,
      'comment',
    );

    if (comment != null &&
        comment.length > 500) {
      throw const ReviewRepositoryException(
        'Stored review comment is invalid.',
      );
    }

    final int createdAtMilliseconds =
    _readRequiredInteger(
      row[
      'created_at'],
      'Review timestamp',
    );

    if (createdAtMilliseconds <= 0) {
      throw const ReviewRepositoryException(
        'Stored review timestamp is invalid.',
      );
    }

    return Review(
      id:
      id,
      swapRequestId:
      swapRequestId,
      reviewerUserId:
      reviewerUserId,
      revieweeUserId:
      revieweeUserId,
      rating:
      rating,
      comment:
      comment,
      createdAt:
      DateTime.fromMillisecondsSinceEpoch(
        createdAtMilliseconds,
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _requireText(
      String value,
      String fieldName,
      ) {
    final String clean =
    value.trim();

    if (clean.isEmpty) {
      throw ReviewRepositoryException(
        '$fieldName is required.',
      );
    }

    return clean;
  }

  String _requireStoredText(
      Map<String, Object?> row,
      String key,
      String label,
      ) {
    final Object? value =
    row[
    key
    ];

    if (value is! String) {
      throw ReviewRepositoryException(
        '$label is invalid.',
      );
    }

    final String clean =
    value.trim();

    if (clean.isEmpty) {
      throw ReviewRepositoryException(
        '$label is invalid.',
      );
    }

    return clean;
  }

  String? _readNullableString(
      Map<String, Object?> row,
      String key,
      ) {
    final Object? value =
    row[
    key
    ];

    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw const ReviewRepositoryException(
        'Stored text value is invalid.',
      );
    }

    final String clean =
    value.trim();

    return clean.isEmpty
        ? null
        : clean;
  }

  int _readRequiredInteger(
      Object? value,
      String label,
      ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      final double numeric =
      value.toDouble();

      if (numeric.isFinite &&
          numeric ==
              numeric.truncateToDouble()) {
        return numeric.toInt();
      }
    }

    if (value is String) {
      final int? parsed =
      int.tryParse(
        value.trim(),
      );

      if (parsed != null) {
        return parsed;
      }
    }

    throw ReviewRepositoryException(
      '$label is invalid.',
    );
  }

  double _readRequiredDouble(
      Object? value,
      String label,
      ) {
    if (value is num) {
      final double numeric =
      value.toDouble();

      if (numeric.isFinite) {
        return numeric;
      }
    }

    if (value is String) {
      final double? parsed =
      double.tryParse(
        value.trim(),
      );

      if (parsed != null &&
          parsed.isFinite) {
        return parsed;
      }
    }

    throw ReviewRepositoryException(
      '$label is invalid.',
    );
  }

  int _dateTimeToMilliseconds(
      DateTime value,
      String label,
      ) {
    final int milliseconds =
        value.millisecondsSinceEpoch;

    if (milliseconds <= 0) {
      throw ReviewRepositoryException(
        '$label is invalid.',
      );
    }

    final DateTime roundTrip =
    DateTime.fromMillisecondsSinceEpoch(
      milliseconds,
    );

    if (roundTrip.millisecondsSinceEpoch !=
        milliseconds) {
      throw ReviewRepositoryException(
        '$label could not be stored safely.',
      );
    }

    return milliseconds;
  }

  String? _normalizeNullable(
      String? value,
      ) {
    if (value == null) {
      return null;
    }

    final String clean =
    value.trim();

    return clean.isEmpty
        ? null
        : clean;
  }
}