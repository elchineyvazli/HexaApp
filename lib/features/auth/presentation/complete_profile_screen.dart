// lib/features/auth/presentation/complete_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../data/user_repository.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Google'dan gelen e-postanın ilk kısmını varsayılan kullanıcı adı olarak önerelim
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      _usernameController.text = user.email!.split('@')[0];
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    if (username.isEmpty || username.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı adı en az 3 karakter olmalıdır!'),
          backgroundColor: Color(0xFFFF5E00),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Veritabanında profili tamamla ve kalkanı aç
        await ref.read(userRepositoryProvider).completeUserProfile(
              uid: user.uid,
              username: username,
              bio: bio,
            );

        if (mounted) {
          // Kalkan açıldı, doğrudan akış ekranına fırlat!
          context.go('/feed');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: const Color(0xFFFF5E00)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope ile donanımsal geri tuşunu ve kaydırma hareketini tamamen kilitliyoruz!
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Siber ağa katılmadan önce profilini tamamlamalısın! 🛡️'),
              backgroundColor: Color(0xFFFF5E00),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0E15),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.shield_outlined, size: 80, color: Color(0xFFFF5E00)),
                    const SizedBox(height: 16),
                    const Text(
                      'SON BİR ADIM KALDI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hexa dünyasında tanınacağın siber kimliğini ve biyografini belirle.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8E92B2), fontSize: 14),
                    ),
                    const SizedBox(height: 40),

                    // Kullanıcı Adı Alanı
                    const Text('KULLANICI ADI', style: TextStyle(color: Color(0xFFFF5E00), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: '@ ',
                        prefixStyle: const TextStyle(color: Color(0xFFFF5E00), fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: const Color(0xFF181926),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF5E00), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Biyografi Alanı
                    const Text('BİYOGRAFİ', style: TextStyle(color: Color(0xFF9D4EDD), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bioController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Siber dünyada yeni bir yolcu...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF181926),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Tamamla Butonu
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5E00),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 10,
                        shadowColor: const Color(0xFFFF5E00).withOpacity(0.4),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text(
                              'SİBER AĞA GİRİŞ YAP',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}