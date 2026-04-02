import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class GhostAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showShieldIcon;
  final bool showAvatar;

  const GhostAppBar({
    super.key,
    this.showShieldIcon = false,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgSecondary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
      ),
      child: SizedBox(
        height: kToolbarHeight,
        child: Row(
          children: [
            if (showAvatar) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.bgCard,
                  border: Border.all(color: AppTheme.borderLight, width: 1.5),
                ),
                child: ClipOval(
                  child: Icon(
                    Icons.person,
                    color: AppTheme.textMuted,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            if (showShieldIcon) ...[
              Icon(Icons.security, color: AppTheme.accentBlue, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              'GHOSTRUN',
              style: GoogleFonts.rajdhani(
                color: AppTheme.accentBlue,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Icon(
                Icons.settings,
                color: AppTheme.textMuted,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + 0, // padding added in build
      );
}

// Ghost card widget
class GhostCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double radius;

  const GhostCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppTheme.bgCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}

// Label chip widget
class GhostChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;

  const GhostChip({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.rajdhani(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor ?? color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// Section label
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.rajdhani(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppTheme.textMuted,
        letterSpacing: 2,
      ),
    );
  }
}
