import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:campus_event_hub/core/widgets/widgets.dart';
import 'package:campus_event_hub/features/reviews/domain/review.dart';
import 'package:campus_event_hub/features/reviews/presentation/controllers/reviews_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReviewSheet extends ConsumerStatefulWidget {
  final String eventId;
  final ReviewModel? existingReview;

  const ReviewSheet({
    super.key,
    required this.eventId,
    this.existingReview,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String eventId,
    ReviewModel? existingReview,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewSheet(
        eventId: eventId,
        existingReview: existingReview,
      ),
    );
  }

  @override
  ConsumerState<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<ReviewSheet> {
  late int _rating;
  late TextEditingController _commentController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 5;
    _commentController =
        TextEditingController(text: widget.existingReview?.comment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1 || _rating > 5) {
      setState(() => _errorMessage = 'Please select a rating between 1 and 5 stars.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repo = ref.read(reviewRepositoryProvider);
    final res = await repo.submitReview(
      eventId: widget.eventId,
      rating: _rating,
      comment: _commentController.text,
    );

    if (!mounted) return;

    res.when(
      ok: (review) {
        ref.invalidate(myReviewForEventProvider(widget.eventId));
        ref.invalidate(myReviewsProvider);
        ref.invalidate(eventFeedbackProvider(widget.eventId));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingReview != null
                ? 'Review updated successfully.'
                : 'Thank you for your feedback!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      },
      err: (failure) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = failure.message;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.existingReview != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              isEditing ? 'Edit Your Review' : 'Rate & Review Event',
              style: AppTextStyles.headline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Your verified feedback helps organizers improve future events.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Star Rating Picker
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isSelected = starIndex <= _rating;
                  return IconButton(
                    iconSize: 40,
                    splashRadius: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    icon: Icon(
                      isSelected
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: isSelected
                          ? const Color(0xFFF59E0B) // Amber
                          : AppColors.textMuted,
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() {
                              _rating = starIndex;
                              _errorMessage = null;
                            }),
                  );
                }),
              ),
            ),
            Center(
              child: Text(
                _getRatingLabel(_rating),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Comment Field
            TextField(
              controller: _commentController,
              enabled: !_isSubmitting,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText:
                    'What did you like? What could be improved? (Optional)',
                hintStyle: AppTextStyles.bodySecondary,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.md,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.md,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.md,
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: AppRadius.sm,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: AppColors.danger),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            AppPrimaryButton(
              label: isEditing ? 'Update Review' : 'Submit Review',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
