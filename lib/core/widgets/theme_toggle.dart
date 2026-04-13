import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Phase 5: UI/UX Polish - Theme Toggle Widget
/// 
/// Widget to toggle between light and dark mode
class ThemeToggle extends StatelessWidget {
  final bool useSwitch;
  final bool showLabel;

  const ThemeToggle({
    super.key,
    this.useSwitch = true,
    this.showLabel = true,
  });

  const ThemeToggle.icon({
    super.key,
  })  : useSwitch = false,
        showLabel = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    if (useSwitch) {
      return ListTile(
        leading: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          'Dark Mode',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: showLabel
            ? Text(
                isDark ? 'Enabled' : 'Disabled',
                style: Theme.of(context).textTheme.bodySmall,
              )
            : null,
        trailing: Switch.adaptive(
          value: isDark,
          onChanged: (_) => themeProvider.toggleTheme(),
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        onTap: () => themeProvider.toggleTheme(),
      );
    }

    // Icon button variant
    return IconButton(
      icon: Icon(
        isDark ? Icons.dark_mode : Icons.light_mode,
        color: isDark
            ? Colors.amber
            : Theme.of(context).colorScheme.primary,
      ),
      onPressed: () => themeProvider.toggleTheme(),
      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
    );
  }
}

/// Theme mode selector with radio buttons
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final themeMode = themeProvider.themeMode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Light'),
          subtitle: const Text('Always use light theme'),
          secondary: const Icon(Icons.light_mode),
          value: ThemeMode.light,
          groupValue: themeMode,
          onChanged: (value) {
            if (value != null) themeProvider.setThemeMode(value);
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Dark'),
          subtitle: const Text('Always use dark theme'),
          secondary: const Icon(Icons.dark_mode),
          value: ThemeMode.dark,
          groupValue: themeMode,
          onChanged: (value) {
            if (value != null) themeProvider.setThemeMode(value);
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text('System'),
          subtitle: const Text('Follow system settings'),
          secondary: const Icon(Icons.settings_suggest),
          value: ThemeMode.system,
          groupValue: themeMode,
          onChanged: (value) {
            if (value != null) themeProvider.setThemeMode(value);
          },
        ),
      ],
    );
  }
}
