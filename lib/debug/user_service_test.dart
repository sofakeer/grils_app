import 'package:flutter/material.dart';
import 'package:grils_app/services/user_service.dart';
import 'package:grils_app/widgets/outlined_text_widget.dart';

/// UserService测试工具页面
class UserServiceTestPage extends StatefulWidget {
  const UserServiceTestPage({super.key});

  @override
  State<UserServiceTestPage> createState() => _UserServiceTestPageState();
}

class _UserServiceTestPageState extends State<UserServiceTestPage> {
  late UserService _userService;

  @override
  void initState() {
    super.initState();
    _userService = UserService.instance;
    _userService.addListener(_onUserDataChanged);
    _initializeUserService();
  }

  void _initializeUserService() async {
    await _userService.initialize();
    print("UserServiceTest: 初始化完成");
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _userService.removeListener(_onUserDataChanged);
    super.dispose();
  }

  void _onUserDataChanged() {
    print("UserServiceTest: 数据变化 - 金币: ${_userService.coinCount}, 爱心: ${_userService.heartCount}");
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UserService 测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 当前状态显示
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                children: [
                  OutlinedTextWidget(
                    text: '当前状态',
                    fontSize: 20,
                    textColor: Colors.blue,
                    strokeColor: Colors.white,
                    strokeWidth: 1.0,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          OutlinedTextWidget(
                            text: '金币',
                            fontSize: 16,
                            textColor: Colors.orange,
                            strokeColor: Colors.white,
                            strokeWidth: 1.0,
                          ),
                          const SizedBox(height: 5),
                          OutlinedTextWidget(
                            text: '${_userService.coinCount}',
                            fontSize: 24,
                            textColor: Colors.orange,
                            strokeColor: Colors.black,
                            strokeWidth: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          OutlinedTextWidget(
                            text: '爱心',
                            fontSize: 16,
                            textColor: Colors.red,
                            strokeColor: Colors.white,
                            strokeWidth: 1.0,
                          ),
                          const SizedBox(height: 5),
                          OutlinedTextWidget(
                            text: '${_userService.heartCount}',
                            fontSize: 24,
                            textColor: Colors.red,
                            strokeColor: Colors.black,
                            strokeWidth: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 操作按钮
            OutlinedTextWidget(
              text: '操作测试',
              fontSize: 18,
              textColor: Colors.black,
              strokeColor: Colors.white,
              strokeWidth: 1.0,
              fontWeight: FontWeight.bold,
            ),
            
            const SizedBox(height: 20),
            
            // 金币操作
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _userService.addCoins(100);
                      print("添加100金币");
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('金币 +100', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _userService.spendCoins(50);
                      print("消费50金币");
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('金币 -50', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // 爱心操作
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _userService.addHearts(10);
                      print("添加10爱心");
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                    child: const Text('爱心 +10', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _userService.spendHearts(5);
                      print("消费5爱心");
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    child: const Text('爱心 -5', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // 重置按钮
            ElevatedButton(
              onPressed: () async {
                await _userService.resetUserData();
                print("重置用户数据");
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('重置数据', style: TextStyle(color: Colors.white)),
            ),
            
            const SizedBox(height: 20),
            
            // 说明文字
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.yellow),
              ),
              child: const OutlinedTextWidget(
                text: '点击按钮测试UserService的功能\n查看控制台输出了解详细信息',
                fontSize: 14,
                textColor: Colors.orange,
                strokeColor: Colors.white,
                strokeWidth: 0.5,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}