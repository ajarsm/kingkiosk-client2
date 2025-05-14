import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/media_item.dart';
import '../models/web_item.dart';
import '../../core/utils/app_constants.dart';

/// Repository for fetching content items
class ContentRepository {
  // Cache the loaded items
  List<MediaItem>? _cachedMediaItems;
  List<WebItem>? _cachedWebItems;
  
  /// Fetches media items (video, audio)
  Future<List<MediaItem>> getMediaItems() async {
    // Return cached items if available
    if (_cachedMediaItems != null) {
      return _cachedMediaItems!;
    }
    
    try {
      // First try to load from assets
      final jsonString = await rootBundle.loadString('assets/data/sample_data.json');
      final jsonData = json.decode(jsonString);
      
      final List<MediaItem> items = (jsonData['mediaItems'] as List)
          .map((item) => MediaItem.fromJson(item))
          .toList();
      
      _cachedMediaItems = items;
      return items;
    } catch (e) {
      // If loading from assets fails, use the fallback data
      print('Error loading media items from assets: $e');
      print('Using fallback media items');
      
      final List<MediaItem> fallbackItems = AppConstants.sampleMediaItems
          .asMap()
          .entries
          .map((entry) => MediaItem(
                id: entry.key.toString(),
                name: entry.value['name']!,
                url: entry.value['url']!,
                type: entry.value['type']!,
              ))
          .toList();
      
      _cachedMediaItems = fallbackItems;
      return fallbackItems;
    }
  }
  
  /// Fetches web URLs for displaying in WebView
  Future<List<WebItem>> getWebItems() async {
    // Return cached items if available
    if (_cachedWebItems != null) {
      return _cachedWebItems!;
    }
    
    try {
      // First try to load from assets
      final jsonString = await rootBundle.loadString('assets/data/sample_data.json');
      final jsonData = json.decode(jsonString);
      
      final List<WebItem> items = (jsonData['webItems'] as List)
          .map((item) => WebItem.fromJson(item))
          .toList();
      
      _cachedWebItems = items;
      return items;
    } catch (e) {
      // If loading from assets fails, use the fallback data
      print('Error loading web items from assets: $e');
      print('Using fallback web items');
      
      final List<WebItem> fallbackItems = AppConstants.sampleWebItems
          .asMap()
          .entries
          .map((entry) => WebItem(
                id: entry.key.toString(),
                name: entry.value['name']!,
                url: entry.value['url']!,
              ))
          .toList();
      
      _cachedWebItems = fallbackItems;
      return fallbackItems;
    }
  }
  
  /// Refresh content from source (clear cache and reload)
  Future<void> refreshContent() async {
    _cachedMediaItems = null;
    _cachedWebItems = null;
    
    // Pre-load items for next use
    await Future.wait([
      getMediaItems(),
      getWebItems(),
    ]);
  }
}