import '../../domain/entities/content_type.dart';
import '../../domain/entities/platform_type.dart';

class ContentTypeDetectionService {
  /// Detect the content type from URL and platform
  /// If metadataContentType is provided (from metadata service), it takes priority
  ContentType detectContentType(String url, PlatformType platform, [String? metadataContentType]) {
    // If we have a content type from metadata, use it
    if (metadataContentType != null && metadataContentType.isNotEmpty) {
      return _parseContentType(metadataContentType);
    }

    return _detectFromUrl(url, platform);
  }

  /// Parse content type string to enum
  ContentType _parseContentType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return ContentType.video;
      case 'reel':
        return ContentType.reel;
      case 'short':
        return ContentType.short;
      case 'post':
        return ContentType.post;
      case 'article':
        return ContentType.article;
      case 'image':
        return ContentType.image;
      case 'story':
        return ContentType.story;
      case 'thread':
        return ContentType.thread;
      case 'podcast':
        return ContentType.podcast;
      case 'music':
        return ContentType.music;
      case 'profile':
        return ContentType.profile;
      default:
        return ContentType.other;
    }
  }

  /// Detect content type from URL patterns
  ContentType _detectFromUrl(String url, PlatformType platform) {
    final uri = Uri.tryParse(url.toLowerCase());
    if (uri == null) return ContentType.other;

    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();

    // YouTube
    if (platform == PlatformType.youtube || host.contains('youtube') || host.contains('youtu.be')) {
      if (path.contains('/shorts/') || path.contains('/shorts')) {
        return ContentType.short;
      }
      if (path.contains('/watch') || host.contains('youtu.be')) {
        return ContentType.video;
      }
      if (path.contains('/playlist')) {
        return ContentType.video;
      }
      if (path.contains('/channel/') || path.contains('/@') || path.contains('/c/')) {
        return ContentType.profile;
      }
      if (path.contains('/music') || path.contains('/premium')) {
        return ContentType.music;
      }
      return ContentType.video;
    }

    // Instagram
    if (platform == PlatformType.instagram || host.contains('instagram')) {
      if (path.contains('/reel/') || path.contains('/reels/')) {
        return ContentType.reel;
      }
      if (path.contains('/stories/')) {
        return ContentType.story;
      }
      if (path.contains('/p/')) {
        return ContentType.post;
      }
      if (path.contains('/tv/')) {
        return ContentType.video;
      }
      // Profile URLs are usually just /username
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.length == 1 && !['explore', 'direct', 'accounts'].contains(segments.first)) {
        return ContentType.profile;
      }
      return ContentType.post;
    }

    // Facebook
    if (platform == PlatformType.facebook || host.contains('facebook') || host.contains('fb.')) {
      if (path.contains('/reel/') || path.contains('/reels/') || host.contains('fb.watch')) {
        return ContentType.reel;
      }
      if (path.contains('/watch/') || path.contains('/videos/')) {
        return ContentType.video;
      }
      if (path.contains('/stories/')) {
        return ContentType.story;
      }
      if (path.contains('/posts/') || path.contains('/photo') || path.contains('/permalink')) {
        return ContentType.post;
      }
      if (path.contains('/events/')) {
        return ContentType.other;
      }
      // Profile-like URLs
      if (path.split('/').where((s) => s.isNotEmpty).length == 1) {
        return ContentType.profile;
      }
      return ContentType.post;
    }

    // Twitter/X
    if (platform == PlatformType.twitter || host.contains('twitter') || host.contains('x.com')) {
      if (path.contains('/status/')) {
        // Check if it's a thread (would need metadata, default to post)
        return ContentType.post;
      }
      if (path.contains('/i/spaces')) {
        return ContentType.podcast;
      }
      // Profile URLs
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.length == 1 && !['home', 'explore', 'search', 'notifications', 'messages', 'i'].contains(segments.first)) {
        return ContentType.profile;
      }
      return ContentType.post;
    }

    // LinkedIn
    if (platform == PlatformType.linkedin || host.contains('linkedin')) {
      if (path.contains('/posts/') || path.contains('/feed/update/')) {
        return ContentType.post;
      }
      if (path.contains('/pulse/') || path.contains('/article/')) {
        return ContentType.article;
      }
      if (path.contains('/in/') || path.contains('/company/')) {
        return ContentType.profile;
      }
      if (path.contains('/video/')) {
        return ContentType.video;
      }
      return ContentType.post;
    }

    // TikTok (even if categorized as other platform)
    if (host.contains('tiktok')) {
      if (path.contains('/video/') || path.contains('/@') && path.split('/').length > 2) {
        return ContentType.short;
      }
      if (path.startsWith('/@') && path.split('/').length <= 2) {
        return ContentType.profile;
      }
      return ContentType.short;
    }

    // Spotify
    if (host.contains('spotify')) {
      if (path.contains('/track/') || path.contains('/album/') || path.contains('/playlist/')) {
        return ContentType.music;
      }
      if (path.contains('/episode/') || path.contains('/show/')) {
        return ContentType.podcast;
      }
      if (path.contains('/artist/') || path.contains('/user/')) {
        return ContentType.profile;
      }
      return ContentType.music;
    }

    // Medium / Substack / Blog platforms
    if (host.contains('medium.com') || host.contains('substack.com') ||
        host.contains('dev.to') || host.contains('hashnode')) {
      return ContentType.article;
    }

    // News sites
    if (host.contains('bbc') || host.contains('cnn') || host.contains('nytimes') ||
        host.contains('theguardian') || host.contains('reuters') || host.contains('aljazeera')) {
      return ContentType.article;
    }

    // Podcast platforms
    if (host.contains('podcasts.apple') || host.contains('anchor.fm') ||
        host.contains('pocketcasts') || host.contains('overcast.fm')) {
      return ContentType.podcast;
    }

    // Image hosting
    if (host.contains('imgur') || host.contains('flickr') ||
        host.contains('unsplash') || host.contains('pexels')) {
      return ContentType.image;
    }

    // Video platforms
    if (host.contains('vimeo') || host.contains('dailymotion') ||
        host.contains('twitch') || host.contains('rumble')) {
      return ContentType.video;
    }

    // Reddit
    if (host.contains('reddit')) {
      if (path.contains('/comments/')) {
        return ContentType.thread;
      }
      if (path.startsWith('/r/') && path.split('/').length <= 3) {
        return ContentType.profile;
      }
      if (path.startsWith('/user/') || path.startsWith('/u/')) {
        return ContentType.profile;
      }
      return ContentType.post;
    }

    // GitHub
    if (host.contains('github')) {
      return ContentType.article;
    }

    // Default based on common URL patterns
    if (path.contains('/video') || path.contains('/watch')) {
      return ContentType.video;
    }
    if (path.contains('/article') || path.contains('/blog') || path.contains('/post/')) {
      return ContentType.article;
    }
    if (path.contains('/image') || path.contains('/photo') || path.contains('/gallery')) {
      return ContentType.image;
    }

    return ContentType.other;
  }
}
