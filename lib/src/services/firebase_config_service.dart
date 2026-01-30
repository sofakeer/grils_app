import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../models/firebase_config.dart';
import '../providers/user_type_provider.dart';

/// Firebase配置服务
class FirebaseConfigService {
  static const String _configKey = 'image_config';
  static const Duration _fetchTimeout = Duration(seconds: 5);
  static const Duration _minimumFetchInterval = Duration(seconds: 0);

  /// 获取Firebase Remote Config实例
  FirebaseRemoteConfig get _remoteConfig => FirebaseRemoteConfig.instance;

  /// 初始化Remote Config设置
  Future<void> _initializeRemoteConfig() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: _fetchTimeout,
      minimumFetchInterval: _minimumFetchInterval,
    ));
  }

  /// 获取用户类型对应的配置键名
  String _getConfigKey(UserType userType) {
    switch (userType) {
      case UserType.natural:
        return '${_configKey}_nature';
      case UserType.paid:
        return '${_configKey}_paid';
    }
  }

  /// 从Firebase Remote Config获取配置
  Future<FirebaseConfig?> fetchConfig(UserType userType) async {
    try {
      print('[FirebaseConfigService] 🌐 开始获取远程配置...');
      
      // 初始化Remote Config
      await _initializeRemoteConfig();
      
      // 获取并激活配置
      await _remoteConfig.fetchAndActivate().timeout(
        _fetchTimeout,
        onTimeout: () => throw TimeoutException('Firebase fetch timeout'),
      );

      // 根据用户类型获取对应的配置
      final String configKey = _getConfigKey(userType);
      final String configJson = _remoteConfig.getString(configKey);
      
      print('[FirebaseConfigService] 📦 远程配置键: $configKey');
      print('[FirebaseConfigService] 📦 远程配置长度: ${configJson.length}');
      
      if (configJson.isEmpty) {
        print('[FirebaseConfigService] ⚠️ 远程配置为空，使用本地默认配置');
        return _getDefaultConfig(userType);
      }

      // 解析JSON配置
      final Map<String, dynamic> json = jsonDecode(configJson);
      final config = FirebaseConfig.fromJson(json);
      
      print('[FirebaseConfigService] ✅ 远程配置解析成功: version=${config.version}');
      return config;
      
    } catch (e) {
      print('[FirebaseConfigService] ❌ 获取远程配置失败: $e');
      print('[FirebaseConfigService] 🔄 使用本地默认配置');
      return _getDefaultConfig(userType);
    }
  }

  /// 获取默认配置（本地配置）
  FirebaseConfig? _getDefaultConfig(UserType userType) {
    try {
      return _createDefaultConfig(userType);
    } catch (e) {
      print('[FirebaseConfigService] ❌ 加载默认配置失败: $e');
      return null;
    }
  }

  /// 获取默认配置（公共方法）
  FirebaseConfig getDefaultConfig(UserType userType) {
    try {
      return _createDefaultConfig(userType);
    } catch (e) {
      print('[FirebaseConfigService] ❌ 加载默认配置失败: $e');
      // 返回一个基本的默认配置，避免递归调用
      return _createBasicDefaultConfig(userType);
    }
  }

  /// 创建默认配置
  FirebaseConfig _createDefaultConfig(UserType userType) {
    if (userType == UserType.natural) {
      // 自然量用户默认配置
      return FirebaseConfig(
        version: "1.0.0",
        lastUpdated: DateTime.now().toIso8601String(),
        images: ImageConfig(
          levelA: LevelImageConfig(
            baseUrl: "https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/",
            fileNamePattern: "level_a_{index}.png",
            localPathPattern: "assets/pic_level/a/level_a_{index}.png",
            totalCount: 200,
            requiredCount: 5,
            priorityGroups: [
              PriorityGroup(startIndex: 1, endIndex: 5, priority: 10, isRequired: true),
              PriorityGroup(startIndex: 6, endIndex: 20, priority: 8, isRequired: false),
              PriorityGroup(startIndex: 21, endIndex: 50, priority: 7, isRequired: false),
              PriorityGroup(startIndex: 51, endIndex: 100, priority: 6, isRequired: false),
              PriorityGroup(startIndex: 101, endIndex: 150, priority: 5, isRequired: false),
              PriorityGroup(startIndex: 151, endIndex: 200, priority: 4, isRequired: false),
            ],
          ),
          levelB: LevelImageConfig(
            baseUrl: "",
            fileNamePattern: "",
            localPathPattern: "",
            totalCount: 0,
            requiredCount: 0,
            priorityGroups: [],
          ),
          levelC: LevelImageConfig(
            baseUrl: "",
            fileNamePattern: "",
            localPathPattern: "",
            totalCount: 0,
            requiredCount: 0,
            priorityGroups: [],
          ),
        ),
        secrets: SecretConfig(baseUrl: "", sets: []),
        treasure: TreasureConfig(
          baseUrl: "",
          fileNamePattern: "",
          localPathPattern: "",
          totalCount: 0,
          priority: 5,
        ),
      );
    } else {
      // 买量用户默认配置
      return FirebaseConfig(
        version: "1.0.0",
        lastUpdated: DateTime.now().toIso8601String(),
        images: ImageConfig(
          levelA: LevelImageConfig(
            baseUrl: "",
            fileNamePattern: "",
            localPathPattern: "",
            totalCount: 0,
            requiredCount: 0,
            priorityGroups: [],
          ),
          levelB: LevelImageConfig(
            baseUrl: "https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/",
            fileNamePattern: "level_b_{index}.png",
            localPathPattern: "assets/pic_level/b/level_b_{index}.png",
            totalCount: 200,
            requiredCount: 5,
            priorityGroups: [
              PriorityGroup(startIndex: 1, endIndex: 5, priority: 10, isRequired: true),
              PriorityGroup(startIndex: 6, endIndex: 20, priority: 8, isRequired: false),
              PriorityGroup(startIndex: 21, endIndex: 50, priority: 7, isRequired: false),
              PriorityGroup(startIndex: 51, endIndex: 100, priority: 6, isRequired: false),
              PriorityGroup(startIndex: 101, endIndex: 150, priority: 5, isRequired: false),
              PriorityGroup(startIndex: 151, endIndex: 200, priority: 4, isRequired: false),
            ],
          ),
          levelC: LevelImageConfig(
            baseUrl: "https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/",
            fileNamePattern: "level_c_{index}.png",
            localPathPattern: "assets/pic_level/c/level_c_{index}.png",
            totalCount: 200,
            requiredCount: 5,
            priorityGroups: [
              PriorityGroup(startIndex: 1, endIndex: 5, priority: 10, isRequired: true),
              PriorityGroup(startIndex: 6, endIndex: 20, priority: 8, isRequired: false),
              PriorityGroup(startIndex: 21, endIndex: 50, priority: 7, isRequired: false),
              PriorityGroup(startIndex: 51, endIndex: 100, priority: 6, isRequired: false),
              PriorityGroup(startIndex: 101, endIndex: 150, priority: 5, isRequired: false),
              PriorityGroup(startIndex: 151, endIndex: 200, priority: 4, isRequired: false),
            ],
          ),
        ),
        secrets: SecretConfig(
          baseUrl: "https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/",
          sets: [
            SecretSet(
              setId: 1,
              title: "套图1",
              unlockLevel: 3,
              fileNamePattern: "secret_{setId}_{type}_{slot}.png",
              localPathPattern: "assets/pic_secret/a/secret_{setId}_{type}_{slot}.png",
              slotCount: 9,
              priority: 7,
            ),
            SecretSet(
              setId: 2,
              title: "套图2",
              unlockLevel: 10,
              fileNamePattern: "secret_{setId}_{type}_{slot}.png",
              localPathPattern: "assets/pic_secret/b/secret_{setId}_{type}_{slot}.png",
              slotCount: 9,
              priority: 6,
            ),
            SecretSet(
              setId: 3,
              title: "套图3",
              unlockLevel: 20,
              fileNamePattern: "secret_{setId}_{type}_{slot}.png",
              localPathPattern: "assets/pic_secret/c/secret_{setId}_{type}_{slot}.png",
              slotCount: 9,
              priority: 5,
            ),
            SecretSet(
              setId: 4,
              title: "套图4",
              unlockLevel: 50,
              fileNamePattern: "secret_{setId}_{type}_{slot}.png",
              localPathPattern: "assets/pic_secret/d/secret_{setId}_{type}_{slot}.png",
              slotCount: 9,
              priority: 4,
            ),
            SecretSet(
              setId: 5,
              title: "套图5",
              unlockLevel: 70,
              fileNamePattern: "secret_{setId}_{type}_{slot}.png",
              localPathPattern: "assets/pic_secret/e/secret_{setId}_{type}_{slot}.png",
              slotCount: 9,
              priority: 3,
            ),
            SecretSet(
              setId: 6,
              title: "套图6",
              unlockLevel: 90,
              fileNamePattern: "secret_{setId}_{type}_{slot}.png",
              localPathPattern: "assets/pic_secret/f/secret_{setId}_{type}_{slot}.png",
              slotCount: 9,
              priority: 2,
            ),
            SecretSet(
              setId: 7,
              title: "套图7",
              unlockLevel: 110,
              fileNamePattern: "secret_{setId}_{type}_{slot}.png",
              localPathPattern: "assets/pic_secret/j/secret_{setId}_{type}_{slot}.png",
              slotCount: 9,
              priority: 1,
            ),
            SecretSet(
              setId: 8,
              title: "套图8",
              unlockLevel: 130,
              fileNamePattern: "secret_{setId}_{type}_{slot}.png",
              localPathPattern: "assets/pic_secret/h/secret_{setId}_{type}_{slot}.png",
              slotCount: 9,
              priority: 1,
            ),
            SecretSet(
              setId: 9,
              title: "套图9",
              unlockLevel: 150,
              fileNamePattern: "secret_{setId}_{type}_{slot}.png",
              localPathPattern: "assets/pic_secret/i/secret_{setId}_{type}_{slot}.png",
              slotCount: 9,
              priority: 1,
            ),
          ],
        ),
        treasure: TreasureConfig(
          baseUrl: "https://mindwell.s3.ap-northeast-1.amazonaws.com/girls/",
          fileNamePattern: "pass_c_{index}.png",
          localPathPattern: "assets/pic_pass/c/pass_c_{index}.png",
          totalCount: 30,
          priority: 5,
        ),
      );
    }
  }

  /// 创建基本的默认配置（异常情况下的回退配置）
  FirebaseConfig _createBasicDefaultConfig(UserType userType) {
    return FirebaseConfig(
      version: "1.0.0",
      lastUpdated: DateTime.now().toIso8601String(),
      images: ImageConfig(
        levelA: LevelImageConfig(
          baseUrl: "",
          fileNamePattern: "",
          localPathPattern: "",
          totalCount: 0,
          requiredCount: 0,
          priorityGroups: [],
        ),
        levelB: LevelImageConfig(
          baseUrl: "",
          fileNamePattern: "",
          localPathPattern: "",
          totalCount: 0,
          requiredCount: 0,
          priorityGroups: [],
        ),
        levelC: LevelImageConfig(
          baseUrl: "",
          fileNamePattern: "",
          localPathPattern: "",
          totalCount: 0,
          requiredCount: 0,
          priorityGroups: [],
        ),
      ),
      secrets: SecretConfig(baseUrl: "", sets: []),
      treasure: TreasureConfig(
        baseUrl: "",
        fileNamePattern: "",
        localPathPattern: "",
        totalCount: 0,
        priority: 5,
      ),
    );
  }

  /// 检查配置版本是否需要更新
  Future<bool> shouldUpdateConfig(UserType userType, String currentVersion) async {
    try {
      final config = await fetchConfig(userType);
      if (config == null) return false;
      
      return config.version != currentVersion;
    } catch (e) {
      print('[FirebaseConfigService] 版本检查异常: $e');
      return false;
    }
  }

  /// 获取指定关卡类型的图片总数（与四选一弹窗 bTotal/cTotal 规则一致，含上限）
  int getTotalCountForLevelType(String levelType, FirebaseConfig config) {
    switch (levelType) {
      case 'a':
        const int maxACount = 160;
        final countA = config.images.levelA.totalCount > 0 ? config.images.levelA.totalCount : 10;
        return countA > maxACount ? maxACount : countA;
      case 'b':
        const int maxBCount = 200;
        final countB = config.images.levelB.totalCount > 0 ? config.images.levelB.totalCount : 200;
        return countB > maxBCount ? maxBCount : countB;
      case 'c':
        const int maxCCount = 160;
        final countC = config.images.levelC.totalCount > 0 ? config.images.levelC.totalCount : 10;
        return countC > maxCCount ? maxCCount : countC;
      default:
        return 10;
    }
  }

  /// 获取所有图片资源列表
  List<ImageResource> getAllImageResources(FirebaseConfig config) {
    final List<ImageResource> resources = [];
    
    // 添加关卡图片
    resources.addAll(config.images.levelA.generateImageResources());
    resources.addAll(config.images.levelB.generateImageResources());
    resources.addAll(config.images.levelC.generateImageResources());
    
    // 添加套图图片
    for (final set in config.secrets.sets) {
      resources.addAll(set.generateImageResources(config.secrets.baseUrl));
    }
    
    // 添加宝藏图片
    resources.addAll(config.treasure.generateImageResources());
    
    return resources;
  }

  /// 获取必需图片资源（本地保留）
  List<ImageResource> getRequiredImageResources(FirebaseConfig config) {
    return getAllImageResources(config)
        .where((resource) => resource.isRequired)
        .toList();
  }

  /// 获取按优先级排序的下载任务
  List<ImageResource> getDownloadTasks(FirebaseConfig config) {
    return getAllImageResources(config)
        .where((resource) => !resource.isRequired)
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }
}

