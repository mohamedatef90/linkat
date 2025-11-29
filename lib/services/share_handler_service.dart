import 'dart:convert';
import 'package:flutter/services.dart';

class ShareHandlerService {
  static const MethodChannel _methodChannel = MethodChannel(
    'receive_sharing_intent/messages',
  );
  static const EventChannel _eventChannel = EventChannel(
    'receive_sharing_intent/events-media',
  );

  Stream<List<SharedMedia>>? _mediaStream;

  /// Initialize the share handler with a callback for received shared media
  Future<void> initialize({
    required Function(List<SharedMedia>) onSharedMedia,
  }) async {
    // Get initial shared media (when app was opened via share while closed)
    final initialMedia = await getInitialMedia();
    if (initialMedia != null && initialMedia.isNotEmpty) {
      onSharedMedia(initialMedia);
      await reset(); // Clear after handling
    }

    // Listen for shared media when app is running or in background
    _mediaStream = getMediaStream();
    _mediaStream?.listen((List<SharedMedia> files) {
      if (files.isNotEmpty) {
        onSharedMedia(files);
        reset(); // Clear after handling
      }
    });
  }

  /// Get the initial shared media when app was closed and opened via share
  Future<List<SharedMedia>?> getInitialMedia() async {
    try {
      final String? json = await _methodChannel.invokeMethod('getInitialMedia');
      if (json == null || json.isEmpty) return null;

      final List<dynamic> parsed = jsonDecode(json);
      return parsed.map((item) => SharedMedia.fromJson(item)).toList();
    } catch (e) {
      print('Error getting initial media: $e');
      return null;
    }
  }

  /// Listen to shared media when app is in background/foreground
  Stream<List<SharedMedia>> getMediaStream() {
    return _eventChannel.receiveBroadcastStream().map((dynamic json) {
      if (json == null || json.isEmpty) return <SharedMedia>[];

      final List<dynamic> parsed = jsonDecode(json);
      return parsed.map((item) => SharedMedia.fromJson(item)).toList();
    });
  }

  /// Reset the shared media
  Future<void> reset() async {
    try {
      await _methodChannel.invokeMethod('reset');
    } catch (e) {
      print('Error resetting: $e');
    }
  }

  void dispose() {
    // Stream will be canceled when listeners are removed
  }
}

class SharedMedia {
  final String path;
  final String? mimeType;
  final String? thumbnail;
  final double? duration;
  final String? message;
  final SharedMediaType type;

  SharedMedia({
    required this.path,
    this.mimeType,
    this.thumbnail,
    this.duration,
    this.message,
    required this.type,
  });

  factory SharedMedia.fromJson(Map<dynamic, dynamic> json) {
    return SharedMedia(
      path: json['path'] as String,
      mimeType: json['mimeType'] as String?,
      thumbnail: json['thumbnail'] as String?,
      duration: json['duration'] as double?,
      message: json['message'] as String?,
      type: SharedMediaType.fromString(json['type'] as String),
    );
  }

  bool get isUrl => type == SharedMediaType.url;
  bool get isText => type == SharedMediaType.text;
  bool get isImage => type == SharedMediaType.image;
  bool get isVideo => type == SharedMediaType.video;
  bool get isFile => type == SharedMediaType.file;
}

enum SharedMediaType {
  image,
  video,
  text,
  file,
  url;

  static SharedMediaType fromString(String type) {
    switch (type) {
      case 'image':
        return SharedMediaType.image;
      case 'video':
        return SharedMediaType.video;
      case 'text':
        return SharedMediaType.text;
      case 'file':
        return SharedMediaType.file;
      case 'url':
        return SharedMediaType.url;
      default:
        return SharedMediaType.text;
    }
  }
}
