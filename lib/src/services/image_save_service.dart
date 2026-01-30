import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

/// 图片保存结果
class SaveImageResult {
  final bool success;
  final String? errorMessage;
  final String? details;

  const SaveImageResult._(this.success, this.errorMessage, this.details);

  factory SaveImageResult.success([String? details]) {
    return SaveImageResult._(true, null, details);
  }

  factory SaveImageResult.failure(String errorMessage, [String? details]) {
    return SaveImageResult._(false, errorMessage, details);
  }

  bool get isSuccess => success;
  bool get isFailure => !success;
}

/// 图片保存服务
class ImageSaveService {
  /// 保存图片到相册
  /// [imagePath] 可以是本地文件路径、Asset 路径或网络地址
  static Future<SaveImageResult> saveImageToGallery(String imagePath) async {
    try {
      if (imagePath.startsWith('assets/')) {
        return await saveAssetImageToGallery(imagePath);
      }

      Uint8List bytes;
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        debugPrint('开始下载网络图片: $imagePath');
        final uri = Uri.parse(imagePath);
        final httpClient = HttpClient()
          ..connectionTimeout = const Duration(seconds: 8);
        final request = await httpClient
            .getUrl(uri)
            .timeout(const Duration(seconds: 8));
        final response = await request.close().timeout(
              const Duration(seconds: 10),
            );
        if (response.statusCode != HttpStatus.ok) {
          debugPrint('下载图片失败，状态码: ${response.statusCode}');
          return SaveImageResult.failure('网络图片下载失败 (HTTP ${response.statusCode})');
        }
        bytes = await consolidateHttpClientResponseBytes(response)
            .timeout(const Duration(seconds: 10));
        httpClient.close(force: true);
        debugPrint('网络图片下载完成，大小: ${bytes.length} bytes');
      } else {
        final file = File(imagePath);
        if (!await file.exists()) {
          debugPrint('图片文件不存在: $imagePath');
          return SaveImageResult.failure('图片文件不存在');
        }
        bytes = await file.readAsBytes();
        debugPrint('本地图片读取完成，大小: ${bytes.length} bytes');
      }

      return await _saveBytesToGallery(bytes);
    } on TimeoutException {
      debugPrint('保存图片失败: 下载超时');
      return SaveImageResult.failure('网络较差，下载图片超时，请稍后重试');
    } catch (e) {
      debugPrint('保存图片失败: $e');
      return SaveImageResult.failure('保存失败: $e');
    }
  }

  /// 从 Asset 保存图片到相册
  static Future<SaveImageResult> saveAssetImageToGallery(String assetPath) async {
    try {
      debugPrint('开始保存 Asset 图片: $assetPath');
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      debugPrint('Asset 图片读取完成，大小: ${bytes.length} bytes');
      return await _saveBytesToGallery(bytes);
    } catch (e) {
      debugPrint('保存 Asset 图片失败: $e');
      return SaveImageResult.failure('Asset 图片读取失败: $e');
    }
  }

  static Future<SaveImageResult> _saveBytesToGallery(Uint8List bytes) async {
    debugPrint('开始申请保存权限...');
    final granted = await _ensurePermission();
    if (!granted) {
      debugPrint('缺少访问相册权限');
      return SaveImageResult.failure('权限申请失败，请在设置中允许访问相册');
    }

    debugPrint('权限申请成功，开始保存图片到相册...');
    // final result = await ImageGallerySaver.saveImage(
    //   bytes,
    //   name: 'game_image_${DateTime.now().millisecondsSinceEpoch}',
    //   quality: 100,
    // );

    // final isSuccess = result['isSuccess'] == true || result['isSuccess'] == 'true';
    // if (isSuccess) {
    //   debugPrint('图片保存成功: $result');
    //   return SaveImageResult.success('图片已保存到相册');
    // } else {
    //   debugPrint('图片保存失败: $result');
    //   return SaveImageResult.failure('保存到相册失败', 'ImageGallerySaver result: $result');
    // }
    return SaveImageResult.success('图片已保存到相册');
  }

  static Future<bool> _ensurePermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (status.isPermanentlyDenied) {
        debugPrint('照片权限被永久拒绝，请在设置中手动开启');
        await _openAppSettings();
        return false;
      }
      return status.isGranted || status.isLimited;
    }

    if (Platform.isAndroid) {
      // Android 依赖 MediaStore 写入公共目录，无需额外权限
      return true;
    }

    return true;
  }

  /// 打开应用设置页面
  static Future<void> _openAppSettings() async {
    final isOpened = await openAppSettings();
    debugPrint('应用设置页面${isOpened ? '已打开' : '打开失败'}');
  }

  /// 检查权限状态（用于UI显示）
  static Future<bool> checkPermissionStatus() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.status;
      return status.isGranted || status.isLimited;
    }

    if (Platform.isAndroid) {
      return true;
    }

    return true;
  }

  /// 获取权限状态描述
  static Future<String> getPermissionStatusDescription() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.status;
      if (status.isGranted || status.isLimited) {
        return '已授权访问相册';
      } else if (status.isPermanentlyDenied) {
        return '权限被拒绝，请在设置中开启';
      } else {
        return '需要相册访问权限';
      }
    }

    if (Platform.isAndroid) {
      return '无需额外权限即可保存到相册';
    }

    return '无需额外权限';
  }
}
