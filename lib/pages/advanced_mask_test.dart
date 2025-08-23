import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class AdvancedMaskTest extends StatefulWidget {
  @override
  _AdvancedMaskTestState createState() => _AdvancedMaskTestState();
}

class _AdvancedMaskTestState extends State<AdvancedMaskTest> {
  ui.Image? maskImage;
  bool isLoading = true;
  String? errorMessage;
  int currentBackgroundIndex = 0;
  double maskOpacity = 1.0;
  bool useInvertedMask = false;
  BlendMode currentBlendMode = BlendMode.dstIn;

  // 定义不同的背景选项
  final List<Map<String, dynamic>> backgrounds = [
    {
      'name': '蓝色渐变',
      'colors': [Colors.blue[200]!, Colors.purple[200]!, Colors.pink[200]!],
    },
    {
      'name': '彩虹渐变',
      'colors': [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.indigo, Colors.purple],
    },
    {
      'name': '粉色系',
      'colors': [Colors.pink[100]!, Colors.pink[300]!, Colors.pink[500]!],
    },
    {
      'name': '金色渐变',
      'colors': [Colors.amber[300]!, Colors.orange[300]!, Colors.red[300]!],
    },
    {
      'name': '绿色渐变',
      'colors': [Colors.green[200]!, Colors.teal[200]!, Colors.cyan[200]!],
    },
  ];

  // 可用的混合模式
  final List<Map<String, dynamic>> blendModes = [
    {'name': 'dstIn', 'mode': BlendMode.dstIn},
    {'name': 'dstOut', 'mode': BlendMode.dstOut},
    {'name': 'srcIn', 'mode': BlendMode.srcIn},
    {'name': 'srcOut', 'mode': BlendMode.srcOut},
    {'name': 'multiply', 'mode': BlendMode.multiply},
    {'name': 'screen', 'mode': BlendMode.screen},
    {'name': 'overlay', 'mode': BlendMode.overlay},
    {'name': 'darken', 'mode': BlendMode.darken},
    {'name': 'lighten', 'mode': BlendMode.lighten},
  ];

  @override
  void initState() {
    super.initState();
    loadMaskImage();
  }

  Future<void> loadMaskImage() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // 加载蒙版图片
      final maskData = await rootBundle.load('assets/images/Girl01_chage_Btn_All/Btn_gril01_bra_1_unlock.png');
      final maskCodec = await ui.instantiateImageCodec(maskData.buffer.asUint8List());
      final maskFrame = await maskCodec.getNextFrame();
      
      setState(() {
        maskImage = maskFrame.image;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading mask image: $e');
      setState(() {
        errorMessage = '加载图片失败: $e';
        isLoading = false;
      });
    }
  }

  void _changeBackground() {
    setState(() {
      currentBackgroundIndex = (currentBackgroundIndex + 1) % backgrounds.length;
    });
  }

