import 'package:flutter/material.dart';
import 'dart:math' as math;

class TiltTestPage extends StatefulWidget {
  @override
  _TiltTestPageState createState() => _TiltTestPageState();
}

class _TiltTestPageState extends State<TiltTestPage> {
  double tiltAngle = 0.3;
  double tiltPosition = 0.5;
  int currentImageIndex = 0;
  int currentTiltMode = 0; // 0: 简单倾斜, 1: 瓶子倾斜
  double bottleAngle = 0.0; // 瓶子旋转角度（弧度比例 0..1 -> 0..90°）
  double fillLevel = 0.6; // 液位高度（0 顶部，1 底部）
  
  final List<Map<String, dynamic>> images = [
    {
      'name': '瓶子外部',
      'path': 'assets/images/boll.png',
    },
    {
      'name': '瓶子内部',
      'path': 'assets/images/boll_inner.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('瓶子倾斜效果测试'),
        backgroundColor: Colors.blue[100],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildControlPanel(),
            SizedBox(height: 24),
            
            Text(
              '瓶子倾倒效果',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildTiltEffect(),
            SizedBox(height: 32),
            
            Text(
              '原始图片',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildOriginalImage(),
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
            '瓶子倾倒效果控制面板',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          
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
          
          // 倾倒模式选择
          Row(
            children: [
              Icon(Icons.category, color: Colors.indigo[300]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '倾倒模式: ${currentTiltMode == 0 ? "液体表面" : "瓶子形状"}',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                icon: Icon(Icons.swap_horiz),
                onPressed: () {
                  setState(() {
                    currentTiltMode = (currentTiltMode + 1) % 2;
                  });
                },
                tooltip: '切换模式',
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // 倾倒角度控制
          Row(
            children: [
              Icon(Icons.trending_down, color: Colors.red[300]),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('倾倒角度: ${(tiltAngle * 100).toInt()}%'),
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
          
          // 液体位置控制
          Row(
            children: [
              Icon(Icons.swap_vert, color: Colors.orange[300]),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('液体位置: ${(tiltPosition * 100).toInt()}%'),
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

          // 瓶子旋转角度（弧度：0°~90°）
          Row(
            children: [
              Icon(Icons.rotate_right, color: Colors.blue[300]),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('瓶子旋转: ${(bottleAngle * 90).toInt()}°'),
                    Slider(
                      value: bottleAngle,
                      min: 0.0,
                      max: 1.0,
                      divisions: 18,
                      onChanged: (value) {
                        setState(() {
                          bottleAngle = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 液位高度（0 顶部，1 底部）
          Row(
            children: [
              Icon(Icons.water_drop, color: Colors.cyan[300]),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('液位高度: ${(fillLevel * 100).toInt()}%'),
                    Slider(
                      value: fillLevel,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: (value) {
                        setState(() {
                          fillLevel = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTiltEffect() {
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
          color: Colors.grey[200],
          child: Center(
            child: Transform.rotate(
              angle: bottleAngle * math.pi / 2,
              alignment: Alignment.center,
              child: Stack(
                children: [
                  // 内部水：用瓶子形状裁剪 + 液面裁剪（液面根据反向角度绘制，以保持屏幕水平）
                  ClipPath(
                    clipper: _BottleClipper(),
                    child: ClipPath(
                      clipper: _LiquidClipper(level: fillLevel, angleRad: -(bottleAngle * math.pi / 2)),
                      child: Image.asset(
                        'assets/images/boll_inner.png',
                        width: 300,
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // 外部瓶子：与内部共同旋转（由父 Transform.rotate 统一驱动）
                  Image.asset(
                    'assets/images/boll.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ],
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
        child: Image.asset(
          images[currentImageIndex]['path'],
          width: 300,
          height: 300,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// 倾斜切割器
class TiltClipper extends CustomClipper<Path> {
  final double tiltAngle;
  final double tiltPosition;
  final int tiltMode;

  TiltClipper({
    required this.tiltAngle,
    required this.tiltPosition,
    this.tiltMode = 0,
  });

  @override
  Path getClip(Size size) {
    if (tiltMode == 0) {
      return _createSimpleTiltPath(size);
    } else {
      return _createBottleTiltPath(size);
    }
  }

  Path _createSimpleTiltPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 计算倾倒效果 - 模拟液体表面
    final tiltY = centerY + (size.height * 0.3 * (tiltPosition - 0.5));
    final tiltSlope = (tiltAngle - 0.5) * 2.0; // 调整斜率范围
    
    // 创建液体表面切割线
    final leftY = tiltY - tiltSlope * centerX;
    final rightY = tiltY + tiltSlope * centerX;
    
    // 确保切割线在画布范围内
    final startY = math.max(0.0, math.min(size.height, leftY)).toDouble();
    final endY = math.max(0.0, math.min(size.height, rightY)).toDouble();
    
    // 创建液体表面以上的区域（瓶子倾倒时液体流出的部分）
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    
    // 使用更自然的液体表面曲线
    final controlPoint1 = Offset(size.width * 0.3, startY + (endY - startY) * 0.2);
    final controlPoint2 = Offset(size.width * 0.7, startY + (endY - startY) * 0.8);
    
    path.quadraticBezierTo(controlPoint1.dx, controlPoint1.dy, size.width * 0.5, (startY + endY) / 2);
    path.quadraticBezierTo(controlPoint2.dx, controlPoint2.dy, size.width, endY);
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    return path;
  }

  Path _createBottleTiltPath(Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final width = size.width * 0.9;
    final height = size.height * 0.9;
    
    // 创建瓶子形状的液体表面切割
    final tiltY = centerY + (height * 0.2 * (tiltPosition - 0.5));
    final tiltSlope = (tiltAngle - 0.5) * 1.8; // 调整斜率范围
    
    // 创建瓶子轮廓 - 更符合实际瓶子形状
    final bottlePath = Path();
    
    // 瓶子底部（更宽）
    bottlePath.moveTo(centerX - width * 0.35, centerY + height * 0.45);
    bottlePath.lineTo(centerX + width * 0.35, centerY + height * 0.45);
    
    // 瓶子右侧（更自然的曲线）
    bottlePath.quadraticBezierTo(
      centerX + width * 0.3, centerY + height * 0.2,
      centerX + width * 0.25, centerY - height * 0.1,
    );
    
    // 瓶子颈部
    bottlePath.lineTo(centerX + width * 0.18, centerY - height * 0.3);
    bottlePath.lineTo(centerX + width * 0.18, centerY - height * 0.25);
    
    // 瓶子顶部
    bottlePath.lineTo(centerX + width * 0.22, centerY - height * 0.25);
    bottlePath.lineTo(centerX + width * 0.22, centerY - height * 0.2);
    bottlePath.lineTo(centerX - width * 0.22, centerY - height * 0.2);
    bottlePath.lineTo(centerX - width * 0.22, centerY - height * 0.25);
    bottlePath.lineTo(centerX - width * 0.18, centerY - height * 0.25);
    
    // 瓶子左侧
    bottlePath.lineTo(centerX - width * 0.18, centerY - height * 0.3);
    bottlePath.quadraticBezierTo(
      centerX - width * 0.25, centerY - height * 0.1,
      centerX - width * 0.3, centerY + height * 0.2,
    );
    bottlePath.close();
    
    // 创建液体表面切割线
    final cutPath = Path();
    final leftY = tiltY - tiltSlope * centerX;
    final rightY = tiltY + tiltSlope * centerX;
    
    final startY = math.max(0.0, math.min(size.height, leftY)).toDouble();
    final endY = math.max(0.0, math.min(size.height, rightY)).toDouble();
    
    // 创建液体表面以上的区域
    cutPath.moveTo(0, 0);
    cutPath.lineTo(size.width, 0);
    
    // 使用更自然的液体表面曲线
    final controlPoint1 = Offset(size.width * 0.25, startY + (endY - startY) * 0.1);
    final controlPoint2 = Offset(size.width * 0.75, startY + (endY - startY) * 0.9);
    
    cutPath.quadraticBezierTo(controlPoint1.dx, controlPoint1.dy, size.width * 0.5, (startY + endY) / 2);
    cutPath.quadraticBezierTo(controlPoint2.dx, controlPoint2.dy, size.width, endY);
    
    cutPath.lineTo(size.width, size.height);
    cutPath.lineTo(0, size.height);
    cutPath.close();
    
    // 结合瓶子形状和液体表面切割
    return Path.combine(PathOperation.intersect, bottlePath, cutPath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

// 基于瓶子形状的剪裁器：生成一个旋转后的瓶子轮廓，用于约束“水平水面”的可见范围
class _BottleClipper extends CustomClipper<Path> {
  _BottleClipper();

  @override
  Path getClip(Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final width = size.width * 0.9;
    final height = size.height * 0.9;

    final bottlePath = Path();

    // 底部
    bottlePath.moveTo(centerX - width * 0.35, centerY + height * 0.45);
    bottlePath.lineTo(centerX + width * 0.35, centerY + height * 0.45);

    // 右侧曲线 -> 颈部
    bottlePath.quadraticBezierTo(
      centerX + width * 0.3, centerY + height * 0.2,
      centerX + width * 0.25, centerY - height * 0.1,
    );
    bottlePath.lineTo(centerX + width * 0.18, centerY - height * 0.3);
    bottlePath.lineTo(centerX + width * 0.18, centerY - height * 0.25);

    // 顶部口
    bottlePath.lineTo(centerX + width * 0.22, centerY - height * 0.25);
    bottlePath.lineTo(centerX + width * 0.22, centerY - height * 0.2);
    bottlePath.lineTo(centerX - width * 0.22, centerY - height * 0.2);
    bottlePath.lineTo(centerX - width * 0.22, centerY - height * 0.25);
    bottlePath.lineTo(centerX - width * 0.18, centerY - height * 0.25);

    // 左侧 颈部 -> 曲线 -> 底部
    bottlePath.lineTo(centerX - width * 0.18, centerY - height * 0.3);
    bottlePath.quadraticBezierTo(
      centerX - width * 0.25, centerY - height * 0.1,
      centerX - width * 0.3, centerY + height * 0.2,
    );
    bottlePath.close();

    // 由父级统一旋转，这里不再旋转
    return bottlePath;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

// 液位水平剪裁器：保留水平面以下区域，模拟始终水平的水面
class _LiquidClipper extends CustomClipper<Path> {
  final double level; // 0 顶部 -> 1 底部
  final double angleRad; // 液面相对于容器的反向角度（全局保持水平）

  _LiquidClipper({required this.level, required this.angleRad});

  @override
  Path getClip(Size size) {
    final levelY = size.height * level.clamp(0.0, 1.0);
    final cx = size.width / 2;
    final slope = math.tan(angleRad); // 反向角度的斜率，使全局看起来水平

    // 过中心点 (cx, levelY) 的倾斜直线：y = levelY + slope * (x - cx)
    // 我们保留直线“下方”的区域（模拟液体）
    final y0 = levelY + slope * (0 - cx);
    final y1 = levelY + slope * (size.width - cx);

    final path = Path();
    path.moveTo(0, y0);
    path.lineTo(size.width, y1);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

// 倾斜线绘制器
class TiltLinePainter extends CustomPainter {
  final double tiltAngle;
  final double tiltPosition;

  TiltLinePainter({
    required this.tiltAngle,
    required this.tiltPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 计算液体表面线的位置和角度 - 与TiltClipper保持一致
    final tiltY = centerY + (size.height * 0.3 * (tiltPosition - 0.5));
    final tiltSlope = (tiltAngle - 0.5) * 2.0;
    
    final leftY = tiltY - tiltSlope * centerX;
    final rightY = tiltY + tiltSlope * centerX;
    
    // 确保切割线在画布范围内
    final startY = math.max(0.0, math.min(size.height, leftY)).toDouble();
    final endY = math.max(0.0, math.min(size.height, rightY)).toDouble();
    
    // 绘制液体表面线 - 使用贝塞尔曲线
    final path = Path();
    path.moveTo(0, startY);
    
    // 使用贝塞尔曲线创建自然的液体表面
    final controlPoint1 = Offset(size.width * 0.3, startY + (endY - startY) * 0.2);
    final controlPoint2 = Offset(size.width * 0.7, startY + (endY - startY) * 0.8);
    
    path.quadraticBezierTo(controlPoint1.dx, controlPoint1.dy, size.width * 0.5, (startY + endY) / 2);
    path.quadraticBezierTo(controlPoint2.dx, controlPoint2.dy, size.width, endY);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
