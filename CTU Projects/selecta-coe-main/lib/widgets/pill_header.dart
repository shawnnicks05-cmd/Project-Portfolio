import 'package:flutter/material.dart';

class PillHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData leadingIcon;
  final VoidCallback? onLeadingTap;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;
  final bool useSafeArea;

  const PillHeader({
    super.key,
    required this.title,
    this.leadingIcon = Icons.menu,
    this.onLeadingTap,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 10),
    this.useSafeArea = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final header = Padding(
      padding: padding,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onLeadingTap,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(leadingIcon, size: 18, color: scheme.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconTheme.merge(
                  data: IconThemeData(color: scheme.primary, size: 18),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions,
                  ),
                ),
              ]
            ],
          ),
        ),
    );

    return useSafeArea
        ? SafeArea(bottom: false, child: header)
        : header;
  }
}
