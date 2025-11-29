import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to handle pending links saved from the share extension
class PendingLinksService {
  static const _channel = MethodChannel('com.example.linkat/pending_links');

  /// Get pending links from shared UserDefaults
  static Future<List<PendingLink>> getPendingLinks() async {
    try {
      debugPrint('PendingLinksService: Checking for pending links...');
      final String? jsonString = await _channel.invokeMethod('getPendingLinks');

      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('PendingLinksService: No pending links found');
        return [];
      }

      debugPrint('PendingLinksService: Found pending links JSON: $jsonString');

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final links = jsonList.map((json) => PendingLink.fromJson(json as Map<String, dynamic>)).toList();

      debugPrint('PendingLinksService: Parsed ${links.length} pending links');
      return links;
    } catch (e, stackTrace) {
      debugPrint('PendingLinksService Error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Clear pending links after processing
  static Future<void> clearPendingLinks() async {
    try {
      debugPrint('PendingLinksService: Clearing pending links...');
      await _channel.invokeMethod('clearPendingLinks');
      debugPrint('PendingLinksService: Pending links cleared');
    } catch (e) {
      debugPrint('PendingLinksService Error clearing: $e');
    }
  }
}

class PendingLink {
  final String url;
  final String title;
  final DateTime createdAt;

  PendingLink({
    required this.url,
    required this.title,
    required this.createdAt,
  });

  factory PendingLink.fromJson(Map<String, dynamic> json) {
    return PendingLink(
      url: json['url'] as String,
      title: json['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['createdAt'] as num) * 1000).toInt(),
      ),
    );
  }
}
