class LessonState {
  final bool isLoading;
  final String? error;
  final bool isImporting;
  final double importProgress; // 0.0 to 1.0

  const LessonState({
    this.isLoading = false,
    this.error,
    this.isImporting = false,
    this.importProgress = 0.0,
  });

  LessonState copyWith({
    bool? isLoading,
    String? error,
    bool? isImporting,
    double? importProgress,
  }) {
    return LessonState(
      isLoading: isLoading ?? this.isLoading,
      error:
          error, // Error can be null, so we replace it instead of coalescing if we want to clear it? No, if we want to clear we need a special way, or just use this.
      isImporting: isImporting ?? this.isImporting,
      importProgress: importProgress ?? this.importProgress,
    );
  }
}
