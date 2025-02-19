import 'package:flutter/material.dart';
import 'video_model.dart';
import 'news_model.dart';
import '/youtube_api_service.dart';
import '/view/Widgets/reels_container.dart';
import '/view/Widgets/NewsContainer.dart';

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
    // Add more channel IDs as needed.
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

    // Map the videos to feed items.
    final videoFeed =
    videos.map((video) => {'type': 'video', 'data': video}).toList();

    // Remove dummy news; feed consists solely of videos.
    final List<Map<String, dynamic>> combinedFeed = [...videoFeed];

    // Shuffle the combined feed to randomize the order.
    combinedFeed.shuffle();

    return combinedFeed;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// When the vertical drag ends, check the swipe velocity.
  /// If it exceeds the threshold, animate to next or previous page.
  void _onVerticalDragEnd(DragEndDetails details, int totalPages) {
    const swipeThreshold = 100; // Adjust this threshold as needed.
    final double velocity = details.primaryVelocity ?? 0;
    final int currentPage = _pageController.page?.round() ?? 0;

    if (velocity < -swipeThreshold && currentPage < totalPages - 1) {
      // Swipe up: move to next page.
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (velocity > swipeThreshold && currentPage > 0) {
      // Swipe down: move to previous page.
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Immersive experience without an AppBar.
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
              // Wrap the PageView in a GestureDetector so that swipe gestures
              // trigger page animations instead of the built-in physics.
              onVerticalDragEnd: (details) =>
                  _onVerticalDragEnd(details, feedItems.length),
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable default scroll physics.
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
                      newsDesc: news.desc, // Passing the detailed description.
                      newsUrl: news.newsUrl,
                      isBookmarked: false,
                      onBookmarkToggle: () {
                        // Implement your bookmark logic here.
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            );
          }
        },
      ),
    );
  }
}
