import 'package:flutter/material.dart';

import '../../../app/haptics.dart';
import '../../../app/nutri_colors.dart';

/// Accent options used by the Appearance setting.
enum NutriAccent { forest, olive, berry, sea }

const Map<NutriAccent, Color> nutriAccentColor = {
  NutriAccent.forest: Color(0xFF2F6A4B),
  NutriAccent.olive:  Color(0xFF6B7A2E),
  NutriAccent.berry:  Color(0xFF8B3A4C),
  NutriAccent.sea:    Color(0xFF2C6B76),
};

const Map<NutriAccent, String> nutriAccentLabel = {
  NutriAccent.forest: 'Forest',
  NutriAccent.olive:  'Olive',
  NutriAccent.berry:  'Berry',
  NutriAccent.sea:    'Sea',
};

/// Small all-caps section header shown above a [SettingsGroup].
class SettingsHeader extends StatelessWidget {
  final String label;
  const SettingsHeader(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 22, 6, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: context.nutri.ink2,
        ),
      ),
    );
  }
}

/// A warm card grouping several rows, auto-inserting hairline dividers.
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Padding(
          padding: const EdgeInsets.only(left: 60),
          child: Divider(height: 1, color: c.line),
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

/// Standard tappable settings row with a tinted icon tile and optional trailing.
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    final titleColor = destructive ? c.warn : c.ink;

    Widget? tail = trailing;
    tail ??= (onTap != null || value != null)
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                Flexible(
                  child: Text(
                    value!,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: c.ink2, fontWeight: FontWeight.w500),
                  ),
                ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 20, color: c.ink3),
              ],
            ],
          )
        : null;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap == null ? null : () { Haptics.selectionClick(); onTap!(); },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: titleColor),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: TextStyle(fontSize: 12, color: c.ink2)),
                    ],
                  ],
                ),
              ),
              if (tail != null) ...[const SizedBox(width: 10), Flexible(child: tail)],
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings row whose trailing control is a Material [Switch].
class SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggleRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(fontSize: 12, color: c.ink2)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: c.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: c.lineStrong,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

/// Settings row with a compact two-option segmented control on the right.
class SettingsSegmentedRow<T> extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  const SettingsSegmentedRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(11)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (val, label) in options)
                  GestureDetector(
                    onTap: () => onChanged(val),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: val == value ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: val == value
                            ? [BoxShadow(color: c.ink.withValues(alpha: 0.08), blurRadius: 3, offset: const Offset(0, 1))]
                            : null,
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: val == value ? c.ink : c.ink2,
                        ),
                      ),
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

/// Appearance row showing four tappable accent swatches on the right.
class SettingsAccentRow extends StatelessWidget {
  final NutriAccent value;
  final ValueChanged<NutriAccent> onChanged;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const SettingsAccentRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Accent colour', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(nutriAccentLabel[value]!, style: TextStyle(fontSize: 12, color: c.ink2)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final a in NutriAccent.values)
                GestureDetector(
                  onTap: () => onChanged(a),
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: nutriAccentColor[a],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: a == value ? c.ink : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: a == value
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
