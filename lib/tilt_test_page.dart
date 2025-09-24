import 'package:flutter/material.dart';
import 'dart:math' as math;

class TiltTestPage extends StatefulWidget {
  @override
  _TiltTestPageState createState() => _TiltTestPageState();
}

class _TiltTestPageState extends State<TiltTestPage> {
  static const String _outerBottleAsset = 'assets/images/boll.png';
  static const String _innerBottleAsset = 'assets/images/boll_inner.png';

  double tiltAngle = 0.3;
  double tiltPosition = 0.5;
  int currentImageIndex = 0;
  int currentTiltMode = 0; // 0: 简单倾斜, 1: 瓶子倾斜
  double bottleAngle = 0.0; // 瓶子旋转角度（弧度比例 0..1 -> 0..90°）
  double fillLevel = 0.6; // 液位高度（0 顶部，1 底部）

  final List<Map<String, dynamic>> images = [
    {
      'name': '瓶子外部',
      'path': _outerBottleAsset,
    },
    {
      'name': '瓶子内部',
      'path': _innerBottleAsset,
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
    const canvasSize = 260.0;
    final bottleAngleRad = bottleAngle * math.pi / 2;
    final fluidWobble = (tiltAngle - 0.5) * (math.pi / 4);
    final fluidAngleRad = -(bottleAngleRad + fluidWobble);
    final sloshOffset = (0.5 - tiltPosition) * 0.25;
    final dynamicLevel = (fillLevel + sloshOffset).clamp(0.0, 1.0);

    return Container(
      width: 300,
      height: 320,
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
            child: currentTiltMode == 0
                ? _buildSimpleTiltDemo(
                    size: canvasSize,
                    level: dynamicLevel,
                    fluidAngleRad: fluidAngleRad,
                  )
                : _buildBottleTiltDemo(
                    canvasSize: canvasSize,
                    bottleAngleRad: bottleAngleRad,
                    fluidAngleRad: fluidAngleRad,
                    level: dynamicLevel,
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

  Widget _buildSimpleTiltDemo({
    required double size,
    required double level,
    required double fluidAngleRad,
  }) {
    final backgroundGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    );

    final liquidGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x994DD0E1), Color(0xFF0097A7)],
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(gradient: backgroundGradient),
            ),
          ),
          Positioned.fill(
            child: ClipPath(
              clipper: _LiquidClipper(
                level: level,
                angleRad: fluidAngleRad,
              ),
              child: Container(
                decoration: BoxDecoration(gradient: liquidGradient),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _LiquidSurfacePainter(
                level: level,
                angleRad: fluidAngleRad,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottleTiltDemo({
    required double canvasSize,
    required double bottleAngleRad,
    required double fluidAngleRad,
    required double level,
  }) {
    return SizedBox(
      width: canvasSize,
      height: canvasSize + 40,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Transform.rotate(
            angle: bottleAngleRad,
            alignment: const Alignment(0, -0.85),
            child: SizedBox(
              width: canvasSize,
              height: canvasSize,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipPath(
                      clipper: _BottleClipper(),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              _innerBottleAsset,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned.fill(
                            child: ClipPath(
                              clipper: _LiquidClipper(
                                level: level,
                                angleRad: fluidAngleRad,
                              ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF4DD0E1),
                                      Color(0xFF0097A7),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _LiquidSurfacePainter(
                                level: level,
                                angleRad: fluidAngleRad,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Image.asset(
                        _outerBottleAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
      centerX + width * 0.3,
      centerY + height * 0.2,
      centerX + width * 0.25,
      centerY - height * 0.1,
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
      centerX - width * 0.25,
      centerY - height * 0.1,
      centerX - width * 0.3,
      centerY + height * 0.2,
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

class _LiquidSurfacePainter extends CustomPainter {
  final double level;
  final double angleRad;

  _LiquidSurfacePainter({required this.level, required this.angleRad});

  @override
  void paint(Canvas canvas, Size size) {
    final clampedLevel = level.clamp(0.0, 1.0);
    final levelY = size.height * clampedLevel;
    final centerX = size.width / 2;
    final slope = math.tan(angleRad);

    final startY = levelY + slope * (0 - centerX);
    final endY = levelY + slope * (size.width - centerX);

    final surfacePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, startY), Offset(size.width, endY), surfacePaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidSurfacePainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.angleRad != angleRad;
  }
}
