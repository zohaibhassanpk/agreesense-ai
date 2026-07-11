import '../logger/logger_service.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  final LoggerService _logger = LoggerService(className: 'UrlLauncherService');

  Future<bool> openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _logger.error('Invalid URL: $url');
      return false;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _logger.warning('launchUrl returned false for $url');
      }
      return launched;
    } catch (e, stackTrace) {
      _logger.error('Failed to launch $url', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
