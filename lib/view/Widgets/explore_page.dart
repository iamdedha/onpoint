import 'package:flutter/material.dart';
import '/news_model.dart';
import '/view/Widgets/NewsContainer.dart';
import 'reels_container.dart';
import '/video_model.dart';
import '/youtube_api_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// A union class that holds either a news item or a reel video.
class ExploreItem {
  final NewsModel? news;
  final VideoModel? video;

  ExploreItem.news(this.news) : video = null;
  ExploreItem.video(this.video) : news = null;

  bool get isNews => news != null;
  bool get isVideo => video != null;
}

/// This widget shows a YouTube player that autoplays muted.
class MutedReelTile extends StatefulWidget {
  final VideoModel video;
  const MutedReelTile({Key? key, required this.video}) : super(key: key);

  @override
  _MutedReelTileState createState() => _MutedReelTileState();
}

class _MutedReelTileState extends State<MutedReelTile> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: true,
        loop: true,
        hideControls: true,
        disableDragSeek: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _controller,
      showVideoProgressIndicator: false,
      progressIndicatorColor: Colors.transparent,
    );
  }
}

/// Lazy version of MutedReelTile to build the player only when visible.
class LazyMutedReelTile extends StatefulWidget {
  final VideoModel video;
  const LazyMutedReelTile({Key? key, required this.video}) : super(key: key);

  @override
  _LazyMutedReelTileState createState() => _LazyMutedReelTileState();
}

class _LazyMutedReelTileState extends State<LazyMutedReelTile> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.video.videoId),
      onVisibilityChanged: (VisibilityInfo info) {
        if (mounted) {
          setState(() {
            _isVisible = info.visibleFraction > 0.5;
          });
        }
      },
      child: _isVisible
          ? MutedReelTile(video: widget.video)
          : Image.network(
        widget.video.thumbnailUrl,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Full-screen reel page launched from Explore.
class ExploreReelPage extends StatefulWidget {
  final VideoModel video;
  const ExploreReelPage({Key? key, required this.video}) : super(key: key);

  @override
  _ExploreReelPageState createState() => _ExploreReelPageState();
}

class _ExploreReelPageState extends State<ExploreReelPage> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: true,
        hideControls: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent AppBar with an iOS-style back arrow.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SizedBox.expand(
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: false,
        ),
      ),
    );
  }
}

//////////////////////////////////////////////
/// ExplorePage with paginated loading.
class ExplorePage extends StatefulWidget {
  final List<NewsModel> newsList;
  const ExplorePage({Key? key, required this.newsList}) : super(key: key);

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  late ScrollController _scrollController;
  List<ExploreItem> _loadedItems = [];
  int _currentPage = 0;
  final int _pageSize = 10; // number of news items per page

  List<NewsModel> get _filteredNews {
    if (_searchQuery.trim().isEmpty) return widget.newsList;
    final query = _searchQuery.toLowerCase();
    return widget.newsList.where((news) {
      return news.head.toLowerCase().contains(query) ||
          news.desc.toLowerCase().contains(query);
    }).toList();
  }

  List<ExploreItem> get _filteredLoadedItems {
    if (_searchQuery.trim().isEmpty) return _loadedItems;
    final query = _searchQuery.toLowerCase();
    return _loadedItems.where((item) {
      if (item.isNews) {
        return item.news!.head.toLowerCase().contains(query) ||
            item.news!.desc.toLowerCase().contains(query);
      } else if (item.isVideo) {
        return item.video!.title.toLowerCase().contains(query) ||
            item.video!.description.toLowerCase().contains(query);
      }
      return false;
    }).toList();
  }

