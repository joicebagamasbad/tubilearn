import '../model/repositories/explore_repository.dart';
import '../model/repositories/firestore_explore_repository.dart';
import '../model/repositories/local_explore_projection_repository.dart';
import 'current_user_service.dart';

class ExploreServiceException implements Exception {
  final String message;

  const ExploreServiceException(this.message);

  @override
  String toString() => message;
}

enum ExploreServiceSource { server, cache, localFallback }

class ExploreServiceResult {
  final ExploreServiceSource source;
  final bool remoteProjectionOccurred;
  final int? candidateCount;

  const ExploreServiceResult({
    required this.source,
    required this.remoteProjectionOccurred,
    required this.candidateCount,
  });
}

class ExploreService {
  ExploreService({
    FirestoreExploreRepository? firestoreRepository,
    LocalExploreProjectionRepository? localRepository,
    ExploreRepository? exploreRepository,
    CurrentUserService? currentUserService,
  }) : _firestoreRepository =
           firestoreRepository ?? FirestoreExploreRepository.instance,
       _localRepository =
           localRepository ?? LocalExploreProjectionRepository.instance,
       _exploreRepository = exploreRepository ?? ExploreRepository.instance,
       _currentUserService = currentUserService ?? CurrentUserService.instance;

  static final ExploreService instance = ExploreService();

  final FirestoreExploreRepository _firestoreRepository;
  final LocalExploreProjectionRepository _localRepository;
  final ExploreRepository _exploreRepository;
  final CurrentUserService _currentUserService;

  Future<ExploreServiceResult> prepareCurrentSession() {
    return _runForCurrentSession();
  }

  Future<ExploreServiceResult> refreshCurrentExplore() {
    return _runForCurrentSession();
  }

  Future<ExploreServiceResult> _runForCurrentSession() {
    return _currentUserService.runForSession<ExploreServiceResult>(() async {
      final String uid = _currentUserService.requireUserId();
      final FirestoreExploreSnapshot snapshot;
      try {
        snapshot = await _firestoreRepository.load(uid);
      } on FirestoreExploreRepositoryException catch (error) {
        throw ExploreServiceException(error.message);
      }
      _currentUserService.requireActiveOperation();

      final bool remoteProjectionOccurred =
          snapshot.source != FirestoreExploreSource.unavailable;
      if (remoteProjectionOccurred) {
        _currentUserService.requireActiveOperation();
        try {
          await _localRepository.project(viewerUid: uid, snapshot: snapshot);
        } on LocalExploreProjectionException catch (error) {
          throw ExploreServiceException(error.message);
        }
        _currentUserService.requireActiveOperation();
      }

      _currentUserService.requireActiveOperation();
      try {
        await _exploreRepository.refresh();
      } on ExploreRepositoryException catch (error) {
        throw ExploreServiceException(error.message);
      }
      _currentUserService.requireActiveOperation();

      final ExploreServiceResult result = ExploreServiceResult(
        source: _serviceSource(snapshot.source),
        remoteProjectionOccurred: remoteProjectionOccurred,
        candidateCount: remoteProjectionOccurred ? snapshot.users.length : null,
      );
      _currentUserService.requireActiveOperation();
      return result;
    });
  }

  ExploreServiceSource _serviceSource(FirestoreExploreSource source) {
    switch (source) {
      case FirestoreExploreSource.server:
        return ExploreServiceSource.server;
      case FirestoreExploreSource.cache:
        return ExploreServiceSource.cache;
      case FirestoreExploreSource.unavailable:
        return ExploreServiceSource.localFallback;
    }
  }
}
