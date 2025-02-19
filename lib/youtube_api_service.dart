import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'video_model.dart';

class YouTubeApiService {
  final String apiKey;

  YouTubeApiService({required this.apiKey});

  Future<List<VideoModel>> fetchShorts({
    required String channelId,
    String order = 'date',
    int maxResults = 100,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'shorts_$channelId';
    final cacheExpiryKey = '${cacheKey}_expiry';
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if cached data exists and hasn't expired
    final expiry = prefs.getInt(cacheExpiryKey);
    if (expiry != null && now < expiry) {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        final List<dynamic> items = jsonDecode(cachedData);
        return items.map((item) => VideoModel.fromJson(item)).toList();
      }
    }

    // Otherwise, fetch fresh data from the API
    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search'
          '?key=$apiKey'
          '&channelId=$channelId'
          '&part=snippet'
          '&order=$order'
          '&videoDuration=short'
          '&type=video'
          '&maxResults=$maxResults',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'];

      // Cache the fetched data for, e.g., one hour (3600000 ms)
      prefs.setString(cacheKey, jsonEncode(items));
      prefs.setInt(cacheExpiryKey, now + 3600000);

      return items.map((item) => VideoModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load videos: ${response.statusCode}');
    }
  }
}
