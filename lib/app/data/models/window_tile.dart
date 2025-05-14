import 'package:flutter/material.dart';

enum TileType {
  webView,
  media,
  audio,
}

class WindowTile {
  final String id;
  final String name;
  final TileType type;
  final String url;
  final Offset position;
  final Size size;

  WindowTile({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.position,
    required this.size,
  });

  WindowTile copyWith({
    String? id,
    String? name,
    TileType? type,
    String? url,
    Offset? position,
    Size? size,
  }) {
    return WindowTile(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      position: position ?? this.position,
      size: size ?? this.size,
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