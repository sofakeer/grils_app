# 图片蒙版效果测试

这个项目实现了Flutter中的图片蒙版效果，使用黑白图片作为蒙版来控制其他图片的显示效果。

## 功能说明

### 蒙版原理
- **白色区域**: 显示背景内容
- **黑色区域**: 变成透明
- **灰色区域**: 显示半透明效果

### 实现方法

#### 1. 使用 ShaderMask
```dart
ShaderMask(
  shaderCallback: (Rect bounds) {
    return ImageShader(
      maskImage,  // 蒙版图片
      TileMode.clamp,
      TileMode.clamp,
      Matrix4.identity().storage,
    );
  },
  blendMode: BlendMode.dstIn,  // 关键：使用dstIn混合模式
  child: Container(
    color: Colors.white,
  ),
)
```

#### 2. 使用 CustomPainter
```dart
class ImageMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final maskPaint = Paint()
      ..blendMode = BlendMode.dstIn;
    
    canvas.drawImageRect(
      maskImage,
      sourceRect,
      destRect,
      maskPaint,
    );
  }
}
```

## 测试页面

### 1. 简单蒙版测试 (`SimpleMaskTest`)
- 基础的蒙版效果展示
- 使用固定的渐变背景
- 适合快速验证功能

### 2. 完整蒙版测试 (`MaskTestPage`)
- 支持多种背景切换
- 包含错误处理
- 提供详细的使用说明

## 使用方法

1. 在主页面点击右侧的测试按钮：
   - 粉色按钮：完整蒙版测试
   - 蓝色按钮：简单蒙版测试

2. 在测试页面中：
   - 查看蒙版效果展示
   - 对比原始蒙版图片
   - 点击右上角按钮切换背景

## 技术要点

### 图片加载
```dart
Future<ui.Image> loadImage(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  return frame.image;
}
```

### 混合模式
- `BlendMode.dstIn`: 使用蒙版图片的alpha通道
- 白色区域保持不透明
- 黑色区域完全透明
- 灰色区域部分透明

### 性能优化
- 图片预加载
- 错误处理
- 状态管理

## 应用场景

1. **游戏开发**: 角色服装系统
2. **图片编辑**: 局部效果应用
3. **UI设计**: 特殊形状的图片展示
4. **动画效果**: 渐变过渡效果

## 注意事项

1. 蒙版图片应该是黑白图片
2. 图片格式支持PNG、JPG等
3. 性能考虑图片大小
4. 错误处理很重要

## 扩展功能

可以进一步扩展的功能：
- 动态蒙版切换
- 蒙版动画效果
- 多图层蒙版
- 实时蒙版编辑
