import '../model/repositories/swap_repository.dart';
import '../model/swap_request.dart';

class SwapServiceException implements Exception {
  final String message;

  const SwapServiceException(
      this.message,
      );

  @override
  String toString() => message;
}

class SwapService {
  SwapService._();

  static final SwapService instance =
  SwapService._();

  final SwapRepository _repository =
  SwapRepository();

  final List<SwapRequest> _requests = [];

  bool _initialized = false;

  List<SwapRequest> get requests =>
      List.unmodifiable(_requests);

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final List<SwapRequest> savedRequests =
    await _repository.getAllSwapRequests();

    _requests
      ..clear()
      ..addAll(savedRequests);

    _initialized = true;
  }

  // ============================================================
  // CREATE REQUEST
  //
  // Identity fields are temporarily optional at the method
  // boundary so the current UI can still compile during the
  // migration.
  //
  // Once one identity field is supplied, ALL four are required.
  // The CreateSwapRequestScreen will be updated next so every
  // newly created request uses stable IDs.
  // ============================================================

  Future<SwapRequest> createRequest({
    String? requesterUserId,
    String? providerUserId,
    String? skillToLearnId,
    String? skillToOfferId,

    required String providerName,
    required String providerInitials,
    required String providerCity,

    required String skillToLearn,
    required String skillToOffer,

    required DateTime proposedAt,

    required String mode,

    String? meetingDetails,
    String? note,
  }) async {
    final String? cleanRequesterUserId =
    _cleanNullableText(
      requesterUserId,
    );

    final String? cleanProviderUserId =
    _cleanNullableText(
      providerUserId,
    );

    final String? cleanSkillToLearnId =
    _cleanNullableText(
      skillToLearnId,
    );

    final String? cleanSkillToOfferId =
    _cleanNullableText(
      skillToOfferId,
    );

    final String cleanProviderName =
    providerName.trim();

    final String cleanProviderInitials =
    providerInitials.trim();

    final String cleanProviderCity =
    providerCity.trim();

    final String cleanSkillToLearn =
    skillToLearn.trim();

    final String cleanSkillToOffer =
    skillToOffer.trim();

    final String cleanMode =
    mode.trim();

    final String? cleanMeetingDetails =
    _cleanNullableText(
      meetingDetails,
    );

    final String? cleanNote =
    _cleanNullableText(
      note,
    );

    _validateIdentityGroup(
      requesterUserId:
      cleanRequesterUserId,
      providerUserId:
      cleanProviderUserId,
      skillToLearnId:
      cleanSkillToLearnId,
      skillToOfferId:
      cleanSkillToOfferId,
    );

    _validateCreateRequest(
      requesterUserId:
      cleanRequesterUserId,
      providerUserId:
      cleanProviderUserId,
      skillToLearnId:
      cleanSkillToLearnId,
      skillToOfferId:
      cleanSkillToOfferId,

      providerName:
      cleanProviderName,
      providerInitials:
      cleanProviderInitials,
      providerCity:
      cleanProviderCity,

      skillToLearn:
      cleanSkillToLearn,
      skillToOffer:
      cleanSkillToOffer,

      proposedAt:
      proposedAt,

      mode:
      cleanMode,

      meetingDetails:
      cleanMeetingDetails,

      note:
      cleanNote,
    );

    _preventDuplicateActiveRequest(
      requesterUserId:
      cleanRequesterUserId,
      providerUserId:
      cleanProviderUserId,
      skillToLearnId:
      cleanSkillToLearnId,
      skillToOfferId:
      cleanSkillToOfferId,

      providerName:
      cleanProviderName,
      skillToLearn:
      cleanSkillToLearn,
      skillToOffer:
      cleanSkillToOffer,
    );

    final DateTime now =
    DateTime.now();

    final SwapRequest request =
    SwapRequest(
      id:
      now.microsecondsSinceEpoch
          .toString(),

      requesterUserId:
      cleanRequesterUserId,

      providerUserId:
      cleanProviderUserId,

      skillToLearnId:
      cleanSkillToLearnId,

      skillToOfferId:
      cleanSkillToOfferId,

      providerName:
      cleanProviderName,

      providerInitials:
      cleanProviderInitials,

      providerCity:
      cleanProviderCity,

      skillToLearn:
      cleanSkillToLearn,

      skillToOffer:
      cleanSkillToOffer,

      proposedAt:
      proposedAt,

      mode:
      cleanMode,

      meetingDetails:
      cleanMeetingDetails,

      note:
      cleanNote,

      status:
      SwapRequestStatus.pending,

      createdAt:
      now,

      updatedAt:
      now,
    );

    // ----------------------------------------------------------
    // Database first.
    //
    // Memory is changed only after successful persistence.
    // ----------------------------------------------------------

    await _repository.saveSwapRequest(
      request,
    );

    _requests.insert(
      0,
      request,
    );

    return request;
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> updateStatus({
    required String requestId,
    required SwapRequestStatus status,
  }) async {
    final String cleanRequestId =
    requestId.trim();

    if (cleanRequestId.isEmpty) {
      throw const SwapServiceException(
        'Swap request ID is required.',
      );
    }

    final SwapRequest? request =
    findById(
      cleanRequestId,
    );

    if (request == null) {
      throw const SwapServiceException(
        'Swap request not found.',
      );
    }

    if (request.status == status) {
      return;
    }

    if (!request.status
        .canTransitionTo(status)) {
      throw SwapServiceException(
        'Cannot change request status from '
            '${request.status.label} to '
            '${status.label}.',
      );
    }

    final DateTime updatedAt =
    DateTime.now();

    // Database first.
    await _repository.updateStatus(
      requestId:
      request.id,
      status:
      status,
      updatedAt:
      updatedAt,
    );

    // Memory only changes after DB success.
    request.status = status;
    request.updatedAt = updatedAt;
  }

  // ============================================================
  // CANCEL REQUEST
  // ============================================================

  Future<void> cancelRequest(
      String requestId,
      ) async {
    final String cleanRequestId =
    requestId.trim();

    if (cleanRequestId.isEmpty) {
      throw const SwapServiceException(
        'Swap request ID is required.',
      );
    }

    final SwapRequest? request =
    findById(
      cleanRequestId,
    );

    if (request == null) {
      throw const SwapServiceException(
        'Swap request not found.',
      );
    }

    if (!request.status
        .canBeCancelled) {
      throw SwapServiceException(
        'This ${request.status.label.toLowerCase()} '
            'request can no longer be cancelled.',
      );
    }

    await updateStatus(
      requestId:
      request.id,
      status:
      SwapRequestStatus.cancelled,
    );
  }

  // ============================================================
  // DELETE REQUEST
  //
  // Hard delete is NOT normal cancellation behavior.
  // ============================================================

  Future<void> deleteRequest(
      String requestId,
      ) async {
    final String cleanRequestId =
    requestId.trim();

    if (cleanRequestId.isEmpty) {
      throw const SwapServiceException(
        'Swap request ID is required.',
      );
    }

    final SwapRequest? request =
    findById(
      cleanRequestId,
    );

    if (request == null) {
      throw const SwapServiceException(
        'Swap request not found.',
      );
    }

    // Database first.
    await _repository.deleteSwapRequest(
      cleanRequestId,
    );

    // Memory only changes after DB success.
    _requests.removeWhere(
          (item) =>
      item.id ==
          cleanRequestId,
    );
  }

  // ============================================================
  // FIND
  // ============================================================

  SwapRequest? findById(
      String requestId,
      ) {
    final String cleanRequestId =
    requestId.trim();

    if (cleanRequestId.isEmpty) {
      return null;
    }

    for (final SwapRequest request
    in _requests) {
      if (request.id ==
          cleanRequestId) {
        return request;
      }
    }

    return null;
  }

  // ============================================================
  // IDENTITY VALIDATION
  // ============================================================

  void _validateIdentityGroup({
    required String? requesterUserId,
    required String? providerUserId,
    required String? skillToLearnId,
    required String? skillToOfferId,
  }) {
    final bool hasAnyIdentity =
        requesterUserId != null ||
            providerUserId != null ||
            skillToLearnId != null ||
            skillToOfferId != null;

    if (!hasAnyIdentity) {
      // --------------------------------------------------------
      // Transitional legacy mode.
      //
      // Existing UI callers may still reach this path until the
      // next refactor step.
      // --------------------------------------------------------
      return;
    }

    if (requesterUserId == null ||
        providerUserId == null ||
        skillToLearnId == null ||
        skillToOfferId == null) {
      throw const SwapServiceException(
        'Incomplete swap request identity.',
      );
    }

    if (requesterUserId ==
        providerUserId) {
      throw const SwapServiceException(
        'You cannot create a swap request with yourself.',
      );
    }

    if (skillToLearnId ==
        skillToOfferId) {
      throw const SwapServiceException(
        'The skill you want to learn and the skill you offer must be different.',
      );
    }
  }

  // ============================================================
  // CREATE VALIDATION
  // ============================================================

  void _validateCreateRequest({
    required String? requesterUserId,
    required String? providerUserId,
    required String? skillToLearnId,
    required String? skillToOfferId,

    required String providerName,
    required String providerInitials,
    required String providerCity,

    required String skillToLearn,
    required String skillToOffer,

    required DateTime proposedAt,

    required String mode,

    required String? meetingDetails,
    required String? note,
  }) {
    if (providerName.isEmpty) {
      throw const SwapServiceException(
        'Provider name is required.',
      );
    }

    if (providerInitials.isEmpty) {
      throw const SwapServiceException(
        'Provider initials are required.',
      );
    }

    if (providerCity.isEmpty) {
      throw const SwapServiceException(
        'Provider city is required.',
      );
    }

    if (skillToLearn.isEmpty) {
      throw const SwapServiceException(
        'Skill to learn is required.',
      );
    }

    if (skillToOffer.isEmpty) {
      throw const SwapServiceException(
        'Skill to offer is required.',
      );
    }

    if (skillToLearn.toLowerCase() ==
        skillToOffer.toLowerCase()) {
      throw const SwapServiceException(
        'The skill you want to learn and the skill you offer must be different.',
      );
    }

    if (!proposedAt.isAfter(
      DateTime.now(),
    )) {
      throw const SwapServiceException(
        'The proposed schedule must be in the future.',
      );
    }

    const Set<String> allowedModes = {
      'Online',
      'In-person',
    };

    if (!allowedModes.contains(
      mode,
    )) {
      throw const SwapServiceException(
        'Invalid session mode.',
      );
    }

    if (meetingDetails == null ||
        meetingDetails.isEmpty) {
      throw SwapServiceException(
        mode == 'Online'
            ? 'Preferred online platform is required.'
            : 'Preferred public meeting area is required.',
      );
    }

    if (meetingDetails.length >
        150) {
      throw const SwapServiceException(
        'Meeting details are too long.',
      );
    }

    if (note != null &&
        note.length > 300) {
      throw const SwapServiceException(
        'Message must be 300 characters or less.',
      );
    }

    // ----------------------------------------------------------
    // If stable identity is supplied, make sure no field became
    // empty after normalization.
    // ----------------------------------------------------------

    final bool hasStableIdentity =
        requesterUserId != null &&
            providerUserId != null &&
            skillToLearnId != null &&
            skillToOfferId != null;

    if (hasStableIdentity) {
      if (requesterUserId.isEmpty ||
          providerUserId.isEmpty ||
          skillToLearnId.isEmpty ||
          skillToOfferId.isEmpty) {
        throw const SwapServiceException(
          'Swap request identity contains an invalid value.',
        );
      }
    }
  }

  // ============================================================
  // DUPLICATE PREVENTION
  //
  // New ID-based requests use stable identity.
  //
  // Legacy requests that do not yet have IDs are compared using
  // their old display snapshots so existing protection is not
  // lost during migration.
  // ============================================================

  void _preventDuplicateActiveRequest({
    required String? requesterUserId,
    required String? providerUserId,
    required String? skillToLearnId,
    required String? skillToOfferId,

    required String providerName,
    required String skillToLearn,
    required String skillToOffer,
  }) {
    final bool incomingHasStableIdentity =
        requesterUserId != null &&
            providerUserId != null &&
            skillToLearnId != null &&
            skillToOfferId != null;

    final String normalizedProviderName =
    providerName
        .trim()
        .toLowerCase();

    final String normalizedLearnTitle =
    skillToLearn
        .trim()
        .toLowerCase();

    final String normalizedOfferTitle =
    skillToOffer
        .trim()
        .toLowerCase();

    for (final SwapRequest request
    in _requests) {
      if (!request.status.isActive) {
        continue;
      }

      // --------------------------------------------------------
      // Preferred comparison:
      // stable IDs on both requests.
      // --------------------------------------------------------

      if (incomingHasStableIdentity &&
          request.hasStableIdentity) {
        final bool sameRequester =
            request.requesterUserId ==
                requesterUserId;

        final bool sameProvider =
            request.providerUserId ==
                providerUserId;

        final bool sameLearnSkill =
            request.skillToLearnId ==
                skillToLearnId;

        final bool sameOfferSkill =
            request.skillToOfferId ==
                skillToOfferId;

        if (sameRequester &&
            sameProvider &&
            sameLearnSkill &&
            sameOfferSkill) {
          throw const SwapServiceException(
            'You already have an active swap request '
                'with this user for the same skill exchange.',
          );
        }

        continue;
      }

      // --------------------------------------------------------
      // Legacy fallback:
      // required only while old v3 rows or old UI-created rows
      // without stable IDs may still exist.
      // --------------------------------------------------------

      final bool sameProvider =
          request.providerName
              .trim()
              .toLowerCase() ==
              normalizedProviderName;

      final bool sameLearnSkill =
          request.skillToLearn
              .trim()
              .toLowerCase() ==
              normalizedLearnTitle;

      final bool sameOfferSkill =
          request.skillToOffer
              .trim()
              .toLowerCase() ==
              normalizedOfferTitle;

      if (sameProvider &&
          sameLearnSkill &&
          sameOfferSkill) {
        throw const SwapServiceException(
          'You already have an active swap request '
              'with this user for the same skill exchange.',
        );
      }
    }
  }

  // ============================================================
  // TEXT CLEANING
  // ============================================================

  String? _cleanNullableText(
      String? value,
      ) {
    if (value == null) {
      return null;
    }

    final String cleaned =
    value.trim();

    if (cleaned.isEmpty) {
      return null;
    }

    return cleaned;
  }
}