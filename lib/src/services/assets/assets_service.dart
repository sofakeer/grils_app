import '../../core/locator.dart';
import '../remote_config/remote_config_service.dart';

abstract class AssetsService {
  String imageUrl({required String path});
}

class DefaultAssetsService implements AssetsService {
  @override
  String imageUrl({required String path}) {
    final rc = ServiceLocator.instance.get<RemoteConfigService>();
    final base = rc.getString('assets.base_url', defaultValue: '');
    if (base.isEmpty) return path;
    final sep = base.endsWith('/') || path.startsWith('/') ? '' : '/';
    return '$base$sep$path';
  }
}

