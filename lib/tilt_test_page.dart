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
              '倾斜切割效果',
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
            '倾斜切割控制面板',
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
          
          // 倾斜角度控制
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
          
          // 倾斜位置控制
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
          color: Colors.grey[300],
          child: Center(
            child: ClipPath(
              clipper: TiltClipper(
                tiltAngle: tiltAngle,
                tiltPosition: tiltPosition,
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Image.asset(
                  images[currentImageIndex]['path'],
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
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

  TiltClipper({
    required this.tiltAngle,
    required this.tiltPosition,
  });

  @override
  Path getClip(Size size) {
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
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 计算倾斜线的位置和角度
    final tiltY = centerY + (size.height * 0.3 * (tiltPosition - 0.5));
    final tiltSlope = (tiltAngle - 0.5) * 3;
    
    final leftY = tiltY - tiltSlope * centerX;
    final rightY = tiltY + tiltSlope * centerX;
    
    // 确保切割线在画布范围内
    final startY = math.max(0.0, math.min(size.height, leftY)).toDouble();
    final endY = math.max(0.0, math.min(size.height, rightY)).toDouble();
    
    // 绘制切割线
    canvas.drawLine(
      Offset(0, startY),
      Offset(size.width, endY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
