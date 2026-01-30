enum ImageType { A, B, C }
enum ImageSourceType { general, secret, treasure }

class ImageItem {
  final String id;
  final ImageType type;
  final String src; // path or URL (without base)
  final bool unlocked;
  final ImageSourceType source;
  final bool liked;
  final bool downloaded;
  final int ts;

  const ImageItem({
    required this.id,
    required this.type,
    required this.src,
    this.unlocked = false,
    required this.source,
    this.liked = false,
    this.downloaded = false,
    this.ts = 0,
  });

  ImageItem copyWith({
    String? id,
    ImageType? type,
    String? src,
    bool? unlocked,
    ImageSourceType? source,
    bool? liked,
    bool? downloaded,
    int? ts,
  }) =>
      ImageItem(
        id: id ?? this.id,
        type: type ?? this.type,
        src: src ?? this.src,
        unlocked: unlocked ?? this.unlocked,
        source: source ?? this.source,
        liked: liked ?? this.liked,
        downloaded: downloaded ?? this.downloaded,
        ts: ts ?? this.ts,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'src': src,
        'unlocked': unlocked,
        'source': source.name,
        'liked': liked,
        'downloaded': downloaded,
        'ts': ts,
      };

  static ImageItem fromJson(Map<String, Object?> json) => ImageItem(
        id: json['id'] as String,
        type: ImageType.values.firstWhere((e) => e.name == json['type']),
        src: json['src'] as String,
        unlocked: (json['unlocked'] as bool?) ?? false,
        source: ImageSourceType.values.firstWhere((e) => e.name == json['source']),
        liked: (json['liked'] as bool?) ?? false,
        downloaded: (json['downloaded'] as bool?) ?? false,
        ts: (json['ts'] as int?) ?? 0,
      );
}

