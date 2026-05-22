class HeartRateData {
  final int heartRate;
  final List<int> rrIntervals; // in milliseconds

  const HeartRateData({required this.heartRate, required this.rrIntervals});
}

class HeartRateParser {
  /// Parses a BLE Heart Rate Measurement characteristic value (0x2A37).
  /// See: https://www.bluetooth.com/specifications/specs/heart-rate-service-1-0/
  static HeartRateData parse(List<int> data) {
    if (data.isEmpty) {
      return const HeartRateData(heartRate: 0, rrIntervals: []);
    }

    final flags = data[0];
    final isUint16 = (flags & 0x01) != 0;
    final hasRR = (flags & 0x10) != 0;

    int offset = 1;
    int heartRate;

    if (isUint16) {
      heartRate = data[offset] | (data[offset + 1] << 8);
      offset += 2;
    } else {
      heartRate = data[offset];
      offset += 1;
    }

    // Skip energy expended if present
    if ((flags & 0x08) != 0) {
      offset += 2;
    }

    final rrIntervals = <int>[];
    if (hasRR) {
      while (offset + 1 < data.length) {
        // RR intervals are in 1/1024 second units
        final rawRR = data[offset] | (data[offset + 1] << 8);
        // Convert to milliseconds: rawRR * 1000 / 1024
        final rrMs = (rawRR * 1000) ~/ 1024;
        rrIntervals.add(rrMs);
        offset += 2;
      }
    }

    return HeartRateData(heartRate: heartRate, rrIntervals: rrIntervals);
  }
}
