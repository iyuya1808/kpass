import 'package:flutter/services.dart';

class NativeCookieService {
  static const MethodChannel _channel = MethodChannel('com.technophere.kpass/cookies');

  static Future<String?> getCookiesForUrl(String url) async {
    try {
      final cookies = await _channel.invokeMethod<String>('getCookiesForUrl', {
        'url': url,
      });
      return cookies;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> httpGet(String url) async {
    try {
      final resp = await _channel.invokeMethod<dynamic>('httpGet', {
        'url': url,
      });
      if (resp is Map) {
        return Map<String, dynamic>.from(resp);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}


