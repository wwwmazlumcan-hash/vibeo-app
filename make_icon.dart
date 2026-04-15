import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

List<int> createPng(int w, int h, List<List<List<int>>> pixels) {
  final ihdr = ByteData(13);
  ihdr.setUint32(0, w);
  ihdr.setUint32(4, h);
  ihdr.setUint8(8, 8);
  ihdr.setUint8(9, 2);
  ihdr.setUint8(10, 0);
  ihdr.setUint8(11, 0);
  ihdr.setUint8(12, 0);

  final raw = <int>[];
  for (int y = 0; y < h; y++) {
    raw.add(0);
    for (int x = 0; x < w; x++) {
      raw.addAll(pixels[y][x]);
    }
  }

  final compressed = zlib.encode(raw);

  List<int> chunk(List<int> name, List<int> data) {
    final crc = Crc32().convert([...name, ...data]);
    final len = ByteData(4)..setUint32(0, data.length);
    final crcBytes = ByteData(4)..setUint32(0, crc);
    return [
      ...len.buffer.asUint8List(),
      ...name,
      ...data,
      ...crcBytes.buffer.asUint8List()
    ];
  }

  return [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    ...chunk([0x49, 0x48, 0x44, 0x52], ihdr.buffer.asUint8List().toList()),
    ...chunk([0x49, 0x44, 0x41, 0x54], compressed),
    ...chunk([0x49, 0x45, 0x4E, 0x44], []),
  ];
}

class Crc32 {
  static final _table = _makeTable();
  static List<int> _makeTable() {
    final t = List<int>.filled(256, 0);
    for (int n = 0; n < 256; n++) {
      int c = n;
      for (int k = 0; k < 8; k++) {
        c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
      }
      t[n] = c;
    }
    return t;
  }

  int convert(List<int> data) {
    int c = 0xFFFFFFFF;
    for (final b in data) {
      c = _table[(c ^ b) & 0xFF] ^ (c >> 8);
    }
    return c ^ 0xFFFFFFFF;
  }
}

List<int> _mix(List<int> a, List<int> b, double t) {
  t = t.clamp(0.0, 1.0);
  return [
    (a[0] * (1 - t) + b[0] * t).round(),
    (a[1] * (1 - t) + b[1] * t).round(),
    (a[2] * (1 - t) + b[2] * t).round(),
  ];
}

void main() {
  const W = 1024, H = 1024;
  final cx = W / 2.0, cy = H / 2.0;
  final Rmax = W / 2.0 - 8;

  // Dark to cyan gradient background circle
  final bgDark = [5, 15, 25];
  final bgMid = [8, 30, 50];
  final cyan = [0, 220, 220];
  final brightCyan = [120, 255, 255];

  final pixels = List.generate(H, (_) => List.generate(W, (_) => [0, 0, 0]));

  for (int y = 0; y < H; y++) {
    for (int x = 0; x < W; x++) {
      final dx = x - cx, dy = y - cy;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist > Rmax) continue;

      // Radial gradient from dark center to slightly brighter edge
      final radial = dist / Rmax;
      var color = _mix(bgDark, bgMid, radial * 0.6);

      // Swirl pattern — double spiral arms
      final angle = atan2(dy, dx);
      final swirl = angle + dist * 0.012;
      final arm1 = (sin(swirl * 2) + 1) / 2; // 0..1
      final arm2 = (sin(swirl * 2 + pi) + 1) / 2;

      // Glowing arms fade toward center and edge
      final armMask =
          (1 - (radial - 0.5).abs() * 2).clamp(0.0, 1.0); // peak at mid
      final armIntensity = max(pow(arm1, 8), pow(arm2, 8)).toDouble() * armMask;
      color = _mix(color, brightCyan, armIntensity * 0.9);

      // Outer ring glow
      if (radial > 0.88 && radial < 0.98) {
        final ringT = 1 - ((radial - 0.93).abs() * 20).clamp(0.0, 1.0);
        color = _mix(color, cyan, ringT * 0.85);
      }

      // Inner glow / orb at center
      if (radial < 0.3) {
        final glow = pow(1 - radial / 0.3, 2).toDouble();
        color = _mix(color, brightCyan, glow * 0.5);
      }

      pixels[y][x] = color;
    }
  }

  final png = createPng(W, H, pixels);
  File('assets/icon/app_icon.png').writeAsBytesSync(png);
  print('app_icon.png oluşturuldu (${png.length} bytes)');
}
