import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../model/repositories/explore_repository.dart';
import '../model/user.dart';
import 'current_user_service.dart';

class ProfileImageServiceException implements Exception {
  final String message;

  const ProfileImageServiceException(
      this.message,
      );

  @override
  String toString() => message;
}

class ProfileImageService {
  ProfileImageService._();

  static final ProfileImageService instance =
  ProfileImageService._();

  final ImagePicker _imagePicker =
  ImagePicker();

  final ExploreRepository _repository =
      ExploreRepository.instance;

  final CurrentUserService _currentUserService =
      CurrentUserService.instance;

  static const int _maxSourceBytes =
      10 * 1024 * 1024;

  static const Set<String> _allowedExtensions =
  <String>{
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  };

  // ============================================================
  // PICK + SAVE CURRENT USER PROFILE IMAGE
  // ============================================================

  Future<User?> pickAndSaveCurrentUserProfileImage() async {
    final String currentUserId =
    _requireCurrentUserId();

    await _repository.initialize();

    final User? currentUser =
    _repository.findUserById(
      currentUserId,
    );

    if (currentUser == null) {
      throw const ProfileImageServiceException(
        'Your profile could not be found.',
      );
    }

    final XFile? pickedImage =
    await _pickImageFromGallery();

    if (pickedImage == null) {
      return null;
    }

    final File sourceFile =
    File(
      pickedImage.path,
    );

    if (!await sourceFile.exists()) {
      throw const ProfileImageServiceException(
        'The selected photo could not be found.',
      );
    }

    final int sourceLength;

    try {
      sourceLength =
      await sourceFile.length();
    } on FileSystemException {
      throw const ProfileImageServiceException(
        'The selected photo could not be read.',
      );
    } catch (_) {
      throw const ProfileImageServiceException(
        'The selected photo could not be read.',
      );
    }

    if (sourceLength <= 0) {
      throw const ProfileImageServiceException(
        'The selected photo is empty or invalid.',
      );
    }

    if (sourceLength > _maxSourceBytes) {
      throw const ProfileImageServiceException(
        'Please choose a photo smaller than 10 MB.',
      );
    }

    final String extension =
    _safeImageExtension(
      pickedImage.path,
    );

    final Directory profileDirectory =
    await _profileImageDirectory();

    final String safeUserId =
    _safeFileComponent(
      currentUserId,
    );

    final String fileName =
        '${safeUserId}_${DateTime.now().microsecondsSinceEpoch}$extension';

    final String targetPath =
    p.join(
      profileDirectory.path,
      fileName,
    );

    final File targetFile =
    File(
      targetPath,
    );

    try {
      await sourceFile.copy(
        targetPath,
      );
    } on FileSystemException {
      throw const ProfileImageServiceException(
        'The selected photo could not be saved to app storage.',
      );
    } catch (_) {
      throw const ProfileImageServiceException(
        'The selected photo could not be saved to app storage.',
      );
    }

    try {
      final User updatedUser =
      await _repository.updateCurrentUserProfileImagePath(
        profileImagePath:
        targetPath,
      );

      await _deleteManagedFileIfSafe(
        currentUser.profileImagePath,
        exceptPath:
        targetPath,
      );

      return updatedUser;
    } on ExploreRepositoryException catch (error) {
      await _deleteFileQuietly(
        targetFile,
      );

      throw ProfileImageServiceException(
        error.message,
      );
    } catch (_) {
      await _deleteFileQuietly(
        targetFile,
      );

      throw const ProfileImageServiceException(
        'Your profile photo could not be updated.',
      );
    }
  }

  // ============================================================
  // GALLERY PICKER
  // ============================================================

  Future<XFile?> _pickImageFromGallery() async {
    try {
      return await _imagePicker.pickImage(
        source:
        ImageSource.gallery,
        maxWidth:
        1600,
        maxHeight:
        1600,
        imageQuality:
        88,
        requestFullMetadata:
        false,
      );
    } on MissingPluginException {
      throw const ProfileImageServiceException(
        'Image Picker is not registered in the Android app. '
            'Stop the app completely, rebuild it, and try again.',
      );
    } on PlatformException catch (error) {
      final String code =
      error.code.trim();

      final String message =
          error.message?.trim() ??
              '';

      if (code == 'already_active') {
        throw const ProfileImageServiceException(
          'The photo picker is already open.',
        );
      }

      if (code == 'camera_access_denied' ||
          code == 'photo_access_denied') {
        throw const ProfileImageServiceException(
          'Photo access was denied. Check the app permissions and try again.',
        );
      }

      if (message.isNotEmpty) {
        throw ProfileImageServiceException(
          'Photo picker error: $code — $message',
        );
      }

      throw ProfileImageServiceException(
        'Photo picker error: $code',
      );
    } catch (error) {
      throw ProfileImageServiceException(
        'Photo picker failed: ${error.runtimeType}',
      );
    }
  }

