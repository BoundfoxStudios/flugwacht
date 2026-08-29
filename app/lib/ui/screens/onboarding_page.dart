import 'package:material_ui/material_ui.dart';

import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';

/// What the dash in front of a point says about it: yellow for something the
/// app does, grey for something it deliberately does not.
enum OnboardingTone { promise, limit }

@immutable
class OnboardingBullet {
  const OnboardingBullet(this.text, this.tone);

  final String text;
  final OnboardingTone tone;
}

/// One page of the introduction: the illustration band, the heading and the
/// points below it. The pager and the button stay with the screen, so they
/// hold still while the pages move.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    required this.artwork,
    required this.title,
    required this.bullets,
    super.key,
  });

  static const _bandHeight = 280.0;
  static const _horizontalPadding = 28.0;
  static const _titleTopPadding = 32.0;
  static const _bulletsGap = 24.0;
  static const _bulletSpacing = 16.0;

  final Widget artwork;
  final String title;
  final List<OnboardingBullet> bullets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: _bandHeight,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outline),
              ),
            ),
            child: artwork,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _horizontalPadding,
              _titleTopPadding,
              _horizontalPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.headlineLarge),
                const SizedBox(height: _bulletsGap),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: _bulletSpacing,
                  children: [
                    for (final bullet in bullets) _BulletRow(bullet: bullet),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.bullet});

  static const _dashGap = AppSpacing.cardPadding;
  static const _lineHeight = 1.5;

  final OnboardingBullet bullet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limitDash = switch (theme.brightness) {
      Brightness.light => AppColors.neutral600,
      Brightness.dark => AppColors.neutral500,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: _dashGap,
      children: [
        ExcludeSemantics(
          child: Text(
            '–',
            style: AppTextStyles.body.copyWith(
              color: switch (bullet.tone) {
                OnboardingTone.promise => AppColors.amber,
                OnboardingTone.limit => limitDash,
              },
            ),
          ),
        ),
        Expanded(
          child: Text(
            bullet.text,
            style: theme.textTheme.bodyMedium?.copyWith(height: _lineHeight),
          ),
        ),
      ],
    );
  }
}