/// Firebase配置服务Provider
final firebaseConfigServiceProvider = Provider<FirebaseConfigService>((ref) {
  return FirebaseConfigService();
});

/// 当前Firebase配置Provider
final firebaseConfigProvider = StateNotifierProvider<FirebaseConfigNotifier, AsyncValue<FirebaseConfig?>>((ref) {
  return FirebaseConfigNotifier(ref);
});

class FirebaseConfigNotifier extends StateNotifier<AsyncValue<FirebaseConfig?>> {
  final Ref _ref;
  FirebaseConfigService? _service;

  FirebaseConfigNotifier(this._ref) : super(const AsyncValue.loading()) {
    _service = _ref.read(firebaseConfigServiceProvider);
    _loadConfig();
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    try {
      state = const AsyncValue.loading();
      
      final userType = _ref.read(userTypeProvider);
      final config = await _service!.fetchConfig(userType);
      
      if (config != null) {
        state = AsyncValue.data(config);
        print('[FirebaseConfig] 配置加载成功: ${config.version}');
      } else {
        state = AsyncValue.error('配置加载失败', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      print('[FirebaseConfig] 配置加载异常: $e');
    }
  }

  /// 刷新配置
  Future<void> refresh() async {
    await _loadConfig();
  }

  /// 检查更新
  Future<bool> checkForUpdate() async {
    try {
      final currentConfig = state.valueOrNull;
      if (currentConfig == null) return false;
      
      final userType = _ref.read(userTypeProvider);
      return await _service!.shouldUpdateConfig(userType, currentConfig.version);
    } catch (e) {
      print('[FirebaseConfig] 更新检查异常: $e');
      return false;
    }
  }
}
