// lib/features/feed/feed_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// YENİ: Arama türlerini belirleyen Enum
enum SearchType { video, user, hashtag }

// YENİ: Arama sorgusu ve seçilen filtre için Riverpod State'leri
final searchQueryProvider = StateProvider<String>((ref) => '');
final searchTypeProvider = StateProvider<SearchType>((ref) => SearchType.video);

// GÜNCEL: Arama kelimesine ve seçilen filtreye göre canlı akış sağlayan Provider
final videosStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final type = ref.watch(searchTypeProvider);
  return ref.watch(feedRepositoryProvider).getVideos(query: query, type: type);
});

final feedRepositoryProvider = Provider(
  (ref) => FeedRepository(FirebaseFirestore.instance),
);

class FeedRepository {
  final FirebaseFirestore _firestore;

  FeedRepository(this._firestore) {
    seedDatabaseIfEmpty();
  }

  static final List<Map<String, dynamic>> _defaultVideos = [
    {
      'videoUrl': 'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBizzell.mp4',
      'description': 'Siberpunk Şehir Gezisi #Hexa #cyber',
      'uploaderId': 'system_admin',
      'username': '@system_admin',
      'likesCount': 142,
      'viewsCount': 1250,
      'sharesCount': 18,
      'commentsCount': 12,
    },
    {
      'videoUrl': 'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'description': 'Yeni Nesil Sosyal Ağ Testi 🚀 #future #tech',
      'uploaderId': 'system_admin',
      'username': '@system_admin',
      'likesCount': 89,
      'viewsCount': 840,
      'sharesCount': 5,
      'commentsCount': 7,
    },
  ];

  // GÜNCEL: Arama ve filtreleme yeteneği kazandırılmış akış motoru
  Stream<List<Map<String, dynamic>>> getVideos({String query = '', SearchType type = SearchType.video}) {
    return _firestore.collection('videos').snapshots().map((snapshot) {
      List<Map<String, dynamic>> docs = [];

      if (snapshot.docs.isEmpty) {
        docs = List.from(_defaultVideos);
      } else {
        docs = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      }

      // ⚡ AKILLI FİLTRELEME MOTORU ⚡
      if (query.isNotEmpty) {
        docs = docs.where((video) {
          final description = (video['description'] as String? ?? '').toLowerCase();
          final username = (video['username'] as String? ?? '').toLowerCase();

          switch (type) {
            case SearchType.video:
              return description.contains(query);
            case SearchType.user:
              final cleanQuery = query.startsWith('@') ? query.substring(1) : query;
              return username.contains(cleanQuery);
            case SearchType.hashtag:
              final cleanTag = query.startsWith('#') ? query : '#$query';
              return description.contains(cleanTag);
          }
        }).toList();
      }

      // createdAt alanına göre güvenli client-side sıralama
      docs.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return docs;
    });
  }

  Future<void> seedDatabaseIfEmpty() async {
    final snapshot = await _firestore.collection('videos').limit(1).get();
    if (snapshot.docs.isEmpty) {
      for (var video in _defaultVideos) {
        await _firestore.collection('videos').add({
          ...video,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }
}