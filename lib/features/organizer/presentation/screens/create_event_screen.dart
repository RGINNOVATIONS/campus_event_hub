import 'dart:typed_data';

import 'package:campus_pulse/app/providers.dart';
import 'package:campus_pulse/app/theme.dart';
import 'package:campus_pulse/core/widgets/widgets.dart';
import 'package:campus_pulse/features/events/domain/event.dart';
import 'package:campus_pulse/features/events/presentation/controllers/events_controllers.dart';
import 'package:campus_pulse/features/organizer/domain/organizer_repository.dart';
import 'package:campus_pulse/features/organizer/presentation/screens/organizer_dashboard_screen.dart';
import 'package:campus_pulse/features/organizer/presentation/screens/organizer_events_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  final EventModel? existing;
  const CreateEventScreen({super.key, this.existing});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _shortDesc =
      TextEditingController(text: widget.existing?.shortDescription);
  late final _fullDesc =
      TextEditingController(text: widget.existing?.fullDescription);
  late final _venue = TextEditingController(text: widget.existing?.venue);
  late final _eligibility =
      TextEditingController(text: widget.existing?.eligibility);
  late final _rules = TextEditingController(text: widget.existing?.rules);
  late final _feeText = TextEditingController(text: widget.existing?.feeText);
  late final _contactName =
      TextEditingController(text: widget.existing?.contactName);
  late final _contactEmail =
      TextEditingController(text: widget.existing?.contactEmail);
  late final _contactPhone =
      TextEditingController(text: widget.existing?.contactPhone);

  DateTime? _start;
  DateTime? _end;
  DateTime? _deadline;
  String? _categoryId;
  bool _saving = false;
  String? _error;
  Uint8List? _posterPreviewBytes;
  String? _uploadedPosterPath;

  @override
  void initState() {
    super.initState();
    _start = widget.existing?.startAt;
    _end = widget.existing?.endAt;
    _deadline = widget.existing?.registrationDeadline;
    _categoryId = widget.existing?.categoryId;
    _uploadedPosterPath = widget.existing?.posterPath;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Create Event' : 'Edit Event'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Basic Details Card
                _FormCard(
                  title: 'Basic Details',
                  subtitle: 'Event title, category, and descriptions',
                  children: [
                    TextFormField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        hintText: 'e.g. Annual Tech Symposium 2026',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    categoriesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Could not load categories'),
                      data: (categories) => DropdownButtonFormField<String>(
                        initialValue: _categoryId,
                        decoration:
                            const InputDecoration(labelText: 'Category'),
                        items: categories
                            .map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _categoryId = v),
                        validator: (v) =>
                            v == null ? 'Select a category' : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _shortDesc,
                      decoration: const InputDecoration(
                        labelText: 'Short Description',
                        hintText: 'One sentence highlight for event cards',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _fullDesc,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Full Description',
                        hintText:
                            'Provide detailed agenda, speakers, and topics...',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // 2. Poster Card
                _FormCard(
                  title: 'Event Banner Poster',
                  subtitle: 'Upload a banner image to attract participants',
                  children: [
                    _PosterPicker(
                      previewBytes: _posterPreviewBytes,
                      existingPath: _uploadedPosterPath,
                      onPick: _pickPoster,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // 3. Schedule & Location Card
                _FormCard(
                  title: 'Schedule & Location',
                  subtitle: 'Timing, venue, and registration deadline',
                  children: [
                    TextFormField(
                      controller: _venue,
                      decoration: const InputDecoration(
                        labelText: 'Venue / Location',
                        hintText: 'e.g. Auditorium Hall B / Online Link',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DateField(
                      label: 'Start Date & Time',
                      value: _start,
                      onPick: (d) => setState(() => _start = d),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DateField(
                      label: 'End Date & Time',
                      value: _end,
                      onPick: (d) => setState(() => _end = d),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DateField(
                      label: 'Registration Deadline',
                      value: _deadline,
                      onPick: (d) => setState(() => _deadline = d),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // 4. Guidelines & Fee Card
                _FormCard(
                  title: 'Participation Guidelines',
                  subtitle: 'Eligibility requirements, rules, and entry fees',
                  children: [
                    TextFormField(
                      controller: _eligibility,
                      decoration: const InputDecoration(
                        labelText: 'Eligibility',
                        hintText: 'e.g. Open to all B.Tech / M.Tech students',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _rules,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Rules & Requirements',
                        hintText:
                            'e.g. Teams of 2 to 4. Carry college student ID.',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _feeText,
                      decoration: const InputDecoration(
                        labelText: 'Fee Information (Optional)',
                        hintText: 'e.g. Free Entry or ₹100 per team',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // 5. Organizer Contact Card
                _FormCard(
                  title: 'Organizer Contact',
                  subtitle: 'Contact details displayed for inquiries',
                  children: [
                    TextFormField(
                      controller: _contactName,
                      decoration: const InputDecoration(
                        labelText: 'Contact Person Name',
                        prefixIcon: Icon(Icons.person_outline, size: 18),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _contactEmail,
                      decoration: const InputDecoration(
                        labelText: 'Contact Email',
                        prefixIcon: Icon(Icons.email_outlined, size: 18),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _contactPhone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone (Optional)',
                        prefixIcon: Icon(Icons.phone_outlined, size: 18),
                      ),
                    ),
                  ],
                ),

                // Error Message Callout
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: AppRadius.sm,
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.danger,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'Save Draft',
                        onPressed: _saving ? null : () => _save(submit: false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Submit for Approval',
                        isLoading: _saving,
                        onPressed: _saving ? null : () => _save(submit: true),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPoster() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;

    final ext = picked.name.split('.').last.toLowerCase();
    const allowed = ['jpg', 'jpeg', 'png', 'webp'];
    if (!allowed.contains(ext)) {
      setState(() => _error = 'Poster must be a JPG, PNG, or WebP image.');
      return;
    }
    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      setState(() => _error = 'Poster must be under 5 MB.');
      return;
    }

    setState(() {
      _error = null;
      _posterPreviewBytes = bytes;
    });

    final repo = ref.read(organizerRepositoryProvider);
    final result = await repo.uploadPoster(bytes: bytes, fileExtension: ext);
    result.when(
      ok: (path) => setState(() => _uploadedPosterPath = path),
      err: (f) => setState(() => _error = f.message),
    );
  }

  Future<void> _save({required bool submit}) async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_start == null || _end == null || _deadline == null) {
      setState(() => _error = 'Please set all three dates.');
      return;
    }
    final dateError = EventDateValidator.validate(
      start: _start!,
      end: _end!,
      registrationDeadline: _deadline!,
      now: DateTime.now(),
    );
    if (dateError != null) {
      setState(() => _error = dateError);
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(organizerRepositoryProvider);
    final result = await repo.saveDraft(DraftEventInput(
      id: widget.existing?.id,
      categoryId: _categoryId!,
      title: _title.text.trim(),
      shortDescription: _shortDesc.text.trim(),
      fullDescription: _fullDesc.text.trim(),
      posterPath: _uploadedPosterPath,
      venue: _venue.text.trim(),
      startAt: _start!,
      endAt: _end!,
      registrationDeadline: _deadline!,
      eligibility: _eligibility.text.trim(),
      rules: _rules.text.trim(),
      feeText: _feeText.text.trim().isEmpty ? null : _feeText.text.trim(),
      contactName: _contactName.text.trim(),
      contactEmail: _contactEmail.text.trim(),
      contactPhone:
          _contactPhone.text.trim().isEmpty ? null : _contactPhone.text.trim(),
    ));

    await result.when(
      ok: (event) async {
        if (submit) {
          final submitResult = await repo.submitForApproval(event.id);
          final submitErr =
              submitResult.when(ok: (_) => null, err: (f) => f.message);
          if (submitErr != null) {
            setState(() => _error = submitErr);
            return;
          }
        }
        ref.invalidate(organizerEventsProvider);
        ref.invalidate(organizerDashboardProvider);
        if (mounted) Navigator.of(context).pop();
      },
      err: (f) async => setState(() => _error = f.message),
    );
    if (mounted) setState(() => _saving = false);
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _FormCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
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
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  const _DateField(
      {required this.label, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, d MMM yyyy · h:mm a');

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
        );
        if (time == null) return;
        onPick(
            DateTime(date.year, date.month, date.day, time.hour, time.minute));
      },
      borderRadius: AppRadius.sm,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
        ),
        child: Text(
          value == null ? 'Tap to select date & time' : dateFmt.format(value!),
          style: TextStyle(
            color: value == null ? AppColors.textMuted : AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _PosterPicker extends StatelessWidget {
  final Uint8List? previewBytes;
  final String? existingPath;
  final VoidCallback onPick;
  const _PosterPicker(
      {required this.previewBytes,
      required this.existingPath,
      required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onPick,
          borderRadius: AppRadius.md,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: previewBytes != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(previewBytes!, fit: BoxFit.cover),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: AppRadius.sm,
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Change',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        existingPath != null
                            ? 'Poster set — tap to replace'
                            : 'Upload event poster image',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'JPG, PNG or WebP, up to 5 MB',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
