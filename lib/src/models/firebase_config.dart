

import '../utils/secret_image_utils.dart';

/// Firebase配置数据模型
class FirebaseConfig {
  final String version;
  final String lastUpdated;
  final ImageConfig images;
  final SecretConfig secrets;
  final TreasureConfig treasure;

  const FirebaseConfig({
    required this.version,
    required this.lastUpdated,
    required this.images,
    required this.secrets,
    required this.treasure,
  });

  factory FirebaseConfig.fromJson(Map<String, dynamic> json) {
    return FirebaseConfig(
      version: json['version'] ?? '1.0.0',
      lastUpdated: json['lastUpdated'] ?? '',
      images: ImageConfig.fromJson(json['images'] ?? {}),
      secrets: SecretConfig.fromJson(json['secrets'] ?? {}),
      treasure: TreasureConfig.fromJson(json['treasure'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'lastUpdated': lastUpdated,
      'images': images.toJson(),
      'secrets': secrets.toJson(),
      'treasure': treasure.toJson(),
    };
  }
}

/// 图片配置
class ImageConfig {
  final LevelImageConfig levelA;
  final LevelImageConfig levelB;
  final LevelImageConfig levelC;

  const ImageConfig({
    required this.levelA,
    required this.levelB,
    required this.levelC,
  });

  factory ImageConfig.fromJson(Map<String, dynamic> json) {
    return ImageConfig(
      levelA: LevelImageConfig.fromJson(json['levelA'] ?? {}),
      levelB: LevelImageConfig.fromJson(json['levelB'] ?? {}),
      levelC: LevelImageConfig.fromJson(json['levelC'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levelA': levelA.toJson(),
      'levelB': levelB.toJson(),
      'levelC': levelC.toJson(),
    };
  }
}

/// 关卡图片配置
class LevelImageConfig {
  final String baseUrl;
  final String fileNamePattern;
  final String localPathPattern;
  final int totalCount;
  final int requiredCount;
  final List<PriorityGroup> priorityGroups;

  const LevelImageConfig({
    required this.baseUrl,
    required this.fileNamePattern,
    required this.localPathPattern,
    required this.totalCount,
    required this.requiredCount,
    required this.priorityGroups,
  });

  factory LevelImageConfig.fromJson(Map<String, dynamic> json) {
    return LevelImageConfig(
      baseUrl: json['baseUrl'] ?? '',
      fileNamePattern: json['fileNamePattern'] ?? '',
      localPathPattern: json['localPathPattern'] ?? '',
      totalCount: json['totalCount'] ?? 0,
      requiredCount: json['requiredCount'] ?? 0,
      priorityGroups: (json['priorityGroups'] as List<dynamic>?)
          ?.map((e) => PriorityGroup.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'fileNamePattern': fileNamePattern,
      'localPathPattern': localPathPattern,
      'totalCount': totalCount,
      'requiredCount': requiredCount,
      'priorityGroups': priorityGroups.map((e) => e.toJson()).toList(),
    };
  }

  /// 生成所有图片资源
  List<ImageResource> generateImageResources() {
    if (totalCount == 0) return [];
    
    final List<ImageResource> resources = [];
    
    for (int i = 1; i <= totalCount; i++) {
      final group = _getPriorityGroupForIndex(i);
      final url = baseUrl + fileNamePattern.replaceAll('{index}', i.toString());
      final localPath = localPathPattern.replaceAll('{index}', i.toString());
      
      resources.add(ImageResource(
        id: 'level_${_getLevelType()}_$i',
        url: url,
        localPath: localPath,
        size: 1024000, // 默认大小
        checksum: '${_getLevelType()}_$i',
        isRequired: group?.isRequired ?? false,
        priority: group?.priority ?? 1,
      ));
    }
    
    return resources;
  }

  String _getLevelType() {
    if (fileNamePattern.contains('level_a_')) return 'a';
    if (fileNamePattern.contains('level_b_')) return 'b';
    if (fileNamePattern.contains('level_c_')) return 'c';
    return 'unknown';
  }

  PriorityGroup? _getPriorityGroupForIndex(int index) {
    for (final group in priorityGroups) {
      if (index >= group.startIndex && index <= group.endIndex) {
        return group;
      }
    }
    return null;
  }
}

/// 优先级组
class PriorityGroup {
  final int startIndex;
  final int endIndex;
  final int priority;
  final bool isRequired;

  const PriorityGroup({
    required this.startIndex,
    required this.endIndex,
    required this.priority,
    required this.isRequired,
  });

  factory PriorityGroup.fromJson(Map<String, dynamic> json) {
    return PriorityGroup(
      startIndex: json['startIndex'] ?? 1,
      endIndex: json['endIndex'] ?? 1,
      priority: json['priority'] ?? 1,
      isRequired: json['isRequired'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startIndex': startIndex,
      'endIndex': endIndex,
      'priority': priority,
      'isRequired': isRequired,
    };
  }
}

/// 套图配置
class SecretConfig {
  final String baseUrl;
  final List<SecretSet> sets;

  const SecretConfig({
    required this.baseUrl,
    required this.sets,
  });

  factory SecretConfig.fromJson(Map<String, dynamic> json) {
    return SecretConfig(
      baseUrl: json['baseUrl'] ?? '',
      sets: (json['sets'] as List<dynamic>?)
          ?.map((e) => SecretSet.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'sets': sets.map((e) => e.toJson()).toList(),
    };
  }
}

/// 宝藏配置
class TreasureConfig {
  final String baseUrl;
  final String fileNamePattern;
  final String localPathPattern;
  final int totalCount;
  final int priority;

  const TreasureConfig({
    required this.baseUrl,
    required this.fileNamePattern,
    required this.localPathPattern,
    required this.totalCount,
    required this.priority,
  });

  factory TreasureConfig.fromJson(Map<String, dynamic> json) {
    return TreasureConfig(
      baseUrl: json['baseUrl'] ?? '',
      fileNamePattern: json['fileNamePattern'] ?? '',
      localPathPattern: json['localPathPattern'] ?? '',
      totalCount: json['totalCount'] ?? 0,
      priority: json['priority'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'fileNamePattern': fileNamePattern,
      'localPathPattern': localPathPattern,
      'totalCount': totalCount,
      'priority': priority,
    };
  }

  /// 生成宝藏图片资源
  List<ImageResource> generateImageResources() {
    if (totalCount == 0) return [];
    
    final List<ImageResource> resources = [];
    
    for (int i = 1; i <= totalCount; i++) {
      final url = baseUrl + fileNamePattern.replaceAll('{index}', i.toString());
      final localPath = localPathPattern.replaceAll('{index}', i.toString());
      
      resources.add(ImageResource(
        id: 'pass_c_$i',
        url: url,
        localPath: localPath,
        size: 1024000,
        checksum: 'pass_c_$i',
        isRequired: false,
        priority: priority,
      ));
    }
    
    return resources;
  }
}

/// 套图集合
class SecretSet {
  final int setId;
  final String title;
  final int unlockLevel;
  final String fileNamePattern;
  final String localPathPattern;
  final int slotCount;
  final int priority;

  const SecretSet({
    required this.setId,
    required this.title,
    required this.unlockLevel,
    required this.fileNamePattern,
    required this.localPathPattern,
    required this.slotCount,
    required this.priority,
  });

  factory SecretSet.fromJson(Map<String, dynamic> json) {
    return SecretSet(
      setId: json['setId'] ?? 0,
      title: json['title'] ?? '',
      unlockLevel: json['unlockLevel'] ?? 1,
      fileNamePattern: json['fileNamePattern'] ?? '',
      localPathPattern: json['localPathPattern'] ?? '',
      slotCount: json['slotCount'] ?? 0,
      priority: json['priority'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setId': setId,
      'title': title,
      'unlockLevel': unlockLevel,
      'fileNamePattern': fileNamePattern,
      'localPathPattern': localPathPattern,
      'slotCount': slotCount,
      'priority': priority,
    };
  }

  /// 生成套图资源
  List<ImageResource> generateImageResources(String baseUrl) {
    final List<ImageResource> resources = [];
    
    for (int i = 1; i <= slotCount; i++) {
      final typeLetter = SecretImageUtils.typeLetter(i);
      final fileName = fileNamePattern
          .replaceAll('{slot}', i.toString())
          .replaceAll('{setId}', setId.toString())
          .replaceAll('{type}', typeLetter);
      final localPath = localPathPattern
          .replaceAll('{slot}', i.toString())
          .replaceAll('{setId}', setId.toString())
          .replaceAll('{type}', typeLetter);
      final url = baseUrl + fileName;
      
      resources.add(ImageResource(
        id: 'secret_${setId}_$i',
        url: url,
        localPath: localPath,
        size: 1024000,
        checksum: 'secret_${setId}_$i',
        isRequired: false,
        priority: priority,
      ));
    }
    
    return resources;
  }
}

/// 图片资源
class ImageResource {
  final String id;
  final String url;
  final String localPath;
  final int size;
  final String checksum;
  final bool isRequired; // 是否必需（本地保留）
  final int priority; // 下载优先级 1-10

  const ImageResource({
    required this.id,
    required this.url,
    required this.localPath,
    required this.size,
    required this.checksum,
    this.isRequired = false,
    this.priority = 5,
  });

  factory ImageResource.fromJson(Map<String, dynamic> json) {
    return ImageResource(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      localPath: json['localPath'] ?? '',
      size: json['size'] ?? 0,
      checksum: json['checksum'] ?? '',
      isRequired: json['isRequired'] ?? false,
      priority: json['priority'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'localPath': localPath,
      'size': size,
      'checksum': checksum,
      'isRequired': isRequired,
      'priority': priority,
    };
  }
}

/// 下载状态
enum DownloadStatus {
  pending,    // 等待下载
  downloading, // 正在下载
  completed,  // 下载完成
  failed,     // 下载失败
  cached,     // 已缓存
}

/// 下载任务
class DownloadTask {
  final String id;
  final String url;
  final String localPath;
  final int priority;
  final DownloadStatus status;
  final int progress; // 0-100
  final String? error;

  const DownloadTask({
    required this.id,
    required this.url,
    required this.localPath,
    required this.priority,
    required this.status,
    this.progress = 0,
    this.error,
  });

  DownloadTask copyWith({
    String? id,
    String? url,
    String? localPath,
    int? priority,
    DownloadStatus? status,
    int? progress,
    String? error,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}
