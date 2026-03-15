import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  String _selectedType = 'text';
  final TextEditingController _textController = TextEditingController();
  Color _backgroundColor = AppTheme.primary;
  String _selectedFont = 'Poppins';

  final List<Color> _colors = [
    AppTheme.primary,
    AppTheme.secondary,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.red,
    Colors.green,
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Story posted!'),
                  backgroundColor: AppTheme.success,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Post', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Story Type Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TypeButton(
                  icon: Icons.text_fields,
                  label: 'Text',
                  isSelected: _selectedType == 'text',
                  onTap: () => setState(() => _selectedType = 'text'),
                ),
                const SizedBox(width: 16),
                _TypeButton(
                  icon: Icons.photo,
                  label: 'Photo',
                  isSelected: _selectedType == 'photo',
                  onTap: () => setState(() => _selectedType = 'photo'),
                ),
                const SizedBox(width: 16),
                _TypeButton(
                  icon: Icons.videocam,
                  label: 'Video',
                  isSelected: _selectedType == 'video',
                  onTap: () => setState(() => _selectedType = 'video'),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms),

          const SizedBox(height: 20),

          // Story Preview
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _selectedType == 'text'
                  ? _buildTextStory()
                  : _selectedType == 'photo'
                      ? _buildPhotoStory()
                      : _buildVideoStory(),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
          ),

          const SizedBox(height: 20),

          // Options Bar
          if (_selectedType == 'text')
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Color Picker
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colors.length,
                      itemBuilder: (context, index) {
                        final color = _colors[index];
                        final isSelected = _backgroundColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _backgroundColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Font Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['Poppins', 'Serif', 'Mono'].map((font) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFont = font),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _selectedFont == font
                                ? Colors.white.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            font,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTextStory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: TextField(
          controller: _textController,
          maxLines: null,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontFamily: _selectedFont == 'Mono' ? 'Courier' : null,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            hintText: 'Type your story...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoStory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add_photo_alternate, color: Colors.white, size: 40),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Open photo picker')),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap to add photo',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoStory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.videocam, color: Colors.white, size: 40),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Open video recorder')),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap to record video',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
