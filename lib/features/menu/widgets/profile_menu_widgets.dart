import 'package:flutter/material.dart';
import 'package:sixam_mart/util/responsive_size.dart';

/// Shared visual constants for the redesigned profile ("حسابي") screen.
/// Text styles are built per-context so their font sizes scale with the screen.
class ProfileMenuStyle {
  static const Color pageColor = Color(0xFFF6F7F9);
  static const Color cardColor = Colors.white;
  static const Color borderColor = Color(0xFFF0F0F0);
  static const Color dividerColor = Color(0xFFF1F2F4);
  static const Color titleColor = Color(0xFF2D3633);
  static const Color subtitleColor = Color(0xFF8A9199);
  static const Color chevronColor = Color(0xFFBFC6CC);

  static TextStyle sectionLabel(BuildContext context) => TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 18.r(context),
        height: 1.6,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF111B18),
      );

  static TextStyle rowTitle(BuildContext context) => TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 16.r(context),
        height: 1.6,
        fontWeight: FontWeight.w700,
        color: titleColor,
      );

  static TextStyle rowSubtitle(BuildContext context) => TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 12.r(context),
        height: 1.6,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF707784),
      );
}

/// A titled group of rows rendered inside a single white rounded card.
class ProfileSectionCard extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const ProfileSectionCard({
    super.key,
    required this.label,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(
              20.r(context), 18.r(context), 20.r(context), 10.r(context)),
          child: Text(label, style: ProfileMenuStyle.sectionLabel(context)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: ProfileMenuStyle.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ProfileMenuStyle.borderColor),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// A single tappable row: leading icon, title (+ optional subtitle) and a
/// trailing widget which defaults to a chevron. Provide [trailing] to render a
/// switch, badge, etc.
class ProfileMenuRow extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ProfileMenuRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: 14.r(context), vertical: 14.r(context)),
        child: Row(
          children: <Widget>[
            SizedBox(
                width: 24.r(context),
                height: 24.r(context),
                child: Center(child: icon)),
            SizedBox(width: 14.r(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: ProfileMenuStyle.rowTitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                    SizedBox(height: 3.r(context)),
                    Text(
                      subtitle!,
                      style: ProfileMenuStyle.rowSubtitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.r(context)),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  size: 15.r(context),
                  color: ProfileMenuStyle.chevronColor,
                ),
          ],
        ),
      ),
    );
  }
}

/// Small pill badge used as a row trailing (e.g. delivery-man status).
class ProfileStatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const ProfileStatusBadge(
      {super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 10.r(context), vertical: 4.r(context)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 11.r(context),
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// One of the balance/points summary cards under the profile header.
class ProfileStatCard extends StatelessWidget {
  final Color background;
  final Color accent;
  final String image;
  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  const ProfileStatCard({
    super.key,
    required this.background,
    required this.accent,
    required this.image,
    required this.label,
    required this.value,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 145.r(context),
          width: 109.r(context),
          padding: EdgeInsets.all(12.r(context)),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14.r(context),
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: ProfileMenuStyle.titleColor,
                ),
              ),
              SizedBox(height: 2.r(context)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 24.r(context),
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: ProfileMenuStyle.titleColor,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                SizedBox(height: 2.r(context)),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 10.r(context),
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                    color: ProfileMenuStyle.titleColor,
                  ),
                ),
              ],
              // Fills the remaining space and scales the illustration to fit,
              // so the card never overflows regardless of the subtitle.
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Image.asset(
                    image,
                    fit: BoxFit.contain,
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
