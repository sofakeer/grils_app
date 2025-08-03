# 公共组件

## CommonHeader 公共头部组件

这是一个可复用的头部组件，包含金币显示、爱心显示、返回按钮和标题。

### 功能特性

- ✅ 金币数量显示
- ✅ 爱心数量显示  
- ✅ 返回按钮（可自定义回调）
- ✅ 页面标题（可选）
- ✅ 响应式布局
- ✅ 统一的视觉风格
- ✅ 自动从UserService获取最新数据

### 使用方法

```dart
import 'package:grils_app/widgets/common_header.dart';

// 基本使用
const CommonHeader(
  title: '相册',
)

// 自定义返回按钮回调
const CommonHeader(
  title: '相册',
  onBackPressed: () {
    // 自定义返回逻辑
    Navigator.pop(context);
  },
)

// 不显示返回按钮
const CommonHeader(
  title: '相册',
  showBackButton: false,
)
```

### 参数说明

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| title | String? | ❌ | null | 页面标题 |
| onBackPressed | VoidCallback? | ❌ | Navigator.pop | 返回按钮回调 |
| showBackButton | bool | ❌ | true | 是否显示返回按钮 |

### 样式说明

- 金币显示：金色背景，橙色边框
- 爱心显示：粉色背景，粉色边框
- 返回按钮：半透明黑色圆形背景
- 标题：白色文字，居中显示

### 已集成页面

- ✅ GalleryPage (相册页面)
- 🔄 其他页面可继续集成

---

## UserModel 用户模型

管理用户的金币和爱心货币，支持本地缓存存储和读取。

### 功能特性

- ✅ 金币和爱心货币管理
- ✅ 自动本地缓存存储
- ✅ 增加/消费货币方法
- ✅ 余额检查
- ✅ 数据重置功能
- ✅ JSON序列化支持

### 使用方法

```dart
import 'package:grils_app/models/user_model.dart';

// 创建用户模型
final user = UserModel(coinCount: 1000, heartCount: 50);

// 增加金币
user.addCoins(100);

// 消费金币
if (user.spendCoins(50)) {
  print('消费成功');
}

// 检查余额
if (user.hasEnoughCoins(100)) {
  print('余额充足');
}

// 从缓存加载
final user = await UserModel.loadFromCache();
```

---

## UserService 用户服务

提供全局的用户模型管理，使用单例模式。

### 功能特性

- ✅ 全局单例管理
- ✅ 自动数据同步
- ✅ 响应式数据更新
- ✅ 错误处理
- ✅ 数据持久化

### 使用方法

```dart
import 'package:grils_app/services/user_service.dart';

// 获取服务实例
final userService = UserService.instance;

// 初始化服务
await userService.initialize();

// 增加金币
await userService.addCoins(100);

// 消费爱心
if (await userService.spendHearts(5)) {
  print('消费成功');
}

// 检查余额
if (userService.hasEnoughCoins(100)) {
  print('余额充足');
}

// 重置数据
await userService.resetUserData();
```

### 监听数据变化

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late UserService _userService;

  @override
  void initState() {
    super.initState();
    _userService = UserService.instance;
    _userService.addListener(_onUserDataChanged);
  }

  @override
  void dispose() {
    _userService.removeListener(_onUserDataChanged);
    super.dispose();
  }

  void _onUserDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text('金币: ${_userService.coinCount}');
  }
}
``` 