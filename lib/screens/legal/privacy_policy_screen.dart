import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gizlilik Politikası')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _PolicyContent(),
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanım Koşulları')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _TermsContent(),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section('Son güncelleme: Nisan 2026'),
        _Section('1. Toplanan Veriler',
            'Vibeo, hizmetleri sunabilmek için e-posta adresi, kullanıcı adı ve paylaşılan içerikler gibi bilgileri toplar. Kamera ve galeri erişimi yalnızca siz talep ettiğinizde kullanılır.'),
        _Section('2. Verilerin Kullanımı',
            'Verileriniz; hesap yönetimi, içerik sunumu ve uygulama güvenliği amacıyla kullanılır. Üçüncü taraflarla satılmaz.'),
        _Section('3. Firebase',
            'Uygulama, Google Firebase altyapısını kullanmaktadır. Firebase\'in kendi gizlilik politikası geçerlidir: https://firebase.google.com/support/privacy'),
        _Section('4. AI İçerik',
            'Üretilen görseller Pollinations.AI servisi aracılığıyla oluşturulur. Promptlarınız bu servis tarafından işlenir.'),
        _Section('5. Çerezler ve Takip',
            'Uygulama analitik amaçlı anonim kullanım verisi toplayabilir. Bunu ayarlardan devre dışı bırakabilirsiniz.'),
        _Section('6. Veri Silme',
            'Hesabınızı profil ekranındaki hesap silme aksiyonu ile uygulama içinden silebilirsiniz. Gerekirse destek@vibeo.app üzerinden ek destek alabilirsiniz.'),
        _Section('7. İletişim', 'Sorularınız için: destek@vibeo.app'),
      ],
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section('Son güncelleme: Nisan 2026'),
        _Section('1. Hizmet Kullanımı',
            'Vibeo\'yu kullanarak bu koşulları kabul etmiş sayılırsınız. 13 yaşından küçük kullanıcılar uygulamayı kullanamaz.'),
        _Section('2. İçerik Sorumluluğu',
            'Paylaştığınız içeriklerin telif hakkı ve yasal sorumluluğu size aittir. Yasadışı, zararlı veya hakaret içeren içerikler yasaktır.'),
        _Section('3. AI Kullanımı',
            'AI ile üretilen içerikler otomatik moderasyona tabidir. Kötüye kullanım hesap askıya alınmasına yol açabilir.'),
        _Section('4. Fikri Mülkiyet',
            'Vibeo logosu ve markası bize aittir. Kullanıcılar kendi içeriklerinin haklarını saklı tutar.'),
        _Section('5. Hizmet Kesintisi',
            'Bakım, güncelleme veya teknik nedenlerle hizmet geçici olarak durdurulabilir.'),
        _Section('6. Değişiklikler',
            'Bu koşullar önceden bildirim yapılarak değiştirilebilir. Güncel koşullar uygulama içinde yayınlanır.'),
        _Section('7. İletişim', 'Hukuki sorular için: hukuk@vibeo.app'),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? body;
  const _Section(this.title, [this.body]);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(body!,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.6)),
          ],
        ],
      ),
    );
  }
}
