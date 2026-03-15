import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class MediaGalleryScreen extends StatefulWidget {
  final String chatName;

  const MediaGalleryScreen({super.key, required this.chatName});

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Media - ${widget.chatName}'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textLight,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Photos'),
            Tab(text: 'Videos'),
            Tab(text: 'Files'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPhotosTab(),
          _buildVideosTab(),
          _buildFilesTab(),
        ],
      ),
    );
  }

  Widget _buildPhotosTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ScreenSize.isMobile ? 3 : 5,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 20,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('View photo ${index + 1}')),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: [
                Colors.blue.shade100,
                Colors.green.shade100,
                Colors.orange.shade100,
                Colors.purple.shade100,
                Colors.pink.shade100,
              ][index % 5],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.image,
                color: [
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.pink,
                ][index % 5].withOpacity(0.5),
                size: 40,
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 30))
            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
      },
    );
  }

  Widget _buildVideosTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 180,
          decoration: BoxDecoration(
            color: AppTheme.primaryDark,
            borderRadius: AppTheme.borderRadiusMedium,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.play_circle_fill,
                size: 60,
                color: Colors.white.withOpacity(0.8),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Video ${index + 1}.mp4',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      '${(index + 1) * 15}s',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 100))
            .slideX(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildFilesTab() {
    final files = [
      {'name': 'Document.pdf', 'size': '2.5 MB', 'icon': Icons.picture_as_pdf, 'color': Colors.red},
      {'name': 'Spreadsheet.xlsx', 'size': '1.2 MB', 'icon': Icons.table_chart, 'color': Colors.green},
      {'name': 'Presentation.pptx', 'size': '5.8 MB', 'icon': Icons.slideshow, 'color': Colors.orange},
      {'name': 'Report.docx', 'size': '890 KB', 'icon': Icons.description, 'color': Colors.blue},
      {'name': 'Archive.zip', 'size': '15 MB', 'icon': Icons.folder_zip, 'color': Colors.purple},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Open ${file['name']}')),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: AppTheme.borderRadiusMedium,
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (file['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(file['icon'] as IconData, color: file['color'] as Color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file['name'] as String,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        file['size'] as String,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  color: AppTheme.primary,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloading ${file['name']}')),
                    );
                  },
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 100))
            .slideX(begin: 0.05, end: 0);
      },
    );
  }
}
