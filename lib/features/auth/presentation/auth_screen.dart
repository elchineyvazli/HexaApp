// lib/features/auth/presentation/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/auth_service.dart';
import 'widgets/hexagon_logo.dart';
import 'widgets/auth_background.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final userCredential = await authService.signInWithGoogle();
      if (userCredential != null && mounted) context.goNamed('feed');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      body: Stack(
        children: [
          const AuthBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const HexagonLogo().animate(onPlay: (c) => c.repeat()).rotate(duration: 10.seconds),
                        const Text('HEXA', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('NEXT-GEN DISCOVERY', style: TextStyle(color: Color(0xFF8E92B2), letterSpacing: 4, fontSize: 12)),
                  const Spacer(),
                  _buildGoogleButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF181926), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Color(0xFFFF5E00), width: 1.5))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isLoading) const CircularProgressIndicator(color: Color(0xFFFF5E00))
          else ...[
            const Icon(Icons.g_mobiledata, size: 32, color: Color(0xFFFF5E00)),
            const SizedBox(width: 12),
            const Text('GOOGLE İLE BAŞLA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutBack);
  }
}