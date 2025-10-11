import 'package:flutter/material.dart';
import 'package:grils_app/generated/assets.dart';
import '../widgets/outlined_text_widget.dart';
import '../managers/audio_manager.dart';

class SpecialGamePage extends StatefulWidget {
  const SpecialGamePage({super.key});

  @override
  State<SpecialGamePage> createState() => _SpecialGamePageState();
}

class _SpecialGamePageState extends State<SpecialGamePage> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  int _score = 0;
  int _targetScore = 100;
  bool _isGameComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // 播放特殊关卡游戏音效
    AudioManager().playSpecialEffect();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _scaleController.forward();
  }

  void _addScore() async {
    if (_isGameComplete) return;
    
    setState(() {
      _score += 10;
    });
    
    // 播放得分音效
    await AudioManager().playCoinEffect();
    
    // 检查是否完成游戏
    if (_score >= _targetScore) {
      _completeGame();
    }
  }

  void _completeGame() async {
    setState(() {
      _isGameComplete = true;
    });

    // 播放完成音效
    await AudioManager().playSettlementCoin();

    // 延迟后返回 true 表示游戏完成
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // 返回 true 表示特殊关卡完成
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 标题
                  const OutlinedTextWidget(
                    text: 'SPECIAL STAGE',
                    fontSize: 32,
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
                  
                  const SizedBox(height: 40),
                  
                  // 分数显示
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Column(
                      children: [
                        OutlinedTextWidget(
                          text: 'Score: $_score / $_targetScore',
                          fontSize: 24,
                          textColor: Colors.yellow,
                          strokeColor: Colors.black,
                          strokeWidth: 2.0,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: _score / _targetScore,
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellow),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // 游戏按钮
                  if (!_isGameComplete)
                    GestureDetector(
                      onTap: _addScore,
                      child: Container(
                        width: 200,
                        height: 80,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(Assets.wincoinWinCoinBtnGreen),
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: const Center(
                          child: OutlinedTextWidget(
                            text: 'TAP TO SCORE',
                            fontSize: 20,
                            textColor: Colors.white,
                            strokeColor: Colors.black,
                            strokeWidth: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  if (_isGameComplete)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const OutlinedTextWidget(
                        text: 'STAGE COMPLETE!',
                        fontSize: 24,
                        textColor: Colors.white,
                        strokeColor: Colors.black,
                        strokeWidth: 2.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
