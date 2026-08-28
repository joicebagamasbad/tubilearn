import 'package:flutter/material.dart';

import '../model/repositories/explore_repository.dart';
import '../model/skill.dart';
import '../model/user.dart';
import '../services/swap_service.dart';
import '../theme/app_theme.dart';

class CreateSwapRequestScreen extends StatefulWidget {
  final String? providerUserId;
  final String? skillToLearnId;

  final String providerName;
  final String providerInitials;
  final String providerCity;
  final String skillToLearn;

  const CreateSwapRequestScreen({
    super.key,
    this.providerUserId,
    this.skillToLearnId,
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
  static const Color primary = AppTheme.primary;
  static const Color darkText = AppTheme.darkText;
  static const Color mutedText = AppTheme.mutedText;
  static const Color border = AppTheme.border;
  static const Color background = AppTheme.background;

  // ============================================================
  // CURRENT LOCAL USER
  //
  // Temporary stable identity for the local/demo prototype.
  // Later this must come from the authenticated signed-in user.
  // ============================================================

  static const String _currentRequesterUserId =
      'user_joice_local';

  final ExploreRepository _repository =
  ExploreRepository();

  final TextEditingController _noteController =
  TextEditingController();

  final TextEditingController
  _meetingDetailsController =
  TextEditingController();

  Skill? _selectedSkillToOffer;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String _selectedMode = 'Online';

  bool _isSending = false;

  // ============================================================
  // TEMPORARY CURRENT-USER SKILLS
  //
  // These use real Skill objects and stable IDs.
  // Later they will come from the authenticated user's saved
  // UserSkill records instead of this local list.
  // ============================================================

  List<Skill> get _mySkills {
    const List<String> ids = [
      'skill_photography',
      'skill_graphic_design',
      'skill_video_editing',
    ];

    return ids
        .map(
          (id) => _repository.findSkillById(id),
    )
        .whereType<Skill>()
        .toList();
  }

  // ============================================================
  // RESOLVED PROVIDER ID
  // ============================================================

  String? get _resolvedProviderUserId {
    final String? supplied =
    _cleanOptionalId(
      widget.providerUserId,
    );

    if (supplied != null) {
      return supplied;
    }

    for (final User user
    in _repository.users) {
      if (user.name.trim().toLowerCase() ==
          widget.providerName
              .trim()
              .toLowerCase()) {
        return user.id;
      }
    }

    return null;
  }

  // ============================================================
  // RESOLVED LEARN SKILL
  // ============================================================

  Skill? get _resolvedSkillToLearn {
    final String? suppliedId =
    _cleanOptionalId(
      widget.skillToLearnId,
    );

    if (suppliedId != null) {
      final Skill? byId =
      _repository.findSkillById(
        suppliedId,
      );

      if (byId != null) {
        return byId;
      }
    }

    for (final Skill skill
    in _repository.skills) {
      if (skill.title
          .trim()
          .toLowerCase() ==
          widget.skillToLearn
              .trim()
              .toLowerCase()) {
        return skill;
      }
    }

    return null;
  }

  // ============================================================
  // OFFERABLE SKILLS
  //
  // Prevent offering the exact same skill being requested.
  // ============================================================

  List<Skill> get _availableSkillsToOffer {
    final String? learnId =
        _resolvedSkillToLearn?.id;

    return _mySkills.where(
          (skill) {
        return skill.id != learnId;
      },
    ).toList();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _meetingDetailsController.dispose();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _isSending
              ? null
              : () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: primary,
          ),
        ),
        title: const Text(
          'Request a Skill Swap',
          style: AppTextStyles.cardTitle,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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

              const SizedBox(height: 26),

              _buildSectionLabel(
                'You want to learn',
              ),

              const SizedBox(height: 8),

              _buildReadOnlySkill(),

              const SizedBox(height: 22),

              _buildSectionLabel(
                'What can you offer?',
              ),

              const SizedBox(height: 5),

              const Text(
                'Choose one of your skills to teach in exchange.',
                style:
                AppTextStyles.secondary,
              ),

              const SizedBox(height: 10),

              _buildSkillDropdown(),

              const SizedBox(height: 22),

              _buildSectionLabel(
                'Preferred schedule',
              ),

              const SizedBox(height: 5),

              const Text(
                'Suggest a date and time that works for you.',
                style:
                AppTextStyles.secondary,
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child:
                    _buildDateSelector(),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child:
                    _buildTimeSelector(),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              _buildSectionLabel(
                'Session mode',
              ),

              const SizedBox(height: 5),

              const Text(
                'Choose how you prefer to conduct the skill swap.',
                style:
                AppTextStyles.secondary,
              ),

              const SizedBox(height: 10),

              _buildModeSelector(),

              const SizedBox(height: 16),

              _buildMeetingDetails(),

              const SizedBox(height: 22),

              _buildSectionLabel(
                'Message',
              ),

              const SizedBox(height: 5),

              const Text(
                'Introduce yourself or add anything the other person should know.',
                style:
                AppTextStyles.secondary,
              ),

              const SizedBox(height: 10),

              TextField(
                controller:
                _noteController,
                enabled:
                !_isSending,
                maxLines: 4,
                maxLength: 300,
                style:
                AppTextStyles.input,
                decoration:
                const InputDecoration(
                  hintText:
                  'Example: Hi! I would love to learn this skill. I can help you with...',
                  hintStyle:
                  AppTextStyles.inputHint,
                ),
              ),

              const SizedBox(height: 10),

              _buildRequestSummary(),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                  _isSending
                      ? null
                      : _sendRequest,
                  child: _isSending
                      ? const Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2.2,
                          color:
                          Colors.white,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
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
        ),
      ),
    );
  }

  // ============================================================
  // INTRODUCTION
  // ============================================================

  Widget _buildIntroduction() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF3F1FF),
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE4E0FF),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/mascot/tubi_planning.png',
            width: 65,
            height: 65,
            fit: BoxFit.contain,
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Swap with ${widget.providerName}',
                  style:
                  AppTextStyles.cardTitle,
                ),

                const SizedBox(height: 5),

                Text(
                  'Make a clear request so both of you know what you will learn, teach, and when you are available.',
                  style:
                  AppTextStyles.secondary
                      .copyWith(
                    color:
                    const Color(
                      0xFF666B80,
                    ),
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
      AppTextStyles.cardTitle,
    );
  }

  // ============================================================
  // SKILL TO LEARN
  // ============================================================

  Widget _buildReadOnlySkill() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFF7F7FB),
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.school_outlined,
            size: 20,
            color: primary,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _resolvedSkillToLearn?.title ??
                  widget.skillToLearn,
              style:
              AppTextStyles.body
                  .copyWith(
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),

          const Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: mutedText,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SKILL TO OFFER
  // ============================================================

  Widget _buildSkillDropdown() {
    final List<Skill> skills =
        _availableSkillsToOffer;

    return DropdownButtonFormField<Skill>(
      initialValue:
      _selectedSkillToOffer,
      style:
      AppTextStyles.input,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: primary,
      ),
      decoration:
      const InputDecoration(
        hintText:
        'Select a skill you can teach',
        hintStyle:
        AppTextStyles.inputHint,
      ),
      items: skills.map(
            (skill) {
          return DropdownMenuItem<Skill>(
            value: skill,
            child: Text(
              skill.title,
            ),
          );
        },
      ).toList(),
      onChanged: _isSending
          ? null
          : (value) {
        setState(() {
          _selectedSkillToOffer =
              value;
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
      BorderRadius.circular(12),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(12),
          border: Border.all(
            color: border,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 19,
              color: primary,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                _selectedDate == null
                    ? 'Select date'
                    : _formatDate(
                  _selectedDate!,
                ),
                style:
                _selectedDate == null
                    ? AppTextStyles
                    .inputHint
                    : AppTextStyles
                    .input,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime now =
    DateTime.now();

    final DateTime? result =
    await showDatePicker(
      context: context,
      initialDate: now.add(
        const Duration(days: 1),
      ),
      firstDate: now,
      lastDate: now.add(
        const Duration(days: 90),
      ),
    );

    if (result == null ||
        !mounted) {
      return;
    }

    setState(() {
      _selectedDate = result;
    });
  }

  // ============================================================
  // TIME
  // ============================================================

  Widget _buildTimeSelector() {
    return InkWell(
      borderRadius:
      BorderRadius.circular(12),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(12),
          border: Border.all(
            color: border,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 19,
              color: primary,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                _selectedTime == null
                    ? 'Select time'
                    : _selectedTime!
                    .format(context),
                style:
                _selectedTime == null
                    ? AppTextStyles
                    .inputHint
                    : AppTextStyles
                    .input,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? result =
    await showTimePicker(
      context: context,
      initialTime:
      const TimeOfDay(
        hour: 16,
        minute: 0,
      ),
    );

    if (result == null ||
        !mounted) {
      return;
    }

    setState(() {
      _selectedTime = result;
    });
  }

  // ============================================================
  // MODE
  // ============================================================

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildModeOption(
            label: 'Online',
            icon:
            Icons.videocam_outlined,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildModeOption(
            label: 'In-person',
            icon:
            Icons.people_outline_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildModeOption({
    required String label,
    required IconData icon,
  }) {
    final bool selected =
        _selectedMode == label;

    return InkWell(
      borderRadius:
      BorderRadius.circular(12),
      onTap: _isSending
          ? null
          : () {
        setState(() {
          _selectedMode =
              label;
          _meetingDetailsController
              .clear();
        });
      },
      child: AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 160,
        ),
        height: 62,
        decoration: BoxDecoration(
          color: selected
              ? const Color(
            0xFFF0EFFF,
          )
              : Colors.white,
          borderRadius:
          BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? primary
                : border,
            width:
            selected
                ? 1.4
                : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? primary
                  : mutedText,
            ),

            const SizedBox(width: 7),

            Text(
              label,
              style:
              AppTextStyles.secondary
                  .copyWith(
                color: selected
                    ? primary
                    : darkText,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MEETING DETAILS
  // ============================================================

  Widget _buildMeetingDetails() {
    final bool online =
        _selectedMode == 'Online';

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
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller:
          _meetingDetailsController,
          enabled:
          !_isSending,
          maxLength: 150,
          style:
          AppTextStyles.input,
          decoration:
          InputDecoration(
            hintText: online
                ? 'Example: Google Meet or Messenger'
                : 'Example: DCT campus or a public café',
            hintStyle:
            AppTextStyles.inputHint,
            prefixIcon: Icon(
              online
                  ? Icons.language_rounded
                  : Icons
                  .location_on_outlined,
              size: 20,
              color: primary,
            ),
          ),
        ),

        if (!online) ...[
          const SizedBox(height: 7),

          const Text(
            'For safety, use a public meeting place. Exact details can be confirmed after the request is accepted.',
            style:
            AppTextStyles.secondary,
          ),
        ],
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildRequestSummary() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color: border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Request summary',
            style:
            AppTextStyles.cardTitle,
          ),

          const SizedBox(height: 12),

          _buildSummaryRow(
            'Learn',
            _resolvedSkillToLearn
                ?.title ??
                widget.skillToLearn,
          ),

          _buildSummaryRow(
            'Offer',
            _selectedSkillToOffer
                ?.title ??
                'Not selected',
          ),

          _buildSummaryRow(
            'Schedule',
            _selectedDate == null ||
                _selectedTime == null
                ? 'Not selected'
                : '${_formatDate(_selectedDate!)} • ${_selectedTime!.format(context)}',
          ),

          _buildSummaryRow(
            'Mode',
            _selectedMode,
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
                AppTextStyles.secondary,
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
                  color: darkText,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        if (showDivider)
          const Padding(
            padding:
            EdgeInsets.symmetric(
              vertical: 9,
            ),
            child: Divider(
              height: 1,
              color: border,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // SEND
  // ============================================================

  Future<void> _sendRequest() async {
    if (_isSending) {
      return;
    }

    final String? providerUserId =
        _resolvedProviderUserId;

    final Skill? skillToLearn =
        _resolvedSkillToLearn;

    final Skill? skillToOffer =
        _selectedSkillToOffer;

    if (providerUserId == null) {
      _showError(
        'We could not identify this provider. Please go back and try again.',
      );
      return;
    }

    if (skillToLearn == null) {
      _showError(
        'We could not identify the skill you want to learn. Please go back and try again.',
      );
      return;
    }

    if (skillToOffer == null) {
      _showError(
        'Please select a skill you can offer.',
      );
      return;
    }

    if (skillToLearn.id ==
        skillToOffer.id) {
      _showError(
        'Please offer a different skill from the one you want to learn.',
      );
      return;
    }

    if (_selectedDate == null ||
        _selectedTime == null) {
      _showError(
        'Please choose your preferred date and time.',
      );
      return;
    }

    final DateTime proposedAt =
    DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (!proposedAt.isAfter(
      DateTime.now(),
    )) {
      _showError(
        'Please choose a future date and time.',
      );
      return;
    }

    final String meetingDetails =
    _meetingDetailsController.text
        .trim();

    if (meetingDetails.isEmpty) {
      _showError(
        _selectedMode == 'Online'
            ? 'Please enter your preferred online platform.'
            : 'Please enter a preferred public meeting area.',
      );
      return;
    }

    if (meetingDetails.length >
        150) {
      _showError(
        'Meeting details must be 150 characters or less.',
      );
      return;
    }

    final String cleanNote =
    _noteController.text.trim();

    if (cleanNote.length > 300) {
      _showError(
        'Message must be 300 characters or less.',
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await SwapService.instance
          .createRequest(
        requesterUserId:
        _currentRequesterUserId,

        providerUserId:
        providerUserId,

        skillToLearnId:
        skillToLearn.id,

        skillToOfferId:
        skillToOffer.id,

        providerName:
        widget.providerName,

        providerInitials:
        widget.providerInitials,

        providerCity:
        widget.providerCity,

        skillToLearn:
        skillToLearn.title,

        skillToOffer:
        skillToOffer.title,

        proposedAt:
        proposedAt,

        mode:
        _selectedMode,

        meetingDetails:
        meetingDetails,

        note:
        cleanNote.isEmpty
            ? null
            : cleanNote,
      );

      if (!mounted) {
        return;
      }

      await _showSuccessDialog();

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } on SwapServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        error.message,
      );
    } catch (error) {
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
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  Future<void>
  _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons
                    .check_circle_rounded,
                color: primary,
              ),

              SizedBox(width: 9),

              Expanded(
                child: Text(
                  'Request sent!',
                  style:
                  AppTextStyles.cardTitle,
                ),
              ),
            ],
          ),
          content: const Text(
            'Your skill swap request was saved successfully and is now Pending.',
            style:
            AppTextStyles.body,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
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

  String? _cleanOptionalId(
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

  String _formatDate(
      DateTime date,
      ) {
    const List<String> months = [
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

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}