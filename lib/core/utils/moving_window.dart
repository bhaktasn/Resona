class MovingWindow<T> {
  final int maxSize;
  final List<T> _buffer = [];

  MovingWindow(this.maxSize);

  void add(T value) {
    _buffer.add(value);
    while (_buffer.length > maxSize) {
      _buffer.removeAt(0);
    }
  }

  void addAll(Iterable<T> values) {
    for (final v in values) {
      add(v);
    }
  }

  List<T> toList() => List.unmodifiable(_buffer);

  bool get isFull => _buffer.length >= maxSize;
  int get length => _buffer.length;

  void clear() => _buffer.clear();

  double get totalDurationSeconds {
    if (T != double && T != int) return 0;
    double sum = 0;
    for (final v in _buffer) {
      sum += (v as num).toDouble();
    }
    return sum;
  }
}
