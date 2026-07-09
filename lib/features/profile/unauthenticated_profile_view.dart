// lib/features/profile/unauthenticated_profile_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexa/features/auth/application/auth_service.dart';

class UnauthenticatedProfileView extends ConsumerStatefulWidget {
  const UnauthenticatedProfileView({super.key});

  @override
  ConsumerState<UnauthenticatedProfileView> createState() => _UnauthenticatedProfileViewState();
}

class _UnauthenticatedProfileViewState extends ConsumerState<UnauthenticatedProfileView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // true = Giriş Yap, false = Kaydol
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // Giriş başarılı olunca Riverpod otomatik olarak ana profil ekranını tetikleyecek!
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giriş Hatası: $e'), backgroundColor: const Color(0xFFFF5E00)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_outline_rounded, size: 80, color: Color(0xFFFF5E00)),
              const SizedBox(height: 16),
              Text(
                _isLogin ? 'Hexa\'ya Giriş Yap' : 'Siber Ağımıza Kaydol',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Profili görüntülemek, video yüklemek ve etkileşime geçmek için bir hesaba ihtiyacın var.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8E92B2), fontSize: 14),
              ),
              const SizedBox(height: 32),

              // E-posta Girdi Alanı
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'E-posta Adresi',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF8E92B2)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              // Şifre Girdi Alanı
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Şifre',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF8E92B2)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),

              // Giriş Yap / Kaydol Butonu (E-posta için)
              ElevatedButton(
                onPressed: _isLoading ? null : () {
                  // İleride E-posta/Şifre ile giriş/kayıt motoru buraya bağlanacak
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen şimdilik Google ile Giriş Yap butonunu kullanın.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5E00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isLogin ? 'GİRİŞ YAP' : 'HESAP OLUŞTUR',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // Giriş / Kayıt Modu Değiştirici
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? 'Hesabın yok mu? Hemen Kaydol' : 'Zaten bir hesabın var mı? Giriş Yap',
                  style: const TextStyle(color: Color(0xFF9D4EDD)),
                ),
              ),
              const SizedBox(height: 24),

              // Ayraç
              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFF1E293B))),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('VEYA', style: TextStyle(color: Colors.white38, fontSize: 12))),
                  Expanded(child: Divider(color: Color(0xFF1E293B))),
                ],
              ),
              const SizedBox(height: 24),

              // Google İle Giriş Butonu
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.g_mobiledata, size: 28, color: Color(0xFFFF5E00)),
                label: const Text('GOOGLE İLE DEVAM ET', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF181926),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFFF5E00), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}