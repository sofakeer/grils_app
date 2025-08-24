import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import 'package:grils_app/pages/win_page.dart';
import '../widgets/outlined_text_widget.dart';
import '../managers/game_state_manager.dart';
import '../widgets/unlock_new_gril_dialog.dart';
import '../managers/audio_manager.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _currentLevel = 1;
  int _simulatedLevel = 1; // 模拟关卡用于测试

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentLevel();
  }
  
  void _loadCurrentLevel() async {
    await GameStateManager().init();
    setState(() {
      _currentLevel = GameStateManager().getCurrentLevel();
      _simulatedLevel = _currentLevel;
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  void _passStage() async {
    // 通关逻辑
    int newLevel = await GameStateManager().passLevel();
    
    // 检查是否解锁新女生
    _checkForNewGirlUnlock(newLevel);
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const WinPage(),
      ),
    );
  }
  
  // 模拟通关到指定关卡
  void _simulatePassToLevel(int targetLevel) async {
    await GameStateManager().setCurrentLevel(targetLevel);
    setState(() {
      _currentLevel = targetLevel;
      _simulatedLevel = targetLevel;
    });
    
    // 检查是否解锁新女生
    _checkForNewGirlUnlock(targetLevel);
  }
  
  // 检查是否解锁新女生
  void _checkForNewGirlUnlock(int level) async {
    int? unlockedGirlIndex;
    
    // 检查100关解锁第二个女生
    if (level == 100 && !GameStateManager().isGirlUnlocked(1)) {
      unlockedGirlIndex = 1;
      await GameStateManager().unlockGirl(1);
    }
    // 检查300关解锁第三个女生
    else if (level == 300 && !GameStateManager().isGirlUnlocked(2)) {
      unlockedGirlIndex = 2;
      await GameStateManager().unlockGirl(2);
    }
    
    // 如果有新解锁的女生，显示弹窗
    if (unlockedGirlIndex != null && mounted) {
      await AudioManager().playPopupOpen();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UnlockNewGrilDialog(
          girlIndex: unlockedGirlIndex!,
          onAccept: () {
            Navigator.of(context).pop();
            // 跳转到预览页面
            Navigator.of(context).pushNamed('/spine_preview');
          },
          onDecline: () {
            Navigator.of(context).pop();
          },
        ),
      );
    }
  }

  // 构建模拟按钮
  Widget _buildSimulateButton(String text, int level, bool isUnlocked) {
    return GestureDetector(
      onTap: isUnlocked ? null : () => _simulatePassToLevel(level),
      child: Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          color: isUnlocked ? Colors.grey : Colors.blue,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedTextWidget(
                text: text,
                fontSize: 16,
                textColor: Colors.white,
                strokeColor: Colors.black,
                strokeWidth: 1.5,
                fontWeight: FontWeight.bold,
              ),
              if (isUnlocked)
                const OutlinedTextWidget(
                  text: '✓ Unlocked',
                  fontSize: 10,
                  textColor: Colors.greenAccent,
                  strokeColor: Colors.black,
                  strokeWidth: 1.0,
                  fontWeight: FontWeight.normal,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Assets.wincoinWinCoinBg),
            fit: BoxFit.cover,
          ),
        ),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 游戏标题和关卡显示
                    Container(
                      margin: const EdgeInsets.only(bottom: 50),
                      child: Column(
                        children: [
                          const OutlinedTextWidget(
                            text: 'GAME',
                            fontSize: 48,
                            textColor: Colors.white,
                            strokeColor: Colors.black,
                            strokeWidth: 3.0,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          OutlinedTextWidget(
                            text: 'Level $_currentLevel',
                            fontSize: 24,
                            textColor: Colors.yellow,
                            strokeColor: Colors.black,
                            strokeWidth: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                    ),

                    // Pass Stage 按钮
                    GestureDetector(
                      onTap: _passStage,
                      child: Container(
                        width: 250,
                        height: 80,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(Assets.wincoinWinCoinBtnGreen),
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: const Center(
                          child: OutlinedTextWidget(
                            text: 'PASS STAGE',
                            fontSize: 24,
                            textColor: Colors.white,
                            strokeColor: Colors.black,
                            strokeWidth: 2.0,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // 模拟关卡按钮组
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const OutlinedTextWidget(
                            text: 'Test Unlock Girls:',
                            fontSize: 18,
                            textColor: Colors.white70,
                            strokeColor: Colors.black,
                            strokeWidth: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 模拟到100关按钮
                              _buildSimulateButton(
                                'Lv 100',
                                100,
                                GameStateManager().isGirlUnlocked(1),
                              ),
                              const SizedBox(width: 20),
                              // 模拟到300关按钮
                              _buildSimulateButton(
                                'Lv 300',
                                300,
                                GameStateManager().isGirlUnlocked(2),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
