/// Pure optimistic-update logic for the favourite heart button.
/// The controller (Riverpod) calls [optimisticNextState] immediately on
/// tap, updates the UI, fires the repository call, and calls
/// [rollback]/keeps state depending on the result.
class FavouriteToggle {
  FavouriteToggle._();

  static bool optimisticNextState(bool current) => !current;

  /// If the backend call fails, the state must revert to what it was
  /// before the optimistic flip.
  static bool rollback(bool priorState) => priorState;
}
