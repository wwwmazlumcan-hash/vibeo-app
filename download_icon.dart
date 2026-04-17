import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main() async {
  const prompt =
      'dark glossy black sphere center, horizontal elliptical rings wrapping around it symmetrically, bright white cyan teal neon energy rings glow, lens flare bright points at left and right ring tips, pure black background, front facing view, symmetric centered composition, no text, futuristic logo icon, dramatic lighting, high contrast';
  final encoded = Uri.encodeComponent(prompt);
  final url =
      'https://image.pollinations.ai/prompt/$encoded?width=1024&height=1024&nologo=true&seed=2024';
  stdout.writeln('Fetching image...');
  stdout.writeln(url);
  final resp = await http.get(Uri.parse(url));
  stdout.writeln(
    'Status: ${resp.statusCode}  Size: ${resp.bodyBytes.length} bytes',
  );
  if (resp.statusCode == 200 && resp.bodyBytes.length > 10000) {
    final f = File(r'assets/icon/app_icon.png');
    await f.writeAsBytes(resp.bodyBytes);
    stdout.writeln('Saved to assets/icon/app_icon.png');
    exitCode = 0;
  } else {
    stderr.writeln('ERROR: bad response');
    exitCode = 1;
  }
}
