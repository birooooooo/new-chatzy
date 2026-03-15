import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  String _themeMode = 'System';
  String _chatWallpaper = 'Default';
  String _accentColor = 'Blue';
  double _fontSize = 1.0;
  bool _highContrast = false;

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Blue', 'color': AppTheme.primary},
    {'name': 'Green', 'color': Colors.green},
    {'name': 'Purple', 'color': Colors.purple},
    {'name': 'Orange', 'color': Colors.orange},
    {'name': 'Pink', 'color': Colors.pink},
    {'name': 'Teal', 'color': Colors.teal},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Theme'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Mode
            _SectionTitle(title: 'Theme Mode')
                .animate()
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  _ThemeModeOption(
                    icon: Icons.brightness_auto,
                    title: 'System',
                    subtitle: 'Follow system settings',
                    isSelected: _themeMode == 'System',
                    onTap: () => setState(() => _themeMode = 'System'),
                  ),
                  const Divider(height: 1),
                  _ThemeModeOption(
                    icon: Icons.light_mode,
                    title: 'Light',
                    subtitle: 'Always use light theme',
                    isSelected: _themeMode == 'Light',
                    onTap: () => setState(() => _themeMode = 'Light'),
                  ),
                  const Divider(height: 1),
                  _ThemeModeOption(
                    icon: Icons.dark_mode,
                    title: 'Dark',
                    subtitle: 'Always use dark theme',
                    isSelected: _themeMode == 'Dark',
                    onTap: () => setState(() => _themeMode = 'Dark'),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Accent Color
            _SectionTitle(title: 'Accent Color')
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.softShadow,
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _colors.map((color) {
                  final isSelected = _accentColor == color['name'];
                  return GestureDetector(
                    onTap: () => setState(() => _accentColor = color['name']),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color['color'],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (color['color'] as Color).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Chat Wallpaper
            _SectionTitle(title: 'Chat Wallpaper')
                .animate()
                .fadeIn(delay: 400.ms, duration: 300.ms),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.softShadow,
              ),
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.wallpaper, color: AppTheme.primary),
                ),
                title: const Text('Chat Wallpaper'),
                subtitle: Text(_chatWallpaper),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                onTap: () => _showWallpaperPicker(),
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Font Size
            _SectionTitle(title: 'Font Size')
                .animate()
                .fadeIn(delay: 600.ms, duration: 300.ms),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('A', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 0.8,
                          max: 1.4,
                          divisions: 3,
                          onChanged: (value) => setState(() => _fontSize = value),
                        ),
                      ),
                      const Text('A', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                  Text(
                    'Preview: This is how text will look',
                    style: TextStyle(fontSize: 14 * _fontSize),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Accessibility
            _SectionTitle(title: 'Accessibility')
                .animate()
                .fadeIn(delay: 800.ms, duration: 300.ms),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.softShadow,
              ),
              child: SwitchListTile(
                title: const Text('High Contrast'),
                subtitle: const Text('Increase contrast for better visibility'),
                value: _highContrast,
                onChanged: (value) => setState(() => _highContrast = value),
              ),
            )
                .animate()
                .fadeIn(delay: 900.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }

  void _showWallpaperPicker() {
    final wallpapers = ['Default', 'Gradient Blue', 'Gradient Purple', 'Dark', 'Custom'];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Wallpaper',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...wallpapers.map((wallpaper) => ListTile(
              title: Text(wallpaper),
              trailing: _chatWallpaper == wallpaper
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
              onTap: () {
                setState(() => _chatWallpaper = wallpaper);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppTheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppTheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
