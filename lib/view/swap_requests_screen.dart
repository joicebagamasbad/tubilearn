import 'package:flutter/material.dart';

import '../model/swap_request.dart';
import '../services/swap_service.dart';
import '../theme/app_theme.dart';

class SwapRequestsScreen extends StatefulWidget {
  const SwapRequestsScreen({
    super.key,
  });

  @override
  State<SwapRequestsScreen> createState() =>
      _SwapRequestsScreenState();
}

class _SwapRequestsScreenState
    extends State<SwapRequestsScreen> {
  static const Color primary = AppTheme.primary;
  static const Color darkText = AppTheme.darkText;
  static const Color mutedText = AppTheme.mutedText;
  static const Color background = AppTheme.background;
  static const Color border = AppTheme.border;

  String _selectedFilter = 'All';

  String? _processingRequestId;

  final List<String> _filters = [
    'All',
    'Pending',
    'Scheduled',
    'Completed',
  ];

  List<SwapRequest> get _filteredRequests {
    final requests =
        SwapService.instance.requests;

    if (_selectedFilter == 'All') {
      return requests;
    }

    return requests.where((request) {
      return request.status.label ==
          _selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final requests = _filteredRequests;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _processingRequestId != null
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
          'My Swap Requests',
          style: AppTextStyles.cardTitle,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            _buildFilters(),

            Expanded(
              child: requests.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: _refreshRequests,
                child: ListView.separated(
                  physics:
                  const AlwaysScrollableScrollPhysics(
                    parent:
                    BouncingScrollPhysics(),
                  ),
                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    30,
                  ),
                  itemCount:
                  requests.length,
                  separatorBuilder:
                      (context, index) {
                    return const SizedBox(
                      height: 14,
                    );
                  },
                  itemBuilder:
                      (context, index) {
                    return _buildRequestCard(
                      requests[index],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1FF),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: const Color(0xFFE4E0FF),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/mascot/tubi_checking.png',
            width: 62,
            height: 62,
            fit: BoxFit.contain,
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Track your skill swaps',
                  style:
                  AppTextStyles.cardTitle,
                ),

                SizedBox(height: 5),

                Text(
                  'Check your requests, schedules, and completed exchanges here.',
                  style:
                  AppTextStyles.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        itemCount: _filters.length,
        separatorBuilder:
            (context, index) {
          return const SizedBox(
            width: 8,
          );
        },
        itemBuilder:
            (context, index) {
          final filter =
          _filters[index];

          final selected =
              _selectedFilter == filter;

          return ChoiceChip(
            label: Text(
              filter,
              style:
              AppTextStyles.secondary
                  .copyWith(
                color: selected
                    ? Colors.white
                    : darkText,
                fontWeight:
                FontWeight.w700,
              ),
            ),
            selected: selected,
            onSelected:
            _processingRequestId != null
                ? null
                : (_) {
              setState(() {
                _selectedFilter =
                    filter;
              });
            },
            showCheckmark: false,
            selectedColor: primary,
            backgroundColor:
            Colors.white,
            side: BorderSide(
              color: selected
                  ? primary
                  : border,
            ),
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                20,
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // REQUEST CARD
  // ============================================================

  Widget _buildRequestCard(
      SwapRequest request,
      ) {
    final bool isProcessing =
        _processingRequestId ==
            request.id;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          17,
        ),
        border: Border.all(
          color: border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment:
                Alignment.center,
                decoration:
                const BoxDecoration(
                  color:
                  Color(0xFFFFB45E),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  request
                      .providerInitials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      request.providerName,
                      style:
                      AppTextStyles.cardTitle,
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      request.providerCity,
                      style:
                      AppTextStyles.caption,
                    ),
                  ],
                ),
              ),

              _buildStatusBadge(
                request.status,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(
              12,
            ),
            decoration: BoxDecoration(
              color:
              const Color(
                0xFFF8F7FF,
              ),
              borderRadius:
              BorderRadius.circular(
                13,
              ),
            ),
            child: Column(
              children: [
                _buildSkillRow(
                  icon:
                  Icons.school_outlined,
                  label: 'Learn',
                  value:
                  request.skillToLearn,
                ),

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

                _buildSkillRow(
                  icon:
                  Icons.lightbulb_outline_rounded,
                  label: 'Offer',
                  value:
                  request.skillToOffer,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _buildDetailRow(
            icon:
            Icons.calendar_month_outlined,
            text:
            _formatDateTime(
              request.proposedAt,
            ),
          ),

          const SizedBox(height: 8),

          _buildDetailRow(
            icon: request.mode ==
                'Online'
                ? Icons
                .videocam_outlined
                : Icons
                .location_on_outlined,
            text: request.mode,
          ),

          if (request
              .meetingDetails !=
              null &&
              request.meetingDetails!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(height: 8),

            _buildDetailRow(
              icon:
              Icons.info_outline_rounded,
              text:
              request.meetingDetails!,
            ),
          ],

          if (request.note != null &&
              request.note!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(
                11,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFFAFAFC,
                ),
                borderRadius:
                BorderRadius.circular(
                  11,
                ),
                border: Border.all(
                  color: border,
                ),
              ),
              child: Text(
                request.note!,
                style:
                AppTextStyles.secondary
                    .copyWith(
                  color: darkText,
                ),
              ),
            ),
          ],

          if (request.status
              .canBeCancelled) ...[
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: isProcessing
                    ? null
                    : () {
                  _confirmCancelRequest(
                    request,
                  );
                },
                style:
                OutlinedButton
                    .styleFrom(
                  foregroundColor:
                  const Color(
                    0xFFD95454,
                  ),
                  side:
                  const BorderSide(
                    color: Color(
                      0xFFE8BABA,
                    ),
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      11,
                    ),
                  ),
                ),
                child: isProcessing
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'CANCEL REQUEST',
                  style:
                  AppTextStyles.button,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: primary,
        ),

        const SizedBox(width: 9),

        Text(
          label,
          style:
          AppTextStyles.secondary,
        ),

        const SizedBox(width: 10),

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
              FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: primary,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            text,
            style:
            AppTextStyles.secondary
                .copyWith(
              color: darkText,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(
      SwapRequestStatus status,
      ) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case SwapRequestStatus.pending:
        backgroundColor =
        const Color(
          0xFFFFF4D8,
        );
        textColor =
        const Color(
          0xFFB87900,
        );
        break;

      case SwapRequestStatus.accepted:
        backgroundColor =
        const Color(
          0xFFEAF7ED,
        );
        textColor =
        const Color(
          0xFF378A4C,
        );
        break;

      case SwapRequestStatus.scheduled:
        backgroundColor =
        const Color(
          0xFFEDEBFF,
        );
        textColor = primary;
        break;

      case SwapRequestStatus.completed:
        backgroundColor =
        const Color(
          0xFFEAF7ED,
        );
        textColor =
        const Color(
          0xFF378A4C,
        );
        break;

      case SwapRequestStatus.declined:
        backgroundColor =
        const Color(
          0xFFFFECEC,
        );
        textColor =
        const Color(
          0xFFC65353,
        );
        break;

      case SwapRequestStatus.cancelled:
        backgroundColor =
        const Color(
          0xFFF1F1F4,
        );
        textColor = mutedText;
        break;
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        status.label,
        style:
        AppTextStyles.caption
            .copyWith(
          color: textColor,
          fontWeight:
          FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding:
        const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/mascot/tubi_confused.png',
              width: 110,
              height: 110,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 16),

            Text(
              _selectedFilter == 'All'
                  ? 'No swap requests yet'
                  : 'No $_selectedFilter requests',
              textAlign:
              TextAlign.center,
              style:
              AppTextStyles.sectionTitle,
            ),

            const SizedBox(height: 7),

            Text(
              _selectedFilter == 'All'
                  ? 'Explore skills and send a request when you find someone you want to exchange skills with.'
                  : 'Your $_selectedFilter requests will appear here.',
              textAlign:
              TextAlign.center,
              style:
              AppTextStyles.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CANCEL
  // ============================================================

  Future<void>
  _confirmCancelRequest(
      SwapRequest request,
      ) async {
    if (_processingRequestId != null) {
      return;
    }

    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
          Colors.white,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
          ),
          title: const Text(
            'Cancel request?',
            style:
            AppTextStyles.cardTitle,
          ),
          content: Text(
            'Your skill swap request to ${request.providerName} will be cancelled.',
            style:
            AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'KEEP REQUEST',
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
              ElevatedButton
                  .styleFrom(
                backgroundColor:
                const Color(
                  0xFFD95454,
                ),
                foregroundColor:
                Colors.white,
                minimumSize:
                const Size(
                  0,
                  40,
                ),
              ),
              child: const Text(
                'CANCEL REQUEST',
                style:
                AppTextStyles.button,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    setState(() {
      _processingRequestId =
          request.id;
    });

    try {
      await SwapService.instance
          .cancelRequest(
        request.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {});

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Swap request cancelled.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
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
        'We could not cancel this request. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingRequestId =
          null;
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
        content: Text(
          message,
        ),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void>
  _refreshRequests() async {
    await SwapService.instance
        .initialize();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDateTime(
      DateTime date,
      ) {
    const months = [
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

    int hour = date.hour;

    final minute =
    date.minute
        .toString()
        .padLeft(
      2,
      '0',
    );

    final period =
    hour >= 12
        ? 'PM'
        : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return '${months[date.month - 1]} ${date.day}, ${date.year} • $hour:$minute $period';
  }
}