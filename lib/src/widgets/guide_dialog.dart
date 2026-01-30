import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/image_loader_service.dart';
import '../providers/user_type_provider.dart';
import '../widgets/small_button.dart';
import '../providers/guide_providers.dart';
import '../features/photo_album/photo_set_page.dart';
import '../features/treasure/treasure_page.dart';

/// 引导弹窗类型
enum GuideDialogType {
  photoSet, // 套图引导
  treasure, // 通行证引导
}

/// 引导弹窗组件
class GuideDialog extends ConsumerStatefulWidget {
  final GuideDialogType type;

  const GuideDialog({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<GuideDialog> createState() => _GuideDialogState();
}

class _GuideDialogState extends ConsumerState<GuideDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  List<String> _imageIds = [];
  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    _animationController.forward();
    _loadImages();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 加载图片
  Future<void> _loadImages() async {
    if (widget.type == GuideDialogType.photoSet) {
      // 套图引导：加载前4个套图的第1张图片
      _imageIds = [
        'secret_1_1', // 套图1的第1张
        'secret_2_1', // 套图2的第1张
        'secret_3_1', // 套图3的第1张
        'secret_4_1', // 套图4的第1张
      ];
    } else {
      // 通行证引导：加载通行证第1张图片
      _imageIds = ['pass_c_1'];
    }

    setState(() {
      _imagesLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userType = ref.read(userTypeProvider);

    return WillPopScope(
      onWillPop: () async => false, // 禁止返回键关闭
      child: Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero, // 去掉外间距
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(30),
            color: Colors.black,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // 标题
                  Text(
                    widget.type == GuideDialogType.photoSet
                        ? 'PRIVATE PHOTO SETS'
                        : 'PASS MODE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 图片展示区域 - 使用 Expanded 占据剩余空间
                  Expanded(
                    child: _buildImageArea(userType),
                  ),
                  const SizedBox(height: 20),
                  // 按钮固定在底部
                  SmallButton(
                    text: 'GO',
                    width: 200,
                   
                    style: SmallButtonStyle.green,
                    size: SmallButtonSize.large,
                    onPressed: () => _onButtonTap(context),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建图片展示区域
  Widget _buildImageArea(UserType userType) {
    if (!_imagesLoaded) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (widget.type == GuideDialogType.photoSet) {
      // 套图引导：显示4张图片，2x2网格，自适应空间
      return LayoutBuilder(
        builder: (context, constraints) {
          // 计算每个图片的尺寸，确保 2x2 网格能完整显示
          final spacing = 12.0;
          final availableWidth = constraints.maxWidth - spacing;
          final availableHeight = constraints.maxHeight - spacing;
          // 取较小值确保图片不超出
          final cellWidth = (availableWidth - spacing) / 2;
          final cellHeight = (availableHeight - spacing) / 2;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              // 根据可用空间计算宽高比
              childAspectRatio: cellWidth / cellHeight,
            ),
            itemCount: _imageIds.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SmartImageWidget(
                    imageId: _imageIds[index],
                    userType: userType,
                    fit: BoxFit.contain, // 使用 contain 确保图片完整显示
                    errorWidget: Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.image,
                        color: Colors.white54,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      // 通行证引导：显示1张图片，居中
      return Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SmartImageWidget(
              imageId: _imageIds.first,
              userType: userType,
              fit: BoxFit.contain, // 使用 contain 确保图片完整显示
              errorWidget: Container(
                color: Colors.grey[800],
                child: const Icon(
                  Icons.image,
                  color: Colors.white54,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  /// 按钮点击处理
  void _onButtonTap(BuildContext context) {
    final guideController = ref.read(guideProvider.notifier);

    if (widget.type == GuideDialogType.photoSet) {
      // 标记已看过套图引导和已进入套图页面
      guideController.markPhotoSetGuideShown();
      guideController.markPhotoSetPageEntered();
      // 导航到套图页面
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PhotoSetPage()),
      );
    } else {
      // 标记已看过通行证引导和已进入通行证页面
      guideController.markTreasureGuideShown();
      guideController.markTreasurePageEntered();
      // 导航到通行证页面
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TreasurePage()),
      );
    }
  }
}

/// 显示套图引导弹窗
Future<void> showPhotoSetGuideDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const GuideDialog(type: GuideDialogType.photoSet),
  );
}

/// 显示通行证引导弹窗
Future<void> showTreasureGuideDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const GuideDialog(type: GuideDialogType.treasure),
  );
}
