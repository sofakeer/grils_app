import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class ImprovedMaskTest extends StatefulWidget {
  @override
  _ImprovedMaskTestState createState() => _ImprovedMaskTestState();
}

class _ImprovedMaskTestState extends State<ImprovedMaskTest> {
  ui.Image? maskImage;
  bool isLoading = true;
  String? errorMessage;
  int currentBackgroundIndex = 0;
  double maskOpacity = 1.0;
  bool useInvertedMask = false;

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

  void _toggleInvertedMask() {
    setState(() {
      useInvertedMask = !useInvertedMask;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('改进版蒙版测试'),
        backgroundColor: Colors.pink[100],
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
                      _buildControlPanel(),
                      SizedBox(height: 24),
                      
                      // 蒙版效果展示
                      Text(
                        '蒙版效果展示',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      _buildImprovedMaskEffect(),
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
                      _buildExplanation(),
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
            '控制面板',
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

  Widget _buildImprovedMaskEffect() {
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
      child: Stack(
        children: [
          // 背景渐变
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: backgrounds[currentBackgroundIndex]['colors'],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // 改进的蒙版效果
          if (maskImage != null)
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return ImageShader(
                  maskImage!,
                  TileMode.clamp,
                  TileMode.clamp,
                  Matrix4.identity().storage,
                );
              },
              blendMode: useInvertedMask ? BlendMode.dstOut : BlendMode.dstIn,
              child: Opacity(
                opacity: maskOpacity,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
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

  Widget _buildExplanation() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '改进版蒙版效果说明:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800]),
          ),
          SizedBox(height: 8),
          Text(
            '• 白色区域显示背景内容\n• 黑色区域变成透明\n• 灰色区域显示半透明效果\n• 可调节蒙版透明度\n• 支持蒙版反转\n• 点击右上角按钮切换背景',
            style: TextStyle(fontSize: 14, color: Colors.blue[700]),
          ),
          SizedBox(height: 12),
          Text(
            '使用技巧:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[800]),
          ),
          SizedBox(height: 4),
          Text(
            '• 如果蒙版效果相反，请开启"反转蒙版"\n• 调整透明度可以获得更柔和的效果\n• 尝试不同的背景来找到最佳效果',
            style: TextStyle(fontSize: 12, color: Colors.blue[600]),
          ),
        ],
      ),
    );
  }
}
