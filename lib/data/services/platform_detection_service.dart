import '../../domain/entities/platform_type.dart';

class PlatformDetectionService {
  PlatformType detectPlatform(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return PlatformType.other;

    final host = uri.host.toLowerCase();

    if (host.contains('facebook.com') || host.contains('fb.com')) {
      return PlatformType.facebook;
    } else if (host.contains('instagram.com')) {
      return PlatformType.instagram;
    } else if (host.contains('twitter.com') || host.contains('x.com')) {
      return PlatformType.twitter;
    } else if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return PlatformType.youtube;
    } else if (host.contains('linkedin.com')) {
      return PlatformType.linkedin;
    } else {
      return PlatformType.other;
    }
  }
}
