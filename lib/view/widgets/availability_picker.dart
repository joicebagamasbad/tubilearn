import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Shared Days/Time/Custom availability picker, matching Edit Profile's
/// composed '{days} • {time}' design. Owns its own Days dropdown, Time
/// dropdown, and 'Custom days' text field; reports the composed string
/// back via [onChanged] on every change.
class AvailabilityPicker extends StatefulWidget {
  const AvailabilityPicker({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.enabled,
    required this.surfaceColor,
    required this.textColor,
    required this.primaryColor,
    required this.mutedColor,
    required this.borderColor,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final Color surfaceColor;
  final Color textColor;
  final Color primaryColor;
  final Color mutedColor;
  final Color borderColor;

  static const List<String> daysOptions = <String>[
    'Weekdays',
    'Weekends',
    'Every day',
    'Custom',
  ];

  static const List<String> timeOptions = <String>[
    'Mornings',
    'Afternoons',
    'Evenings',
    'Anytime',
  ];

  @override
  State<AvailabilityPicker> createState() => _AvailabilityPickerState();
}

class _AvailabilityPickerState extends State<AvailabilityPicker> {
  late final TextEditingController _customDaysController;

  String? _days;
  String? _time;

  @override
  void initState() {
    super.initState();

    _customDaysController = TextEditingController();

    _parseInitialValue();
  }

  @override
  void dispose() {
    _customDaysController.dispose();

    super.dispose();
  }

  // ============================================================
  // PARSE
  // ============================================================

  /// Parses [AvailabilityPicker.initialValue] once, in order:
  /// (1) '{canonical days} • {canonical time}';
  /// (2) a bare canonical days value (not 'Custom') -> Days set, Time null;
  /// (3) a bare canonical time value -> Days unselected, Time set;
  /// (4) anything else (legacy prose, 'Flexible', etc.) -> Days = 'Custom',
  ///     the whole string placed in the custom field, Time unselected.
  /// Never guesses, and never calls [AvailabilityPicker.onChanged].
  void _parseInitialValue() {
    final String trimmed =
        widget.initialValue.trim();

    final int separatorIndex =
        trimmed.indexOf(
          ' • ',
        );

    if (separatorIndex != -1) {
      final String daysPart =
      trimmed
          .substring(
        0,
        separatorIndex,
      )
          .trim();

      final String timePart =
      trimmed
          .substring(
        separatorIndex + 3,
      )
          .trim();

      if (AvailabilityPicker.daysOptions.contains(
        daysPart,
      ) &&
          daysPart != 'Custom' &&
          AvailabilityPicker.timeOptions.contains(
            timePart,
          )) {
        _days = daysPart;
        _time = timePart;
        return;
      }
    } else {
      if (AvailabilityPicker.daysOptions.contains(
        trimmed,
      ) &&
          trimmed != 'Custom') {
        _days = trimmed;
        _time = null;
        return;
      }

      if (AvailabilityPicker.timeOptions.contains(
        trimmed,
      )) {
        _days = null;
        _time = trimmed;
        return;
      }
    }

    _days = 'Custom';
    _time = null;
    _customDaysController.text = trimmed;
  }

  // ============================================================
  // COMPOSE
  // ============================================================

  String _compose() {
    final String daysPart =
    _days == null
        ? ''
        : (_days == 'Custom'
        ? _customDaysController.text.trim()
        : _days!);

    final String? timePart =
        _time;

    if (timePart == null ||
        timePart.isEmpty) {
      return daysPart;
    }

    if (daysPart.isEmpty) {
      return timePart;
    }

    return '$daysPart • $timePart';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _buildDaysDropdown(),

        if (_days ==
            'Custom') ...[
          const SizedBox(
            height: 14,
          ),

          _buildCustomDaysField(),
        ],

        const SizedBox(
          height: 14,
        ),

        _buildTimeDropdown(),
      ],
    );
  }

