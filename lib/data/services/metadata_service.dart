import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'dart:convert';

class MetadataService {
  Future<Map<String, String?>> fetchMetadata(String url) async {
    try {
      // Check if it's a Twitter/X URL and use special handling
      if (_isTwitterUrl(url)) {
        return await _fetchTwitterMetadata(url);
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return {};
      }

      final document = parser.parse(response.body);
      return _extractMetadata(document, url);
    } catch (e) {
      return {};
    }
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
      if (tweetInfo == null) {
        return _generateFallbackTwitterMetadata(url, null, null);
      }

      final username = tweetInfo['username'];
      final tweetId = tweetInfo['tweetId'];

      // Try multiple services in order of reliability
      Map<String, String?>? metadata;

      // 1. Try FixTweetAPI (returns JSON)
      metadata = await _tryFixTweetApi(username!, tweetId!);
      if (_isValidMetadata(metadata)) return metadata!;

      // 2. Try vxtwitter.com HTML scraping
      metadata = await _tryVxTwitter(url);
      if (_isValidMetadata(metadata)) return metadata!;

      // 3. Try fxtwitter.com HTML scraping
      metadata = await _tryFxTwitter(url);
      if (_isValidMetadata(metadata)) return metadata!;

      // 4. Try original Twitter/X with mobile user agent
      metadata = await _tryOriginalTwitter(url);
      if (_isValidMetadata(metadata)) return metadata!;

      // 5. Generate fallback metadata from URL
      return _generateFallbackTwitterMetadata(url, username, tweetId);
    } catch (e) {
      return _generateFallbackTwitterMetadata(url, null, null);
    }
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
