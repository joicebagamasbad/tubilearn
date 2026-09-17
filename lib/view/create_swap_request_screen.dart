import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/create_swap_request_controller.dart';
import '../model/skill.dart';
import '../model/user.dart';
import '../theme/app_theme.dart';

class CreateSwapRequestScreen extends StatefulWidget {
  final String? providerUserId;
  final String? skillToLearnId;
  final String? skillToOfferId;
  final String? skillToOffer;

  final String providerName;
  final String providerInitials;
  final String providerCity;
  final String skillToLearn;

  const CreateSwapRequestScreen({
    super.key,
    this.providerUserId,
    this.skillToLearnId,
    this.skillToOfferId,
    this.skillToOffer,
    required this.providerName,
    required this.providerInitials,
    required this.providerCity,
    required this.skillToLearn,
  });

  @override
  State<CreateSwapRequestScreen> createState() =>
      _CreateSwapRequestScreenState();
}

class _CreateSwapRequestScreenState
    extends State<CreateSwapRequestScreen> {
  final CreateSwapRequestController _controller =
  CreateSwapRequestController();

  final TextEditingController _noteController =
  TextEditingController();

  final TextEditingController _meetingDetailsController =
  TextEditingController();

  CreateSwapRequestSnapshot? _snapshot;

  final List<Skill> _mySkills = <Skill>[];

  Skill? _selectedSkillToOffer;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String? _selectedMode = 'Online';

  bool _isLoading = true;
  bool _isSending = false;
  bool _hasUnsavedChanges = false;
  bool _isShowingLeaveDialog = false;

  String? _loadError;

  // ============================================================
  // INPUT
  // ============================================================

  CreateSwapRequestInput get _requestInput =>
      CreateSwapRequestInput(
        providerUserId: widget.providerUserId,
        skillToLearnId: widget.skillToLearnId,
        skillToOfferId: widget.skillToOfferId,
        skillToOffer: widget.skillToOffer,
        providerName: widget.providerName,
        providerInitials: widget.providerInitials,
        providerCity: widget.providerCity,
        skillToLearn: widget.skillToLearn,
      );

  // ============================================================
  // SNAPSHOT
  // ============================================================

  User? get _resolvedProvider =>
      _snapshot?.provider;

  Skill? get _resolvedSkillToLearn =>
      _snapshot?.skillToLearn;

  bool get _providerStillOffersLearnSkill =>
      _snapshot?.providerStillOffersLearnSkill ??
          false;

  // ============================================================
  // THEME
  // ============================================================

  bool get _isDarkMode =>
      Theme.of(context).brightness ==
          Brightness.dark;

  Color get _primaryColor =>
      Theme.of(context).colorScheme.primary;

  Color get _surfaceColor =>
      Theme.of(context).colorScheme.surface;

  Color get _surfaceVariantColor =>
      Theme.of(context)
          .colorScheme
          .surfaceContainerHighest;

  Color get _textColor =>
      Theme.of(context).colorScheme.onSurface;

  Color get _mutedColor =>
      Theme.of(context)
          .colorScheme
          .onSurfaceVariant;

  Color get _borderColor =>
      Theme.of(context)
          .colorScheme
          .outlineVariant;

  Color get _highlightBackground =>
      _isDarkMode
          ? _primaryColor.withValues(
        alpha: 0.14,
      )
          : const Color(
        0xFFE4F0EF,
      );

  Color get _highlightBorder =>
      _isDarkMode
          ? _primaryColor.withValues(
        alpha: 0.28,
      )
          : const Color(
        0xFFD2E5E2,
      );

  // ============================================================
  // SESSION MODE
  // ============================================================

  List<String> get _supportedModes =>
      _controller.supportedModes(
        skillToLearn: _resolvedSkillToLearn,
        skillToOffer: _selectedSkillToOffer,
      );

  bool get _hasCommonSessionMode =>
      _supportedModes.isNotEmpty;

  bool get _canAttemptSend =>
      !_isSending &&
          _selectedSkillToOffer != null &&
          _selectedMode != null &&
          _hasCommonSessionMode;

  bool _isModeSupported(
      String mode,
      ) {
    return _controller.isModeSupported(
      skillToLearn: _resolvedSkillToLearn,
      skillToOffer: _selectedSkillToOffer,
      mode: mode,
    );
  }

  void _normalizeSelectedMode({
    required bool clearMeetingDetails,
  }) {
    final String? normalized =
    _controller.normalizedMode(
      skillToLearn: _resolvedSkillToLearn,
      skillToOffer: _selectedSkillToOffer,
      currentMode: _selectedMode,
    );

    if (_selectedMode == normalized) {
      return;
    }

    _selectedMode = normalized;

    if (clearMeetingDetails) {
      _meetingDetailsController.clear();
    }
  }

  void _selectMode(
      String mode,
      ) {
    if (_isSending ||
        !_isModeSupported(mode) ||
        _selectedMode == mode) {
      return;
    }

    setState(() {
      _selectedMode = mode;
      _meetingDetailsController.clear();
      _hasUnsavedChanges = true;
    });
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadScreenData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _meetingDetailsController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadScreenData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final CreateSwapRequestSnapshot snapshot =
      await _controller.load(
        _requestInput,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _snapshot = snapshot;

        _mySkills
          ..clear()
          ..addAll(
            snapshot.availableOfferSkills,
          );

        if (_selectedSkillToOffer != null &&
            !_mySkills.any(
                  (
                  Skill skill,
                  ) =>
              skill.id ==
                  _selectedSkillToOffer!.id,
            )) {
          _selectedSkillToOffer = null;
        }

        _selectedSkillToOffer ??=
            snapshot.preselectedOfferSkill;

        _normalizeSelectedMode(
          clearMeetingDetails: false,
        );

        _isLoading = false;
        _loadError = null;
      });
    } on CreateSwapRequestControllerException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError =
        'Swap request details could not be loaded. Please try again.';
      });
    }
  }

  // ============================================================
  // UNSAVED CHANGES
  // ============================================================

  void _markChanged() {
    if (_hasUnsavedChanges ||
        _isLoading ||
        _isSending) {
      return;
    }

    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _handleBackPressed() async {
    if (_isSending ||
        _isShowingLeaveDialog) {
      return;
    }

    if (!_hasUnsavedChanges) {
      if (mounted) {
        Navigator.pop(context);
      }

      return;
    }

    _isShowingLeaveDialog = true;

    final bool shouldDiscard =
    await _showDiscardConfirmation();

    _isShowingLeaveDialog = false;

    if (!mounted ||
        !shouldDiscard) {
      return;
    }

    setState(() {
      _hasUnsavedChanges = false;
    });

    Navigator.pop(context);
  }

  Future<bool> _showDiscardConfirmation() async {
    final bool? result =
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.accent,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  'Discard this request?',
                  style:
                  AppTextStyles.cardTitle
                      .copyWith(
                    color: _textColor,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'You have unsaved changes. If you leave now, your request details will be lost.',
            style:
            AppTextStyles.body.copyWith(
              color: _textColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
              const Text(
                'KEEP EDITING',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
              const Text(
                'DISCARD',
                style:
                AppTextStyles.button,
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return PopScope(
      canPop:
      !_isSending &&
          !_hasUnsavedChanges,
      onPopInvokedWithResult: (
          bool didPop,
          Object? result,
          ) {
        if (didPop) {
          return;
        }

        _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor:
        Theme.of(context)
            .scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor:
          _surfaceColor,
          surfaceTintColor:
          Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed:
            _isSending
                ? null
                : _handleBackPressed,
            icon: Icon(
              Icons
                  .arrow_back_ios_new_rounded,
              size: 19,
              color:
              _isSending
                  ? _mutedColor
                  : _primaryColor,
            ),
          ),
          title: Text(
            'Request a Skill Swap',
            style:
            AppTextStyles.cardTitle
                .copyWith(
              color: _textColor,
            ),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child:
              CircularProgressIndicator(
                strokeWidth: 2.5,
                color:
                _primaryColor,
              ),
            ),
            const SizedBox(
              height: 14,
            ),
            Text(
              'Loading your skills...',
              style:
              AppTextStyles.secondary
                  .copyWith(
                color:
                _mutedColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_loadError != null) {
      return _buildErrorState();
    }

    if (_resolvedProvider == null) {
      return _buildUnavailableState(
        title:
        'Provider unavailable',
        message:
        'We could not safely identify this provider. Go back to Explore and open their profile again.',
      );
    }

    if (_resolvedSkillToLearn == null) {
      return _buildUnavailableState(
        title:
        'Skill unavailable',
        message:
        'We could not safely identify the skill for this request. Go back and select the skill again.',
      );
    }

    if (!_providerStillOffersLearnSkill) {
      return _buildUnavailableState(
        title:
        'Skill no longer offered',
        message:
        'This provider no longer offers the selected skill. Go back to Explore and choose another available provider.',
      );
    }

    return SingleChildScrollView(
      physics:
      const BouncingScrollPhysics(),
      padding:
      const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        30,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _buildIntroduction(),

          const SizedBox(
            height: 26,
          ),

          _buildSectionLabel(
            'You want to learn',
          ),

          const SizedBox(
            height: 8,
          ),

          _buildReadOnlySkill(),

          const SizedBox(
            height: 22,
          ),

          _buildSectionLabel(
            'What can you offer?',
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'Choose one of your saved skills to teach in exchange.',
            style:
            AppTextStyles.secondary
                .copyWith(
              color: _mutedColor,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          _buildSkillDropdown(),

          const SizedBox(
            height: 22,
          ),

          _buildSectionLabel(
            'Preferred schedule',
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'Suggest a date and time that works for you.',
            style:
            AppTextStyles.secondary
                .copyWith(
              color: _mutedColor,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Row(
            children: [
              Expanded(
                child:
                _buildDateSelector(),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child:
                _buildTimeSelector(),
              ),
            ],
          ),

          const SizedBox(
            height: 22,
          ),

          _buildSectionLabel(
            'Session mode',
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'Only modes supported by both skills can be selected.',
            style:
            AppTextStyles.secondary
                .copyWith(
              color: _mutedColor,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          _buildModeSelector(),

          if (_selectedSkillToOffer !=
              null &&
              !_hasCommonSessionMode) ...[
            const SizedBox(
              height: 10,
            ),
            _buildNoCommonModeWarning(),
          ],

          const SizedBox(
            height: 16,
          ),

          _buildMeetingDetails(),

          const SizedBox(
            height: 22,
          ),

          _buildSectionLabel(
            'Message',
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'Introduce yourself or add anything the other person should know.',
            style:
            AppTextStyles.secondary
                .copyWith(
              color: _mutedColor,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          TextField(
            controller:
            _noteController,
            enabled:
            !_isSending,
            maxLines: 4,
            maxLength: 300,
            maxLengthEnforcement:
            MaxLengthEnforcement
                .enforced,
            onChanged: (_) {
              _markChanged();
            },
            style:
            AppTextStyles.input
                .copyWith(
              color: _textColor,
            ),
            decoration:
            InputDecoration(
              hintText:
              'Example: Hi! I would love to learn this skill. I can help you with...',
              hintStyle:
              AppTextStyles.inputHint
                  .copyWith(
                color:
                _mutedColor,
              ),
              filled: true,
              fillColor:
              _surfaceColor,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          _buildRequestSummary(),

          const SizedBox(
            height: 24,
          ),

          SizedBox(
            width:
            double.infinity,
            height: 50,
            child:
            ElevatedButton(
              onPressed:
              _canAttemptSend
                  ? _sendRequest
                  : null,
              child:
              _isSending
                  ? Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .center,
                children: [
                  SizedBox(
                    width:
                    20,
                    height:
                    20,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2.2,
                      color:
                      _isDarkMode
                          ? const Color(
                        0xFF092E31,
                      )
                          : Colors
                          .white,
                    ),
                  ),
                  const SizedBox(
                    width:
                    10,
                  ),
                  const Text(
                    'SENDING...',
                    style:
                    AppTextStyles
                        .button,
                  ),
                ],
              )
                  : const Text(
                'SEND SWAP REQUEST',
                style:
                AppTextStyles
                    .button,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR / UNAVAILABLE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 42,
              color:
              _mutedColor,
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              'Could not load your skills',
              style:
              AppTextStyles.cardTitle
                  .copyWith(
                color:
                _textColor,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              _loadError ??
                  'Something went wrong.',
              textAlign:
              TextAlign.center,
              style:
              AppTextStyles.secondary
                  .copyWith(
                color:
                _mutedColor,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            ElevatedButton(
              onPressed:
              _loadScreenData,
              child:
              const Text(
                'RETRY',
                style:
                AppTextStyles.button,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableState({
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/mascot/tubi_confused.png',
              width: 95,
              height: 95,
              fit:
              BoxFit.contain,
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              title,
              textAlign:
              TextAlign.center,
              style:
              AppTextStyles.cardTitle
                  .copyWith(
                color:
                _textColor,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              message,
              textAlign:
              TextAlign.center,
              style:
              AppTextStyles.secondary
                  .copyWith(
                color:
                _mutedColor,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            OutlinedButton(
              onPressed:
              _handleBackPressed,
              child:
              const Text(
                'GO BACK',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INTRODUCTION
  // ============================================================

  Widget _buildIntroduction() {
    final User provider =
    _resolvedProvider!;

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      BoxDecoration(
        color:
        _highlightBackground,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border:
        Border.all(
          color:
          _highlightBorder,
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/mascot/tubi_planning.png',
            width: 65,
            height: 65,
            fit:
            BoxFit.contain,
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Swap with ${provider.name}',
                  style:
                  AppTextStyles.cardTitle
                      .copyWith(
                    color:
                    _textColor,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Make a clear request so both of you know what you will learn, teach, and when you are available.',
                  style:
                  AppTextStyles.secondary
                      .copyWith(
                    color:
                    _mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(
      String text,
      ) {
    return Text(
      text,
      style:
      AppTextStyles.cardTitle
          .copyWith(
        color:
        _textColor,
      ),
    );
  }

  // ============================================================
  // SKILL TO LEARN
  // ============================================================

  Widget _buildReadOnlySkill() {
    final Skill skill =
    _resolvedSkillToLearn!;

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration:
      BoxDecoration(
        color:
        _surfaceVariantColor,
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        border:
        Border.all(
          color:
          _borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.school_outlined,
            size: 20,
            color:
            _primaryColor,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  skill.title,
                  style:
                  AppTextStyles.body
                      .copyWith(
                    color:
                    _textColor,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  skill.mode,
                  style:
                  AppTextStyles.caption
                      .copyWith(
                    color:
                    _mutedColor,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color:
            _mutedColor,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OFFER SKILL
  // ============================================================

  Widget _buildSkillDropdown() {
    if (_mySkills.isEmpty) {
      return Container(
        width:
        double.infinity,
        padding:
        const EdgeInsets.all(
          14,
        ),
        decoration:
        BoxDecoration(
          color:
          _isDarkMode
              ? AppTheme.accent
              .withValues(
            alpha: 0.12,
          )
              : const Color(
            0xFFFFF6E8,
          ),
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          border:
          Border.all(
            color:
            _isDarkMode
                ? AppTheme.accent
                .withValues(
              alpha: 0.30,
            )
                : const Color(
              0xFFF2D1A6,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 19,
              color:
              AppTheme.accent,
            ),

            const SizedBox(
              width: 9,
            ),

            Expanded(
              child: Text(
                'You do not have another offered skill available for this swap. Add a skill in My Skills first.',
                style:
                AppTextStyles.secondary
                    .copyWith(
                  color:
                  _mutedColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<Skill>(
      key:
      ValueKey<String?>(
        _selectedSkillToOffer?.id,
      ),
      initialValue:
      _selectedSkillToOffer,
      dropdownColor:
      _surfaceColor,
      isExpanded: true,
      style:
      AppTextStyles.input
          .copyWith(
        color:
        _textColor,
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color:
        _primaryColor,
      ),
      decoration:
      InputDecoration(
        hintText:
        'Select a skill you can teach',
        hintStyle:
        AppTextStyles.inputHint
            .copyWith(
          color:
          _mutedColor,
        ),
        filled: true,
        fillColor:
        _surfaceColor,
      ),
      items:
      _mySkills.map(
            (
            Skill skill,
            ) {
          return DropdownMenuItem<Skill>(
            value:
            skill,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    skill.title,
                    maxLines: 1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Flexible(
                  child: Text(
                    skill.mode,
                    maxLines: 1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    textAlign:
                    TextAlign.right,
                    style:
                    AppTextStyles.caption
                        .copyWith(
                      color:
                      _mutedColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
      onChanged:
      _isSending
          ? null
          : (
          Skill? value,
          ) {
        setState(() {
          final String? oldMode =
              _selectedMode;

          _selectedSkillToOffer =
              value;

          _normalizeSelectedMode(
            clearMeetingDetails:
            false,
          );

          if (oldMode !=
              _selectedMode) {
            _meetingDetailsController
                .clear();
          }

          _hasUnsavedChanges =
          true;
        });
      },
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  Widget _buildDateSelector() {
    return InkWell(
      borderRadius:
      BorderRadius.circular(
        12,
      ),
      onTap:
      _isSending
          ? null
          : _selectDate,
      child: Container(
        height: 52,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration:
        BoxDecoration(
          color:
          _surfaceColor,
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          border:
          Border.all(
            color:
            _borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 19,
              color:
              _primaryColor,
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child: Text(
                _selectedDate ==
                    null
                    ? 'Select date'
                    : _formatDate(
                  _selectedDate!,
                ),
                style:
                _selectedDate ==
                    null
                    ? AppTextStyles
                    .inputHint
                    .copyWith(
                  color:
                  _mutedColor,
                )
                    : AppTextStyles
                    .input
                    .copyWith(
                  color:
                  _textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    if (_isSending) {
      return;
    }

    final DateTime now =
    DateTime.now();

    final DateTime today =
    DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime? result =
    await showDatePicker(
      context: context,
      initialDate:
      today.add(
        const Duration(
          days: 1,
        ),
      ),
      firstDate:
      today,
      lastDate:
      today.add(
        const Duration(
          days: 90,
        ),
      ),
    );

    if (result == null ||
        !mounted ||
        _isSending) {
      return;
    }

    setState(() {
      _selectedDate = result;
      _hasUnsavedChanges = true;
    });
  }

  // ============================================================
  // TIME
  // ============================================================

  Widget _buildTimeSelector() {
    return InkWell(
      borderRadius:
      BorderRadius.circular(
        12,
      ),
      onTap:
      _isSending
          ? null
          : _selectTime,
      child: Container(
        height: 52,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration:
        BoxDecoration(
          color:
          _surfaceColor,
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          border:
          Border.all(
            color:
            _borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 19,
              color:
              _primaryColor,
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child: Text(
                _selectedTime ==
                    null
                    ? 'Select time'
                    : _selectedTime!
                    .format(
                  context,
                ),
                style:
                _selectedTime ==
                    null
                    ? AppTextStyles
                    .inputHint
                    .copyWith(
                  color:
                  _mutedColor,
                )
                    : AppTextStyles
                    .input
                    .copyWith(
                  color:
                  _textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    if (_isSending) {
      return;
    }

    final TimeOfDay? result =
    await showTimePicker(
      context: context,
      initialTime:
      _selectedTime ??
          const TimeOfDay(
            hour: 16,
            minute: 0,
          ),
    );

    if (result == null ||
        !mounted ||
        _isSending) {
      return;
    }

    setState(() {
      _selectedTime = result;
      _hasUnsavedChanges = true;
    });
  }

  // ============================================================
  // MODE
  // ============================================================

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child:
          _buildModeOption(
            label:
            'Online',
            icon:
            Icons.videocam_outlined,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child:
          _buildModeOption(
            label:
            'In-person',
            icon:
            Icons
                .people_outline_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildModeOption({
    required String label,
    required IconData icon,
  }) {
    final bool supported =
    _isModeSupported(
      label,
    );

    final bool selected =
        supported &&
            _selectedMode ==
                label;

    final bool enabled =
        supported &&
            !_isSending;

    return Opacity(
      opacity:
      supported
          ? 1
          : 0.48,
      child: InkWell(
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        onTap:
        enabled
            ? () {
          _selectMode(
            label,
          );
        }
            : null,
        child:
        AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 160,
          ),
          height: 68,
          decoration:
          BoxDecoration(
            color:
            selected
                ? _primaryColor
                .withValues(
              alpha:
              _isDarkMode
                  ? 0.18
                  : 0.10,
            )
                : _surfaceColor,
            borderRadius:
            BorderRadius.circular(
              12,
            ),
            border:
            Border.all(
              color:
              selected
                  ? _primaryColor
                  : _borderColor,
              width:
              selected
                  ? 1.4
                  : 1,
            ),
          ),
          child: Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment
                  .center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color:
                  selected
                      ? _primaryColor
                      : _mutedColor,
                ),

                const SizedBox(
                  width: 7,
                ),

                Flexible(
                  child: Text(
                    supported
                        ? label
                        : '$label • unavailable',
                    textAlign:
                    TextAlign.center,
                    maxLines: 2,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    AppTextStyles.secondary
                        .copyWith(
                      color:
                      selected
                          ? _primaryColor
                          : _mutedColor,
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoCommonModeWarning() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        12,
      ),
      decoration:
      BoxDecoration(
        color:
        _isDarkMode
            ? AppTheme.accent
            .withValues(
          alpha: 0.12,
        )
            : const Color(
          0xFFFFF6E8,
        ),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        border:
        Border.all(
          color:
          _isDarkMode
              ? AppTheme.accent
              .withValues(
            alpha: 0.28,
          )
              : const Color(
            0xFFF2D1A6,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color:
            AppTheme.accent,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              'These two skills do not share a compatible session mode. Choose a different skill to offer.',
              style:
              AppTextStyles.secondary
                  .copyWith(
                color:
                _mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MEETING DETAILS
  // ============================================================

  Widget _buildMeetingDetails() {
    final String? selectedMode =
        _selectedMode;

    if (_selectedSkillToOffer ==
        null) {
      return _buildDisabledMeetingDetails(
        'Select a skill you can offer before choosing meeting details.',
      );
    }

    if (selectedMode == null) {
      return _buildDisabledMeetingDetails(
        'A compatible session mode is required before adding meeting details.',
      );
    }

    final bool online =
        selectedMode ==
            'Online';

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          online
              ? 'Preferred online platform'
              : 'Preferred meeting area',
          style:
          AppTextStyles.cardTitle
              .copyWith(
            fontSize: 13,
            color:
            _textColor,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        TextField(
          controller:
          _meetingDetailsController,
          enabled:
          !_isSending,
          maxLength: 150,
          maxLengthEnforcement:
          MaxLengthEnforcement
              .enforced,
          onChanged: (_) {
            _markChanged();
          },
          style:
          AppTextStyles.input
              .copyWith(
            color:
            _textColor,
          ),
          decoration:
          InputDecoration(
            hintText:
            online
                ? 'Example: Google Meet or Messenger'
                : 'Example: DCT campus or a public café',
            hintStyle:
            AppTextStyles.inputHint
                .copyWith(
              color:
              _mutedColor,
            ),
            prefixIcon:
            Icon(
              online
                  ? Icons.language_rounded
                  : Icons
                  .location_on_outlined,
              size: 20,
              color:
              _primaryColor,
            ),
            filled: true,
            fillColor:
            _surfaceColor,
          ),
        ),

        if (!online) ...[
          const SizedBox(
            height: 7,
          ),
          Text(
            'For safety, use a public meeting place. Exact details can be confirmed after the request is accepted.',
            style:
            AppTextStyles.secondary
                .copyWith(
              color:
              _mutedColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDisabledMeetingDetails(
      String message,
      ) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color:
        _surfaceVariantColor,
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        border:
        Border.all(
          color:
          _borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color:
            _mutedColor,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              message,
              style:
              AppTextStyles.secondary
                  .copyWith(
                color:
                _mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildRequestSummary() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color:
        _surfaceColor,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border:
        Border.all(
          color:
          _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'Request summary',
            style:
            AppTextStyles.cardTitle
                .copyWith(
              color:
              _textColor,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          _buildSummaryRow(
            'Learn',
            _resolvedSkillToLearn!
                .title,
          ),

          _buildSummaryRow(
            'Offer',
            _selectedSkillToOffer
                ?.title ??
                'Not selected',
          ),

          _buildSummaryRow(
            'Schedule',
            _selectedDate ==
                null ||
                _selectedTime ==
                    null
                ? 'Not selected'
                : '${_formatDate(_selectedDate!)} • ${_selectedTime!.format(context)}',
          ),

          _buildSummaryRow(
            'Mode',
            _selectedMode ??
                'Not available',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      String label,
      String value, {
        bool showDivider = true,
      }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(
                label,
                style:
                AppTextStyles.secondary
                    .copyWith(
                  color:
                  _mutedColor,
                ),
              ),
            ),

            Expanded(
              child: Text(
                value,
                textAlign:
                TextAlign.right,
                style:
                AppTextStyles.secondary
                    .copyWith(
                  color:
                  _textColor,
                  fontWeight:
                  FontWeight
                      .w600,
                ),
              ),
            ),
          ],
        ),

        if (showDivider)
          Padding(
            padding:
            const EdgeInsets.symmetric(
              vertical: 9,
            ),
            child: Divider(
              height: 1,
              color:
              _borderColor,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // SEND
  // ============================================================

  Future<void> _sendRequest() async {
    if (_isSending ||
        _isLoading) {
      return;
    }

    final CreateSwapRequestSnapshot? snapshot =
        _snapshot;

    if (snapshot == null) {
      _showError(
        'Swap request details are unavailable. Please reload and try again.',
      );
      return;
    }

    final DateTime? proposedAt;

    if (_selectedDate == null ||
        _selectedTime == null) {
      proposedAt = null;
    } else {
      proposedAt = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _controller.submitRequest(
        snapshot: snapshot,
        skillToOffer:
        _selectedSkillToOffer,
        selectedMode:
        _selectedMode,
        proposedAt:
        proposedAt,
        meetingDetails:
        _meetingDetailsController
            .text,
        note:
        _noteController.text,
      );

      if (!mounted) {
        return;
      }

      await _showSuccessDialog();

      if (!mounted) {
        return;
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      Navigator.pop(
        context,
        true,
      );
    } on CreateSwapRequestControllerException catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError(
        'We could not save your swap request. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger =
    ScaffoldMessenger.of(
      context,
    );

    messenger
        .hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content:
        Text(
          message,
        ),
        behavior:
        SnackBarBehavior
            .floating,
      ),
    );
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  Future<void> _showSuccessDialog() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor:
          _surfaceColor,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons
                    .check_circle_rounded,
                color:
                _primaryColor,
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                child: Text(
                  'Request sent!',
                  style:
                  AppTextStyles
                      .cardTitle
                      .copyWith(
                    color:
                    _textColor,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Your skill swap request was saved successfully and is now Pending.',
            style:
            AppTextStyles.body
                .copyWith(
              color:
              _textColor,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
              const Text(
                'DONE',
                style:
                AppTextStyles.button,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatDate(
      DateTime date,
      ) {
    const List<String> months =
    <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} '
        '${date.day}, '
        '${date.year}';
  }
}