import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/remote_config/remote_config_service.dart';
import '../services/storage/prefs_service.dart';
import '../core/locator.dart';

/// 用户类型枚举
enum UserType {
  natural,   // 自然用户 - 直接进入下一关
  paid,      // 买量用户 - 显示3选1弹窗
}

/// 用户类型管理器
class UserTypeNotifier extends StateNotifier<UserType> {
  static const _prefsKey = 'user_type';
  
  UserTypeNotifier() : super(_getInitialUserType()) {
    print('[UserType] 初始化用户类型: ${state.name}');
  }
  
  /// 从持久化存储或配置读取初始用户类型
  static UserType _getInitialUserType() {
    try {
      final prefs = ServiceLocator.instance.get<PrefsService>();
      
      // 优先从持久化存储读取（用户手动设置的）
      final savedType = prefs.getString(_prefsKey);
      if (savedType != null) {
        final type = savedType == 'paid' ? UserType.paid : UserType.natural;
        print('[UserType] 从存储读取: ${type.name}');
        return type;
      }
      
      // 否则从配置读取默认值
      final rc = ServiceLocator.instance.get<RemoteConfigService>();
      final isPaid = rc.getBool('user.is_paid_user', defaultValue: true);
      final type = isPaid ? UserType.paid : UserType.natural;
      print('[UserType] 从配置读取: ${type.name}');
      return type;
    } catch (e) {
      print('[UserType] 读取失败，使用默认值: paid, error: $e');
      return UserType.paid; // 默认买量用户
    }
  }

  /// 设置用户类型（持久化）
  Future<void> setUserType(UserType userType) async {
    state = userType;
    try {
      final prefs = ServiceLocator.instance.get<PrefsService>();
      await prefs.setString(_prefsKey, userType.name);
      print('[UserType] 已保存用户类型: ${userType.name}');
    } catch (e) {
      print('[UserType] 保存失败: $e');
    }
  }

  /// 切换用户类型（用于测试，持久化）
  Future<void> toggleUserType() async {
    final newType = state == UserType.natural ? UserType.paid : UserType.natural;
    
    // ✅ 先保存新的用户类型
    await setUserType(newType);
    
    // ✅ 然后清空所有数据
    await _clearAllUserData();
    
    print('[UserType] 已切换用户类型并清空所有数据，准备重启 app');
    
    // 注意：实际重启 app 的逻辑需要在调用方（app.dart）中处理
  }
  
  /// 清空所有用户数据（保留用户类型）
  Future<void> _clearAllUserData() async {
    final prefs = ServiceLocator.instance.get<PrefsService>();
    
    print('[UserType] 开始清空所有用户数据...');
    
    try {
      // 1. 清空用户进度（金币、道具等）
      await prefs.remove('user_progress');
      print('[UserType] ✓ 已清空用户进度');
      
      // 2. 重置关卡到第一关
      await prefs.setInt('current_level', 1);
      await prefs.remove('selected_character_id');
      await prefs.remove('current_level_type');
      await prefs.remove('current_level_index');
      await prefs.remove('current_level_image_path');
      print('[UserType] ✓ 已重置关卡');
      
      // 3. 清空宝藏状态
      await prefs.remove('treasure_cards_v2');
      print('[UserType] ✓ 已清空宝藏状态');
      
      // 4. 清空签到状态
      await prefs.remove('signin_last_date');
      await prefs.remove('signin_first_date');
      await prefs.remove('signin_index');
      await prefs.remove('signin_total_days');
      await prefs.remove('signin_cumulative_claimed');
      await prefs.remove('signin_popup_shown');
      print('[UserType] ✓ 已清空签到状态');
      
      // 5. 清空相册数据
      await prefs.remove('unlocked_images_v2');
      await prefs.remove('liked_images');
      print('[UserType] ✓ 已清空相册数据');
      
      // 6. 清空旋转抽奖状态
      await prefs.remove('spin_used_count');
      await prefs.remove('spin_last_date');
      print('[UserType] ✓ 已清空旋转抽奖状态');
      
      // 7. 清空游戏道具库存
      final itemTypes = ['undo', 'clear', 'hint', 'bottle', 'reminder', 'pipe'];
      for (final itemType in itemTypes) {
        await prefs.remove('item_${itemType}_count');
        await prefs.remove('item_${itemType}_used');
        await prefs.remove('item_${itemType}_last_used');
      }
      print('[UserType] ✓ 已清空游戏道具库存');
      
      // 8. 清空背景图片
      await prefs.remove('custom_background_image');
      await prefs.remove('last_unlocked_background');
      await prefs.remove('default_background_image');
      await prefs.remove('background_sequence_index');
      print('[UserType] ✓ 已清空背景图片');
      
      // 9. 清空图片下载缓存
      await prefs.remove('image_manifest');
      // 清空图片缓存目录的物理文件（需要在调用方通过 service 清理）
      print('[UserType] ✓ 已清空图片下载缓存（注意：需要调用 clearCache() 清理物理文件）');
      
      // 10. 清空 Firebase 配置缓存
      await prefs.remove('firebase_config');
      await prefs.remove('firebase_config_updated_at');
      print('[UserType] ✓ 已清空 Firebase 配置缓存');
      
      // 11. 清空远程配置缓存
      await prefs.remove('remote_config');
      print('[UserType] ✓ 已清空远程配置缓存');
      
      print('[UserType] 所有用户数据和缓存已清空！');
    } catch (e) {
      print('[UserType] ❌ 清空数据失败: $e');
    }
  }

  /// 检查是否为买量用户
  bool isPaidUser() {
    return state == UserType.paid;
  }

  /// 检查是否为自然用户
  bool isNaturalUser() {
    return state == UserType.natural;
  }
}

/// 用户类型Provider
final userTypeProvider = StateNotifierProvider<UserTypeNotifier, UserType>((ref) {
  return UserTypeNotifier();
});

/// 便捷的扩展方法
extension UserTypeRef on WidgetRef {
  /// 获取用户类型
  UserType get currentUserType => read(userTypeProvider);

  /// 检查是否为买量用户
  bool get isPaidUser => read(userTypeProvider.notifier).isPaidUser();

  /// 检查是否为自然用户
  bool get isNaturalUser => read(userTypeProvider.notifier).isNaturalUser();
}