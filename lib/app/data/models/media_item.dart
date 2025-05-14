class MediaItem {
  final String id;
  final String name;
  final String url;
  final String type;
  final String description;

  MediaItem({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    this.description = '',
  });

  bool get isVideo => type == 'video';
  bool get isAudio => type == 'audio';
  
  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'description': description,
    };
  }

  @override
  String toString() => 'MediaItem(id: $id, name: $name, type: $type)';
}