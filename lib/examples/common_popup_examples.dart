import 'package:flutter/material.dart';
import '../widgets/common_popup.dart';

/// 通用弹窗使用示例
class CommonPopupExamples {
  
  /// 示例1：基础弹窗
  static void showBasicPopup(BuildContext context) {
    CommonPopup.show(
      context: context,
      title: '提示',
      content: const Text(
        '这是一个基础弹窗示例',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      buttons: [
        CommonPopupButton(
          text: '确定',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  /// 示例2：确认弹窗
  static Future<bool> showConfirmPopup(BuildContext context) async {
    return await CommonPopup.showConfirm(
      context: context,
      title: '确认操作',
      content: '您确定要执行此操作吗？',
      confirmText: '确定',
      cancelText: '取消',
      onConfirm: () {
        print('用户点击了确定');
      },
      onCancel: () {
        print('用户点击了取消');
      },
    );
  }

  /// 示例3：提示弹窗
  static void showAlertPopup(BuildContext context) {
    CommonPopup.showAlert(
      context: context,
      title: '提示',
      content: '操作已完成！',
      buttonText: '知道了',
      onPressed: () {
        print('用户确认了提示');
      },
    );
  }

  /// 示例4：多按钮弹窗
  static void showMultiButtonPopup(BuildContext context) {
    CommonPopup.show(
      context: context,
      title: '选择操作',
      content: const Text(
        '请选择您要执行的操作：',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      buttons: [
        CommonPopupButton(
          text: '保存',
          type: CommonPopupButtonType.primary,
          onPressed: () {
            print('用户点击了保存');
            Navigator.pop(context);
          },
        ),
        CommonPopupButton(
          text: '取消',
          type: CommonPopupButtonType.secondary,
          onPressed: () {
            print('用户点击了取消');
            Navigator.pop(context);
          },
        ),
        CommonPopupButton(
          text: '删除',
          type: CommonPopupButtonType.danger,
          onPressed: () {
            print('用户点击了删除');
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  /// 示例5：自定义尺寸弹窗
  static void showCustomSizePopup(BuildContext context) {
    CommonPopup.show(
      context: context,
      title: '自定义尺寸',
      content: const Text(
        '这是一个自定义尺寸的弹窗',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      width: 300,
      height: 400,
      buttons: [
        CommonPopupButton(
          text: '确定',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  /// 示例6：无关闭按钮弹窗
  static void showNoCloseButtonPopup(BuildContext context) {
    CommonPopup.show(
      context: context,
      title: '重要提示',
      content: const Text(
        '这是一个重要的提示，必须通过按钮关闭',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      showCloseButton: false,
      barrierDismissible: false, // 禁止点击背景关闭
      buttons: [
        CommonPopupButton(
          text: '我知道了',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  /// 示例7：复杂内容弹窗
  static void showComplexContentPopup(BuildContext context) {
    CommonPopup.show(
      context: context,
      title: '详细信息',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.info,
            color: Colors.yellow,
            size: 50,
          ),
          const SizedBox(height: 20),
          const Text(
            '这是一个包含复杂内容的弹窗',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '这里可以放置任何复杂的Widget内容',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      buttons: [
        CommonPopupButton(
          text: '确定',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

/// 测试页面 - 用于展示各种弹窗示例
class CommonPopupTestPage extends StatelessWidget {
  const CommonPopupTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通用弹窗示例'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => CommonPopupExamples.showBasicPopup(context),
              child: const Text('基础弹窗'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => CommonPopupExamples.showConfirmPopup(context),
              child: const Text('确认弹窗'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => CommonPopupExamples.showAlertPopup(context),
              child: const Text('提示弹窗'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => CommonPopupExamples.showMultiButtonPopup(context),
              child: const Text('多按钮弹窗'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => CommonPopupExamples.showCustomSizePopup(context),
              child: const Text('自定义尺寸弹窗'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => CommonPopupExamples.showNoCloseButtonPopup(context),
              child: const Text('无关闭按钮弹窗'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => CommonPopupExamples.showComplexContentPopup(context),
              child: const Text('复杂内容弹窗'),
            ),
          ],
        ),
      ),
    );
  }
}