  // ============================================================
  // REMOVE CURRENT USER PROFILE IMAGE
  // ============================================================

  Future<User> removeCurrentUserProfileImage() async {
    final String currentUserId =
    _requireCurrentUserId();

    await _repository.initialize();

    final User? currentUser =
    _repository.findUserById(
      currentUserId,
    );

    if (currentUser == null) {
      throw const ProfileImageServiceException(
        'Your profile could not be found.',
      );
    }

    final String? previousPath =
        currentUser.profileImagePath;

    try {
      final User updatedUser =
      await _repository.updateCurrentUserProfileImagePath(
        profileImagePath:
        null,
      );

      await _deleteManagedFileIfSafe(
        previousPath,
      );

      return updatedUser;
    } on ExploreRepositoryException catch (error) {
      throw ProfileImageServiceException(
        error.message,
      );
    } catch (_) {
      throw const ProfileImageServiceException(
        'Your profile photo could not be removed.',
      );
    }
  }

  // ============================================================
  // FILE HELPERS
  // ============================================================

  Future<Directory> _profileImageDirectory() async {
    final Directory supportDirectory;

    try {
      supportDirectory =
      await getApplicationSupportDirectory();
    } catch (_) {
      throw const ProfileImageServiceException(
        'App storage is unavailable.',
      );
    }

    final Directory directory =
    Directory(
      p.join(
        supportDirectory.path,
        'profile_images',
      ),
    );

    try {
      if (!await directory.exists()) {
        await directory.create(
          recursive:
          true,
        );
      }
    } catch (_) {
      throw const ProfileImageServiceException(
        'Profile photo storage could not be prepared.',
      );
    }

    return directory;
  }

  String _safeImageExtension(
      String sourcePath,
      ) {
    final String extension =
    p.extension(
      sourcePath,
    ).toLowerCase();

    if (_allowedExtensions.contains(
      extension,
    )) {
      return extension;
    }

    return '.jpg';
  }

  String _safeFileComponent(
      String value,
      ) {
    final String cleaned =
    value
        .trim()
        .replaceAll(
      RegExp(
        r'[^A-Za-z0-9_-]',
      ),
      '_',
    );

    if (cleaned.isEmpty) {
      return 'user';
    }

    return cleaned;
  }

  Future<void> _deleteManagedFileIfSafe(
      String? path, {
        String? exceptPath,
      }) async {
    final String? cleanPath =
    _cleanNullablePath(
      path,
    );

    if (cleanPath == null) {
      return;
    }

    final String? cleanExceptPath =
    _cleanNullablePath(
      exceptPath,
    );

    if (cleanExceptPath != null &&
        p.equals(
          p.normalize(
            cleanPath,
          ),
          p.normalize(
            cleanExceptPath,
          ),
        )) {
      return;
    }

    final Directory managedDirectory;

    try {
      managedDirectory =
      await _profileImageDirectory();
    } on ProfileImageServiceException {
      return;
    }

    final String normalizedManagedDirectory =
    p.normalize(
      managedDirectory.path,
    );

    final String normalizedFilePath =
    p.normalize(
      cleanPath,
    );

    if (!p.isWithin(
      normalizedManagedDirectory,
      normalizedFilePath,
    )) {
      return;
    }

    await _deleteFileQuietly(
      File(
        normalizedFilePath,
      ),
    );
  }

  Future<void> _deleteFileQuietly(
      File file,
      ) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Cleanup failure should not make the user action fail.
    }
  }

  String? _cleanNullablePath(
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

  // ============================================================
  // CURRENT USER
  // ============================================================

  String _requireCurrentUserId() {
    try {
      return _currentUserService.requireUserId();
    } on CurrentUserServiceException {
      throw const ProfileImageServiceException(
        'Current user identity is unavailable.',
      );
    }
  }
}