import 'package:flutter/material.dart';
import '../../widgets/vibeo_button.dart';
import '../../widgets/vibeo_input.dart';

class UploadScreen extends StatelessWidget {
  final String imageUrl; // Paylaşılacak görselin linki

  const UploadScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final TextEditingController captionController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar:
          AppBar(title: const Text("PAYLAŞ"), backgroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(imageUrl, height: 300, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            // HATAYI ÇÖZEN KISIM: 'hintText' ve 'maxLines' eklendi
            VibeoInput(
              controller: captionController,
              hintText: "Bu eser hakkında bir şeyler yaz...",
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            VibeoButton(
              text: "ŞİMDİ PAYLAŞ",
              onPressed: () {
                // Paylaşma mantığı
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
