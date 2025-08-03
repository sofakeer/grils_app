import 'package:shared_preferences/shared_preferences.dart';

/// 用户模型类
/// 
/// 管理用户的金币和爱心货币，支持本地缓存存储和读取
class UserModel {
  int _coinCount;
  int _heartCount;
  
  // 默认值
  static const int defaultCoinCount = 1000;
  static const int defaultHeartCount = 50;
  
  // 存储键名
  static const String _coinCountKey = 'user_coin_count';
  static const String _heartCountKey = 'user_heart_count';

  UserModel({
    int coinCount = defaultCoinCount,
    int heartCount = defaultHeartCount,
  }) : _coinCount = coinCount,
       _heartCount = heartCount;

  // Getters
  int get coinCount => _coinCount;
  int get heartCount => _heartCount;

  // Setters
  set coinCount(int value) {
    _coinCount = value;
    _saveCoinCount();
  }

  set heartCount(int value) {
    _heartCount = value;
    _saveHeartCount();
  }

  /// 增加金币
  void addCoins(int amount) {
    if (amount > 0) {
      _coinCount += amount;
      _saveCoinCount();
    }
  }

  /// 减少金币
  bool spendCoins(int amount) {
    if (amount > 0 && _coinCount >= amount) {
      _coinCount -= amount;
      _saveCoinCount();
      return true;
    }
    return false;
  }

  /// 增加爱心
  void addHearts(int amount) {
    if (amount > 0) {
      _heartCount += amount;
      _saveHeartCount();
    }
  }

  /// 减少爱心
  bool spendHearts(int amount) {
    if (amount > 0 && _heartCount >= amount) {
      _heartCount -= amount;
      _saveHeartCount();
      return true;
    }
    return false;
  }

  /// 检查是否有足够的金币
  bool hasEnoughCoins(int amount) {
    return _coinCount >= amount;
  }

  /// 检查是否有足够的爱心
  bool hasEnoughHearts(int amount) {
    return _heartCount >= amount;
  }

  /// 从缓存加载用户数据
  static Future<UserModel> loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    
    final coinCount = prefs.getInt(_coinCountKey) ?? defaultCoinCount;
    final heartCount = prefs.getInt(_heartCountKey) ?? defaultHeartCount;
    
    return UserModel(
      coinCount: coinCount,
      heartCount: heartCount,
    );
  }

  /// 保存金币数量到缓存
  Future<void> _saveCoinCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinCountKey, _coinCount);
  }

  /// 保存爱心数量到缓存
  Future<void> _saveHeartCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_heartCountKey, _heartCount);
  }

  /// 保存所有数据到缓存
  Future<void> saveToCache() async {
    await Future.wait([
      _saveCoinCount(),
      _saveHeartCount(),
    ]);
  }

  /// 重置用户数据到默认值
  Future<void> resetToDefaults() async {
    _coinCount = defaultCoinCount;
    _heartCount = defaultHeartCount;
    await saveToCache();
  }

  /// 获取用户数据摘要
  Map<String, dynamic> toJson() {
    return {
      'coinCount': _coinCount,
      'heartCount': _heartCount,
    };
  }

  /// 从JSON创建用户模型
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      coinCount: json['coinCount'] ?? defaultCoinCount,
      heartCount: json['heartCount'] ?? defaultHeartCount,
    );
  }

  @override
  String toString() {
    return 'UserModel(coins: $_coinCount, hearts: $_heartCount)';
  }
} 