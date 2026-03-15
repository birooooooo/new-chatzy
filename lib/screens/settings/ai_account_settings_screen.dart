import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class AiAccountSettingsScreen extends StatefulWidget {
  const AiAccountSettingsScreen({super.key});

  @override
  State<AiAccountSettingsScreen> createState() => _AiAccountSettingsScreenState();
}

class _AiAccountSettingsScreenState extends State<AiAccountSettingsScreen> {
  String _selectedAi = 'ChatBot Pro';
  bool _autoSuggestions = true;
  bool _smartReplies = true;
  bool _sentimentAnalysis = true;
  bool _autoTranslate = false;
  String _preferredLanguage = 'English';

  final List<Map<String, dynamic>> _aiPersonas = [
    {
      'name': 'ChatBot Pro',
      'description': 'Professional and helpful assistant',
      'icon': Icons.smart_toy,
      'color': AppTheme.primary,
      'features': ['Smart replies', 'Sentiment analysis', 'Translation'],
    },
    {
      'name': 'Creative AI',
      'description': 'Creative and playful responses',
      'icon': Icons.palette,
      'color': Colors.purple,
      'features': ['Creative writing', 'Fun responses', 'Emoji suggestions'],
    },
    {
      'name': 'Business Assistant',
      'description': 'Formal and professional tone',
      'icon': Icons.business_center,
      'color': Colors.teal,
      'features': ['Professional tone', 'Email templates', 'Meeting summaries'],
    },
    {
      'name': 'Friendly Helper',
      'description': 'Casual and friendly communication',
      'icon': Icons.emoji_emotions,
      'color': Colors.orange,
      'features': ['Casual tone', 'Friendly greetings', 'Fun facts'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('AI Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Persona Selection
            Text(
              'Choose AI Persona',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 12),
            
            ...List.generate(_aiPersonas.length, (index) {
              final persona = _aiPersonas[index];
              final isSelected = _selectedAi == persona['name'];
              
              return _AiPersonaCard(
                name: persona['name'],
                description: persona['description'],
                icon: persona['icon'],
                color: persona['color'],
                features: List<String>.from(persona['features']),
                isSelected: isSelected,
                onTap: () => setState(() => _selectedAi = persona['name']),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 300.ms)
                  .slideX(begin: 0.05, end: 0);
            }),

            const SizedBox(height: 24),

            // AI Features
            Text(
              'AI Features',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 300.ms),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.lightbulb, color: AppTheme.accent),
                    title: const Text('Auto Suggestions'),
                    subtitle: const Text('AI will suggest replies while typing'),
                    value: _autoSuggestions,
                    onChanged: (value) => setState(() => _autoSuggestions = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.quickreply, color: AppTheme.info),
                    title: const Text('Smart Replies'),
                    subtitle: const Text('Quick response suggestions'),
                    value: _smartReplies,
                    onChanged: (value) => setState(() => _smartReplies = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.psychology, color: Colors.purple),
                    title: const Text('Sentiment Analysis'),
                    subtitle: const Text('Analyze chat mood and tone'),
                    value: _sentimentAnalysis,
                    onChanged: (value) => setState(() => _sentimentAnalysis = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.translate, color: AppTheme.success),
                    title: const Text('Auto Translate'),
                    subtitle: const Text('Automatically translate messages'),
                    value: _autoTranslate,
                    onChanged: (value) => setState(() => _autoTranslate = value),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Language Preference
            Text(
              'Language Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 300.ms),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.softShadow,
              ),
              child: ListTile(
                leading: const Icon(Icons.language, color: AppTheme.primary),
                title: const Text('Preferred Language'),
                subtitle: Text(_preferredLanguage),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
                onTap: () => _showLanguagePicker(),
              ),
            )
                .animate()
                .fadeIn(delay: 800.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Reset AI
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showResetDialog(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reset AI Settings'),
              ),
            )
                .animate()
                .fadeIn(delay: 900.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    final languages = ['English', 'Spanish', 'French', 'German', 'Arabic', 'Chinese', 'Japanese'];
    
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
              'Select Language',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...languages.map((language) => ListTile(
              title: Text(language),
              trailing: _preferredLanguage == language
                  ? const Icon(Icons.check, color: AppTheme.primary)
                  : null,
              onTap: () {
                setState(() => _preferredLanguage = language);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset AI Settings'),
        content: const Text('This will reset all AI settings to default. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedAi = 'ChatBot Pro';
                _autoSuggestions = true;
                _smartReplies = true;
                _sentimentAnalysis = true;
                _autoTranslate = false;
                _preferredLanguage = 'English';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI settings reset to default')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _AiPersonaCard extends StatelessWidget {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> features;
  final bool isSelected;
  final VoidCallback onTap;

  const _AiPersonaCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.features,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppTheme.surface,
          borderRadius: AppTheme.borderRadiusMedium,
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: features.map((feature) => Chip(
                      label: Text(feature, style: const TextStyle(fontSize: 10)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: color.withOpacity(0.1),
                    )).toList(),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}
