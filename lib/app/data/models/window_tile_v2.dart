import 'package:flutter/material.dart';

/// The type of content in a window tile
enum TileType {
  webView,
  media,
  audio,
  audioVisualizer, // Added audio visualizer type
  image, // Added image type
  youtube, // Added YouTube player type
  pdf, // Added PDF viewer type
  clock, // Added clock widget type
  alarmo, // Added Alarmo dialpad type
  weather, // Added weather widget type
  calendar, // Added calendar widget type
}

/// Represents a window tile in the tiling window manager
class WindowTile {
  final String id;
  final String name;
  final TileType type;
  final String url; // Primary URL (kept for backward compatibility)
  final List<String> imageUrls; // List of image URLs for carousel
  final bool loop; // Whether to loop media playback
  bool isMaximized; // Whether the tile is maximized

  // These properties need to be mutable for tiling layout
  Offset position;
  Size size;

  // Additional metadata for special cases (YouTube video ID, etc.)
  final Map<String, dynamic>? metadata;

  WindowTile({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    this.imageUrls = const [], // Default to empty list
    required this.position,
    required this.size,
    this.loop = false,
    this.isMaximized = false,
    this.metadata,
  });

  /// Creates a copy of this WindowTile with the given fields replaced
  WindowTile copyWith({
    String? id,
    String? name,
    TileType? type,
    String? url,
    List<String>? imageUrls,
    Offset? position,
    Size? size,
    bool? loop,
    bool? isMaximized,
    Map<String, dynamic>? metadata,
  }) {
    return WindowTile(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      imageUrls: imageUrls ?? this.imageUrls,
      position: position ?? this.position,
      size: size ?? this.size,
      loop: loop ?? this.loop,
      isMaximized: isMaximized ?? this.isMaximized,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WindowTile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
