import 'package:flutter/material.dart';
import '../core/onboarding_storage.dart';
import '../utils/app_theme.dart';
import '../widgets/app_scaled_text.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // Order requested from the reference:
  // 1) first screen image, 2) third screen image, 3) second screen image.
  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      image: 'assets/images/onboarding_1.png',
      title: 'Track your money easily',
      subtitle:
          'Log expenses and income quickly, manage multiple accounts, '
          'and view clear transaction histories without stress or complexity '
          'every single day.',
    ),
    _OnboardingData(
      image: 'assets/images/onboarding_3.png',
      title: 'Plan budgets with confidence',
      subtitle:
          'Create budgets, track progress visually, receive timely alerts, '
          'and manage shared spending together without pressure or confusion '
          'for everyone involved.',
    ),
    _OnboardingData(
      image: 'assets/images/onboarding_2.png',
      title: 'Gain insights effortlessly',
      subtitle:
          'Explore analytics, calendar views, receipt scanning, and AI '
          'insights that explain spending patterns clearly and help smarter '
          'decisions every time.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goToLogin() async {
    await OnboardingStorage.markAsSeen();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _next() {
    if (_currentPage == _pages.length - 1) {
      _goToLogin();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColor(context),
      body: SafeArea(
        child: PageView.builder(
          controller: _controller,
          itemCount: _pages.length,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemBuilder: (context, index) {
            final isLastPage = index == _pages.length - 1;

            return _OnboardingPage(
              data: _pages[index],
              currentPage: _currentPage,
              totalPages: _pages.length,
              isLastPage: isLastPage,
              onSkip: _goToLogin,
              onNext: _next,
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.isLastPage,
    required this.onSkip,
    required this.onNext,
  });

  final _OnboardingData data;
  final int currentPage;
  final int totalPages;
  final bool isLastPage;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallHeight = constraints.maxHeight < 700;
        final isNarrow = constraints.maxWidth < 370;

        final horizontalPadding = isNarrow ? 18.0 : 20.0;
        final topGap = isSmallHeight ? 16.0 : 24.0;
        final titleGap = isSmallHeight ? 10.0 : 14.0;

        // Smaller gap gives more space to the image.
        final imageVerticalGap = isSmallHeight ? 8.0 : 12.0;

        // Bigger image area, but image itself is less zoomed/cropped.
        final imageHeight = (constraints.maxHeight * 0.48)
            .clamp(isSmallHeight ? 260.0 : 320.0, isSmallHeight ? 350.0 : 430.0)
            .toDouble();

        return SingleChildScrollView(
          physics: isSmallHeight
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                22,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TopBar(
                        currentPage: currentPage,
                        totalPages: totalPages,
                        showSkip: !isLastPage,
                        onSkip: onSkip,
                      ),
                      SizedBox(height: topGap),
                      AppScaledText(
                        data.title,
                        maxLines: 2,
                        minFontSize: 24,
                        style: TextStyle(
                          fontFamily: AppTheme.titleFontFamily,
                          color: AppTheme.titleColor(context),
                          fontSize: isNarrow ? 32 : 32,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: titleGap),
                      AppScaledText(
                        data.subtitle,
                        maxLines: isSmallHeight ? 3 : 4,
                        minFontSize: 11,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: AppTheme.bodyColor(context),
                          fontSize: 14,

                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: imageVerticalGap),
                    child: Center(
                      child: SizedBox(
                        height: imageHeight,
                        width: double.infinity,
                        child: Transform.scale(
                          // Before: 1.18
                          // Now: zoomed out, but container is bigger.
                          scale: 1.03,
                          child: Image.asset(
                            data.image,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _ContinueActions(
                    label: isLastPage ? 'Get Started' : 'Continue',
                    onNext: onNext,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentPage,
    required this.totalPages,
    required this.showSkip,
    required this.onSkip,
  });

  final int currentPage;
  final int totalPages;
  final bool showSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: List.generate(
            totalPages,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 7),
              width: currentPage == index ? 34 : 24,
              height: 6,
              decoration: BoxDecoration(
                color: currentPage == index
                    ? AppTheme.primary
                    : AppTheme.primary.withValues(
                        alpha: AppTheme.isDark(context) ? 0.24 : 0.14,
                      ),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        const Spacer(),
        AnimatedOpacity(
          opacity: showSkip ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: TextButton(
            onPressed: showSkip ? onSkip : null,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppTheme.bodyColor(context),
            ),
            child: Text(
              'Skip',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueActions extends StatelessWidget {
  const _ContinueActions({required this.label, required this.onNext});

  final String label;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _PrimaryActionButton(label: label, onPressed: onNext);
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.image,
    required this.title,
    required this.subtitle,
  });

  final String image;
  final String title;
  final String subtitle;
}
