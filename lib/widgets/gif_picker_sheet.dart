import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/gif_service.dart';
import '../theme/app_theme.dart';

/// Telegram-style animated GIF picker bottom sheet.
/// Call [GifPickerSheet.show] to display it.
///
/// Returns the selected [GifResult], or null if dismissed.
class GifPickerSheet extends StatefulWidget {
  const GifPickerSheet({super.key});

  static Future<GifResult?> show(BuildContext context) {
    return showModalBottomSheet<GifResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GifPickerSheet(),
    );
  }

  @override
  State<GifPickerSheet> createState() => _GifPickerSheetState();
}

class _GifPickerSheetState extends State<GifPickerSheet> {
  final _gifService = GifService();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<GifResult> _gifs = [];
  bool _loading = true;
  bool _hasError = false;
  String _errorMsg = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _load(query: _searchController.text.trim());
    });
  }

  Future<void> _load({String query = ''}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
      _errorMsg = '';
    });
    try {
      final results = query.isEmpty
          ? await _gifService.fetchTrending()
          : await _gifService.search(query);
      if (!mounted) return;
      setState(() {
        _gifs = results;
        _loading = false;
        _hasError = results.isEmpty;
        _errorMsg = results.isEmpty
            ? (query.isNotEmpty
                ? 'No GIFs found for "$query"'
                : 'Could not load GIFs.\nCheck your internet connection.')
            : '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMsg = 'Failed to load GIFs.\nCheck your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, sheetScroll) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            // ── Handle ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'GIF',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _searchController.text.isEmpty ? 'Trending' : 'Results',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Search bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.search_rounded,
                          color: Colors.white54, size: 20),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search GIFs...',
                          hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (q) => _load(query: q.trim()),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: Colors.white38, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // ── Grid ────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.secondary, strokeWidth: 2))
                  : _hasError
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.gif_box_outlined,
                                  color: Colors.white24, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _errorMsg,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: () => _load(
                                    query: _searchController.text.trim()),
                                icon: const Icon(Icons.refresh_rounded,
                                    color: Colors.white54),
                                label: const Text('Retry',
                                    style:
                                        TextStyle(color: Colors.white54)),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          controller: sheetScroll,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1.5,
                          ),
                          itemCount: _gifs.length,
                          itemBuilder: (_, i) => _GifCell(
                            gif: _gifs[i],
                            onTap: () => Navigator.pop(context, _gifs[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Individual GIF cell ───────────────────────────────────────────────────────
class _GifCell extends StatelessWidget {
  final GifResult gif;
  final VoidCallback onTap;

  const _GifCell({required this.gif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Animated GIF thumbnail
            CachedNetworkImage(
              imageUrl: gif.previewUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Colors.white.withOpacity(0.05),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: Colors.white24),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.white.withOpacity(0.05),
                child: const Icon(Icons.broken_image_outlined,
                    color: Colors.white24),
              ),
            ),

            // Dark gradient overlay at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 30,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // "GIF" badge top-left
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'GIF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
