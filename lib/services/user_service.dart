import 'package:flutter/foundation.dart';
import 'package:grils_app/models/user_model.dart';

/// 用户服务类
/// 
/// 提供全局的用户模型管理，使用单例模式
class UserService extends ChangeNotifier {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();
  
  UserService._();

  UserModel? _userModel;
  bool _isLoading = false;

  // Getters
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  
  int get coinCount => _userModel?.coinCount ?? UserModel.defaultCoinCount;
  int get heartCount => _userModel?.heartCount ?? UserModel.defaultHeartCount;

  /// 初始化用户服务
  Future<void> initialize() async {
    if (_userModel != null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _userModel = await UserModel.loadFromCache();
    } catch (e) {
      debugPrint('Failed to load user data: $e');
      _userModel = UserModel(); // 使用默认值
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 重新加载用户数据
  Future<void> reload() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _userModel = await UserModel.loadFromCache();
    } catch (e) {
      debugPrint('Failed to reload user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 增加金币
  Future<void> addCoins(int amount) async {
    if (_userModel != null) {
      _userModel!.addCoins(amount);
      notifyListeners();
    }
  }

  /// 消费金币
  Future<bool> spendCoins(int amount) async {
    if (_userModel != null) {
      final success = _userModel!.spendCoins(amount);
      if (success) {
        notifyListeners();
      }
      return success;
    }
    return false;
  }

  /// 增加爱心
  Future<void> addHearts(int amount) async {
    if (_userModel != null) {
      _userModel!.addHearts(amount);
      notifyListeners();
    }
  }

  /// 消费爱心
  Future<bool> spendHearts(int amount) async {
    if (_userModel != null) {
      final success = _userModel!.spendHearts(amount);
      if (success) {
        notifyListeners();
      }
      return success;
    }
    return false;
  }

  /// 检查是否有足够的金币
  bool hasEnoughCoins(int amount) {
    return _userModel?.hasEnoughCoins(amount) ?? false;
  }

  /// 检查是否有足够的爱心
  bool hasEnoughHearts(int amount) {
    return _userModel?.hasEnoughHearts(amount) ?? false;
  }

  /// 重置用户数据
  Future<void> resetUserData() async {
    if (_userModel != null) {
      await _userModel!.resetToDefaults();
      notifyListeners();
    }
  }

  /// 获取用户数据摘要
  Map<String, dynamic> getUserData() {
    return _userModel?.toJson() ?? {
      'coinCount': UserModel.defaultCoinCount,
      'heartCount': UserModel.defaultHeartCount,
    };
  }

  /// 更新用户数据
  Future<void> updateUserData({
    int? coinCount,
    int? heartCount,
  }) async {
    if (_userModel != null) {
      if (coinCount != null) {
        _userModel!.coinCount = coinCount;
      }
      if (heartCount != null) {
        _userModel!.heartCount = heartCount;
      }
      notifyListeners();
    }
  }
} 