import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/notion_theme.dart';
import '../widgets/magic/magic.dart';

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

    // d. "Qlip" text fades in below logo (1200-1800ms)
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
      backgroundColor: NotionTheme.ink,
      body: AuraBackground(
        child: Center(
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
                          BoxShadow(
                            color: NotionTheme.lime.withValues(
                              alpha: 0.4 * _glowAnimation.value,
                            ),
                            blurRadius: 50 * _glowAnimation.value,
                            spreadRadius: 15 * _glowAnimation.value,
                          ),
                          BoxShadow(
                            color: NotionTheme.green.withValues(
                              alpha: 0.3 * _glowAnimation.value,
                            ),
                            blurRadius: 80 * _glowAnimation.value,
                            spreadRadius: 28 * _glowAnimation.value,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/qlip.png',
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

            // "Qlip" text with gradient and fade animation
            FadeTransition(
              opacity: _textFadeAnimation,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    NotionTheme.limePale,
                    NotionTheme.lime,
                    NotionTheme.green,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'Qlip',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle with fade animation
            FadeTransition(
              opacity: _textFadeAnimation,
              child: Text(
                'Your AI knowledge vault',
                style: TextStyle(
                  fontSize: 16,
                  color: NotionTheme.fog.withValues(alpha: 0.7),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
