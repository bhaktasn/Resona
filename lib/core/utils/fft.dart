import 'dart:math';
import 'dart:typed_data';

class Complex {
  final double real;
  final double imag;
  const Complex(this.real, this.imag);

  Complex operator +(Complex other) => Complex(real + other.real, imag + other.imag);
  Complex operator -(Complex other) => Complex(real - other.real, imag - other.imag);
  Complex operator *(Complex other) => Complex(
    real * other.real - imag * other.imag,
    real * other.imag + imag * other.real,
  );

  double get magnitude => sqrt(real * real + imag * imag);
  double get magnitudeSquared => real * real + imag * imag;
}

/// Radix-2 Cooley-Tukey FFT. Input length must be a power of 2.
List<Complex> fft(List<double> input) {
  final n = input.length;
  assert(n > 0 && (n & (n - 1)) == 0, 'Input length must be a power of 2');

  // Bit-reversal permutation
  final result = Float64List(n * 2); // interleaved real/imag
  final bits = (log(n) / ln2).round();

  for (int i = 0; i < n; i++) {
    int reversed = 0;
    int temp = i;
    for (int j = 0; j < bits; j++) {
      reversed = (reversed << 1) | (temp & 1);
      temp >>= 1;
    }
    result[reversed * 2] = input[i];
    result[reversed * 2 + 1] = 0.0;
  }

  // Butterfly operations
  for (int size = 2; size <= n; size *= 2) {
    final halfSize = size ~/ 2;
    final angle = -2.0 * pi / size;

    for (int i = 0; i < n; i += size) {
      for (int j = 0; j < halfSize; j++) {
        final wReal = cos(angle * j);
        final wImag = sin(angle * j);

        final evenIdx = (i + j) * 2;
        final oddIdx = (i + j + halfSize) * 2;

        final tReal = wReal * result[oddIdx] - wImag * result[oddIdx + 1];
        final tImag = wReal * result[oddIdx + 1] + wImag * result[oddIdx];

        result[oddIdx] = result[evenIdx] - tReal;
        result[oddIdx + 1] = result[evenIdx + 1] - tImag;
        result[evenIdx] += tReal;
        result[evenIdx + 1] += tImag;
      }
    }
  }

  return List.generate(n, (i) => Complex(result[i * 2], result[i * 2 + 1]));
}

/// Zero-pad input to the next power of 2.
List<double> zeroPadToPow2(List<double> input) {
  final n = input.length;
  if (n > 0 && (n & (n - 1)) == 0) return input;

  int nextPow2 = 1;
  while (nextPow2 < n) {
    nextPow2 *= 2;
  }

  return [...input, ...List.filled(nextPow2 - n, 0.0)];
}