  Widget _buildDaysDropdown() {
    return DropdownButtonFormField<String>(
      initialValue:
      _days,
      isExpanded:
      true,
      hint:
      Text(
        'Select days',
        style:
        TextStyle(
          color:
          widget.mutedColor,
        ),
      ),
      style:
      TextStyle(
        color:
        widget.textColor,
        fontWeight:
        FontWeight.w500,
      ),
      dropdownColor:
      widget.surfaceColor,
      decoration:
      InputDecoration(
        labelText:
        'Availability days',
        floatingLabelBehavior:
        FloatingLabelBehavior.always,
        labelStyle:
        TextStyle(
          color:
          widget.primaryColor,
          fontWeight:
          FontWeight.w600,
        ),
        prefixIcon:
        Icon(
          Icons.calendar_month_outlined,
          color:
          widget.primaryColor,
          size:
          20,
        ),
        filled:
        true,
        fillColor:
        widget.surfaceColor,
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            widget.borderColor,
          ),
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            widget.borderColor,
            width:
            1.2,
          ),
        ),
        disabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            widget.borderColor,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            widget.primaryColor,
            width:
            2,
          ),
        ),
      ),
      items:
      AvailabilityPicker.daysOptions
          .map(
            (
            String value,
            ) {
          return DropdownMenuItem<String>(
            value:
            value,
            child: Text(
              value,
              overflow:
              TextOverflow.ellipsis,
            ),
          );
        },
      )
          .toList(),
      onChanged:
      !widget.enabled
          ? null
          : (
          String? value,
          ) {
        if (value ==
            null) {
          return;
        }

        setState(() {
          _days =
              value;

          if (value != 'Custom') {
            _customDaysController.clear();
          }
        });

        widget.onChanged(
          _compose(),
        );
      },
    );
  }

  Widget _buildCustomDaysField() {
    return TextFormField(
      controller:
      _customDaysController,
      enabled:
      widget.enabled,
      maxLength:
      60,
      cursorColor:
      widget.primaryColor,
      style:
      TextStyle(
        color:
        widget.textColor,
        fontWeight:
        FontWeight.w500,
      ),
      textCapitalization:
      TextCapitalization.words,
      decoration:
      InputDecoration(
        labelText:
        'Custom days',
        hintText:
        'Example: Monday, Wednesday',
        floatingLabelBehavior:
        FloatingLabelBehavior.always,
        labelStyle:
        TextStyle(
          color:
          widget.primaryColor,
          fontWeight:
          FontWeight.w600,
        ),
        hintStyle:
        TextStyle(
          color:
          widget.mutedColor,
        ),
        prefixIcon:
        Icon(
          Icons.edit_calendar_outlined,
          color:
          widget.primaryColor,
          size:
          20,
        ),
        filled:
        true,
        fillColor:
        widget.surfaceColor,
        counterStyle:
        AppTextStyles.caption.copyWith(
          color:
          widget.mutedColor,
        ),
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            widget.borderColor,
          ),
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            widget.borderColor,
            width:
            1.2,
          ),
        ),
        disabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            widget.borderColor,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            widget.primaryColor,
            width:
            2,
          ),
        ),
      ),
      onChanged: (
          String value,
          ) {
        widget.onChanged(
          _compose(),
        );
      },
    );
  }

  Widget _buildTimeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue:
      _time,
      isExpanded:
      true,
      hint:
      Text(
        'Select time',
        style:
        TextStyle(
          color:
          widget.mutedColor,
        ),
      ),
      style:
      TextStyle(
        color:
        widget.textColor,
        fontWeight:
        FontWeight.w500,
      ),
      dropdownColor:
      widget.surfaceColor,
      decoration:
      InputDecoration(
        labelText:
        'Availability time',
        floatingLabelBehavior:
        FloatingLabelBehavior.always,
        labelStyle:
        TextStyle(
          color:
          widget.primaryColor,
          fontWeight:
          FontWeight.w600,
        ),
        prefixIcon:
        Icon(
          Icons.schedule_rounded,
          color:
          widget.primaryColor,
          size:
          20,
        ),
        filled:
        true,
        fillColor:
        widget.surfaceColor,
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            widget.borderColor,
          ),
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            widget.borderColor,
            width:
            1.2,
          ),
        ),
        disabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            widget.borderColor,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          BorderSide(
            color:
            widget.primaryColor,
            width:
            2,
          ),
        ),
      ),
      items:
      AvailabilityPicker.timeOptions
          .map(
            (
            String value,
            ) {
          return DropdownMenuItem<String>(
            value:
            value,
            child: Text(
              value,
              overflow:
              TextOverflow.ellipsis,
            ),
          );
        },
      )
          .toList(),
      onChanged:
      !widget.enabled
          ? null
          : (
          String? value,
          ) {
        setState(() {
          _time =
              value;
        });

        widget.onChanged(
          _compose(),
        );
      },
    );
  }
}
