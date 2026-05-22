class SessionSummary {
  final DateTime startTime;
  final Duration duration;
  final double avgHeartRate;
  final int peakHeartRate;
  final int minHeartRate;
  final double avgCoherence;
  final double peakCoherence;
  final List<int> hrTimeSeries;
  final List<double> coherenceTimeSeries;
  final bool hadHrData;

  const SessionSummary({
    required this.startTime,
    required this.duration,
    required this.avgHeartRate,
    required this.peakHeartRate,
    required this.minHeartRate,
    required this.avgCoherence,
    required this.peakCoherence,
    required this.hrTimeSeries,
    required this.coherenceTimeSeries,
    required this.hadHrData,
  });

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'duration': duration.inSeconds,
    'avgHeartRate': avgHeartRate,
    'peakHeartRate': peakHeartRate,
    'minHeartRate': minHeartRate,
    'avgCoherence': avgCoherence,
    'peakCoherence': peakCoherence,
    'hrTimeSeries': hrTimeSeries,
    'coherenceTimeSeries': coherenceTimeSeries,
    'hadHrData': hadHrData,
  };

  factory SessionSummary.fromJson(Map<String, dynamic> json) => SessionSummary(
    startTime: DateTime.parse(json['startTime'] as String),
    duration: Duration(seconds: json['duration'] as int),
    avgHeartRate: (json['avgHeartRate'] as num).toDouble(),
    peakHeartRate: json['peakHeartRate'] as int,
    minHeartRate: json['minHeartRate'] as int,
    avgCoherence: (json['avgCoherence'] as num).toDouble(),
    peakCoherence: (json['peakCoherence'] as num).toDouble(),
    hrTimeSeries: (json['hrTimeSeries'] as List).cast<int>(),
    coherenceTimeSeries: (json['coherenceTimeSeries'] as List).map((e) => (e as num).toDouble()).toList(),
    hadHrData: json['hadHrData'] as bool,
  );

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