  List<VideoModel> _reels = [];
  bool _isLoadingPage = false;
  bool _allNewsLoaded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadNextPage();
      }
    });
    _fetchReels().then((reels) {
      setState(() {
        _reels = reels;
      });
      _loadNextPage(); // Load first page after reels are fetched.
    });
  }

  Future<List<VideoModel>> _fetchReels() async {
    final List<String> channelIds = [
      'UCt4t-jeY85JegMlZ-E5UWtA',
      'UCx8Z14PpntdaxCt2hakbQLQ',
      'UCD3CdwT8lTCe5ZGHbUBxmWA',
    ];
    final prefs = await SharedPreferences.getInstance();
    for (var id in channelIds) {
      await prefs.remove('shorts_$id');
      await prefs.remove('shorts_${id}_expiry');
    }
    try {
      final apiService = YouTubeApiService(apiKey: 'AIzaSyBUy_tQOz4lQOf0czUBr0l4pZZZmaQA4rI');
      final List<List<VideoModel>> videoLists = await Future.wait(
        channelIds.map((id) => apiService.fetchShorts(channelId: id)),
      );
      final List<VideoModel> reels = videoLists.expand((list) => list).toList();
      reels.shuffle();
      return reels;
    } catch (e) {
      print("Error fetching reels: $e");
      // Fallback dummy reels.
      return [
        VideoModel(
          videoId: "dQw4w9WgXcQ",
          title: "Dummy Video 1",
          description: "Dummy description 1",
          thumbnailUrl: "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
          publishedAt: "2021-01-01T00:00:00Z",
        ),
        VideoModel(
          videoId: "3JZ_D3ELwOQ",
          title: "Dummy Video 2",
          description: "Dummy description 2",
          thumbnailUrl: "https://img.youtube.com/vi/3JZ_D3ELwOQ/hqdefault.jpg",
          publishedAt: "2021-01-01T00:00:00Z",
        ),
      ];
    }
  }

  // Load the next page: _pageSize news items plus one reel at the end.
  void _loadNextPage() {
    if (_isLoadingPage || _allNewsLoaded) return;
    _isLoadingPage = true;
    final news = _filteredNews;
    final startIndex = _currentPage * _pageSize;
    if (startIndex >= news.length) {
      _allNewsLoaded = true;
      _isLoadingPage = false;
      return;
    }
    final endIndex = ((_currentPage + 1) * _pageSize).clamp(0, news.length);
    final pageNews = news.sublist(startIndex, endIndex);
    List<ExploreItem> newItems =
    pageNews.map((n) => ExploreItem.news(n)).toList();
    // Insert one reel at the end of this page if available.
    if (_reels.isNotEmpty) {
      final reel = _reels[_currentPage % _reels.length];
      newItems.add(ExploreItem.video(reel));
    }
    setState(() {
      _loadedItems.addAll(newItems);
      _currentPage++;
      _isLoadingPage = false;
    });
    print("Loaded page $_currentPage, total items: ${_loadedItems.length}");
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with a search bar styled like Instagram's.
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: const InputDecoration(
              hintText: "Search",
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
            ),
          ),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (!_isLoadingPage &&
              scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200) {
            _loadNextPage();
            return true;
          }
          return false;
        },
        child: MasonryGridView.count(
          controller: _scrollController,
          padding: const EdgeInsets.all(2.0),
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          itemCount: _filteredLoadedItems.length,
          itemBuilder: (context, index) {
            final item = _filteredLoadedItems[index];
            if (item.isNews) {
              final news = item.news!;
              return GestureDetector(
                onTap: () {
                  // Open the short news view.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        body: NewsContainer(
                          imgUrl: news.image,
                          imgDesc: news.head,
                          newsHead: news.head,
                          newsDesc: news.desc,
                          newsUrl: news.newsUrl,
                          isBookmarked: false,
                          onBookmarkToggle: () {},
                          onReadMode: null,
                          onExploreTap: null,
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      news.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            } else if (item.isVideo) {
              final video = item.video!;
              return GestureDetector(
                onTap: () {
                  // Open the full-screen reel view with back arrow.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExploreReelPage(video: video),
                    ),
                  );
                },
                child: Container(
                  height: 300,
                  child: LazyMutedReelTile(video: video),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}
