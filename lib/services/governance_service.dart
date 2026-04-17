import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GovernanceProposal {
  final String id;
  final String title;
  final String description;
  final String category;
  final int yesCount;
  final int noCount;
  final int abstainCount;
  final String status;

  const GovernanceProposal({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.yesCount,
    required this.noCount,
    required this.abstainCount,
    required this.status,
  });

  factory GovernanceProposal.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return GovernanceProposal(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      category: (data['category'] ?? 'ethics') as String,
      yesCount: (data['yesCount'] ?? 0) as int,
      noCount: (data['noCount'] ?? 0) as int,
      abstainCount: (data['abstainCount'] ?? 0) as int,
      status: (data['status'] ?? 'open') as String,
    );
  }
}

class GovernanceService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _proposalsRef =>
      _db.collection('governance_proposals');

  static Future<void> ensureSeeded() async {
    final snapshot = await _proposalsRef.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = _db.batch();
    final docs = <Map<String, String>>[
      {
        'id': 'algorithm-transparency',
        'title': 'Algoritmik Şeffaflık Düzeyi',
        'description':
            'Feed sıralamasında neden gösterildi kartlarının zorunlu olup olmayacağına topluluk karar verir.',
        'category': 'algorithm',
      },
      {
        'id': 'memorial-ai',
        'title': 'Anıt AI Varsayılanı',
        'description':
            'Kullanıcılar vefat sonrası profilini Anıt AI olarak bırakmak için açık rıza ekranı görmeli mi?',
        'category': 'legacy',
      },
      {
        'id': 'passive-contribution',
        'title': 'Pasif Katkı Limitleri',
        'description':
            'AI ikizlerin kullanıcı uyurken kaç düşük riskli yardım akışına katılabileceği için üst sınır belirlenir.',
        'category': 'ethics',
      },
    ];

    for (final item in docs) {
      final ref = _proposalsRef.doc(item['id']!);
      batch.set(ref, {
        'title': item['title'],
        'description': item['description'],
        'category': item['category'],
        'yesCount': 0,
        'noCount': 0,
        'abstainCount': 0,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  static Stream<List<GovernanceProposal>> streamProposals() {
    return _proposalsRef.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(GovernanceProposal.fromDoc).toList(),
        );
  }

  static Stream<Map<String, String>> streamMyVotes() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(const <String, String>{});
    }

    return _db
        .collectionGroup('votes')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final result = <String, String>{};
      for (final doc in snapshot.docs) {
        final parentProposalId = doc.reference.parent.parent?.id;
        if (parentProposalId != null) {
          result[parentProposalId] =
              (doc.data()['choice'] ?? 'abstain') as String;
        }
      }
      return result;
    });
  }

  static Future<void> castVote({
    required String proposalId,
    required String choice,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final proposalRef = _proposalsRef.doc(proposalId);
    final voteRef = proposalRef.collection('votes').doc(uid);

    await _db.runTransaction((transaction) async {
      final proposalSnap = await transaction.get(proposalRef);
      final voteSnap = await transaction.get(voteRef);

      final proposal = proposalSnap.data() ?? <String, dynamic>{};
      final previousChoice = (voteSnap.data()?['choice'] ?? '') as String;

      var yesCount = (proposal['yesCount'] ?? 0) as int;
      var noCount = (proposal['noCount'] ?? 0) as int;
      var abstainCount = (proposal['abstainCount'] ?? 0) as int;

      void decrement(String value) {
        if (value == 'yes' && yesCount > 0) yesCount -= 1;
        if (value == 'no' && noCount > 0) noCount -= 1;
        if (value == 'abstain' && abstainCount > 0) abstainCount -= 1;
      }

      void increment(String value) {
        if (value == 'yes') yesCount += 1;
        if (value == 'no') noCount += 1;
        if (value == 'abstain') abstainCount += 1;
      }

      decrement(previousChoice);
      increment(choice);

      transaction.set(
          voteRef,
          {
            'uid': uid,
            'choice': choice,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      transaction.set(
          proposalRef,
          {
            'yesCount': yesCount,
            'noCount': noCount,
            'abstainCount': abstainCount,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    });
  }
}
