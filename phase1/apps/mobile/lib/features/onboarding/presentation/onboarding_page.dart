import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../auth/application/auth_notifier.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late final PageController _pageController;
  int _currentIndex = 0;

  final _slides = const [
    _OnboardingSlide(
      title: 'Benvenuto in XXX',
      description: 'Un’unica piattaforma per sfide, progressi e community. Inizia il tuo viaggio con un profilo personalizzato.',
      icon: Icons.self_improvement,
      accent: Color(0xFF7C3AED),
    ),
    _OnboardingSlide(
      title: 'Progressi in tempo reale',
      description: 'Monitoriamo i tuoi risultati con dashboard dinamiche e sincronizzazione multi-dispositivo.',
      icon: Icons.show_chart,
      accent: Color(0xFFFFA53A),
    ),
    _OnboardingSlide(
      title: 'Sicurezza e controllo',
      description: 'Login federato, token sicuri e sessioni protette: le tue credenziali restano al sicuro.',
      icon: Icons.verified_user,
      accent: Color(0xFF14B8A6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authSessionProvider);
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: authState.when(
          data: (session) {
            if (session.isAuthenticated) {
              return const _OnboardingCompleted();
            }
            return _buildCarousel(context);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _OnboardingError(error: error),
        ),
      ),
    );
  }

  Widget _buildCarousel(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Onboarding',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/auth'),
                    child: const Text('Salta'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return _OnboardingCard(slide: slide, maxHeight: size.height * 0.55)
                        .animate()
                        .fade(duration: 400.ms, curve: Curves.easeOutCirc)
                        .slide(begin: const Offset(0.05, 0.1), curve: Curves.decelerate);
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _slides.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: Colors.white,
                      dotColor: Color(0x80FFFFFF),
                      dotHeight: 8,
                      dotWidth: 8,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.go('/auth'),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(_currentIndex == _slides.length - 1 ? 'Accedi' : 'Avanti'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Fase 1 • Onboarding & Auth sicure',
                style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.slide, required this.maxHeight});

  final _OnboardingSlide slide;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [slide.accent.withOpacity(0.18), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.accent.withOpacity(0.15),
            ),
            child: Icon(slide.icon, size: 30, color: slide.accent),
          ),
          const SizedBox(height: 28),
          Text(
            slide.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF1C1B4D),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.description,
            style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF3B3B63)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: slide.accent.withOpacity(0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.security, color: slide.accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Sicurezza enterprise',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF1C1B4D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
}

class _OnboardingCompleted extends StatelessWidget {
  const _OnboardingCompleted();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.celebration, color: Colors.white, size: 56),
            SizedBox(height: 16),
            Text(
              'Onboarding completato! 🎉',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingError extends StatelessWidget {
  const _OnboardingError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text('Errore onboarding: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/auth'),
                child: const Text('Vai al login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
