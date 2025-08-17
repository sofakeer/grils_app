# OutlinedTextWidget 使用说明

## 概述

`OutlinedTextWidget` 是一个高度可自定义的文字组件，使用 `Anja-Eliane-2.ttf` 字体，支持描边、发光、阴影等多种效果。

## 基本用法

### 1. 基础描边文字

```dart
OutlinedTextWidget(
  text: 'Hello World',
  fontSize: 24,
  textColor: Colors.white,
  strokeColor: Colors.black,
  strokeWidth: 2.0,
)
```

### 2. 发光效果文字

```dart
OutlinedTextWidget.glow(
  text: 'Glowing Text',
  fontSize: 28,
  textColor: Colors.cyan,
  glowColor: Colors.blue,
  glowRadius: 15,
)
```

### 3. 多层阴影效果

```dart
OutlinedTextWidget.multiShadow(
  text: 'Shadow Text',
  fontSize: 24,
  textColor: Colors.white,
  strokeColor: Colors.purple,
  strokeWidth: 3,
)
```

### 4. 彩虹效果

```dart
OutlinedTextWidget.rainbow(
  text: 'Rainbow Text',
  fontSize: 26,
  textColor: Colors.white,
)
```

## 预设样式

### GameTextStyles 类提供了常用的游戏风格文字：

```dart
// 游戏标题
GameTextStyles.title('GAME TITLE')

// 按钮文字
GameTextStyles.button('BUTTON TEXT')

// 分数显示
GameTextStyles.score('SCORE: 99999')

// 提示文字
GameTextStyles.hint('This is a hint')

// 错误信息
GameTextStyles.error('Error Message!')

// 成功信息
GameTextStyles.success('Success Message!')
```

## 自定义参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| text | String | 必需 | 显示的文字内容 |
| fontSize | double | 24.0 | 字体大小 |
| textColor | Color | Colors.white | 文字颜色 |
| strokeColor | Color | Colors.black | 描边颜色 |
| strokeWidth | double | 2.0 | 描边宽度 |
| fontWeight | FontWeight | FontWeight.bold | 字体粗细 |
| textAlign | TextAlign | TextAlign.center | 文字对齐 |
| maxLines | int? | null | 最大行数 |
| fontFamily | String | 'Anja-Eliane' | 字体家族 |
| shadows | List<Shadow>? | null | 阴影效果 |
| letterSpacing | double? | null | 字母间距 |
| height | double? | null | 行高 |

## 示例效果

### 金色文字
```dart
OutlinedTextWidget(
  text: 'GOLDEN TEXT',
  fontSize: 32,
  textColor: Color(0xFFFFD700),
  strokeColor: Color(0xFF8B4513),
  strokeWidth: 3,
  fontWeight: FontWeight.w900,
)
```

### 带间距的文字
```dart
OutlinedTextWidget(
  text: 'S P A C E D   T E X T',
  fontSize: 20,
  textColor: Colors.lime,
  strokeColor: Colors.green,
  strokeWidth: 2,
  letterSpacing: 2.0,
)
```

## 在项目中的使用

1. 确保在 `pubspec.yaml` 中已正确配置字体
2. 导入组件：`import '../widgets/outlined_text_widget.dart';`
3. 使用组件替换普通的 `Text` 组件

## 注意事项

- 字体文件路径：`assets/font/Anja-Eliane-2.ttf`
- 描边效果通过 Stack 层叠实现，性能考虑建议不要过度使用
- 发光效果使用多层 Shadow 实现，在深色背景下效果更佳
- 可以通过调整 `strokeWidth` 为 0 来禁用描边效果