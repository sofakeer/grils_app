import 'dart:io';

/// 网络服务工具
class NetworkService {
  static const List<_ProbeTarget> _probeTargets = [
    // DNS服务器
    _ProbeTarget(host: '1.1.1.1', port: 53),
    _ProbeTarget(host: '8.8.8.8', port: 53),
    _ProbeTarget(host: '223.5.5.5', port: 53), // 阿里DNS
    // HTTPS端口测试
    _ProbeTarget(host: 'www.baidu.com', port: 443),
    _ProbeTarget(host: 'www.google.com', port: 443),
    _ProbeTarget(host: 'www.github.com', port: 443),
    // HTTP端口测试
    _ProbeTarget(host: 'httpbin.org', port: 80),
  ];

  /// 检查是否有可用的网络连接
  static Future<bool> hasNetworkConnection({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final results = await _probeAllTargets(timeout);
    return results.any((result) => result.isSuccess);
  }

  /// 检查网络连接并提供详细信息
  static Future<NetworkResult> checkNetworkConnection({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final results = await _probeAllTargets(timeout);
    final successCount = results.where((result) => result.isSuccess).length;

    return NetworkResult(
      isConnected: successCount > 0,
      successCount: successCount,
      totalTargets: _probeTargets.length,
      successfulTargets: results
          .where((result) => result.isSuccess)
          .map((result) => '${result.target.host}:${result.target.port}')
          .toList(),
      failedTargets: results
          .where((result) => !result.isSuccess)
          .map((result) =>
              '${result.target.host}:${result.target.port} (${result.error})')
          .toList(),
    );
  }

  static Future<List<_ProbeResult>> _probeAllTargets(Duration timeout) async {
    final futures = _probeTargets.map((target) async {
      try {
        final socket = await Socket.connect(
          target.host,
          target.port,
          timeout: timeout,
        );
        await socket.close();
        return _ProbeResult(target: target, isSuccess: true);
      } catch (e) {
        return _ProbeResult(target: target, isSuccess: false, error: e);
      }
    });

    return Future.wait(futures);
  }
}

/// 网络检测结果
class NetworkResult {
  final bool isConnected;
  final int successCount;
  final int totalTargets;
  final List<String> successfulTargets;
  final List<String> failedTargets;

  const NetworkResult({
    required this.isConnected,
    required this.successCount,
    required this.totalTargets,
    required this.successfulTargets,
    required this.failedTargets,
  });

  @override
  String toString() {
    return 'NetworkResult(isConnected: $isConnected, successCount: $successCount/$totalTargets, successfulTargets: $successfulTargets, failedTargets: $failedTargets)';
  }
}

class _ProbeTarget {
  final String host;
  final int port;

  const _ProbeTarget({
    required this.host,
    required this.port,
  });
}

class _ProbeResult {
  final _ProbeTarget target;
  final bool isSuccess;
  final Object? error;

  const _ProbeResult({
    required this.target,
    required this.isSuccess,
    this.error,
  });
}
