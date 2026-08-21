/// When a student follows both the club AND the category of a newly
/// published event, the "followed club published" and "followed category
/// published" triggers would both fire. This collapses recipients so each
/// user gets exactly one notification per event per publish.
///
/// Mirrors the dedup done server-side in the `notify_event_published`
/// trigger (see supabase/migrations) — this pure version is what's unit
/// tested per spec section 25.
class NotificationDedup {
  NotificationDedup._();

  static List<String> dedupeRecipients({
    required List<String> clubFollowerIds,
    required List<String> categoryFollowerIds,
  }) {
    return {...clubFollowerIds, ...categoryFollowerIds}.toList();
  }
}
