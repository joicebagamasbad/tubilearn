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

}