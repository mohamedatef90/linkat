import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _textController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Define animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    // Start animation sequence
    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    // a. Logo fades in (0-500ms)
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();

    // b. Logo scales up slightly with bounce (500-1000ms)
    await Future.delayed(const Duration(milliseconds: 400));
    _scaleController.forward();

    // c. Logo has subtle glow/pulse effect (1000-1500ms)
    await Future.delayed(const Duration(milliseconds: 300));
    _glowController.forward();

    // d. "Linkat" text fades in below logo (1200-1800ms)
    await Future.delayed(const Duration(milliseconds: 200));
    _textController.forward();

    // e. Hold for 800ms
    await Future.delayed(const Duration(milliseconds: 800));

    // f. Navigate to home
    if (mounted) {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with animations
            AnimatedBuilder(
              animation: Listenable.merge([
                _fadeAnimation,
                _scaleAnimation,
                _glowAnimation,
              ]),
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          // Glow effect - Purple
                          BoxShadow(
                            color: const Color(0xFF9333EA).withOpacity(
                              0.4 * _glowAnimation.value,
                            ),
                            blurRadius: 50 * _glowAnimation.value,
                            spreadRadius: 15 * _glowAnimation.value,
                          ),
                          // Glow effect - Blue
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(
                              0.3 * _glowAnimation.value,
                            ),
                            blurRadius: 70 * _glowAnimation.value,
                            spreadRadius: 25 * _glowAnimation.value,
                          ),
                          // Glow effect - Pink
                          BoxShadow(
                            color: const Color(0xFFEC4899).withOpacity(
                              0.2 * _glowAnimation.value,
                            ),
                            blurRadius: 90 * _glowAnimation.value,
                            spreadRadius: 35 * _glowAnimation.value,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/linkat.png',
                          width: 160,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // "Linkat" text with gradient and fade animation
            FadeTransition(
              opacity: _textFadeAnimation,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFFFF6B9D), // Pink
                    Color(0xFFC06CFF), // Purple
                    Color(0xFF7B61FF), // Deep Purple
                    Color(0xFF4D9FFF), // Blue
                    Color(0xFF06B6D4), // Cyan
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'Linkat',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle with fade animation
            FadeTransition(
              opacity: _textFadeAnimation,
              child: Text(
                'Save & Organize Your Links',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
