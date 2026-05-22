class BreathingSettings {
  final Duration inhaleDuration;
  final Duration exhaleDuration;
  final Duration inhaleHoldDuration;
  final Duration exhaleHoldDuration;

  const BreathingSettings({
    this.inhaleDuration = const Duration(seconds: 5),
    this.exhaleDuration = const Duration(seconds: 5),
    this.inhaleHoldDuration = Duration.zero,
    this.exhaleHoldDuration = Duration.zero,
  });

  Duration get totalCycleDuration =>
      inhaleDuration + inhaleHoldDuration + exhaleDuration + exhaleHoldDuration;

  double get breathsPerMinute =>
      60000.0 / totalCycleDuration.inMilliseconds;

  BreathingSettings copyWith({
    Duration? inhaleDuration,
    Duration? exhaleDuration,
    Duration? inhaleHoldDuration,
    Duration? exhaleHoldDuration,
  }) {
    return BreathingSettings(
      inhaleDuration: inhaleDuration ?? this.inhaleDuration,
      exhaleDuration: exhaleDuration ?? this.exhaleDuration,
      inhaleHoldDuration: inhaleHoldDuration ?? this.inhaleHoldDuration,
      exhaleHoldDuration: exhaleHoldDuration ?? this.exhaleHoldDuration,
    );
  }

  Map<String, dynamic> toJson() => {
    'inhaleDuration': inhaleDuration.inMilliseconds,
    'exhaleDuration': exhaleDuration.inMilliseconds,
    'inhaleHoldDuration': inhaleHoldDuration.inMilliseconds,
    'exhaleHoldDuration': exhaleHoldDuration.inMilliseconds,
  };

  factory BreathingSettings.fromJson(Map<String, dynamic> json) => BreathingSettings(
    inhaleDuration: Duration(milliseconds: json['inhaleDuration'] as int),
    exhaleDuration: Duration(milliseconds: json['exhaleDuration'] as int),
    inhaleHoldDuration: Duration(milliseconds: json['inhaleHoldDuration'] as int),
    exhaleHoldDuration: Duration(milliseconds: json['exhaleHoldDuration'] as int),
  );
}
