import 'package:flutter/material.dart';
import 'dart:math' as math;

class FlowerMaskTest extends StatefulWidget {
  @override
  _FlowerMaskTestState createState() => _FlowerMaskTestState();
}

class _FlowerMaskTestState extends State<FlowerMaskTest> {
  int petalCount = 4; // 默认4片花瓣，形成四叶草
  double petalSize = 0.3; // 稍微增大花瓣大小
  bool useInvertedMask = false;
  int currentImageIndex = 0;
  int currentShapeIndex = 0; // 添加形状选择
  double tiltAngle = 0.3; // 倾斜角度控制 (0.0-1.0)
  double tiltPosition = 0.5; // 倾斜位置控制 (0.0-1.0)
  
  // 定义不同的形状选项
  final List<String> shapeNames = [
    '花瓣/四叶草',
    '星形',
    '心形',
    '云朵',
    '不规则多边形',
    '波浪形',
    '倾斜切割',
    '瓶子倾斜',
  ];
  
  // 定义不同的图片选项
  final List<Map<String, dynamic>> images = [
    {
      'name': '内衣图片',
      'path': 'assets/images/Girl01_chage_Btn_All/Btn_gril01_bra_1_unlock.png',
    },
    {
      'name': '瓶子外部',
      'path': 'assets/images/boll.png',
    },
    {
      'name': '瓶子内部',
      'path': 'assets/images/boll_inner.png',
    },
    {
      'name': '码头风景',
      'type': 'gradient',
      'colors': [
        Color(0xFFE6F3FF), // 天空蓝
        Color(0xFFB3D9FF), // 浅蓝
        Color(0xFF80BFFF), // 中蓝
        Color(0xFF4DA6FF), // 深蓝
        Color(0xFF1A8CFF), // 水蓝
      ],
    },
    {
      'name': '日落风景',
      'type': 'gradient',
      'colors': [
        Color(0xFFFFE6CC), // 暖黄
        Color(0xFFFFCC99), // 橙色
        Color(0xFFFFB366), // 深橙
        Color(0xFFFF9933), // 红橙
        Color(0xFFFF8000), // 深红橙
      ],
    },
    {
      'name': '森林风景',
      'type': 'gradient',
      'colors': [
        Color(0xFFE6FFE6), // 浅绿
        Color(0xFFB3FFB3), // 中绿
        Color(0xFF80FF80), // 深绿
        Color(0xFF4DFF4D), // 亮绿
        Color(0xFF1AFF1A), // 荧光绿
      ],
    },
    {
      'name': '紫色梦幻',
      'type': 'gradient',
      'colors': [
        Color(0xFFF0E6FF), // 浅紫
        Color(0xFFE6CCFF), // 中紫
        Color(0xFFD9B3FF), // 深紫
        Color(0xFFCC99FF), // 亮紫
        Color(0xFFBF80FF), // 荧光紫
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('花瓣蒙版测试'),
        backgroundColor: Colors.pink[100],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildControlPanel(),
            SizedBox(height: 24),
            
            Text(
              '花瓣蒙版效果展示',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildFlowerMaskEffect(),
            SizedBox(height: 32),
            
            Text(
              '原始图片',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildOriginalImage(),
            SizedBox(height: 32),
            
            Text(
              '纯花瓣形状',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildPureFlowerShape(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '不规则蒙版控制面板',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '点击按钮切换不同的蒙版形状和图片',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          SizedBox(height: 12),
          
          // 形状选择
          Row(
            children: [
              Icon(Icons.category, color: Colors.indigo[300]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '当前形状: ${shapeNames[currentShapeIndex]}',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                icon: Icon(Icons.swap_horiz),
                onPressed: () {
                  setState(() {
                    currentShapeIndex = (currentShapeIndex + 1) % shapeNames.length;
                  });
                },
                tooltip: '切换形状',
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // 图片选择
          Row(
            children: [
              Icon(Icons.image, color: Colors.purple[300]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '当前图片: ${images[currentImageIndex]['name']}',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                icon: Icon(Icons.swap_horiz),
                onPressed: () {
                  setState(() {
                    currentImageIndex = (currentImageIndex + 1) % images.length;
                  });
                },
                tooltip: '切换图片',
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // 只在花瓣/星形模式下显示数量控制
          if (currentShapeIndex == 0 || currentShapeIndex == 1)
            Row(
              children: [
                Icon(Icons.abc_outlined, color: Colors.green[300]),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${currentShapeIndex == 0 ? "花瓣" : "角"} 数量: $petalCount'),
                      Slider(
                        value: petalCount.toDouble(),
                        min: 3.0,
                        max: 8.0,
                        divisions: 5,
                        onChanged: (value) {
                          setState(() {
                            petalCount = value.toInt();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          
          // 只在倾斜模式下显示倾斜控制
          if (currentShapeIndex == 6 || currentShapeIndex == 7) ...[
            Row(
              children: [
                Icon(Icons.trending_down, color: Colors.red[300]),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('倾斜角度: ${(tiltAngle * 100).toInt()}%'),
                      Slider(
                        value: tiltAngle,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        onChanged: (value) {
                          setState(() {
                            tiltAngle = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.swap_vert, color: Colors.orange[300]),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('倾斜位置: ${(tiltPosition * 100).toInt()}%'),
                      Slider(
                        value: tiltPosition,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        onChanged: (value) {
                          setState(() {
                            tiltPosition = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          
          Row(
            children: [
              Icon(Icons.zoom_in, color: Colors.blue[300]),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('花瓣大小: ${(petalSize * 100).toInt()}%'),
                    Slider(
                      value: petalSize,
                      min: 0.1,
                      max: 0.5,
                      divisions: 8,
                      onChanged: (value) {
                        setState(() {
                          petalSize = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          Row(
            children: [
              Icon(Icons.flip, color: Colors.orange[300]),
              SizedBox(width: 8),
              Text('反转蒙版'),
              Spacer(),
              Switch(
                value: useInvertedMask,
                onChanged: (value) {
                  setState(() {
                    useInvertedMask = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowerMaskEffect() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          // 背景色，用来显示蒙版外的区域
          color: Colors.grey[300],
          child: Center(
            child: ClipPath(
              clipper: IrregularShapeClipper(
                shapeType: currentShapeIndex,
                petalCount: petalCount,
                petalSize: petalSize,
                inverted: useInvertedMask,
                tiltAngle: tiltAngle,
                tiltPosition: tiltPosition,
              ),
              child: Container(
                width: 300,
                height: 300,
                child: images[currentImageIndex]['type'] == 'gradient'
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: images[currentImageIndex]['colors'],
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: Image.asset(
                          images[currentImageIndex]['path'],
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalImage() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: images[currentImageIndex]['type'] == 'gradient'
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: images[currentImageIndex]['colors'],
                  ),
                ),
              )
            : Image.asset(
                images[currentImageIndex]['path'],
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
      ),
    );
  }

  Widget _buildPureFlowerShape() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: Colors.white,
          child: CustomPaint(
            size: Size(300, 300),
            painter: PureShapePainter(
              shapeType: currentShapeIndex,
              petalCount: petalCount,
              petalSize: petalSize,
              tiltAngle: tiltAngle,
              tiltPosition: tiltPosition,
            ),
          ),
        ),
      ),
    );
  }
}

// 自定义剪裁器，用于创建不规则形状的蒙版
class IrregularShapeClipper extends CustomClipper<Path> {
  final int shapeType;
  final int petalCount;
  final double petalSize;
  final bool inverted;
  final double tiltAngle;
  final double tiltPosition;

  IrregularShapeClipper({
    required this.shapeType,
    required this.petalCount,
    required this.petalSize,
    required this.inverted,
    this.tiltAngle = 0.3,
    this.tiltPosition = 0.5,
  });

  @override
  Path getClip(Size size) {
    Path shapePath;
    
    switch (shapeType) {
      case 0: // 花瓣/四叶草
        shapePath = _createFlowerPath(size);
        break;
      case 1: // 星形
        shapePath = _createStarPath(size);
        break;
      case 2: // 心形
        shapePath = _createHeartPath(size);
        break;
      case 3: // 云朵
        shapePath = _createCloudPath(size);
        break;
      case 4: // 不规则多边形
        shapePath = _createIrregularPolygonPath(size);
        break;
      case 5: // 波浪形
        shapePath = _createWavePath(size);
        break;
      case 6: // 倾斜切割
        shapePath = _createTiltCutPath(size);
        break;
      case 7: // 瓶子倾斜
        shapePath = _createBottleTiltPath(size);
        break;
      default:
        shapePath = _createFlowerPath(size);
    }
    
    if (inverted) {
      // 创建反转蒙版
      final fullPath = Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return Path.combine(PathOperation.difference, fullPath, shapePath);
    }
    
    return shapePath;
  }

  Path _createFlowerPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(size.width, size.height) * petalSize;

    path.moveTo(centerX, centerY);

    for (int i = 0; i < petalCount; i++) {
      final angle = (i * 2 * math.pi) / petalCount;
      final nextAngle = ((i + 1) * 2 * math.pi) / petalCount;
      
      final controlAngle = angle + (nextAngle - angle) / 2;
      final controlRadius = radius * 1.8;
      
      final x2 = centerX + radius * math.cos(nextAngle);
      final y2 = centerY + radius * math.sin(nextAngle);
      final cx = centerX + controlRadius * math.cos(controlAngle);
      final cy = centerY + controlRadius * math.sin(controlAngle);
      
      path.quadraticBezierTo(cx, cy, x2, y2);
    }
    
    path.close();
    return path;
  }

  Path _createStarPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius = math.min(size.width, size.height) * petalSize * 1.2;
    final innerRadius = outerRadius * 0.5;

    for (int i = 0; i < petalCount * 2; i++) {
      final angle = (i * math.pi) / petalCount - math.pi / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    return path;
  }

  Path _createHeartPath(Size size) {
    final path = Path();
    final width = size.width * petalSize * 2;
    final height = size.height * petalSize * 2;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    path.moveTo(centerX, centerY + height * 0.3);
    
    // 左侧曲线
    path.cubicTo(
      centerX - width * 0.5, centerY + height * 0.1,
      centerX - width * 0.5, centerY - height * 0.2,
      centerX - width * 0.25, centerY - height * 0.2,
    );
    
    // 左上圆弧
    path.cubicTo(
      centerX - width * 0.1, centerY - height * 0.2,
      centerX, centerY - height * 0.05,
      centerX, centerY,
    );
    
    // 右上圆弧
    path.cubicTo(
      centerX, centerY - height * 0.05,
      centerX + width * 0.1, centerY - height * 0.2,
      centerX + width * 0.25, centerY - height * 0.2,
    );
    
    // 右侧曲线
    path.cubicTo(
      centerX + width * 0.5, centerY - height * 0.2,
      centerX + width * 0.5, centerY + height * 0.1,
      centerX, centerY + height * 0.3,
    );
    
    path.close();
    return path;
  }

  Path _createCloudPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final baseRadius = math.min(size.width, size.height) * petalSize;
    
    // 创建云朵形状
    final bubbles = [
      {'x': -0.5, 'y': 0.2, 'r': 0.7},
      {'x': -0.2, 'y': -0.2, 'r': 0.8},
      {'x': 0.2, 'y': -0.1, 'r': 0.75},
      {'x': 0.5, 'y': 0.15, 'r': 0.65},
      {'x': 0.0, 'y': 0.3, 'r': 0.9},
    ];
    
    for (int i = 0; i < bubbles.length; i++) {
      final bubble = bubbles[i];
      final x = centerX + baseRadius * bubble['x']!;
      final y = centerY + baseRadius * bubble['y']!;
      final r = baseRadius * bubble['r']!;
      
      if (i == 0) {
        path.addOval(Rect.fromCircle(center: Offset(x, y), radius: r));
      } else {
        final tempPath = Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));
        path.fillType = PathFillType.nonZero;
        path.addPath(tempPath, Offset.zero);
      }
    }
    
    return path;
  }

  Path _createIrregularPolygonPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final baseRadius = math.min(size.width, size.height) * petalSize;
    
    // 创建不规则多边形
    final random = math.Random(42); // 固定种子保持形状一致
    final points = <Offset>[];
    final numPoints = 8;
    
    for (int i = 0; i < numPoints; i++) {
      final angle = (i * 2 * math.pi) / numPoints;
      final radiusVariation = 0.7 + random.nextDouble() * 0.6;
      final radius = baseRadius * radiusVariation;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      points.add(Offset(x, y));
    }
    
    // 使用贝塞尔曲线连接点，创建更平滑的形状
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      final control = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(control.dx, control.dy, next.dx, next.dy);
    }
    
    path.close();
    return path;
  }

  Path _createWavePath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(size.width, size.height) * petalSize;
    
    // 创建波浪形状
    final waveCount = 12;
    final waveAmplitude = radius * 0.15;
    
    for (int i = 0; i <= waveCount; i++) {
      final angle = (i * 2 * math.pi) / waveCount;
      final waveOffset = math.sin(angle * 3) * waveAmplitude;
      final r = radius + waveOffset;
      final x = centerX + r * math.cos(angle);
      final y = centerY + r * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // 使用贝塞尔曲线创建平滑的波浪
        final prevAngle = ((i - 1) * 2 * math.pi) / waveCount;
        final prevWaveOffset = math.sin(prevAngle * 3) * waveAmplitude;
        final prevR = radius + prevWaveOffset;
        final prevX = centerX + prevR * math.cos(prevAngle);
        final prevY = centerY + prevR * math.sin(prevAngle);
        
        final controlX = (prevX + x) / 2;
        final controlY = (prevY + y) / 2;
        path.quadraticBezierTo(controlX, controlY, x, y);
      }
    }
    
    path.close();
    return path;
  }

  Path _createTiltCutPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 计算倾斜线的位置和角度
    final tiltY = centerY + (size.height * 0.3 * (tiltPosition - 0.5));
    final tiltSlope = (tiltAngle - 0.5) * 3; // 增大斜率范围，让效果更明显
    
    // 创建倾斜切割路径 - 只保留切割线上方的部分
    final leftY = tiltY - tiltSlope * centerX;
    final rightY = tiltY + tiltSlope * centerX;
    
    // 确保切割线在画布范围内
    final startY = math.max(0.0, math.min(size.height, leftY)).toDouble();
    final endY = math.max(0.0, math.min(size.height, rightY)).toDouble();
    
    // 创建切割线上方的区域
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, endY);
    path.lineTo(0, startY);
    path.close();
    
    return path;
  }

  Path _createBottleTiltPath(Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final width = size.width * petalSize * 2;
    final height = size.height * petalSize * 2;
    
    // 创建瓶子形状的倾斜切割
    final tiltY = centerY + (height * (tiltPosition - 0.5));
    final tiltSlope = (tiltAngle - 0.5) * 1.5; // 稍微减小斜率范围
    
    // 创建瓶子轮廓
    final bottlePath = Path();
    
    // 瓶子底部
    bottlePath.moveTo(centerX - width * 0.3, centerY + height * 0.4);
    bottlePath.lineTo(centerX + width * 0.3, centerY + height * 0.4);
    
    // 瓶子右侧
    bottlePath.lineTo(centerX + width * 0.25, centerY - height * 0.3);
    
    // 瓶子颈部
    bottlePath.lineTo(centerX + width * 0.15, centerY - height * 0.4);
    bottlePath.lineTo(centerX + width * 0.15, centerY - height * 0.35);
    
    // 瓶子顶部
    bottlePath.lineTo(centerX + width * 0.2, centerY - height * 0.35);
    bottlePath.lineTo(centerX + width * 0.2, centerY - height * 0.3);
    bottlePath.lineTo(centerX - width * 0.2, centerY - height * 0.3);
    bottlePath.lineTo(centerX - width * 0.2, centerY - height * 0.35);
    bottlePath.lineTo(centerX - width * 0.15, centerY - height * 0.35);
    
    // 瓶子左侧
    bottlePath.lineTo(centerX - width * 0.15, centerY - height * 0.4);
    bottlePath.lineTo(centerX - width * 0.25, centerY - height * 0.3);
    bottlePath.close();
    
    // 创建倾斜切割线
    final cutPath = Path();
    final leftY = tiltY - tiltSlope * centerX;
    final rightY = tiltY + tiltSlope * centerX;
    
    final startY = math.max(0.0, math.min(size.height, leftY)).toDouble();
    final endY = math.max(0.0, math.min(size.height, rightY)).toDouble();
    
    cutPath.moveTo(0, startY);
    cutPath.lineTo(size.width, endY);
    cutPath.lineTo(size.width, size.height);
    cutPath.lineTo(0, size.height);
    cutPath.close();
    
    // 结合瓶子形状和倾斜切割
    return Path.combine(PathOperation.intersect, bottlePath, cutPath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

// 纯形状绘制器
class PureShapePainter extends CustomPainter {
  final int shapeType;
  final int petalCount;
  final double petalSize;
  final double tiltAngle;
  final double tiltPosition;

  PureShapePainter({
    required this.shapeType,
    required this.petalCount,
    required this.petalSize,
    this.tiltAngle = 0.3,
    this.tiltPosition = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _getShapeColor()
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = _getShapeStrokeColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final clipper = IrregularShapeClipper(
      shapeType: shapeType,
      petalCount: petalCount,
      petalSize: petalSize,
      inverted: false,
      tiltAngle: tiltAngle,
      tiltPosition: tiltPosition,
    );
    
    final shapePath = clipper.getClip(size);
    
    canvas.drawPath(shapePath, paint);
    canvas.drawPath(shapePath, strokePaint);
  }

  Color _getShapeColor() {
    switch (shapeType) {
      case 0: return Colors.pink[300]!; // 花瓣
      case 1: return Colors.amber[300]!; // 星形
      case 2: return Colors.red[300]!; // 心形
      case 3: return Colors.blue[200]!; // 云朵
      case 4: return Colors.purple[300]!; // 不规则多边形
      case 5: return Colors.teal[300]!; // 波浪
      case 6: return Colors.orange[300]!; // 倾斜切割
      case 7: return Colors.cyan[300]!; // 瓶子倾斜
      default: return Colors.pink[300]!;
    }
  }

  Color _getShapeStrokeColor() {
    switch (shapeType) {
      case 0: return Colors.pink[600]!; // 花瓣
      case 1: return Colors.amber[600]!; // 星形
      case 2: return Colors.red[600]!; // 心形
      case 3: return Colors.blue[400]!; // 云朵
      case 4: return Colors.purple[600]!; // 不规则多边形
      case 5: return Colors.teal[600]!; // 波浪
      case 6: return Colors.orange[600]!; // 倾斜切割
      case 7: return Colors.cyan[600]!; // 瓶子倾斜
      default: return Colors.pink[600]!;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
