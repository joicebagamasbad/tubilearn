import '../model/repositories/swap_repository.dart';
import '../model/swap_request.dart';

class SwapServiceException implements Exception {
  final String message;

  const SwapServiceException(this.message);

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

  Future<void>? _initializingFuture;

  final Map<String, Future<SwapRequest>>
  _pendingCreations = {};

  final Map<String, Future<void>>
  _pendingStatusChanges = {};

  final Map<String, Future<void>>
  _pendingDeletions = {};

  int _lastRequestIdMicros = 0;

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

    final Future<void>? pending =
        _initializingFuture;

    if (pending != null) {
      await pending;
      return;
    }

    final Future<void> initialization =
    _initializeInternal();

    _initializingFuture =
        initialization;

    try {
      await initialization;
    } finally {
      if (identical(
        _initializingFuture,
        initialization,
      )) {
        _initializingFuture = null;
      }
    }
  }

  Future<void> _initializeInternal() async {
    final List<SwapRequest> savedRequests =
    await _repository.getAllSwapRequests();

    _requests
      ..clear()
      ..addAll(savedRequests);

    _syncRequestIdCounter(
      savedRequests,
    );

    _initialized = true;
  }

  // ============================================================
  // CREATE REQUEST
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
    await initialize();

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

    final String creationKey =
    _createPendingCreationKey(
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

    final Future<SwapRequest>? pending =
    _pendingCreations[
    creationKey];

    if (pending != null) {
      return pending;
    }

    final Future<SwapRequest> creation =
    _createRequestInternal(
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

    _pendingCreations[
    creationKey] = creation;

    try {
      return await creation;
    } finally {
      if (identical(
        _pendingCreations[
        creationKey],
        creation,
      )) {
        _pendingCreations.remove(
          creationKey,
        );
      }
    }
  }

  Future<SwapRequest> _createRequestInternal({
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
  }) async {
    _preventDuplicateActiveRequest(
      requesterUserId:
      requesterUserId,
      providerUserId:
      providerUserId,
      skillToLearnId:
      skillToLearnId,
      skillToOfferId:
      skillToOfferId,
      providerName:
      providerName,
      skillToLearn:
      skillToLearn,
      skillToOffer:
      skillToOffer,
    );

    final DateTime now =
    DateTime.now();

    final SwapRequest request =
    SwapRequest(
      id:
      _createRequestId(),
      requesterUserId:
      requesterUserId,
      providerUserId:
      providerUserId,
      skillToLearnId:
      skillToLearnId,
      skillToOfferId:
      skillToOfferId,
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

    try {
      await _repository.saveSwapRequest(
        request,
      );
    } catch (_) {
      throw const SwapServiceException(
        'Could not save the swap request. Please try again.',
      );
    }

    _requests.insert(
      0,
      request,
    );

    return request;
  }

  // ============================================================
  // ACCEPT
  // ============================================================

  Future<void> acceptRequest({
    required String requestId,
    required String actorUserId,
  }) async {
    await initialize();

    final SwapRequest request =
    _requireRequest(
      requestId,
    );

    final String actor =
    _requireActorUserId(
      actorUserId,
    );

    if (!request.canAccept(
      actor,
    )) {
      throw const SwapServiceException(
        'You are not allowed to accept this swap request.',
      );
    }

    await _changeStatus(
      request:
      request,
      nextStatus:
      SwapRequestStatus.accepted,
    );
  }

  // ============================================================
  // DECLINE
  // ============================================================

  Future<void> declineRequest({
    required String requestId,
    required String actorUserId,
  }) async {
    await initialize();

    final SwapRequest request =
    _requireRequest(
      requestId,
    );

    final String actor =
    _requireActorUserId(
      actorUserId,
    );

    if (!request.canDecline(
      actor,
    )) {
      throw const SwapServiceException(
        'You are not allowed to decline this swap request.',
      );
    }

    await _changeStatus(
      request:
      request,
      nextStatus:
      SwapRequestStatus.declined,
    );
  }

  // ============================================================
  // CANCEL
  // ============================================================

  Future<void> cancelRequest({
    required String requestId,
    required String actorUserId,
  }) async {
    await initialize();

    final SwapRequest request =
    _requireRequest(
      requestId,
    );

    final String actor =
    _requireActorUserId(
      actorUserId,
    );

    if (!request.canCancel(
      actor,
    )) {
      throw const SwapServiceException(
        'You are not allowed to cancel this swap request.',
      );
    }

    await _changeStatus(
      request:
      request,
      nextStatus:
      SwapRequestStatus.cancelled,
    );
  }

  // ============================================================
  // SCHEDULE
  // ============================================================

  Future<void> scheduleRequest({
    required String requestId,
    required String actorUserId,
  }) async {
    await initialize();

    final SwapRequest request =
    _requireRequest(
      requestId,
    );

    final String actor =
    _requireActorUserId(
      actorUserId,
    );

    if (!request.canSchedule(
      actor,
    )) {
      throw const SwapServiceException(
        'You are not allowed to schedule this swap request.',
      );
    }

    await _changeStatus(
      request:
      request,
      nextStatus:
      SwapRequestStatus.scheduled,
    );
  }

  // ============================================================
  // COMPLETE
  // ============================================================

  Future<void> completeRequest({
    required String requestId,
    required String actorUserId,
  }) async {
    await initialize();

    final SwapRequest request =
    _requireRequest(
      requestId,
    );

    final String actor =
    _requireActorUserId(
      actorUserId,
    );

    if (!request.canComplete(
      actor,
    )) {
      throw const SwapServiceException(
        'You are not allowed to complete this swap request.',
      );
    }

    await _changeStatus(
      request:
      request,
      nextStatus:
      SwapRequestStatus.completed,
    );
  }

  // ============================================================
  // STATUS CHANGE
  // ============================================================

  Future<void> _changeStatus({
    required SwapRequest request,
    required SwapRequestStatus nextStatus,
  }) async {
    final String requestId =
    request.id.trim();

    final Future<void>? pendingDeletion =
    _pendingDeletions[
    requestId];

    if (pendingDeletion != null) {
      throw const SwapServiceException(
        'This swap request is being deleted.',
      );
    }

    while (true) {
      final Future<void>? pendingStatusChange =
      _pendingStatusChanges[
      requestId];

      if (pendingStatusChange == null) {
        break;
      }

      try {
        await pendingStatusChange;
      } catch (_) {
        // Previous caller receives its own error.
      }

      if (_pendingDeletions.containsKey(
        requestId,
      )) {
        throw const SwapServiceException(
          'This swap request is being deleted.',
        );
      }
    }

    final Future<void> operation =
    _changeStatusInternal(
      requestId:
      requestId,
      nextStatus:
      nextStatus,
    );

    _pendingStatusChanges[
    requestId] = operation;

    try {
      await operation;
    } finally {
      if (identical(
        _pendingStatusChanges[
        requestId],
        operation,
      )) {
        _pendingStatusChanges.remove(
          requestId,
        );
      }
    }
  }

  Future<void> _changeStatusInternal({
    required String requestId,
    required SwapRequestStatus nextStatus,
  }) async {
    final SwapRequest request =
    _requireRequest(
      requestId,
    );

    if (request.status ==
        nextStatus) {
      return;
    }

    if (!request.status.canTransitionTo(
      nextStatus,
    )) {
      throw SwapServiceException(
        'Cannot change request status from '
            '${request.status.label} to '
            '${nextStatus.label}.',
      );
    }

    final DateTime updatedAt =
    DateTime.now();

    try {
      await _repository.updateStatus(
        requestId:
        request.id,
        status:
        nextStatus,
        updatedAt:
        updatedAt,
      );
    } catch (_) {
      throw const SwapServiceException(
        'Could not update the swap request. Please try again.',
      );
    }

    request.status =
        nextStatus;

    request.updatedAt =
        updatedAt;
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteRequest({
    required String requestId,
    required String actorUserId,
  }) async {
    await initialize();

    final String cleanRequestId =
    _requireRequestId(
      requestId,
    );

    final Future<void>? pendingDeletion =
    _pendingDeletions[
    cleanRequestId];

    if (pendingDeletion != null) {
      await pendingDeletion;
      return;
    }

    final String actor =
    _requireActorUserId(
      actorUserId,
    );

    final Future<void> deletion =
    _deleteRequestInternal(
      requestId:
      cleanRequestId,
      actorUserId:
      actor,
    );

    _pendingDeletions[
    cleanRequestId] = deletion;

    try {
      await deletion;
    } finally {
      if (identical(
        _pendingDeletions[
        cleanRequestId],
        deletion,
      )) {
        _pendingDeletions.remove(
          cleanRequestId,
        );
      }
    }
  }

  Future<void> _deleteRequestInternal({
    required String requestId,
    required String actorUserId,
  }) async {
    final Future<void>? pendingStatusChange =
    _pendingStatusChanges[
    requestId];

    if (pendingStatusChange != null) {
      try {
        await pendingStatusChange;
      } catch (_) {
        // Continue with fresh state after failed status update.
      }
    }

    final SwapRequest request =
    _requireRequest(
      requestId,
    );

    if (!request.hasStableIdentity) {
      throw const SwapServiceException(
        'This legacy swap request cannot be safely deleted because participant identity is incomplete.',
      );
    }

    final bool isRequester =
        request.requesterUserId ==
            actorUserId;

    final bool isProvider =
        request.providerUserId ==
            actorUserId;

    if (!isRequester &&
        !isProvider) {
      throw const SwapServiceException(
        'You are not allowed to delete this swap request.',
      );
    }

    if (request.status.isActive) {
      throw const SwapServiceException(
        'Active swap requests cannot be deleted. Cancel or finish the request first.',
      );
    }

    try {
      await _repository.deleteSwapRequest(
        request.id,
      );
    } catch (_) {
      throw const SwapServiceException(
        'Could not delete the swap request. Please try again.',
      );
    }

    _requests.removeWhere(
          (
          SwapRequest item,
          ) =>
      item.id ==
          request.id,
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
  // REQUIRE
  // ============================================================

  String _requireRequestId(
      String requestId,
      ) {
    final String cleanRequestId =
    requestId.trim();

    if (cleanRequestId.isEmpty) {
      throw const SwapServiceException(
        'Swap request ID is required.',
      );
    }

    return cleanRequestId;
  }

  SwapRequest _requireRequest(
      String requestId,
      ) {
    final String cleanRequestId =
    _requireRequestId(
      requestId,
    );

    final SwapRequest? request =
    findById(
      cleanRequestId,
    );

    if (request == null) {
      throw const SwapServiceException(
        'Swap request not found.',
      );
    }

    return request;
  }

  String _requireActorUserId(
      String actorUserId,
      ) {
    final String cleanActorUserId =
    actorUserId.trim();

    if (cleanActorUserId.isEmpty) {
      throw const SwapServiceException(
        'Current user identity is required.',
      );
    }

    return cleanActorUserId;
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

    if (skillToLearn
        .toLowerCase() ==
        skillToOffer
            .toLowerCase()) {
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

    const Set<String> allowedModes =
    <String>{
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
            'You already have an active swap request with this user for the same skill exchange.',
          );
        }

        continue;
      }

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
          'You already have an active swap request with this user for the same skill exchange.',
        );
      }
    }
  }

  // ============================================================
  // PENDING CREATE KEY
  // ============================================================

  String _createPendingCreationKey({
    required String? requesterUserId,
    required String? providerUserId,
    required String? skillToLearnId,
    required String? skillToOfferId,
    required String providerName,
    required String skillToLearn,
    required String skillToOffer,
  }) {
    if (requesterUserId != null &&
        providerUserId != null &&
        skillToLearnId != null &&
        skillToOfferId != null) {
      return [
        requesterUserId,
        providerUserId,
        skillToLearnId,
        skillToOfferId,
      ].join('|');
    }

    return [
      providerName
          .trim()
          .toLowerCase(),
      skillToLearn
          .trim()
          .toLowerCase(),
      skillToOffer
          .trim()
          .toLowerCase(),
    ].join('|');
  }

  // ============================================================
  // REQUEST IDS
  // ============================================================

  void _syncRequestIdCounter(
      List<SwapRequest> requests,
      ) {
    int highest =
        _lastRequestIdMicros;

    for (final SwapRequest request
    in requests) {
      final int createdMicros =
          request.createdAt
              .microsecondsSinceEpoch;

      if (createdMicros >
          highest) {
        highest =
            createdMicros;
      }

      final int? parsedId =
      int.tryParse(
        request.id.trim(),
      );

      if (parsedId != null &&
          parsedId > highest) {
        highest =
            parsedId;
      }
    }

    _lastRequestIdMicros =
        highest;
  }

  String _createRequestId() {
    int candidate =
        DateTime.now()
            .microsecondsSinceEpoch;

    if (candidate <=
        _lastRequestIdMicros) {
      candidate =
          _lastRequestIdMicros + 1;
    }

    _lastRequestIdMicros =
        candidate;

    return candidate.toString();
  }

  // ============================================================
  // TEXT
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