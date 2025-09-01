# 特殊关卡功能实现总结

## 功能概述
实现了每5关触发一次特殊关卡的功能，包括视频广告、Spine动画特效和翻倍爱心货币奖励。

## 主要功能点

### 1. 每5关触发机制
- **位置**: `lib/managers/game_state_manager.dart`
- **方法**: `shouldTriggerSpecialStage()`
- **逻辑**: 检查当前关卡是否为5的倍数，且大于上次触发特殊关卡的关卡

### 2. 主页面检测逻辑
- **位置**: `lib/pages/main_page.dart`
- **方法**: `_checkForSpecialStage()`
- **触发时机**: 页面加载完成后自动检测

### 3. 特殊关卡弹窗
- **位置**: `lib/pages/special_page.dart`
- **功能**:
  - 播放Special_Eff Spine动画（born动画后循环idle动画）
  - 显示特殊关卡介绍
  - PLAY按钮触发视频广告
  - SKIP按钮关闭弹窗

### 4. 视频广告模拟
- **功能**: 模拟视频广告加载和播放过程
- **交互**: 用户可以选择跳过或完成广告
- **完成条件**: 只有完成广告才能进入特殊关卡

### 5. 特殊关卡游戏
- **位置**: `lib/pages/special_game_page.dart`
- **游戏机制**: 点击按钮获得分数，达到目标分数完成游戏
- **音效**: 播放特殊关卡音效和得分音效

### 6. 翻倍爱心货币奖励
- **完成奖励**: 特殊关卡完成后显示翻倍爱心货币界面
- **跳转**: 自动跳转到WinHeartPage领取奖励

## 测试功能

### 游戏页面测试按钮
- **位置**: `lib/pages/game_page.dart`
- **功能**: "Trigger Special Stage"按钮，重置特殊关卡触发状态
- **使用**: 点击后下次回到主页面会触发特殊关卡弹窗

## 音效支持
- **特殊关卡音效**: `audio/special01.mp3`
- **AudioManager方法**: `playSpecialEffect()`

## Spine动画
- **资源**: `assets/spine/Special_Eff.atlas` 和 `assets/spine/Special_Eff.skel`
- **动画序列**: 
  1. 加载时播放 `Special_Eff_born` 动画
  2. 完成后循环播放 `Special_Eff_idle` 动画

## 状态管理
- **GameStateManager新增方法**:
  - `shouldTriggerSpecialStage()`: 检查是否应该触发特殊关卡
  - `markSpecialStageTriggered()`: 标记特殊关卡已触发
  - `getLastSpecialStageLevel()`: 获取上次触发特殊关卡的关卡
  - `setLastSpecialStageLevel()`: 设置上次触发特殊关卡的关卡

## 使用流程
1. 玩家通过5关后回到主页面
2. 自动检测并显示特殊关卡弹窗
3. 玩家点击PLAY按钮观看视频广告
4. 广告完成后进入特殊关卡游戏
5. 完成游戏后显示翻倍爱心货币奖励界面
6. 玩家领取奖励后返回主页面

## 注意事项
- 特殊关卡每5关只能触发一次
- 视频广告必须完整观看才能进入游戏
- 特殊关卡完成后不触发金币和解锁新照片界面
- 只触发翻倍领取爱心货币界面
