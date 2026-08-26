import 'dart:async';

import '../model/repositories/swap_repository.dart';
import '../model/swap_request.dart';

class SwapService {
  SwapService._();

  static final SwapService instance =
  SwapService._();

  final SwapRepository _repository =
  SwapRepository();

  final List<SwapRequest>
  _requests = [];

  bool _initialized = false;

  List<SwapRequest> get requests =>
      List.unmodifiable(_requests);

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final savedRequests =
    await _repository
        .getAllSwapRequests();

    _requests
      ..clear()
      ..addAll(savedRequests);

    _initialized = true;
  }

  SwapRequest createRequest({
    required String providerName,
    required String providerInitials,
    required String providerCity,
    required String skillToLearn,
    required String skillToOffer,
    required DateTime proposedAt,
    required String mode,
    String? meetingDetails,
    String? note,
  }) {
    final DateTime now =
    DateTime.now();

    final SwapRequest request =
    SwapRequest(
      id: now
          .microsecondsSinceEpoch
          .toString(),

      providerName:
      providerName,

      providerInitials:
      providerInitials,

      providerCity:
      providerCity,

      skillToLearn:
      skillToLearn,

      skillToOffer:
      skillToOffer,

      proposedAt:
      proposedAt,

      mode:
      mode,

      meetingDetails:
      meetingDetails,

      note:
      note,

      status:
      SwapRequestStatus.pending,

      createdAt:
      now,

      updatedAt:
      now,
    );

    _requests.insert(
      0,
      request,
    );

    unawaited(
      _repository.saveSwapRequest(
        request,
      ),
    );

    return request;
  }

  Future<void> updateStatus({
    required String requestId,
    required SwapRequestStatus status,
  }) async {
    final SwapRequest request =
    _requests.firstWhere(
          (request) =>
      request.id == requestId,
    );

    request.status = status;
    request.updatedAt = DateTime.now();

    await _repository.updateStatus(
      requestId: requestId,
      status: status,
    );
  }

  Future<void> deleteRequest(
      String requestId,
      ) async {
    _requests.removeWhere(
          (request) =>
      request.id == requestId,
    );

    await _repository.deleteSwapRequest(
      requestId,
    );
  }

  SwapRequest? findById(
      String requestId,
      ) {
    for (final request in _requests) {
      if (request.id == requestId) {
        return request;
      }
    }

    return null;
  }
}