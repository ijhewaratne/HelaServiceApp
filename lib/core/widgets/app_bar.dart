import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom app bar with HelaService branding
class HelaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Widget? leading;
  final double elevation;
  final Widget? titleWidget;

  const HelaAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.leading,
    this.elevation = 0,
    this.titleWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? Text(title),
      centerTitle: true,
      elevation: elevation,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      leading: leading ?? (showBackButton && Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed ?? () => context.pop(),
            )
          : null),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Transparent app bar for overlay screens
class TransparentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const TransparentAppBar({
    super.key,
    this.actions,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: onBackPressed ?? () => context.pop(),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