  void _changeBlendMode(BlendMode mode) {
    setState(() {
      currentBlendMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('高级蒙版测试'),
        backgroundColor: Colors.purple[100],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _changeBackground,
            tooltip: '切换背景',
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('加载中...'),
                ],
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: loadMaskImage,
                        child: Text('重试'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 控制面板
                      _buildAdvancedControlPanel(),
                      SizedBox(height: 24),
                      
                      // 蒙版效果展示
                      Text(
                        '高级蒙版效果展示',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      _buildAdvancedMaskEffect(),
                      SizedBox(height: 32),
                      
                      // 原始蒙版图片
                      Text(
                        '原始蒙版图片',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      _buildOriginalMaskImage(),
                      SizedBox(height: 32),
                      
                      // 说明文字
                      _buildAdvancedExplanation(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAdvancedControlPanel() {
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
            '高级控制面板',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          
          // 当前背景
          Row(
            children: [
              Icon(Icons.palette, color: Colors.pink[300]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '当前背景: ${backgrounds[currentBackgroundIndex]['name']}',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // 蒙版透明度
          Row(
            children: [
              Icon(Icons.opacity, color: Colors.blue[300]),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('蒙版透明度: ${(maskOpacity * 100).toInt()}%'),
                    Slider(
                      value: maskOpacity,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (value) {
                        setState(() {
                          maskOpacity = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // 混合模式选择
          Row(
            children: [
              Icon(Icons.filter, color: Colors.green[300]),
              SizedBox(width: 8),
              Text('混合模式:'),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButton<BlendMode>(
                  value: currentBlendMode,
                  isExpanded: true,
                  items: blendModes.map((blend) {
                    return DropdownMenuItem<BlendMode>(
                      value: blend['mode'],
                      child: Text(blend['name']),
                    );
                  }).toList(),
                  onChanged: (BlendMode? newValue) {
                    if (newValue != null) {
                      _changeBlendMode(newValue);
                    }
                  },
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          // 反转蒙版开关
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

  Widget _buildAdvancedMaskEffect() {
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
      child: CustomPaint(
        size: Size(300, 300),
        painter: AdvancedMaskPainter(
          maskImage: maskImage,
          backgroundColors: backgrounds[currentBackgroundIndex]['colors'],
          maskOpacity: maskOpacity,
          blendMode: useInvertedMask ? BlendMode.dstOut : currentBlendMode,
        ),
      ),
    );
  }

  Widget _buildOriginalMaskImage() {
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
          'assets/images/Girl01_chage_Btn_All/Btn_gril01_bra_1_unlock.png',
          width: 300,
          height: 300,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildAdvancedExplanation() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '高级蒙版效果说明:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple[800]),
          ),
          SizedBox(height: 8),
          Text(
            '• 使用CustomPainter实现更精确的控制\n• 支持多种混合模式\n• 可调节蒙版透明度\n• 支持蒙版反转\n• 实时预览效果',
            style: TextStyle(fontSize: 14, color: Colors.purple[700]),
          ),
          SizedBox(height: 12),
          Text(
            '混合模式说明:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purple[800]),
          ),
          SizedBox(height: 4),
          Text(
            '• dstIn: 使用蒙版图片的alpha通道\n• dstOut: 反转的dstIn效果\n• srcIn: 使用源图片的alpha通道\n• multiply: 乘法混合\n• screen: 屏幕混合',
            style: TextStyle(fontSize: 12, color: Colors.purple[600]),
          ),
        ],
      ),
    );
  }
}

class AdvancedMaskPainter extends CustomPainter {
  final ui.Image? maskImage;
  final List<Color> backgroundColors;
  final double maskOpacity;
  final BlendMode blendMode;

  AdvancedMaskPainter({
    this.maskImage,
    required this.backgroundColors,
    required this.maskOpacity,
    required this.blendMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (maskImage == null) return;

    // 保存画布状态
    canvas.save();

    // 创建背景渐变
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: backgroundColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // 绘制背景
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // 设置混合模式
    final maskPaint = Paint()
      ..blendMode = blendMode
      ..color = Colors.white.withOpacity(maskOpacity);

    // 计算图片的缩放和位置，使其居中显示
    final imageAspectRatio = maskImage!.width / maskImage!.height;
    final containerAspectRatio = size.width / size.height;
    
    double drawWidth, drawHeight, offsetX, offsetY;
    
    if (imageAspectRatio > containerAspectRatio) {
      // 图片更宽，以宽度为准
      drawWidth = size.width;
      drawHeight = size.width / imageAspectRatio;
      offsetX = 0;
      offsetY = (size.height - drawHeight) / 2;
    } else {
      // 图片更高，以高度为准
      drawHeight = size.height;
      drawWidth = size.height * imageAspectRatio;
      offsetX = (size.width - drawWidth) / 2;
      offsetY = 0;
    }

    // 绘制蒙版图片
    canvas.drawImageRect(
      maskImage!,
      Rect.fromLTWH(0, 0, maskImage!.width.toDouble(), maskImage!.height.toDouble()),
      Rect.fromLTWH(offsetX, offsetY, drawWidth, drawHeight),
      maskPaint,
    );

    // 恢复画布状态
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // 总是重绘以获得最佳效果
  }
}
