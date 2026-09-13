import 'dart:typed_data';

import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/domain/enums.dart';
import 'package:campus_event_hub/core/widgets/widgets.dart';
import 'package:campus_event_hub/features/events/domain/event.dart';
import 'package:campus_event_hub/features/events/presentation/controllers/events_controllers.dart';
import 'package:campus_event_hub/features/organizer/domain/organizer_repository.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/organizer_dashboard_screen.dart';
import 'package:campus_event_hub/features/organizer/presentation/screens/organizer_events_screen.dart';
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
  final List<_GuestEntry> _guestEntries = [];

  @override
  void initState() {
    super.initState();
    _start = widget.existing?.startAt;
    _end = widget.existing?.endAt;
    _deadline = widget.existing?.registrationDeadline;
    _categoryId = widget.existing?.categoryId;
    _uploadedPosterPath = widget.existing?.posterPath;
    if (widget.existing != null) {
      for (final g in widget.existing!.guests) {
        _guestEntries.add(_GuestEntry(
          name: g.name,
          designation: g.designation,
          org: g.organization,
        ));
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _shortDesc.dispose();
    _fullDesc.dispose();
    _venue.dispose();
    _eligibility.dispose();
    _rules.dispose();
    _feeText.dispose();
    _contactName.dispose();
    _contactEmail.dispose();
    _contactPhone.dispose();
    for (final g in _guestEntries) {
      g.dispose();
    }
    super.dispose();
  }

  void _addGuest() {
    setState(() {
      _guestEntries.add(_GuestEntry());
    });
  }

  void _removeGuest(int index) {
    setState(() {
      final entry = _guestEntries.removeAt(index);
      entry.dispose();
    });
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
        actions: const [OrganizerProfileButton()],
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
                      loading: () => const Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text('Loading categories...'),
                        ],
                      ),
                      error: (_, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Unable to load categories'),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton.icon(
                            onPressed: () => ref.invalidate(categoriesProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                      data: (categories) {
                        if (_categoryId != null &&
                            !categories.any((c) => c.id == _categoryId)) {
                          _categoryId = null;
                        }
                        if (categories.isEmpty) {
                          return const Text('No categories available');
                        }
                        final selectedValue = categories.any((c) => c.id == _categoryId)
                            ? _categoryId
                            : null;
                        return DropdownButtonFormField<String>(
                          initialValue: selectedValue,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            hintText: 'Select a category',
                          ),
                          items: categories
                              .map((c) => DropdownMenuItem(
                                  value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (v) => setState(() => _categoryId = v),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Please select a category'
                                  : null,
                        );
                      },
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

                // 5. Guests & Speakers Card (Optional)
                _FormCard(
                  title: 'Guests & Speakers (Optional)',
                  subtitle:
                      'Add keynote speakers, chief guests, or dignitaries',
                  children: [
                    if (_guestEntries.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: AppRadius.md,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people_outline_rounded,
                                color: AppColors.textMuted, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'No guests or speakers added yet.',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (var i = 0; i < _guestEntries.length; i++) ...[
                      Container(
                        key: ValueKey(_guestEntries[i]),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: AppRadius.md,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryLight,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      'Guest #${i + 1}',
                                      style: AppTextStyles.label.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: AppColors.danger, size: 20),
                                  tooltip: 'Remove Guest',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _removeGuest(i),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _guestEntries[i].nameController,
                              decoration: const InputDecoration(
                                labelText: 'Guest / Speaker Name *',
                                hintText: 'e.g. Dr. Jane Doe',
                                prefixIcon:
                                    Icon(Icons.person_outline, size: 18),
                              ),
                              validator: (v) {
                                final entry = _guestEntries[i];
                                final hasOtherField = entry
                                        .designationController.text
                                        .trim()
                                        .isNotEmpty ||
                                    entry.orgController.text
                                        .trim()
                                        .isNotEmpty;
                                if (hasOtherField &&
                                    (v == null || v.trim().isEmpty)) {
                                  return 'Please enter guest name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller:
                                  _guestEntries[i].designationController,
                              decoration: const InputDecoration(
                                labelText: 'Designation / Role',
                                hintText:
                                    'e.g. Keynote Speaker / Chief Guest / AI Researcher',
                                prefixIcon: Icon(Icons.badge_outlined, size: 18),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _guestEntries[i].orgController,
                              decoration: const InputDecoration(
                                labelText: 'Organization / Affiliation',
                                hintText: 'e.g. Google DeepMind / MIT',
                                prefixIcon:
                                    Icon(Icons.business_outlined, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    OutlinedButton.icon(
                      onPressed: _addGuest,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Guest / Speaker'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.sm),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // 6. Organizer Contact Card
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
                if (widget.existing != null &&
                    (widget.existing!.status == EventStatus.published ||
                        widget.existing!.status == EventStatus.postponed ||
                        widget.existing!.status == EventStatus.pendingApproval))
                  AppPrimaryButton(
                    label: 'Save Changes',
                    isLoading: _saving,
                    fullWidth: true,
                    onPressed: _saving ? null : () => _save(submit: false),
                  )
                else
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

    var ext = picked.name.split('.').last.toLowerCase();
    final bytes = await picked.readAsBytes();

    // On iOS, image_picker with imageQuality converts HEIC/HEIF photos to JPEG.
    // If the picked filename still carries a .heic/.heif extension, verify if the
    // bytes are JPEG (SOI 0xFF 0xD8) and normalize ext to 'jpg'. Otherwise, show
    // clear feedback that HEIC is not supported.
    if (ext == 'heic' || ext == 'heif') {
      final isJpeg = bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
      if (isJpeg) {
        ext = 'jpg';
      } else {
        setState(() => _error =
            'HEIC/HEIF images are not supported. Please select a JPG, PNG, or WebP image.');
        return;
      }
    }

    const allowed = ['jpg', 'jpeg', 'png', 'webp'];
    if (!allowed.contains(ext)) {
      setState(() => _error = 'Poster must be a JPG, PNG, or WebP image.');
      return;
    }
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

    final validGuests = _guestEntries
        .map((e) => e.toGuest())
        .where((g) => g.name.isNotEmpty)
        .toList();

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
      guests: validGuests,
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
        if (widget.existing != null) {
          ref.invalidate(eventByIdProvider(widget.existing!.id));
        }
        ref.invalidate(upcomingEventsProvider);
        ref.invalidate(openEventsProvider);
        if (mounted) {
          final String msg;
          if (submit) {
            msg = 'Event submitted for approval!';
          } else if (widget.existing != null) {
            msg = 'Event updated successfully!';
          } else {
            msg = 'Event draft saved successfully!';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.success,
            ),
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
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
                : (existingPath != null && existingPath!.trim().isNotEmpty)
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          EventPosterContainer(
                            imageUrl: existingPath,
                            fit: BoxFit.cover,
                            borderRadius: AppRadius.md,
                          ),
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
                          const Text(
                            'Upload event poster image',
                            style: TextStyle(
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

class _GuestEntry {
  final TextEditingController nameController;
  final TextEditingController designationController;
  final TextEditingController orgController;

  _GuestEntry({String name = '', String designation = '', String org = ''})
      : nameController = TextEditingController(text: name),
        designationController = TextEditingController(text: designation),
        orgController = TextEditingController(text: org);

  void dispose() {
    nameController.dispose();
    designationController.dispose();
    orgController.dispose();
  }

  EventGuest toGuest() => EventGuest(
        name: nameController.text.trim(),
        designation: designationController.text.trim(),
        organization: orgController.text.trim(),
      );
}

