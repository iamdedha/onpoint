// ExplorePage.dart

import 'dart:convert';                // for jsonEncode/jsonDecode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '/news_model.dart';
import '/view/Widgets/NewsContainer.dart';
import 'reels_container.dart';       // Make sure this import path is correct
import '/video_model.dart';          // See example VideoModel below
import '/youtube_api_service.dart';

//////////////////////////////////////////////////////////////
// Example VideoModel (must have fromJson + toJson)
//////////////////////////////////////////////////////////////
/*
class VideoModel {
  final String videoId;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String publishedAt;

  VideoModel({
    required this.videoId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.publishedAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      videoId: json['videoId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      publishedAt: json['publishedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'publishedAt': publishedAt,
    };
  }
}
*/

//////////////////////////////////////////////////////////////
// Constants for caching
//////////////////////////////////////////////////////////////
const int _kReelsCacheDurationMs = 12 * 60 * 60 * 1000;  // 12 hours in ms
const String _kCachedReelsKey = "cached_reels";
const String _kCachedReelsExpiryKey = "cached_reels_expiry";

//////////////////////////////////////////////////////////////
// ExploreItem: union of a NewsModel or a VideoModel
//////////////////////////////////////////////////////////////
class ExploreItem {
  final NewsModel? news;
  final VideoModel? video;

  ExploreItem.news(this.news) : video = null;
  ExploreItem.video(this.video) : news = null;

  bool get isNews => news != null;
  bool get isVideo => video != null;
}

//////////////////////////////////////////////////////////////
// MutedReelTile: A YouTube player that autoplays muted
//////////////////////////////////////////////////////////////
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
      flags: const YoutubePlayerFlags(
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

//////////////////////////////////////////////////////////////
// LazyMutedReelTile: Only builds the player when visible
//////////////////////////////////////////////////////////////
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
      onVisibilityChanged: (info) {
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

//////////////////////////////////////////////////////////////
// ExploreReelPage: full-screen reel with transparent AppBar
//////////////////////////////////////////////////////////////
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
      flags: const YoutubePlayerFlags(
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
      // Transparent AppBar with iOS-style back arrow
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

//////////////////////////////////////////////////////////////
// ExplorePage: Paginated loading + Reels caching
//////////////////////////////////////////////////////////////
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
  final int _pageSize = 12; // # news items per page

  // The final displayed reels
  List<VideoModel> _reels = [];

  // State for pagination
  bool _isLoadingPage = false;
  bool _allNewsLoaded = false;

  //////////////////////////////////////////////////////
  // GET FILTERED NEWS from the original newsList
  //////////////////////////////////////////////////////
  List<NewsModel> get _filteredNews {
    if (_searchQuery.trim().isEmpty) return widget.newsList;
    final query = _searchQuery.toLowerCase();
    return widget.newsList.where((news) {
      return news.head.toLowerCase().contains(query) ||
          news.desc.toLowerCase().contains(query);
    }).toList();
  }

  //////////////////////////////////////////////////////
  // GET FILTERED ALREADY LOADED items (news + reels)
  //////////////////////////////////////////////////////
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

  //////////////////////////////////////////////////////
  // INIT STATE
  //////////////////////////////////////////////////////
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      // If user is near bottom, try loading next page
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadNextPage();
      }
    });

    // 1) Load Reels (from cache or from network)
    _fetchReels().then((reels) {
      setState(() => _reels = reels);
      // 2) Load first page after we have reels
      _loadNextPage();
    });
  }

  //////////////////////////////////////////////////////
  // DISPOSE
  //////////////////////////////////////////////////////
  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  //////////////////////////////////////////////////////
  // fetchReels with caching
  //////////////////////////////////////////////////////
  Future<List<VideoModel>> _fetchReels() async {
    final channelIds = [
      'UCt4t-jeY85JegMlZ-E5UWtA',
      'UCx8Z14PpntdaxCt2hakbQLQ',
      'UCD3CdwT8lTCe5ZGHbUBxmWA',
    ];

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final cachedExpiry = prefs.getInt(_kCachedReelsExpiryKey) ?? 0;

    // 1) If cache not expired, try to load from it
    if (now < cachedExpiry) {
      final cachedReelsJson = prefs.getString(_kCachedReelsKey);
      if (cachedReelsJson != null && cachedReelsJson.isNotEmpty) {
        try {
          final List<dynamic> jsonList = jsonDecode(cachedReelsJson);
          final List<VideoModel> cachedReels = jsonList.map((data) {
            return VideoModel.fromJson(data as Map<String, dynamic>);
          }).toList();
          if (cachedReels.isNotEmpty) {
            print("Returning reels from cache.");
            return cachedReels..shuffle();
          }
        } catch (e) {
          print("Error parsing cached reels: $e");
          // fallback to fresh fetch
        }
      }
    }

    // 2) If no valid cache, fetch from YouTube
    try {
      final apiService = YouTubeApiService(apiKey: 'YOUR_API_KEY_HERE');
      final videoLists = await Future.wait(
        channelIds.map((id) => apiService.fetchShorts(channelId: id)),
      );
      final reels = videoLists.expand((list) => list).toList();
      reels.shuffle();

      // Save them to cache
      final newExpiry = now + _kReelsCacheDurationMs;
      await prefs.setString(_kCachedReelsKey, jsonEncode(reels));
      await prefs.setInt(_kCachedReelsExpiryKey, newExpiry);

      return reels;
    } catch (e) {
      print("Error fetching reels: $e");
      // 3) fallback dummy
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

  //////////////////////////////////////////////////////
  // Load next page of news + 1 reel
  //////////////////////////////////////////////////////
  void _loadNextPage() {
    if (_isLoadingPage || _allNewsLoaded) return;
    _isLoadingPage = true;

    final news = _filteredNews; // filtered news by search
    final startIndex = _currentPage * _pageSize;
    if (startIndex >= news.length) {
      // no more news to load
      _allNewsLoaded = true;
      _isLoadingPage = false;
      return;
    }

    final endIndex = ((_currentPage + 1) * _pageSize).clamp(0, news.length);
    final pageNews = news.sublist(startIndex, endIndex);
    final newItems = pageNews.map((n) => ExploreItem.news(n)).toList();

    // Insert one reel at the end of each page
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

  //////////////////////////////////////////////////////
  // BUILD
  //////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ensures white grid lines
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
            onChanged: (val) {
              setState(() => _searchQuery = val);
            },
            style: const TextStyle(color: Colors.black),
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
          // If scrolled near bottom, load next page
          if (
          !_isLoadingPage &&
              scrollInfo.metrics.pixels >= (scrollInfo.metrics.maxScrollExtent - 200)
          ) {
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
                  // Show the single news in a new page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: Colors.white,
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
                child: SizedBox(
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
            } else {
              // item is a reel (video)
              final video = item.video!;
              return GestureDetector(
                onTap: () {
                  // Full-screen reel
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExploreReelPage(video: video),
                    ),
                  );
                },
                child: SizedBox(
                  height: 150,
                  child: LazyMutedReelTile(video: video),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
