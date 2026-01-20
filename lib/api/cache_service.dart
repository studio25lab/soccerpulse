import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const Duration _defaultCacheDuration = Duration(minutes: 5);

  Future<dynamic> getData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(key);

      if (jsonString == null) return null;

      final data = json.decode(jsonString);
      final timestamp = data['timestamp'] as int?;

      if (timestamp == null) return null;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      if (now.difference(cacheTime) > _defaultCacheDuration) {
        await prefs.remove(key);
        return null;
      }

      return data['data'];
    } catch (e) {
      print('Error getting cached data: $e');
      return null;
    }
  }

  Future<void> saveData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      };

      final jsonString = json.encode(cacheData);
      await prefs.setString(key, jsonString);
    } catch (e) {
      print('Error saving cached data: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<void> removeData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      print('Error removing cached data: $e');
    }
  }
}
