import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/image_loader_service.dart';
import '../providers/user_type_provider.dart';
import '../features/photo_album/photo_set_providers.dart';
import '../providers/guide_providers.dart';
import '../features/photo_album/photo_set_page.dart';
import '../features/treasure/treasure_page.dart';

/// 套图/通行证引导弹窗
class AlbumPassGuideDialog extends ConsumerWidget {
  final GuideType type;

  const AlbumPassGuideDialog({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                type == GuideType.album ? '发现套图' : '发现通行证',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            // 图片预览区域
            Expanded(
              child: _buildImagePreview(context, ref),
            ),
            // 按钮
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final guideNotifier = ref.read(guideProvider.notifier);
                    if (type == GuideType.album) {
                      await guideNotifier.markPhotoSetGuideShown();
                      await guideNotifier.markPhotoSetPageEntered();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PhotoSetPage()),
                        );
                      }
                    } else {
                      await guideNotifier.markTreasureGuideShown();
                      await guideNotifier.markTreasurePageEntered();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TreasurePage()),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    type == GuideType.album ? '查看套图' : '查看通行证',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, WidgetRef ref) {
    final userType = ref.watch(userTypeProvider);
    
    if (type == GuideType.album) {
      // 套图引导：加载前3个套图的第1张图片
      return _buildAlbumPreview(context, ref, userType);
    } else {
      // 通行证引导：加载通行证第1张图片
      return _buildPassPreview(context, ref, userType);
    }
  }

  Widget _buildAlbumPreview(BuildContext context, WidgetRef ref, UserType userType) {
    final setsAsync = ref.watch(photoSetProvider);
    
    return setsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Icon(Icons.error)),
      data: (sets) {
        // 取前3个套图
        final displaySets = sets.take(3).toList();
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: displaySets.map((set) {
            final firstSlot = set.slots.firstOrNull;
            if (firstSlot == null) return const SizedBox.shrink();
            
            final imageId = userType == UserType.paid 
                ? 'secret_${set.setId}_${firstSlot.index}' 
                : null;
            
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 0.65,
                    child: SmartImageWidget(
                      imageId: imageId,
                      imagePath: firstSlot.assetPath,
                      userType: userType,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPassPreview(BuildContext context, WidgetRef ref, UserType userType) {
    const treasureImageId = 'pass_c_1'; // 通行证第1张图片
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 0.65,
          child: SmartImageWidget(
            imageId: treasureImageId,
            userType: userType,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

enum GuideType {
  album,
  pass,
}

/// 显示引导弹窗
Future<void> showGuideDialog(BuildContext context, GuideType type) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlbumPassGuideDialog(type: type),
  );
}
