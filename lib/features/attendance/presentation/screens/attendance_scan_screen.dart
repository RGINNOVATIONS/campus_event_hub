import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/widgets/widgets.dart';
import 'package:campus_event_hub/features/attendance/domain/scan_result.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/organizer_events_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AttendanceScanScreen extends ConsumerStatefulWidget {
  const AttendanceScanScreen({super.key});

  @override
  ConsumerState<AttendanceScanScreen> createState() =>
      _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends ConsumerState<AttendanceScanScreen> {
  EventModel? _selectedEvent;
  ScanResultUi? _lastResult;
  final _manualToken = TextEditingController();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(organizerEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan Attendance'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Select Active Event Card
            Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.border),
                borderRadius: AppRadius.lg,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Target Event',
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Choose the event you are currently verifying attendees for.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    eventsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text(
                        'Could not load your events.',
                        style: TextStyle(color: AppColors.danger),
                      ),
                      data: (events) => DropdownButtonFormField<EventModel>(
                        initialValue: _selectedEvent,
                        decoration: const InputDecoration(
                          labelText: 'Select Active Event',
                          prefixIcon:
                              Icon(Icons.event_available_outlined, size: 18),
                        ),
                        items: events
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedEvent = v),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 2. Scanner View or Fallback
            if (_selectedEvent != null) ...[
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.border),
                  borderRadius: AppRadius.lg,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QR Code Scanner',
                        style: AppTextStyles.title,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Point camera at the attendee\'s digital pass code.',
                        style: AppTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (!kIsWeb)
                        Container(
                          height: 260,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: AppRadius.md,
                            border: Border.all(color: AppColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              MobileScanner(
                                onDetect: (capture) {
                                  final barcodes = capture.barcodes;
                                  final code = barcodes.isNotEmpty
                                      ? barcodes.first.rawValue
                                      : null;
                                  if (code != null && !_busy) _scan(code);
                                },
                              ),
                              // Center Viewfinder reticle
                              Center(
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2.5,
                                    ),
                                    borderRadius: AppRadius.md,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          height: 120,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: AppRadius.md,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner_rounded,
                                  color: AppColors.textSecondary, size: 28),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                'Camera scanning is available on Android/iOS devices.\nUse manual code entry below on web.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: AppSpacing.lg),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: AppSpacing.lg),

                      // Manual entry fallback
                      const Text(
                        'Manual Code Verification',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Enter the alphanumeric ticket pass code manually.',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualToken,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                letterSpacing: 1.2,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter Pass Token',
                                prefixIcon: Icon(Icons.pin_outlined, size: 18),
                              ),
                              onSubmitted: (v) => _scan(v.trim()),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          AppPrimaryButton(
                            label: 'Verify',
                            isLoading: _busy,
                            onPressed: _busy
                                ? null
                                : () => _scan(_manualToken.text.trim()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Prompt to select an event first
              const EmptyState(
                icon: Icon(Icons.arrow_upward_rounded),
                title: 'Select an Event Above',
                description:
                    'Please select one of your club events from the dropdown above to begin scanning attendee passes.',
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // 3. Result Banner
            if (_lastResult != null) _ResultBanner(result: _lastResult!),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _scan(String token) async {
    if (_selectedEvent == null || token.isEmpty) return;
    setState(() => _busy = true);
    final repo = ref.read(organizerRepositoryProvider);
    final result =
        await repo.scanAttendance(eventId: _selectedEvent!.id, qrToken: token);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _lastResult = result.when(
        ok: (outcome) => ScanResultMapper.uiFor(outcome),
        err: (f) => ScanResultUi('Scan failed', f.message, false),
      );
    });
  }
}

class _ResultBanner extends StatelessWidget {
  final ScanResultUi result;
  const _ResultBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final isSuccess = result.isSuccess;
    final color = isSuccess ? AppColors.success : AppColors.danger;
    final bgColor = isSuccess ? AppColors.successBg : AppColors.dangerBg;

    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        borderRadius: AppRadius.lg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: color,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    result.message,
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
