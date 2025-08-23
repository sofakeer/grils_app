import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class SimpleMaskTest extends StatefulWidget {
  @override
  _SimpleMaskTestState createState() => _SimpleMaskTestState();
}

class _SimpleMaskTestState extends State<SimpleMaskTest> {
  ui.Image? maskImage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMaskImage();
  }

  Future<void> loadMaskImage() async {
    try {
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
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('简单蒙版测试'),
        backgroundColor: Colors.pink[100],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '蒙版效果测试',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 32),
                  
                  // 蒙版效果
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        // 背景渐变
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue[200]!,
                                Colors.purple[200]!,
                                Colors.pink[200]!,
                              ],
                            ),
                          ),
                        ),
                        // 蒙版效果
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
                            blendMode: BlendMode.dstIn,
                            child: Container(
                              width: 200,
                              height: 200,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  
                  // 原始图片
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/Girl01_chage_Btn_All/Btn_gril01_bra_1_unlock.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
