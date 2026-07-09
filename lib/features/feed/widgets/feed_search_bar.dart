// lib/features/feed/widgets/feed_search_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../feed_repository.dart';

class FeedSearchBar extends ConsumerStatefulWidget {
  const FeedSearchBar({super.key});

  @override
  ConsumerState<FeedSearchBar> createState() => _FeedSearchBarState();
}

class _FeedSearchBarState extends ConsumerState<FeedSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ⚡ BUKALEMUN MOD REHBERİ: Her modun kendine ait neon imza rengi var!
  Color _getActiveColor(SearchType type) {
    switch (type) {
      case SearchType.video:
        return const Color(0xFFFF5E00); // Neon Turuncu
      case SearchType.user:
        return const Color(0xFF9D4EDD); // Kuantum Moru
      case SearchType.hashtag:
        return const Color(0xFF00E5FF); // Lazer Siyan / Mavi
    }
  }

  IconData _getActiveIcon(SearchType type) {
    switch (type) {
      case SearchType.video:
        return Icons.play_circle_fill_rounded;
      case SearchType.user:
        return Icons.person_pin_circle_rounded;
      case SearchType.hashtag:
        return Icons.tag_rounded;
    }
  }

  String _getHintText(SearchType type) {
    switch (type) {
      case SearchType.video:
        return 'Akışta bir video sinyali ara...';
      case SearchType.user:
        return 'Siber kimlik ara (@elcin)...';
      case SearchType.hashtag:
        return 'Hashtag ağında keşfet (#cyber)...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentType = ref.watch(searchTypeProvider);
    final activeColor = _getActiveColor(currentType);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        // ⚡ BUKALEMUN NEON GÖLGE: Seçilen modun renginde parlar!
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: activeColor.withOpacity(_isFocused ? 0.45 : 0.15),
              blurRadius: _isFocused ? 25 : 12,
              spreadRadius: _isFocused ? 1 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // ⚡ DERİN UZAY KOKPİT CAMI (HUD VISOR)
                color: const Color(0xFF0A0B10).withOpacity(_isFocused ? 0.90 : 0.75),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: activeColor.withOpacity(_isFocused ? 1.0 : 0.4),
                  width: _isFocused ? 1.8 : 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- 1. KATMAN: ARAMA GİRDİ ALANI ---
                  Row(
                    children: [
                      // Canlı İkon Dönüşümü
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          _getActiveIcon(currentType),
                          key: ValueKey<SearchType>(currentType),
                          color: activeColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          cursorColor: activeColor,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          onChanged: (val) {
                            ref.read(searchQueryProvider.notifier).state = val;
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: _getHintText(currentType),
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      
                      if (_controller.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _controller.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: activeColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // --- 2. KATMAN: KAYAN NEON YÖRÜNGE (SLIDING ORBIT SWITCHER) ---
                  // Sıfır taşma garantili, arkada süzülen kapsül tasarımı!
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Stack(
                      children: [
                        // Kayan Neon Arka Plan Highlighter
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          alignment: _getAlign(currentType),
                          child: FractionallySizedBox(
                            widthFactor: 1 / 3,
                            heightFactor: 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: activeColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: activeColor.withOpacity(0.6),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Sabit Boyutlu Yazı Butonları (Hata kutusunu yok eden kısım)
                        Row(
                          children: [
                            _buildTabItem('Video', SearchType.video, currentType),
                            _buildTabItem('Kullanıcı', SearchType.user, currentType),
                            _buildTabItem('Hashtag', SearchType.hashtag, currentType),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Kayan kapsülün pozisyonunu hesaplayan motor
  Alignment _getAlign(SearchType type) {
    switch (type) {
      case SearchType.video:
        return Alignment.centerLeft;
      case SearchType.user:
        return Alignment.center;
      case SearchType.hashtag:
        return Alignment.centerRight;
    }
  }

  // Taşma yapmayan sabit etiket bileşeni
  Widget _buildTabItem(String label, SearchType type, SearchType currentType) {
    final isSelected = type == currentType;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ref.read(searchTypeProvider.notifier).state = type;
        },
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isSelected ? const Color(0xFF0A0B10) : Colors.white70,
              fontSize: 12,
              // Font ağırlığını sabit tutuyoruz ki Flutter taşma hatası vermesin!
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}