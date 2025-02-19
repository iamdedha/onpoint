// home.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For Cupertino icons
import 'package:http/http.dart' as http;
import '../news_model.dart';
import 'Widgets/NewsContainer.dart';
import 'Widgets/news_webview.dart';
import '/shorts_page.dart'; // For reels mode
import 'Widgets/read_mode.dart';   // For read mode
import 'package:flutter/services.dart'; // For haptic feedback

const String sampleReelVideoUrl =
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";

class HomeScreen extends StatefulWidget {
  final String language;
  const HomeScreen({Key? key, this.language = 'en'}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<NewsModel> newsList = [];
  List<NewsModel> bookmarkedNews = [];
  bool isReelsMode = false; // Toggle between articles and reels

  // Controller for vertical scrolling (articles mode).
  final PageController _verticalController = PageController();

  // Controller for horizontal swiping between bookmarks and news feed.
  final PageController _horizontalController = PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    try {
      // Append language query parameter to your API endpoint.
      final url = Uri.parse('http://192.168.1.14:5000/news');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          newsList = jsonData.map((item) => NewsModel.fromJson(item)).toList();
          newsList.shuffle();
        });
      } else {
        print("Failed to fetch news. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error occurred while fetching news: $e");
    }
  }

  void toggleBookmark(NewsModel news) {
    setState(() {
      if (bookmarkedNews.contains(news)) {
        bookmarkedNews.remove(news);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('News removed from saved'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        bookmarkedNews.insert(0, news);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('News saved. Swipe right to view saved news.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void toggleMode() {
    setState(() {
      isReelsMode = !isReelsMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: PageView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        children: [
          // Bookmarks Page.
          BookmarksPage(
            bookmarkedNews: bookmarkedNews,
            onBookmarkToggle: toggleBookmark,
            onBack: () {
              _horizontalController.animateToPage(
                1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          // News Feed Page.
          newsList.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : NewsFeedPage(
            newsList: newsList,
            bookmarkedNews: bookmarkedNews,
            onBookmarkToggle: toggleBookmark,
            verticalController: _verticalController,
            isReelsMode: isReelsMode,
            onToggleMode: toggleMode,
          ),
        ],
      ),
    );
  }
}

class BookmarksPage extends StatefulWidget {
  final List<NewsModel> bookmarkedNews;
  final Function(NewsModel) onBookmarkToggle;
  final VoidCallback onBack;

  const BookmarksPage({
    Key? key,
    required this.bookmarkedNews,
    required this.onBookmarkToggle,
    required this.onBack,
  }) : super(key: key);

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<NewsModel> get filteredBookmarks {
    if (_searchQuery.isEmpty) {
      return widget.bookmarkedNews;
    } else {
      return widget.bookmarkedNews
          .where((news) => news.head.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved News',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.forward, color: Colors.black87),
            onPressed: widget.onBack,
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredBookmarks.isEmpty
                ? Center(
              child: Text(
                'No Saved News',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredBookmarks.length,
              itemBuilder: (context, index) {
                final news = filteredBookmarks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(milliseconds: 300),
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                NewsWebView(url: news.newsUrl),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              final tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: Curves.easeInOut));
                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                news.image,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                news.head,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.bookmark, color: Colors.blue),
                              onPressed: () {
                                widget.onBookmarkToggle(news);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NewsFeedPage extends StatefulWidget {
  final List<NewsModel> newsList;
  final List<NewsModel> bookmarkedNews;
  final Function(NewsModel) onBookmarkToggle;
  final PageController verticalController;
  final bool isReelsMode;
  final VoidCallback onToggleMode;

  const NewsFeedPage({
    Key? key,
    required this.newsList,
    required this.bookmarkedNews,
    required this.onBookmarkToggle,
    required this.verticalController,
    required this.isReelsMode,
    required this.onToggleMode,
  }) : super(key: key);

  @override
  _NewsFeedPageState createState() => _NewsFeedPageState();
}

class _NewsFeedPageState extends State<NewsFeedPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  AnimationController? _wiggleController;
  Animation<double>? _wiggleAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _wiggleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _wiggleController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _wiggleController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        widget.isReelsMode
            ? const ShortsPage()
            : PageView.builder(
          key: const PageStorageKey('articles_page'),
          controller: widget.verticalController,
          scrollDirection: Axis.vertical,
          itemCount: widget.newsList.length,
          itemBuilder: (context, index) {
            final news = widget.newsList[index];
            final bool isBookmarked = widget.bookmarkedNews.contains(news);
            return NewsContainer(
              imgDesc: news.head,
              imgUrl: news.image,
              newsHead: news.head,
              newsDesc: news.desc,
              newsUrl: news.newsUrl,
              isBookmarked: isBookmarked,
              onBookmarkToggle: () => widget.onBookmarkToggle(news),
              onReadMode: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReadModePage(
                      newsList: widget.newsList,
                      initialIndex: index,
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _wiggleController?.forward(from: 0.0);
                widget.onToggleMode();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isReelsMode ? Colors.white24 : Colors.black54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(40, 40),
              ),
              child: AnimatedBuilder(
                animation: _wiggleAnimation ?? AlwaysStoppedAnimation(0.0),
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _wiggleAnimation?.value ?? 0.0,
                    child: child,
                  );
                },
                child: const Icon(
                  Icons.videocam,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
