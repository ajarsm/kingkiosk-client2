import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/media_item.dart';
import '../data/models/web_item.dart';
import '../data/repositories/content_repository.dart';

class MediaGallery extends StatefulWidget {
  final Function(MediaItem) onMediaSelected;
  final Function(WebItem) onWebSelected;
  
  const MediaGallery({
    Key? key,
    required this.onMediaSelected,
    required this.onWebSelected,
  }) : super(key: key);

  @override
  _MediaGalleryState createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<MediaGallery> with SingleTickerProviderStateMixin {
  final ContentRepository _contentRepository = ContentRepository();
  late TabController _tabController;
  
  List<MediaItem> _mediaItems = [];
  List<WebItem> _webItems = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContent();
  }
  
  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final mediaItems = await _contentRepository.getMediaItems();
      final webItems = await _contentRepository.getWebItems();
      
      setState(() {
        _mediaItems = mediaItems;
        _webItems = webItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Failed to load content: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.movie),
              text: 'Media',
            ),
            Tab(
              icon: Icon(Icons.web),
              text: 'Web',
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMediaList(),
              _buildWebList(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMediaList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_mediaItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_photography, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No media items found'),
            SizedBox(height: 8),
            TextButton(
              onPressed: _loadContent,
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _mediaItems.length,
      itemBuilder: (context, index) {
        final item = _mediaItems[index];
        return ListTile(
          leading: Icon(
            item.isVideo ? Icons.video_file : Icons.audio_file,
            color: item.isVideo ? Colors.blue : Colors.purple,
          ),
          title: Text(item.name),
          subtitle: Text(
            item.description.isEmpty ? item.url : item.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => widget.onMediaSelected(item),
        );
      },
    );
  }
  
  Widget _buildWebList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_webItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.web_asset_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No web items found'),
            SizedBox(height: 8),
            TextButton(
              onPressed: _loadContent,
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _webItems.length,
      itemBuilder: (context, index) {
        final item = _webItems[index];
        return ListTile(
          leading: Icon(Icons.web, color: Colors.green),
          title: Text(item.name),
          subtitle: Text(
            item.description.isEmpty ? item.url : item.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => widget.onWebSelected(item),
        );
      },
    );
  }
}