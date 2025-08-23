import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class OptimizedMaskTest extends StatefulWidget {
  @override
  _OptimizedMaskTestState createState() => _OptimizedMaskTestState();
}

class _OptimizedMaskTestState extends State<OptimizedMaskTest> {
  ui.Image? maskImage;
  bool isLoading = true;
  String? errorMessage;
  int currentBackgroundIndex = 0;
  double maskOpacity = 1.0;
  bool useInvertedMask = false;
  bool useEnhancedMask = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('优化蒙版测试'),
        backgroundColor: Colors.orange[100],
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
                      _buildOptimizedControlPanel(),
                      SizedBox(height: 24),
                      
                      // 蒙版效果展示
                      Text(
                        '优化蒙版效果展示',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      _buildOptimizedMaskEffect(),
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
                      _buildOptimizedExplanation(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOptimizedControlPanel() {
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
            '优化控制面板',
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
          
          // 增强蒙版开关
          Row(
            children: [
              Icon(Icons.auto_fix_high, color: Colors.green[300]),
              SizedBox(width: 8),
              Text('增强蒙版效果'),
              Spacer(),
              Switch(
                value: useEnhancedMask,
                onChanged: (value) {
                  setState(() {
                    useEnhancedMask = value;
                  });
                },
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

  Widget _buildOptimizedMaskEffect() {
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
          // 优化的蒙版效果
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
          // 增强效果层
          if (useEnhancedMask && maskImage != null)
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return ImageShader(
                  maskImage!,
                  TileMode.clamp,
                  TileMode.clamp,
                  Matrix4.identity().storage,
                );
              },
              blendMode: BlendMode.overlay,
              child: Opacity(
                opacity: 0.3,
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

  Widget _buildOptimizedExplanation() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '优化蒙版效果说明:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange[800]),
          ),
          SizedBox(height: 8),
          Text(
            '• 使用多层ShaderMask实现更清晰的效果\n• 增强蒙版功能提供额外的细节\n• 可调节蒙版透明度\n• 支持蒙版反转\n• 优化的渲染性能',
            style: TextStyle(fontSize: 14, color: Colors.orange[700]),
          ),
          SizedBox(height: 12),
          Text(
            '优化特性:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange[800]),
          ),
          SizedBox(height: 4),
          Text(
            '• 增强蒙版: 添加额外的overlay层增加细节\n• 多层渲染: 使用多个ShaderMask层\n• 性能优化: 减少不必要的重绘\n• 更好的边缘处理',
            style: TextStyle(fontSize: 12, color: Colors.orange[600]),
          ),
        ],
      ),
    );
  }
}
