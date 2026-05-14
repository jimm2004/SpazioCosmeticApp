import 'package:flutter/material.dart';

import '../mood_palette.dart';

class MoodBreakpoints {
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 640;
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 640 && width < 1024;
  }

  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1024;
  static bool isWide(BuildContext context) => MediaQuery.of(context).size.width >= 900;
}

class MoodMaxWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  const MoodMaxWidth({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class MoodInfoPillData {
  final IconData icon;
  final String label;
  final String value;

  const MoodInfoPillData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class MoodMarketplaceHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<MoodInfoPillData> pills;
  final Widget? trailing;

  const MoodMarketplaceHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.pills = const [],
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MoodBreakpoints.isWide(context);
    return MoodMaxWidth(
      padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 14, isWide ? 24 : 16, 12),
      child: Container(
        padding: EdgeInsets.all(isWide ? 22 : 18),
        decoration: BoxDecoration(
          gradient: MoodPalette.mainGradient,
          borderRadius: BorderRadius.circular(isWide ? 30 : 24),
          boxShadow: [MoodPalette.cardShadow(.14)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isWide ? 58 : 50,
                  height: isWide ? 58 : 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.16),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(.28)),
                  ),
                  child: Icon(icon, color: Colors.white, size: isWide ? 32 : 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: isWide ? 26 : 21,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        subtitle,
                        maxLines: isWide ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(.78), fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                if (trailing != null && isWide) ...[
                  const SizedBox(width: 16),
                  trailing!,
                ],
              ],
            ),
            if (pills.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: pills.map((pill) => MoodInfoPill(data: pill)).toList(),
              ),
            ],
            if (trailing != null && !isWide) ...[
              const SizedBox(height: 14),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class MoodInfoPill extends StatelessWidget {
  final MoodInfoPillData data;

  const MoodInfoPill({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, color: Colors.white, size: 17),
          const SizedBox(width: 7),
          Text(data.label, style: TextStyle(color: Colors.white.withOpacity(.72), fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(width: 5),
          Text(data.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }
}

class MoodSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double shadow;
  final Color color;

  const MoodSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.shadow = .06,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [MoodPalette.cardShadow(shadow)],
        border: Border.all(color: Colors.black.withOpacity(.035)),
      ),
      child: child,
    );
  }
}

class MoodSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const MoodSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: MoodPalette.text, fontSize: 20, fontWeight: FontWeight.w900)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: const TextStyle(color: MoodPalette.muted, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class MoodPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool loading;

  const MoodPrimaryButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: MoodPalette.pink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: MoodPalette.pink.withOpacity(.55),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}

class MoodGhostButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  const MoodGhostButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: MoodPalette.pink,
        side: BorderSide(color: MoodPalette.pink.withOpacity(.28)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
