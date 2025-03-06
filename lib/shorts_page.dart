import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For CupertinoIcons
import 'package:shared_preferences/shared_preferences.dart';
import 'video_model.dart';
import 'news_model.dart';
import '/youtube_api_service.dart';
import '/view/Widgets/reels_container.dart';
import '/view/Widgets/NewsContainer.dart';
import '/view/home.dart';

class ShortsPage extends StatefulWidget {
  const ShortsPage({Key? key}) : super(key: key);

  @override
  _ShortsPageState createState() => _ShortsPageState();
}

class _ShortsPageState extends State<ShortsPage> {
  // Replace with your API key.
  final String apiKey = 'AIzaSyBUy_tQOz4lQOf0czUBr0l4pZZZmaQA4rI';
  // List of YouTube channel IDs.
  final List<String> channelIds = [
    'UCt4t-jeY85JegMlZ-E5UWtA',
    'UCx8Z14PpntdaxCt2hakbQLQ',
    'UCD3CdwT8lTCe5ZGHbUBxmWA',
  ];

  late final YouTubeApiService apiService;
  late final Future<List<Map<String, dynamic>>> futureFeed;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    apiService = YouTubeApiService(apiKey: apiKey);
    futureFeed = _fetchFeed();
  }

  Future<List<Map<String, dynamic>>> _fetchFeed() async {
    // Fetch video reels from all channels concurrently.
    final List<List<VideoModel>> videoLists = await Future.wait(
      channelIds.map((id) => apiService.fetchShorts(channelId: id)),
    );

    // Flatten all videos into one list.
    final List<VideoModel> videos = videoLists.expand((list) => list).toList();

    // Save to the global cache.
    YouTubeApiService.cachedShorts = videos;

    // Map the videos to feed items.
    final videoFeed =
    videos.map((video) => {'type': 'video', 'data': video}).toList();

    // Shuffle the feed to randomize order.
    videoFeed.shuffle();

    return videoFeed;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// When the vertical drag ends, check the swipe velocity.
  void _onVerticalDragEnd(DragEndDetails details, int totalPages) {
    const swipeThreshold = 100;
    final double velocity = details.primaryVelocity ?? 0;
    final int currentPage = _pageController.page?.round() ?? 0;
    if (velocity < -swipeThreshold && currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (velocity > swipeThreshold && currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _navigateBack() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('preferred_language') ?? 'en';
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(language: lang)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // This callback intercepts system back gestures.
      onWillPop: () async {
        await _navigateBack();
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
              future: futureFeed,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No content found.'));
                } else {
                  final feedItems = snapshot.data!;
                  return GestureDetector(
                    // Wrap the PageView in a GestureDetector to handle swipe gestures.
                    onVerticalDragEnd: (details) =>
                        _onVerticalDragEnd(details, feedItems.length),
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      itemCount: feedItems.length,
                      itemBuilder: (context, index) {
                        final item = feedItems[index];
                        if (item['type'] == 'video') {
                          final video = item['data'] as VideoModel;
                          return ReelsContainer(video: video);
                        } else if (item['type'] == 'news') {
                          final news = item['data'] as NewsModel;
                          return NewsContainer(
                            imgUrl: news.image,
                            imgDesc: news.head,
                            newsHead: news.head,
                            newsDesc: news.desc,
                            newsUrl: news.newsUrl,
                            isBookmarked: false,
                            onBookmarkToggle: () {},
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  );
                }
              },
            ),
            // iOS-style back button at the top left.
            Positioned(
              top: 40,
              left: 16,
              child: IconButton(
                icon:
                const Icon(CupertinoIcons.back, color: Colors.white, size: 28),
                onPressed: _navigateBack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
