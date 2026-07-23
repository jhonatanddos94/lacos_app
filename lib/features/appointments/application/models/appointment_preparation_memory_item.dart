class AppointmentPreparationMemoryItem {
  const AppointmentPreparationMemoryItem({
    this.memoryId,
    required this.content,
    required this.displayEmoji,
    required this.isPinned,
    required this.priorityWeight,
    required this.sortAt,
  });

  final String? memoryId;
  final String content;
  final String displayEmoji;
  final bool isPinned;
  final int priorityWeight;
  final DateTime sortAt;
}
