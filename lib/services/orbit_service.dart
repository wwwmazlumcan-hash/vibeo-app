import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrbitService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamOrbits() {
    return _db
        .collection('orbits')
        .orderBy('memberCount', descending: true)
        .snapshots();
  }

  static Future<void> createOrbit({
    required String name,
    required String description,
    required List<String> themes,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('orbits').add({
      'name': name,
      'description': description,
      'themes': themes,
      'creatorUid': uid,
      'members': [uid],
      'memberCount': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> toggleMembership({
    required String orbitId,
    required bool joined,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('orbits').doc(orbitId).set({
      'members':
          joined ? FieldValue.arrayRemove([uid]) : FieldValue.arrayUnion([uid]),
      'memberCount': FieldValue.increment(joined ? -1 : 1),
    }, SetOptions(merge: true));
  }

  static List<Map<String, dynamic>> suggestedOrbits() {
    return const [
      {
        'name': 'Felsefe Orbiti',
        'description': 'Uzun omurlu fikirler ve zor sorular.',
        'themes': ['felsefe', 'anlam', 'dusunce'],
      },
      {
        'name': 'Teknoloji Orbiti',
        'description': 'Yapay zeka, urun mantigi ve gelecek senaryolari.',
        'themes': ['teknoloji', 'gelecek', 'ai'],
      },
      {
        'name': 'Karadeniz Mizah Orbiti',
        'description': 'Yerel mizah, sert enerji ve hizli refleks.',
        'themes': ['mizah', 'yerel', 'komik'],
      },
    ];
  }
}
