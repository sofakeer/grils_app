import 'image_item.dart';

enum PhotoSetSlotState { locked, rvNeeded, playable, acquired }

class PhotoSetSlot {
  final int index; // 1-based
  final int needRv;
  final int rvProgress;
  final PhotoSetSlotState state;
  final String assetPath;
  final ImageType type;
  final String? imageId; // 新增：图片ID，用于网络加载

  const PhotoSetSlot({
    required this.index,
    required this.needRv,
    required this.rvProgress,
    required this.state,
    required this.assetPath,
    required this.type,
    this.imageId,
  });

  bool get requiresVideo => needRv > 0;

  int get remainingRv => (needRv - rvProgress).clamp(0, needRv);

  PhotoSetSlot copyWith({
    int? needRv,
    int? rvProgress,
    PhotoSetSlotState? state,
    String? assetPath,
    ImageType? type,
    String? imageId,
  }) =>
      PhotoSetSlot(
        index: index,
        needRv: needRv ?? this.needRv,
        rvProgress: rvProgress ?? this.rvProgress,
        state: state ?? this.state,
        assetPath: assetPath ?? this.assetPath,
        type: type ?? this.type,
        imageId: imageId ?? this.imageId,
      );

  Map<String, Object?> toJson() => {
        'index': index,
        'needRv': needRv,
        'rvProgress': rvProgress,
        'state': state.name,
        'assetPath': assetPath,
        'type': type.name,
        'imageId': imageId,
      };

  static PhotoSetSlot fromJson(Map<String, Object?> json) => PhotoSetSlot(
        index: json['index'] as int,
        needRv: json['needRv'] as int,
        rvProgress: (json['rvProgress'] as int?) ?? 0,
        state: PhotoSetSlotState.values
            .firstWhere((e) => e.name == json['state'], orElse: () => PhotoSetSlotState.locked),
        assetPath: json['assetPath'] as String,
        type: ImageType.values
            .firstWhere((e) => e.name == json['type'], orElse: () => ImageType.B),
        imageId: json['imageId'] as String?,
      );
}

class PhotoSetProgress {
  final int setId;
  final String title;
  final int unlockLevel;
  final List<PhotoSetSlot> slots;

  const PhotoSetProgress({
    required this.setId,
    required this.title,
    required this.unlockLevel,
    required this.slots,
  });

  String get coverAsset => slots.first.assetPath;
  
  /// 获取封面图片ID（用于网络加载）
  String? get coverImageId => slots.first.imageId;

  bool get isComplete => slots.every((slot) => slot.state == PhotoSetSlotState.acquired);

  int get acquiredCount =>
      slots.where((slot) => slot.state == PhotoSetSlotState.acquired).length;

  PhotoSetProgress copyWith({
    List<PhotoSetSlot>? slots,
  }) =>
      PhotoSetProgress(
        setId: setId,
        title: title,
        unlockLevel: unlockLevel,
        slots: slots ?? this.slots,
      );

  Map<String, Object?> toJson() => {
        'setId': setId,
        'title': title,
        'unlockLevel': unlockLevel,
        'slots': slots.map((slot) => slot.toJson()).toList(),
      };

  static PhotoSetProgress fromJson(Map<String, Object?> json) => PhotoSetProgress(
        setId: json['setId'] as int,
        title: json['title'] as String,
        unlockLevel: json['unlockLevel'] as int,
        slots: (json['slots'] as List)
            .map((e) => PhotoSetSlot.fromJson((e as Map).cast<String, Object?>()))
            .toList(),
      );
}

