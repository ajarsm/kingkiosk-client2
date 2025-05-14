class WebItem {
  final String id;
  final String name;
  final String url;
  final String description;

  WebItem({
    required this.id,
    required this.name,
    required this.url,
    this.description = '',
  });
  
  factory WebItem.fromJson(Map<String, dynamic> json) {
    return WebItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'description': description,
    };
  }

  @override
  String toString() => 'WebItem(id: $id, name: $name)';
}