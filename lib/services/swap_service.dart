import '../model/repositories/swap_repository.dart';
import '../model/swap_request.dart';
import 'current_user_service.dart';

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

  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  final List<SwapRequest> _requests =
  <SwapRequest>[];

  Future<void>? _initializingFuture;

  final Map<String, Future<SwapRequest>>
  _pendingCreations =
  <String, Future<SwapRequest>>{};

  final Map<String, Future<void>>
  _pendingStatusChanges =
  <String, Future<void>>{};

  final Map<String, Future<void>>
  _pendingHides =
  <String, Future<void>>{};

  final Map<String, Future<SwapRequest>>
  _pendingRestores =
  <String, Future<SwapRequest>>{};

  int _lastRequestIdMicros = 0;

  bool _initialized = false;

  List<SwapRequest> get requests =>
      List<SwapRequest>.unmodifiable(
        _requests,
      );

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
    final String currentUserId =
    _requireCurrentLocalUser();

    late final List<SwapRequest>
    savedRequests;

    try {
      savedRequests =
      await _repository.getAllSwapRequests(
        userId: currentUserId,
      );
    } on SwapRepositoryException catch (_) {
      throw const SwapServiceException(
        'Could not load your swap requests. Please try again.',
      );
    } catch (_) {
      throw const SwapServiceException(
        'Could not load your swap requests. Please try again.',
      );
    }

    _validateLoadedRequests(
      savedRequests,
    );

    _requests
      ..clear()
      ..addAll(
        savedRequests,
      );

    _sortRequests();

    _syncRequestIdCounter(
      savedRequests,
    );

    _initialized = true;
  }

  // ============================================================
  // LOADED DATA VALIDATION
  // ============================================================

  void _validateLoadedRequests(
      List<SwapRequest> requests,
      ) {
    final Set<String> seenRequestIds =
    <String>{};

    final Set<String> activeStableKeys =
    <String>{};

    for (final SwapRequest request
    in requests) {
      _validateLoadedRequest(
        request,
      );

      final String requestId =
      request.id.trim();

      if (!seenRequestIds.add(
        requestId,
      )) {
        throw const SwapServiceException(
          'Saved swap data contains duplicate request IDs.',
        );
      }

      if (!request.status.isActive) {
        continue;
      }

      if (!request.hasStableIdentity ||
          !request
              .hasStructurallyValidIdentityGroup) {
        throw const SwapServiceException(
          'An active saved swap request has incomplete identity data.',
        );
      }

      final String stableKey =
      _stableRequestIdentityKey(
        requesterUserId:
        request.requesterUserId!,
        providerUserId:
        request.providerUserId!,
        skillToLearnId:
        request.skillToLearnId!,
        skillToOfferId:
        request.skillToOfferId!,
      );

      if (!activeStableKeys.add(
        stableKey,
      )) {
        throw const SwapServiceException(
          'Saved swap data contains duplicate active requests.',
        );
      }
    }
  }

  void _validateLoadedRequest(
      SwapRequest request,
      ) {
    if (request.id.trim().isEmpty) {
      throw const SwapServiceException(
        'Saved swap data contains a request without an ID.',
      );
    }

    final String providerName =
    request.providerName.trim();

    final String providerInitials =
    request.providerInitials.trim();

    final String providerCity =
    request.providerCity.trim();

    final String skillToLearn =
    request.skillToLearn.trim();

    final String skillToOffer =
    request.skillToOffer.trim();

    final String mode =
    request.mode.trim();

    final String? meetingDetails =
    _cleanNullableText(
      request.meetingDetails,
    );

    final String? note =
    _cleanNullableText(
      request.note,
    );

    if (providerName.isEmpty ||
        providerInitials.isEmpty ||
        providerCity.isEmpty ||
        skillToLearn.isEmpty ||
        skillToOffer.isEmpty) {
      throw const SwapServiceException(
        'Saved swap data contains incomplete snapshot data.',
      );
    }

    if (skillToLearn.toLowerCase() ==
        skillToOffer.toLowerCase()) {
      throw const SwapServiceException(
        'Saved swap data contains an invalid same-skill exchange.',
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
        'Saved swap data contains an invalid session mode.',
      );
    }

    if (meetingDetails == null ||
        meetingDetails.length > 150) {
      throw const SwapServiceException(
        'Saved swap data contains invalid meeting details.',
      );
    }

    if (note != null &&
        note.length > 300) {
      throw const SwapServiceException(
        'Saved swap data contains a message that is too long.',
      );
    }

    if (request.createdAt
        .millisecondsSinceEpoch <=
        0 ||
        request.updatedAt
            .millisecondsSinceEpoch <=
            0 ||
        request.proposedAt
            .millisecondsSinceEpoch <=
            0) {
      throw const SwapServiceException(
        'Saved swap data contains an invalid timestamp.',
      );
    }

    if (request.updatedAt.isBefore(
      request.createdAt,
    )) {
      throw const SwapServiceException(
        'Saved swap data contains an invalid update timestamp.',
      );
    }

    final String? requesterUserId =
    _cleanNullableText(
      request.requesterUserId,
    );

    final String? providerUserId =
    _cleanNullableText(
      request.providerUserId,
    );

    final String? skillToLearnId =
    _cleanNullableText(
      request.skillToLearnId,
    );

    final String? skillToOfferId =
    _cleanNullableText(
      request.skillToOfferId,
    );

    _validateIdentityGroup(
      requesterUserId:
      requesterUserId,
      providerUserId:
      providerUserId,
      skillToLearnId:
      skillToLearnId,
      skillToOfferId:
      skillToOfferId,
      allowNoIdentity:
      request.status.isTerminal,
    );

    if (request.status.isTerminal &&
        !request.hasStableIdentity &&
        !request.canRemainAsHistory) {
      throw const SwapServiceException(
        'Saved historical swap data is incomplete.',
      );
    }

    if (request.status.isActive &&
        !request.isActionableStableRequest) {
      throw const SwapServiceException(
        'Saved active swap data does not have stable identity.',
      );
    }
  }

  // ============================================================
  // CREATE
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

    final String currentUserId =
    _requireCurrentLocalUser();

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
      allowNoIdentity:
      false,
    );

    if (cleanRequesterUserId !=
        currentUserId) {
      throw const SwapServiceException(
        'New swap requests must belong to the active local user.',
      );
    }

    _validateCreateRequest(
      requesterUserId:
      cleanRequesterUserId!,
      providerUserId:
      cleanProviderUserId!,
      skillToLearnId:
      cleanSkillToLearnId!,
      skillToOfferId:
      cleanSkillToOfferId!,
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
    _stableRequestIdentityKey(
      requesterUserId:
      cleanRequesterUserId,
      providerUserId:
      cleanProviderUserId,
      skillToLearnId:
      cleanSkillToLearnId,
      skillToOfferId:
      cleanSkillToOfferId,
    );

    final Future<SwapRequest>? pending =
    _pendingCreations[
    creationKey
    ];

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
    creationKey
    ] = creation;

    try {
      return await creation;
    } finally {
      if (identical(
        _pendingCreations[
        creationKey
        ],
        creation,
      )) {
        _pendingCreations.remove(
          creationKey,
        );
      }
    }
  }

  Future<SwapRequest> _createRequestInternal({
    required String requesterUserId,
    required String providerUserId,
    required String skillToLearnId,
    required String skillToOfferId,
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
    } on SwapRepositoryException catch (_) {
      throw const SwapServiceException(
        'Could not save the swap request. Please try again.',
      );
    }

    _requests.insert(
      0,
      request,
    );

    _sortRequests();

    return request;
  }

  // ============================================================
  // STATUS ACTIONS
  // ============================================================

  Future<void> acceptRequest({
    required String requestId,
    required String actorUserId,
  }) async {
    await _performActorTransition(
      requestId:
      requestId,
      actorUserId:
      actorUserId,
      target:
      SwapRequestStatus.accepted,
      permission:
          (
          request,
          actor,
          ) =>
          request.canAccept(
            actor,
          ),
      permissionError:
      'You are not allowed to accept this swap request.',
    );
  }

  Future<void> declineRequest({
    required String requestId,
    required String actorUserId,
  }) async {
    await _performActorTransition(
      requestId:
      requestId,
      actorUserId:
      actorUserId,
      target:
      SwapRequestStatus.declined,
      permission:
          (
          request,
          actor,
          ) =>
          request.canDecline(
            actor,
          ),
      permissionError:
      'You are not allowed to decline this swap request.',
    );
  }

  Future<void> cancelRequest({
    required String requestId,
    required String actorUserId,
  }) async {
    await _performActorTransition(
      requestId:
      requestId,
      actorUserId:
      actorUserId,
      target:
      SwapRequestStatus.cancelled,
      permission:
          (
          request,
          actor,
          ) =>
          request.canCancel(
            actor,
          ),
      permissionError:
      'You are not allowed to cancel this swap request.',
    );
  }

  Future<void> scheduleRequest({
    required String requestId,
    required String actorUserId,
  }) async {
    await _performActorTransition(
      requestId:
      requestId,
      actorUserId:
      actorUserId,
      target:
      SwapRequestStatus.scheduled,
      permission:
          (
          request,
          actor,
          ) =>
          request.canSchedule(
            actor,
          ),
      permissionError:
      'You are not allowed to schedule this swap request.',
    );
  }

  Future<void> completeRequest({
    required String requestId,
    required String actorUserId,
  }) async {
    await _performActorTransition(
      requestId:
      requestId,
      actorUserId:
      actorUserId,
      target:
      SwapRequestStatus.completed,
      permission:
          (
          request,
          actor,
          ) =>
          request.canComplete(
            actor,
          ),
      permissionError:
      'You are not allowed to complete this swap request.',
    );
  }

  Future<void> _performActorTransition({
    required String requestId,
    required String actorUserId,
    required SwapRequestStatus target,
    required bool Function(
        SwapRequest request,
        String actor,
        ) permission,
    required String permissionError,
  }) async {
    await initialize();

    final String cleanRequestId =
    _requireRequestId(
      requestId,
    );

    final String actor =
    _requireCurrentActor(
      actorUserId,
    );

    _throwIfRequestHidingOrRestoring(
      cleanRequestId,
    );

    final SwapRequest request =
    _requireRequest(
      cleanRequestId,
    );

    _requireActiveStableRequest(
      request,
    );

    if (!permission(
      request,
      actor,
    )) {
      throw SwapServiceException(
        permissionError,
      );
    }

    await _changeStatus(
      request:
      request,
      nextStatus:
      target,
    );
  }

  Future<void> _changeStatus({
    required SwapRequest request,
    required SwapRequestStatus nextStatus,
  }) async {
    final String requestId =
    request.id.trim();

    _throwIfRequestHidingOrRestoring(
      requestId,
    );

    while (true) {
      final Future<void>? pending =
      _pendingStatusChanges[
      requestId
      ];

      if (pending == null) {
        break;
      }

      try {
        await pending;
      } catch (_) {}

      _throwIfRequestHidingOrRestoring(
        requestId,
      );
    }

    final Future<void> operation =
    _changeStatusInternal(
      requestId:
      requestId,
      nextStatus:
      nextStatus,
    );

    _pendingStatusChanges[
    requestId
    ] = operation;

    try {
      await operation;
    } finally {
      if (identical(
        _pendingStatusChanges[
        requestId
        ],
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

    _requireActiveStableRequest(
      request,
    );

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
    } on SwapRepositoryException catch (_) {
      throw const SwapServiceException(
        'Could not update the swap request. Please try again.',
      );
    }

    request.status =
        nextStatus;

    request.updatedAt =
        updatedAt;

    _sortRequests();
  }

  // ============================================================
  // REMOVE FROM HISTORY
  // ============================================================

  Future<void> removeFromHistory({
    required String requestId,
    required String actorUserId,
  }) async {
    await initialize();

    final String cleanRequestId =
    _requireRequestId(
      requestId,
    );

    final String actor =
    _requireCurrentActor(
      actorUserId,
    );

    final Future<void>? existingHide =
    _pendingHides[
    cleanRequestId
    ];

    if (existingHide != null) {
      await existingHide;
      return;
    }

    final Future<SwapRequest>? pendingRestore =
    _pendingRestores[
    cleanRequestId
    ];

    if (pendingRestore != null) {
      try {
        await pendingRestore;
      } catch (_) {}

      throw const SwapServiceException(
        'This swap request is being restored. Please try again.',
      );
    }

    await _waitForPendingStatusChange(
      cleanRequestId,
    );

    final Future<void> operation =
    _removeFromHistoryInternal(
      requestId:
      cleanRequestId,
      actorUserId:
      actor,
    );

    _pendingHides[
    cleanRequestId
    ] = operation;

    try {
      await operation;
    } finally {
      if (identical(
        _pendingHides[
        cleanRequestId
        ],
        operation,
      )) {
        _pendingHides.remove(
          cleanRequestId,
        );
      }
    }
  }

  Future<void> _removeFromHistoryInternal({
    required String requestId,
    required String actorUserId,
  }) async {
    final SwapRequest request =
    _requireRequest(
      requestId,
    );

    if (request.status.isActive) {
      throw const SwapServiceException(
        'Active swap requests cannot be removed from history. Cancel or finish the request first.',
      );
    }

    if (!request.hasStableIdentity ||
        !request.involvesUser(
          actorUserId,
        )) {
      throw const SwapServiceException(
        'You are not allowed to remove this swap request from your history.',
      );
    }

    try {
      await _repository.hideSwapRequest(
        requestId:
        request.id,
        userId:
        actorUserId,
      );
    } on SwapRepositoryException catch (_) {
      throw const SwapServiceException(
        'Could not remove the swap request from your history. Please try again.',
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

  Future<void> deleteRequest({
    required String requestId,
    required String actorUserId,
  }) async {
    await removeFromHistory(
      requestId:
      requestId,
      actorUserId:
      actorUserId,
    );
  }

  // ============================================================
  // RESTORE HISTORY
  // ============================================================

  Future<SwapRequest> restoreRequest({
    required String requestId,
    required String actorUserId,
  }) async {
    await initialize();

    final String cleanRequestId =
    _requireRequestId(
      requestId,
    );

    final String actor =
    _requireCurrentActor(
      actorUserId,
    );

    final Future<SwapRequest>? existingRestore =
    _pendingRestores[
    cleanRequestId
    ];

    if (existingRestore != null) {
      return existingRestore;
    }

    final Future<void>? pendingHide =
    _pendingHides[
    cleanRequestId
    ];

    if (pendingHide != null) {
      try {
        await pendingHide;
      } catch (_) {
        rethrow;
      }
    }

    await _waitForPendingStatusChange(
      cleanRequestId,
    );

    final Future<SwapRequest> operation =
    _restoreRequestInternal(
      requestId:
      cleanRequestId,
      actorUserId:
      actor,
    );

    _pendingRestores[
    cleanRequestId
    ] = operation;

    try {
      return await operation;
    } finally {
      if (identical(
        _pendingRestores[
        cleanRequestId
        ],
        operation,
      )) {
        _pendingRestores.remove(
          cleanRequestId,
        );
      }
    }
  }

  Future<SwapRequest> _restoreRequestInternal({
    required String requestId,
    required String actorUserId,
  }) async {
    final SwapRequest? visibleRequest =
    findById(
      requestId,
    );

    if (visibleRequest != null) {
      if (!visibleRequest.involvesUser(
        actorUserId,
      )) {
        throw const SwapServiceException(
          'You are not allowed to restore this swap request.',
        );
      }

      return visibleRequest;
    }

    late final List<SwapRequest>
    allRequests;

    try {
      allRequests =
      await _repository.getAllSwapRequests(
        includeHidden:
        true,
      );
    } on SwapRepositoryException catch (_) {
      throw const SwapServiceException(
        'Could not load hidden swap history.',
      );
    } catch (_) {
      throw const SwapServiceException(
        'Could not load hidden swap history.',
      );
    }

    final List<SwapRequest> matches =
    allRequests.where(
          (
          SwapRequest request,
          ) =>
      request.id ==
          requestId,
    ).toList();

    if (matches.length != 1) {
      throw const SwapServiceException(
        'Hidden swap request could not be found.',
      );
    }

    final SwapRequest request =
        matches.single;

    _validateLoadedRequest(
      request,
    );

    if (!request.status.isTerminal) {
      throw const SwapServiceException(
        'Only finished swap history can be restored.',
      );
    }

    if (!request.hasStableIdentity ||
        !request.involvesUser(
          actorUserId,
        )) {
      throw const SwapServiceException(
        'You are not allowed to restore this swap request.',
      );
    }

    try {
      await _repository.unhideSwapRequest(
        requestId:
        request.id,
        userId:
        actorUserId,
      );
    } on SwapRepositoryException catch (_) {
      throw const SwapServiceException(
        'Could not restore the swap request. Please try again.',
      );
    }

    final bool alreadyVisible =
    _requests.any(
          (
          SwapRequest item,
          ) =>
      item.id ==
          request.id,
    );

    if (!alreadyVisible) {
      _requests.add(
        request,
      );

      _sortRequests();
    }

    return request;
  }

  // ============================================================
  // FIND / REQUIRE
  // ============================================================

  SwapRequest? findById(
      String requestId,
      ) {
    final String clean =
    requestId.trim();

    if (clean.isEmpty) {
      return null;
    }

    for (final SwapRequest request
    in _requests) {
      if (request.id ==
          clean) {
        return request;
      }
    }

    return null;
  }

  SwapRequest _requireRequest(
      String requestId,
      ) {
    final SwapRequest? request =
    findById(
      _requireRequestId(
        requestId,
      ),
    );

    if (request == null) {
      throw const SwapServiceException(
        'Swap request not found.',
      );
    }

    return request;
  }

  String _requireRequestId(
      String requestId,
      ) {
    final String clean =
    requestId.trim();

    if (clean.isEmpty) {
      throw const SwapServiceException(
        'Swap request ID is required.',
      );
    }

    return clean;
  }

  void _requireActiveStableRequest(
      SwapRequest request,
      ) {
    if (!request.status.isActive ||
        !request.hasStableIdentity ||
        !request
            .hasStructurallyValidIdentityGroup) {
      throw const SwapServiceException(
        'This active swap request does not have valid stable identity.',
      );
    }
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  String _requireCurrentLocalUser() {
    try {
      return _currentUserService
          .requireUserId();
    } on CurrentUserServiceException catch (_) {
      throw const SwapServiceException(
        'Current user identity is unavailable.',
      );
    }
  }

  String _requireCurrentActor(
      String actorUserId,
      ) {
    final String clean =
    actorUserId.trim();

    if (clean.isEmpty) {
      throw const SwapServiceException(
        'Current user identity is required.',
      );
    }

    final String current =
    _requireCurrentLocalUser();

    if (clean != current) {
      throw const SwapServiceException(
        'This action can only be performed by the active local user.',
      );
    }

    return current;
  }

  // ============================================================
  // CONCURRENCY
  // ============================================================

  void _throwIfRequestHidingOrRestoring(
      String requestId,
      ) {
    if (_pendingHides.containsKey(
      requestId,
    ) ||
        _pendingRestores.containsKey(
          requestId,
        )) {
      throw const SwapServiceException(
        'This swap request is currently unavailable.',
      );
    }
  }

  Future<void> _waitForPendingStatusChange(
      String requestId,
      ) async {
    while (true) {
      final Future<void>? pending =
      _pendingStatusChanges[
      requestId
      ];

      if (pending == null) {
        return;
      }

      try {
        await pending;
      } on SwapServiceException {
        rethrow;
      } catch (_) {
        throw const SwapServiceException(
          'The current swap request update did not finish successfully.',
        );
      }
    }
  }

  // ============================================================
  // IDENTITY VALIDATION
  // ============================================================

  void _validateIdentityGroup({
    required String? requesterUserId,
    required String? providerUserId,
    required String? skillToLearnId,
    required String? skillToOfferId,
    required bool allowNoIdentity,
  }) {
    final int present =
        <String?>[
          requesterUserId,
          providerUserId,
          skillToLearnId,
          skillToOfferId,
        ].where(
              (
              String? value,
              ) =>
          value != null &&
              value.trim().isNotEmpty,
        ).length;

    if (present == 0) {
      if (allowNoIdentity) {
        return;
      }

      throw const SwapServiceException(
        'Stable swap request identity is required.',
      );
    }

    if (present != 4) {
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
        'The two skills must be different.',
      );
    }
  }

  // ============================================================
  // CREATE VALIDATION
  // ============================================================

  void _validateCreateRequest({
    required String requesterUserId,
    required String providerUserId,
    required String skillToLearnId,
    required String skillToOfferId,
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
    if (providerName.isEmpty ||
        providerInitials.isEmpty ||
        providerCity.isEmpty ||
        skillToLearn.isEmpty ||
        skillToOffer.isEmpty) {
      throw const SwapServiceException(
        'Required swap request details are missing.',
      );
    }

    if (!proposedAt.isAfter(
      DateTime.now(),
    )) {
      throw const SwapServiceException(
        'The proposed schedule must be in the future.',
      );
    }

    if (mode != 'Online' &&
        mode != 'In-person') {
      throw const SwapServiceException(
        'Invalid session mode.',
      );
    }

    if (meetingDetails == null ||
        meetingDetails.length > 150) {
      throw const SwapServiceException(
        'Valid meeting details are required.',
      );
    }

    if (note != null &&
        note.length > 300) {
      throw const SwapServiceException(
        'Message must be 300 characters or less.',
      );
    }
  }

  // ============================================================
  // DUPLICATE ACTIVE REQUEST PROTECTION
  // ============================================================

  void _preventDuplicateActiveRequest({
    required String requesterUserId,
    required String providerUserId,
    required String skillToLearnId,
    required String skillToOfferId,
  }) {
    final String incoming =
    _stableRequestIdentityKey(
      requesterUserId:
      requesterUserId,
      providerUserId:
      providerUserId,
      skillToLearnId:
      skillToLearnId,
      skillToOfferId:
      skillToOfferId,
    );

    for (final SwapRequest request
    in _requests) {
      if (!request.status.isActive ||
          !request.hasStableIdentity) {
        continue;
      }

      final String existing =
      _stableRequestIdentityKey(
        requesterUserId:
        request.requesterUserId!,
        providerUserId:
        request.providerUserId!,
        skillToLearnId:
        request.skillToLearnId!,
        skillToOfferId:
        request.skillToOfferId!,
      );

      if (existing ==
          incoming) {
        throw const SwapServiceException(
          'You already have an active swap request with this user for the same skill exchange.',
        );
      }
    }
  }

  String _stableRequestIdentityKey({
    required String requesterUserId,
    required String providerUserId,
    required String skillToLearnId,
    required String skillToOfferId,
  }) {
    return <String>[
      requesterUserId.trim(),
      providerUserId.trim(),
      skillToLearnId.trim(),
      skillToOfferId.trim(),
    ].join('|');
  }

  // ============================================================
  // REQUEST ID
  // ============================================================

  void _syncRequestIdCounter(
      List<SwapRequest> requests,
      ) {
    int highest =
        _lastRequestIdMicros;

    for (final SwapRequest request
    in requests) {
      final int micros =
          request.createdAt
              .microsecondsSinceEpoch;

      if (micros > highest) {
        highest = micros;
      }

      final int? id =
      int.tryParse(
        request.id.trim(),
      );

      if (id != null &&
          id > highest) {
        highest = id;
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
  // SORT
  // ============================================================

  void _sortRequests() {
    _requests.sort(
          (
          SwapRequest a,
          SwapRequest b,
          ) =>
          b.updatedAt.compareTo(
            a.updatedAt,
          ),
    );
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

    return cleaned.isEmpty
        ? null
        : cleaned;
  }
}