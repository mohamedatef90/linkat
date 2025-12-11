import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'dart:convert';

class MetadataService {
  Future<Map<String, String?>> fetchMetadata(String url) async {
    try {
      // Check platform-specific handling
      if (_isTwitterUrl(url)) {
        return await _fetchTwitterMetadata(url);
      }

      if (_isYouTubeShortsUrl(url)) {
        return await _fetchYouTubeShortsMetadata(url);
      }

      if (_isInstagramUrl(url)) {
        return await _fetchInstagramMetadata(url);
      }

      if (_isFacebookUrl(url)) {
        return await _fetchFacebookMetadata(url);
      }

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return {};
      }

      final document = parser.parse(response.body);
      return _extractMetadata(document, url);
    } catch (e) {
      return {};
    }
  }

  // ============ YOUTUBE SHORTS ============

  bool _isYouTubeShortsUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    return (host.contains('youtube.com') && path.contains('/shorts/')) ||
           (host.contains('youtu.be') && path.contains('/shorts'));
  }

  Future<Map<String, String?>> _fetchYouTubeShortsMetadata(String url) async {
    try {
      final videoId = _extractYouTubeVideoId(url);
      final contentType = _detectYouTubeContentType(url);

      if (videoId == null) {
        final fallback = _generateFallbackYouTubeMetadata(url);
        fallback['contentType'] = contentType;
        return fallback;
      }

      // Try oEmbed API first
      final oembedUrl = 'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json';
      final response = await http.get(Uri.parse(oembedUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {
          'title': json['title'] ?? 'YouTube Short',
          'description': json['title'],
          'image': 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
          'publisher': json['author_name'],
          'contentType': contentType,
        };
      }

      final fallback = _generateFallbackYouTubeMetadata(url);
      fallback['contentType'] = contentType;
      return fallback;
    } catch (e) {
      final fallback = _generateFallbackYouTubeMetadata(url);
      fallback['contentType'] = _detectYouTubeContentType(url);
      return fallback;
    }
  }

  String _detectYouTubeContentType(String url) {
    final uri = Uri.tryParse(url.toLowerCase());
    if (uri == null) return 'video';

    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();

    if (path.contains('/shorts/') || path.contains('/shorts')) {
      return 'short';
    }
    if (path.contains('/playlist')) {
      return 'video';
    }
    if (path.contains('/channel/') || path.contains('/@') || path.contains('/c/')) {
      return 'profile';
    }
    if (path.contains('/music') || host.contains('music.youtube')) {
      return 'music';
    }

    return 'video';
  }

  String? _extractYouTubeVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // youtube.com/shorts/VIDEO_ID
    if (uri.path.contains('/shorts/')) {
      final segments = uri.pathSegments;
      final shortsIndex = segments.indexOf('shorts');
      if (shortsIndex >= 0 && shortsIndex + 1 < segments.length) {
        return segments[shortsIndex + 1].split('?').first;
      }
    }

    // youtu.be/VIDEO_ID
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first.split('?').first : null;
    }

    return null;
  }

  Map<String, String?> _generateFallbackYouTubeMetadata(String url) {
    final videoId = _extractYouTubeVideoId(url);
    return {
      'title': 'YouTube Short',
      'description': 'Watch this video on YouTube',
      'image': videoId != null ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg' : null,
      'publisher': 'YouTube',
    };
  }

  // ============ INSTAGRAM REELS ============

  bool _isInstagramUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.host.toLowerCase().contains('instagram.com');
  }

  Future<Map<String, String?>> _fetchInstagramMetadata(String url) async {
    try {
      final contentType = _detectInstagramContentType(url);

      // Try ddinstagram service first
      Map<String, String?>? metadata = await _tryDdInstagram(url);
      if (_isValidMetadata(metadata)) {
        metadata!['contentType'] = contentType;
        return metadata;
      }

      // Try imginn service
      metadata = await _tryImginn(url);
      if (_isValidMetadata(metadata)) {
        metadata!['contentType'] = contentType;
        return metadata;
      }

      // Try direct Instagram with mobile user agent
      metadata = await _tryDirectInstagram(url);
      if (_isValidMetadata(metadata)) {
        metadata!['contentType'] = contentType;
        return metadata;
      }

      final fallback = _generateFallbackInstagramMetadata(url);
      fallback['contentType'] = contentType;
      return fallback;
    } catch (e) {
      final fallback = _generateFallbackInstagramMetadata(url);
      fallback['contentType'] = _detectInstagramContentType(url);
      return fallback;
    }
  }

  String _detectInstagramContentType(String url) {
    final uri = Uri.tryParse(url.toLowerCase());
    if (uri == null) return 'post';

    final path = uri.path.toLowerCase();

    if (path.contains('/reel/') || path.contains('/reels/')) {
      return 'reel';
    }
    if (path.contains('/stories/')) {
      return 'story';
    }
    if (path.contains('/tv/')) {
      return 'video';
    }
    if (path.contains('/p/')) {
      return 'post';
    }

    // Profile check
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length == 1 && !['explore', 'direct', 'accounts', 'reel', 'reels', 'p', 'tv'].contains(segments.first)) {
      return 'profile';
    }

    return 'post';
  }

  Future<Map<String, String?>?> _tryDdInstagram(String url) async {
    try {
      final modifiedUrl = url.replaceFirst('instagram.com', 'ddinstagram.com');
      final response = await http.get(
        Uri.parse(modifiedUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        return _extractMetadata(document, url);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String?>?> _tryImginn(String url) async {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isEmpty) return null;

      // Extract username or post ID
      String? postId;
      if (pathSegments.contains('reel') || pathSegments.contains('p')) {
        final index = pathSegments.contains('reel')
            ? pathSegments.indexOf('reel')
            : pathSegments.indexOf('p');
        if (index + 1 < pathSegments.length) {
          postId = pathSegments[index + 1];
        }
      }

      if (postId == null) return null;

      final imginnUrl = 'https://imginn.com/p/$postId/';
      final response = await http.get(
        Uri.parse(imginnUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        return _extractMetadata(document, url);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String?>?> _tryDirectInstagram(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
          'Accept': 'text/html,application/xhtml+xml',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        return _extractMetadata(document, url);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Map<String, String?> _generateFallbackInstagramMetadata(String url) {
    final username = _extractInstagramUsername(url);
    return {
      'title': username != null ? 'Instagram post by @$username' : 'Instagram Reel',
      'description': 'View this post on Instagram',
      'image': null,
      'publisher': username,
    };
  }

  String? _extractInstagramUsername(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty && !['reel', 'reels', 'p', 'stories'].contains(segments.first)) {
        return segments.first;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============ FACEBOOK REELS ============

  bool _isFacebookUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host.contains('facebook.com') || host.contains('fb.com') || host.contains('fb.watch');
  }

  Future<Map<String, String?>> _fetchFacebookMetadata(String url) async {
    try {
      // Extract video/reel ID from URL to determine content type
      final videoInfo = _extractFacebookVideoInfo(url);
      final contentType = _detectFacebookContentType(url, videoInfo);

      // Try ddFacebook service first (most reliable)
      Map<String, String?>? metadata = await _tryDdFacebook(url);
      if (_isValidMetadata(metadata)) {
        metadata!['contentType'] = contentType;
        return metadata;
      }

      // Try fxfacebook service
      metadata = await _tryFxFacebook(url);
      if (_isValidMetadata(metadata)) {
        metadata!['contentType'] = contentType;
        return metadata;
      }

      // Try with Facebook external hit user agent (for OG tags)
      metadata = await _tryFacebookExternalHit(url);
      if (_isValidMetadata(metadata)) {
        metadata!['contentType'] = contentType;
        return metadata;
      }

      // Try with Telegram bot user agent
      metadata = await _tryFacebookTelegramBot(url);
      if (_isValidMetadata(metadata)) {
        metadata!['contentType'] = contentType;
        return metadata;
      }

      // Try with WhatsApp preview user agent
      metadata = await _tryFacebookWhatsApp(url);
      if (_isValidMetadata(metadata)) {
        metadata!['contentType'] = contentType;
        return metadata;
      }

      // Try mobile Facebook
      metadata = await _tryMobileFacebook(url);
      if (_isValidMetadata(metadata)) {
        metadata!['contentType'] = contentType;
        return metadata;
      }

      final fallback = _generateFallbackFacebookMetadata(url, videoInfo);
      fallback['contentType'] = contentType;
      return fallback;
    } catch (e) {
      final fallback = _generateFallbackFacebookMetadata(url, null);
      fallback['contentType'] = _detectFacebookContentType(url, null);
      return fallback;
    }
  }

  String _detectFacebookContentType(String url, Map<String, String?>? videoInfo) {
    final uri = Uri.tryParse(url.toLowerCase());
    if (uri == null) return 'post';

    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();

    // fb.watch links are typically reels/short videos
    if (host.contains('fb.watch')) {
      return 'reel';
    }

    // Explicit reel URLs
    if (path.contains('/reel/') || path.contains('/reels/')) {
      return 'reel';
    }

    // Video URLs
    if (path.contains('/videos/') || path.contains('/watch')) {
      return 'video';
    }

    // Stories
    if (path.contains('/stories/')) {
      return 'story';
    }

    // Photo posts
    if (path.contains('/photo') || path.contains('/photos/')) {
      return 'image';
    }

    // Check videoInfo type
    if (videoInfo != null) {
      final type = videoInfo['type'];
      if (type == 'reel') return 'reel';
      if (type == 'video' || type == 'watch') return 'video';
    }

    // Posts
    if (path.contains('/posts/') || path.contains('/permalink/')) {
      return 'post';
    }

    // Default to post
    return 'post';
  }

  Map<String, String?>? _extractFacebookVideoInfo(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;

      // fb.watch/xxx
      if (uri.host.contains('fb.watch')) {
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segments.isNotEmpty) {
          return {'videoId': segments.first, 'type': 'watch'};
        }
      }

      // facebook.com/reel/xxx
      if (path.contains('/reel/')) {
        final reelMatch = RegExp(r'/reel/(\d+)').firstMatch(path);
        if (reelMatch != null) {
          return {'videoId': reelMatch.group(1), 'type': 'reel'};
        }
      }

      // facebook.com/watch?v=xxx
      final vParam = uri.queryParameters['v'];
      if (vParam != null) {
        return {'videoId': vParam, 'type': 'watch'};
      }

      // facebook.com/username/videos/xxx
      if (path.contains('/videos/')) {
        final videoMatch = RegExp(r'/videos/(\d+)').firstMatch(path);
        if (videoMatch != null) {
          return {'videoId': videoMatch.group(1), 'type': 'video'};
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String?>?> _tryDdFacebook(String url) async {
    try {
      // ddFacebook is similar to ddInstagram - a privacy-friendly frontend
      String modifiedUrl = url;
      if (url.contains('facebook.com')) {
        modifiedUrl = url.replaceFirst('facebook.com', 'ddfacebook.com');
      } else if (url.contains('fb.com')) {
        modifiedUrl = url.replaceFirst('fb.com', 'ddfacebook.com');
      }

      final response = await http.get(
        Uri.parse(modifiedUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)',
          'Accept': 'text/html',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        return _extractFacebookMetadataFromHtml(document, url);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String?>?> _tryFxFacebook(String url) async {
    try {
      // Similar approach to fxtwitter
      String modifiedUrl = url;
      if (url.contains('facebook.com')) {
        modifiedUrl = url.replaceFirst('facebook.com', 'fxfacebook.com');
      }

      final response = await http.get(
        Uri.parse(modifiedUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        return _extractFacebookMetadataFromHtml(document, url);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String?>?> _tryFacebookExternalHit(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
          'Accept': 'text/html,application/xhtml+xml',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        return _extractFacebookMetadataFromHtml(document, url);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String?>?> _tryFacebookTelegramBot(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'TelegramBot (like TwitterBot)',
          'Accept': 'text/html',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        return _extractFacebookMetadataFromHtml(document, url);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String?>?> _tryFacebookWhatsApp(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'WhatsApp/2.21.4.22 A',
          'Accept': 'text/html',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        return _extractFacebookMetadataFromHtml(document, url);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String?>?> _tryMobileFacebook(String url) async {
    try {
      // Convert to mobile URL
      String mobileUrl = url;
      if (url.contains('www.facebook.com')) {
        mobileUrl = url.replaceFirst('www.facebook.com', 'm.facebook.com');
      } else if (url.contains('facebook.com')) {
        mobileUrl = url.replaceFirst('facebook.com', 'm.facebook.com');
      }

      final response = await http.get(
        Uri.parse(mobileUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBDV/iPhone13,2;FBMD/iPhone;FBSN/iOS;FBSV/15.0;FBSS/3;FBID/phone;FBLC/en_US;FBOP/5]',
          'Accept': 'text/html',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        return _extractFacebookMetadataFromHtml(document, url);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Map<String, String?> _extractFacebookMetadataFromHtml(Document document, String url) {
    String? title = _getMetaContent(document, 'og:title');
    String? description = _getMetaContent(document, 'og:description');
    String? image = _getMetaContent(document, 'og:image');
    String? publisher = _getMetaContent(document, 'og:site_name');

    // Try additional tags
    title ??= _getMetaContent(document, 'twitter:title');
    description ??= _getMetaContent(document, 'twitter:description');
    image ??= _getMetaContent(document, 'twitter:image');

    // Try to get video thumbnail
    image ??= _getMetaContent(document, 'og:video:thumbnail');
    image ??= _getMetaContent(document, 'og:image:url');

    // Get title from page title as fallback
    title ??= document.querySelector('title')?.text;

    // Clean up title
    if (title != null) {
      // Remove "Watch" prefix and common Facebook suffixes
      title = title
          .replaceAll(RegExp(r'^Watch\s*'), '')
          .replaceAll(RegExp(r'\s*\|\s*Facebook$'), '')
          .replaceAll(RegExp(r'\s*-\s*Facebook$'), '')
          .trim();
    }

    // Extract author/page name from description if available
    if (publisher == null || publisher == 'Facebook') {
      // Try to extract from description patterns like "posted by Name"
      if (description != null) {
        final authorMatch = RegExp(r'(?:by|from)\s+([^.]+)').firstMatch(description);
        if (authorMatch != null) {
          publisher = authorMatch.group(1)?.trim();
        }
      }
    }

    return {
      'title': title,
      'description': description,
      'image': image,
      'publisher': publisher ?? 'Facebook',
    };
  }

  Map<String, String?> _generateFallbackFacebookMetadata(String url, Map<String, String?>? videoInfo) {
    final isReel = url.contains('/reel/') || url.contains('fb.watch');
    final isWatch = url.contains('/watch') || url.contains('fb.watch');

    String title;
    if (isReel) {
      title = 'Facebook Reel';
    } else if (isWatch) {
      title = 'Facebook Watch Video';
    } else {
      title = 'Facebook Video';
    }

    String description;
    if (isReel) {
      description = 'Watch this Reel on Facebook';
    } else {
      description = 'Watch this video on Facebook';
    }

    return {
      'title': title,
      'description': description,
      'image': null,
      'publisher': 'Facebook',
    };
  }

  bool _isTwitterUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host.contains('twitter.com') || host.contains('x.com');
  }

  Future<Map<String, String?>> _fetchTwitterMetadata(String url) async {
    try {
      // Extract username and tweet ID from URL
      final tweetInfo = _extractTweetInfo(url);
      final contentType = _detectTwitterContentType(url);

      if (tweetInfo == null) {
        final fallback = _generateFallbackTwitterMetadata(url, null, null);
        fallback['contentType'] = contentType;
        return fallback;
      }

      final username = tweetInfo['username'];
      final tweetId = tweetInfo['tweetId'];

      // Try multiple services in order of reliability
      Map<String, String?>? metadata;

      // 1. Try FixTweetAPI (returns JSON)
      metadata = await _tryFixTweetApi(username!, tweetId!);
      if (_isValidMetadata(metadata)) {
        metadata!['contentType'] = contentType;
        return metadata;
      }

      // 2. Try vxtwitter.com HTML scraping
      metadata = await _tryVxTwitter(url);
      if (_isValidMetadata(metadata)) {
        metadata!['contentType'] = contentType;
        return metadata;
      }

      // 3. Try fxtwitter.com HTML scraping
      metadata = await _tryFxTwitter(url);
      if (_isValidMetadata(metadata)) {
        metadata!['contentType'] = contentType;
        return metadata;
      }

      // 4. Try original Twitter/X with mobile user agent
      metadata = await _tryOriginalTwitter(url);
      if (_isValidMetadata(metadata)) {
        metadata!['contentType'] = contentType;
        return metadata;
      }

      // 5. Generate fallback metadata from URL
      final fallback = _generateFallbackTwitterMetadata(url, username, tweetId);
      fallback['contentType'] = contentType;
      return fallback;
    } catch (e) {
      final fallback = _generateFallbackTwitterMetadata(url, null, null);
      fallback['contentType'] = _detectTwitterContentType(url);
      return fallback;
    }
  }

  String _detectTwitterContentType(String url) {
    final uri = Uri.tryParse(url.toLowerCase());
    if (uri == null) return 'post';

    final path = uri.path.toLowerCase();

    if (path.contains('/i/spaces')) {
      return 'podcast';
    }
    if (path.contains('/status/')) {
      return 'post';
    }

    // Profile check
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length == 1 && !['home', 'explore', 'search', 'notifications', 'messages', 'i'].contains(segments.first)) {
      return 'profile';
    }

    return 'post';
  }

  Map<String, String>? _extractTweetInfo(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // URL pattern: twitter.com/username/status/tweetId or x.com/username/status/tweetId
      if (pathSegments.length >= 3 && pathSegments[1] == 'status') {
        return {
          'username': pathSegments[0],
          'tweetId': pathSegments[2].split('?').first, // Remove query params
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  bool _isValidMetadata(Map<String, String?>? metadata) {
    if (metadata == null) return false;
    final title = metadata['title'];
    return title != null &&
           title.isNotEmpty &&
           !title.contains('Sorry') &&
           !title.contains('doesn\'t exist') &&
           !title.contains('Failed') &&
           title.length > 5;
  }

  Future<Map<String, String?>?> _tryFixTweetApi(String username, String tweetId) async {
    try {
      final apiUrl = 'https://api.fxtwitter.com/$username/status/$tweetId';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['code'] != null && json['code'] != 200) return null;

        final tweet = json['tweet'];
        if (tweet == null) return null;

        String? text = tweet['text'];
        String? image;

        // Get media
        final media = tweet['media'];
        if (media != null) {
          final photos = media['photos'] as List?;
          if (photos != null && photos.isNotEmpty) {
            image = photos[0]['url'];
          }
          // Try video thumbnail
          if (image == null) {
            final videos = media['videos'] as List?;
            if (videos != null && videos.isNotEmpty) {
              image = videos[0]['thumbnail_url'];
            }
          }
        }

        // Get author info
        final author = tweet['author'];
        String? publisher;
        if (author != null) {
          publisher = author['name'] ?? author['screen_name'];
        }

        if (text != null && text.isNotEmpty) {
          return {
            'title': text.length > 120 ? '${text.substring(0, 120)}...' : text,
            'description': text,
            'image': image,
            'publisher': publisher,
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String?>?> _tryVxTwitter(String url) async {
    try {
      final modifiedUrl = url
          .replaceFirst('twitter.com', 'vxtwitter.com')
          .replaceFirst('x.com', 'vxtwitter.com');

      final response = await http.get(
        Uri.parse(modifiedUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)',
          'Accept': 'text/html',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        return _extractTwitterMetadataFromHtml(document);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String?>?> _tryFxTwitter(String url) async {
    try {
      final modifiedUrl = url
          .replaceFirst('twitter.com', 'fxtwitter.com')
          .replaceFirst('x.com', 'fxtwitter.com');

      final response = await http.get(
        Uri.parse(modifiedUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)',
          'Accept': 'text/html',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        return _extractTwitterMetadataFromHtml(document);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String?>?> _tryOriginalTwitter(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        return _extractTwitterMetadataFromHtml(document);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Map<String, String?> _extractTwitterMetadataFromHtml(Document document) {
    String? title = _getMetaContent(document, 'og:title');
    String? description = _getMetaContent(document, 'og:description');
    String? image = _getMetaContent(document, 'og:image');
    String? publisher = _getMetaContent(document, 'og:site_name');

    // Try twitter-specific tags
    title ??= _getMetaContent(document, 'twitter:title');
    description ??= _getMetaContent(document, 'twitter:description');
    image ??= _getMetaContent(document, 'twitter:image');
    image ??= _getMetaContent(document, 'twitter:image:src');
    publisher ??= _getMetaContent(document, 'twitter:creator');
    publisher ??= _getMetaContent(document, 'twitter:site');

    // For tweets, use description as title if title is generic
    if ((title == null || title.isEmpty ||
         title.contains('on X') || title.contains('on Twitter') ||
         title == 'X' || title == 'Twitter' || title == 'FxTwitter' || title == 'vxTwitter')
        && description != null && description.isNotEmpty) {
      title = description.length > 120 ? '${description.substring(0, 120)}...' : description;
    }

    // Clean up publisher
    if (publisher != null) {
      publisher = publisher.replaceAll('@', '').trim();
      if (publisher.isEmpty || publisher == 'X' || publisher == 'Twitter') {
        publisher = null;
      }
    }

    return {
      'title': title,
      'description': description,
      'image': image,
      'publisher': publisher,
    };
  }

  Map<String, String?> _generateFallbackTwitterMetadata(String url, String? username, String? tweetId) {
    // Generate a helpful title from the URL components
    String title;
    if (username != null && tweetId != null) {
      title = 'Post by @$username';
    } else if (username != null) {
      title = '@$username on X';
    } else {
      title = 'X Post';
    }

    return {
      'title': title,
      'description': 'View this post on X (Twitter)',
      'image': null, // X logo could be used as fallback in the UI
      'publisher': username,
    };
  }

  Map<String, String?> _extractMetadata(Document document, String url) {
    final title =
        _getMetaContent(document, 'og:title') ??
        document.querySelector('title')?.text;
    final description =
        _getMetaContent(document, 'og:description') ??
        _getMetaContent(document, 'description');
    final image = _getMetaContent(document, 'og:image');

    // Extract publisher/author name from various meta tags
    final publisher =
        _getMetaContent(document, 'article:author') ??
        _getMetaContent(document, 'author') ??
        _getMetaContent(document, 'og:site_name') ??
        _getMetaContent(document, 'twitter:creator') ??
        _getMetaContent(document, 'twitter:site');

    return {
      'title': title,
      'description': description,
      'image': image,
      'publisher': publisher,
    };
  }

  String? _getMetaContent(Document document, String property) {
    var meta = document.querySelector('meta[property="$property"]');
    meta ??= document.querySelector('meta[name="$property"]');
    return meta?.attributes['content'];
  }
}
