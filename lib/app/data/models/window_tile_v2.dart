import 'package:flutter/material.dart';

/// The type of content in a window tile
enum TileType {
  webView,
  media,
  audio,
  image,  // Added image type
}

/// Represents a window tile in the tiling window manager
class WindowTile {
  final String id;
  final String name;
  final TileType type;
  final String url;
  final bool loop; // Whether to loop media playback
  bool isMaximized; // Whether the tile is maximized
  
  // These properties need to be mutable for tiling layout
  Offset position;
  Size size;
  
  WindowTile({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.position,
    required this.size,
    this.loop = false,
    this.isMaximized = false,
  });
  
  /// Creates a copy of this WindowTile with the given fields replaced
  WindowTile copyWith({
    String? id,
    String? name,
    TileType? type,
    String? url,
    Offset? position,
    Size? size,
    bool? loop,
    bool? isMaximized,
  }) {
    return WindowTile(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      position: position ?? this.position,
      size: size ?? this.size,
      loop: loop ?? this.loop,
      isMaximized: isMaximized ?? this.isMaximized,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WindowTile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}