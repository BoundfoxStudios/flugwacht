import 'dart:async';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../../app_icons.dart';
import '../../l10n/app_localizations.g.dart';
import '../theme/app_tokens.dart';
import '../widgets/controls/app_primary_button.dart';
import '../widgets/onboarding/route_artwork.dart';
import 'onboarding_page.dart';

/// What the app says about itself before it is used for the first time: what
/// it does, what it deliberately does not, and where it lives.
///
/// It runs once per installation and offers no way out other than through, so
/// the three pages stay short and the last one leads into the app.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onDone, super.key});

  /// Called by the last page's button, which is the only way on.
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Leaves the illustration band the room the design gives it below the
  /// status bar.
  static const _topGap = AppSpacing.screenPadding;
  static const _horizontalPadding = 28.0;
  static const _bottomPadding = 32.0;
  static const _pageDuration = Duration(milliseconds: 200);

  final _controller = PageController();
  var _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final pages = _pagesOf(localizations);
    final isLastPage = _index == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: _topGap),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _index = index),
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _horizontalPadding,
                0,
                _horizontalPadding,
                _bottomPadding,
              ),
              child: Column(
                children: [
                  _Pager(
                    count: pages.length,
                    activeIndex: _index,
                    onSelected: _goToPage,
                  ),
                  AppPrimaryButton(
                    label: isLastPage
                        ? localizations.onboardingStart
                        : localizations.onboardingNext,
                    onPressed: isLastPage
                        ? widget.onDone
                        : () => _goToPage(_index + 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToPage(int index) => unawaited(
    _controller.animateToPage(
      index,
      duration: _pageDuration,
      curve: Curves.easeInOut,
    ),
  );

  List<Widget> _pagesOf(AppLocalizations localizations) => [
    OnboardingPage(
      artwork: const RouteArtwork(state: RouteArtworkState.live),
      title: localizations.onboardingPurposeTitle,
      bullets: [
        OnboardingBullet(
          localizations.onboardingPurposeBullet1,
          OnboardingTone.promise,
        ),
        OnboardingBullet(
          localizations.onboardingPurposeBullet2,
          OnboardingTone.promise,
        ),
        OnboardingBullet(
          localizations.onboardingPurposeBullet3,
          OnboardingTone.promise,
        ),
        OnboardingBullet(
          localizations.onboardingPurposeBullet4,
          OnboardingTone.promise,
        ),
      ],
    ),
    OnboardingPage(
      artwork: const RouteArtwork(state: RouteArtworkState.resting),
      title: localizations.onboardingLimitsTitle,
      bullets: [
        OnboardingBullet(
          localizations.onboardingLimitsBullet1,
          OnboardingTone.limit,
        ),
        OnboardingBullet(
          localizations.onboardingLimitsBullet2,
          OnboardingTone.promise,
        ),
        OnboardingBullet(
          localizations.onboardingLimitsBullet3,
          OnboardingTone.limit,
        ),
      ],
    ),
    OnboardingPage(
      artwork: const _BrandGlyphs(),
      title: localizations.onboardingOpenSourceTitle,
      bullets: [
        OnboardingBullet(
          localizations.onboardingOpenSourceBullet1,
          OnboardingTone.promise,
        ),
        OnboardingBullet(
          localizations.onboardingOpenSourceBullet2,
          OnboardingTone.promise,
        ),
      ],
    ),
  ];
}

/// The two places the project lives, as their own marks. The copy beside them
/// names both, so the glyphs carry no semantics of their own.
class _BrandGlyphs extends StatelessWidget {
  const _BrandGlyphs();

  static const _glyphSize = 78.0;
  static const _gap = 40.0;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: _gap,
    children: [
      FaIcon(
        AppIcons.github,
        size: _glyphSize,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      const FaIcon(AppIcons.discord, size: _glyphSize, color: AppColors.amber),
    ],
  );
}

/// Which page of the introduction is showing, and a way to jump to another.
/// The active page widens into a bar instead of only changing colour, so the
/// position reads without relying on the accent alone.
class _Pager extends StatelessWidget {
  const _Pager({
    required this.count,
    required this.activeIndex,
    required this.onSelected,
  });

  static const _dotSize = 8.0;
  static const _activeDotWidth = 20.0;

  /// Half the gap the design puts between two dots, so each dot carries its
  /// own share and the row still spaces them the designed distance apart.
  static const _dotGap = AppSpacing.grid;
  static const _hitHeight = 44.0;
  static const _duration = Duration(milliseconds: 200);

  final int count;
  final int activeIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final inactiveColor = switch (Theme.of(context).brightness) {
      Brightness.light => AppColors.neutral300,
      Brightness.dark => AppColors.neutral600,
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          Semantics(
            button: true,
            selected: index == activeIndex,
            label: localizations.onboardingPageLabel('${index + 1}', '$count'),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(index),
              child: SizedBox(
                height: _hitHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _dotGap),
                  child: Center(
                    child: AnimatedContainer(
                      duration: _duration,
                      curve: Curves.easeInOut,
                      width: index == activeIndex ? _activeDotWidth : _dotSize,
                      height: _dotSize,
                      decoration: BoxDecoration(
                        color: index == activeIndex
                            ? AppColors.amber
                            : inactiveColor,
                        borderRadius: BorderRadius.circular(_dotSize / 2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
