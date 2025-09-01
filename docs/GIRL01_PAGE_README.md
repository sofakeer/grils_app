# Girl01Page - 专用动画页面

## 概述
`Girl01Page` 是一个专门用于播放 Girl 01 Spine 动画的独立页面。该页面使用了以下资源文件：
- `girl01.atlas` - 纹理图集文件
- `girl01.png` - 主要纹理图片
- `girl01_2.png` - 辅助纹理图片
- `girl01.skel` - Spine 骨骼动画文件

## 功能特性

### 1. 动画播放控制
- **播放/暂停**: 点击播放按钮开始动画，点击暂停按钮停止动画
- **停止**: 完全停止动画并清除所有动画轨道
- **动画切换**: 支持在多个动画之间切换（上一个/下一个）

### 2. 用户界面
- **状态显示**: 实时显示当前动画状态（播放中/已暂停）
- **动画信息**: 显示当前播放的动画名称和动画索引
- **可用动画列表**: 显示所有可用的动画名称
- **错误处理**: 当动画加载失败时显示错误信息和重试按钮

### 3. 视觉设计
- **渐变背景**: 使用粉色到紫色的渐变背景
- **圆角边框**: 动画显示区域使用圆角边框
- **彩色按钮**: 不同功能的按钮使用不同颜色区分
- **阴影效果**: 控制面板具有阴影效果

## 访问方式

### 从主页面导航
1. 在主页面的 AppBar 中点击人物图标 (Icons.person)
2. 或者点击主页面中的 "打开 Girl 01 专用页面" 按钮

### 直接启动
可以修改 `main.dart` 中的 `home` 参数直接启动到 Girl01Page：
```dart
home: const Girl01Page(),
```

## 技术实现

### 核心组件
- `SpineWidgetController`: 控制 Spine 动画的播放
- `SpineWidget.fromAsset`: 从资源文件加载 Spine 动画
- `SetupPoseBounds`: 设置动画边界

### 状态管理
- `_isControllerReady`: 控制器是否准备就绪
- `_availableAnimations`: 可用动画列表
- `_currentAnimationIndex`: 当前动画索引
- `_isAnimating`: 动画是否正在播放
- `_isLoading`: 是否正在加载
- `_errorMessage`: 错误信息

### 动画控制方法
- `_playAnimation()`: 播放指定动画
- `_pauseAnimation()`: 暂停动画
- `_resumeAnimation()`: 恢复动画
- `_stopAnimation()`: 停止动画
- `_nextAnimation()`: 切换到下一个动画
- `_previousAnimation()`: 切换到上一个动画

## 文件结构
```
lib/
├── main.dart              # 主应用程序（包含导航到 Girl01Page）
├── girl01_page.dart       # Girl01 专用页面
└── spine_animation_widget.dart  # 通用 Spine 动画组件

assets/spine/
├── girl01.atlas          # Girl01 纹理图集
├── girl01.png           # Girl01 主要纹理
├── girl01_2.png         # Girl01 辅助纹理
└── girl01.skel          # Girl01 骨骼动画数据
```

## 使用说明

1. **启动应用**: 运行 `flutter run`
2. **导航到页面**: 点击主页面的导航按钮
3. **控制动画**: 使用底部的控制按钮来播放、暂停、停止或切换动画
4. **查看信息**: 顶部显示当前动画状态和可用动画列表

## 注意事项

- 确保所有 Spine 资源文件都在 `assets/spine/` 目录中
- 动画文件必须是有效的 Spine 格式
- 如果动画加载失败，会显示错误信息和重试按钮
- 页面会自动播放第一个可用的动画 