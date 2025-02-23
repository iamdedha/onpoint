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
import 'Widgets/read_mode.dart'; // For read mode
import 'package:flutter/services.dart'; // For haptic feedback
import '/view/Widgets/explore_page.dart'; // <--- ADDED THIS IMPORT

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
      final url = Uri.parse('http://192.168.183.15:5000/news');
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
          .where((news) =>
          news.head.toLowerCase().contains(_searchQuery.toLowerCase()))
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
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
                            transitionDuration:
                            const Duration(milliseconds: 300),
                            pageBuilder: (context, animation,
                                secondaryAnimation) =>
                                NewsWebView(url: news.newsUrl),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              final tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(
                                  curve: Curves.easeInOut));
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
                              icon: const Icon(Icons.bookmark,
                                  color: Colors.blue),
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

// ------------------------------
// NewsFeedPage uses NewsStack for the stacked card effect
// ------------------------------
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
            : NewsStack(
          newsList: widget.newsList,
          bookmarkedNews: widget.bookmarkedNews,
          onBookmarkToggle: widget.onBookmarkToggle,
          onReadMode: (index) {
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
        ),
        // Videocam toggle at the top center
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: widget.onToggleMode,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x99000000),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.videocam,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------
// NewsStack: A stack of news cards with draggable top card that moves with the swipe.
// When swiped up, the card is removed; when swiped down, if a previously removed card exists,
// that card is restored as the background.
// ------------------------------
class NewsStack extends StatefulWidget {
  final List<NewsModel> newsList;
  final List<NewsModel> bookmarkedNews;
  final Function(NewsModel) onBookmarkToggle;
  final Function(int index) onReadMode;

  const NewsStack({
    Key? key,
    required this.newsList,
    required this.bookmarkedNews,
    required this.onBookmarkToggle,
    required this.onReadMode,
  }) : super(key: key);

  @override
  _NewsStackState createState() => _NewsStackState();
}

class _NewsStackState extends State<NewsStack>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  final double swipeUpThreshold = -100.0;
  final double swipeDownThreshold = 100.0;
  final List<NewsModel> _removedNews = [];

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  }

  void _animateBack() {
    _animation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    )..addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });
    _animationController.forward(from: 0);
  }

  // Leaving bounce effect logic in place as requested
  void _animateOffScreen(double targetOffset, VoidCallback onAnimationComplete) {
    _animation = Tween<double>(begin: _dragOffset, end: targetOffset).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    )..addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });
    _animationController.forward(from: 0).whenComplete(() {
      onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Decide which background news to show.
    NewsModel? backgroundNews;
    if (_dragOffset > 0 && _removedNews.isNotEmpty) {
      backgroundNews = _removedNews.last;
    } else if (widget.newsList.length > 1) {
      backgroundNews = widget.newsList[1];
    }

    return Stack(
      children: [
        if (backgroundNews != null)
          Positioned.fill(
            child: NewsContainer(
              imgDesc: backgroundNews.head,
              imgUrl: backgroundNews.image,
              newsHead: backgroundNews.head,
              newsDesc: backgroundNews.desc,
              newsUrl: backgroundNews.newsUrl,
              isBookmarked: widget.bookmarkedNews.contains(backgroundNews),
              onBookmarkToggle: () => widget.onBookmarkToggle(backgroundNews!),
              onReadMode: () => widget.onReadMode(1),
              // Minimal addition for the Explore button:
              onExploreTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExplorePage(newsList: widget.newsList),
                  ),
                );
              },
            ),
          ),
        if (widget.newsList.isNotEmpty)
          GestureDetector(
            onPanUpdate: (details) {
              // THIS IS THE ONLY ADDITION: check that vertical displacement dominates
              if (details.delta.dy.abs() > details.delta.dx.abs()) {
                setState(() {
                  _dragOffset += details.delta.dy;
                });
              }
            },
            onPanEnd: (details) {
              final screenHeight = MediaQuery.of(context).size.height;
              if (_dragOffset < swipeUpThreshold) {
                _animateOffScreen(-screenHeight, () {
                  setState(() {
                    _removedNews.add(widget.newsList[0]);
                    widget.newsList.removeAt(0);
                    _dragOffset = 0.0;
                  });
                });
              } else if (_dragOffset > swipeDownThreshold) {
                if (_removedNews.isNotEmpty) {
                  _animateOffScreen(screenHeight, () {
                    setState(() {
                      widget.newsList.insert(0, _removedNews.removeLast());
                      _dragOffset = 0.0;
                    });
                  });
                } else {
                  _animateBack();
                }
              } else {
                _animateBack();
              }
            },
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: NewsContainer(
                imgDesc: widget.newsList[0].head,
                imgUrl: widget.newsList[0].image,
                newsHead: widget.newsList[0].head,
                newsDesc: widget.newsList[0].desc,
                newsUrl: widget.newsList[0].newsUrl,
                isBookmarked:
                widget.bookmarkedNews.contains(widget.newsList[0]),
                onBookmarkToggle: () =>
                    widget.onBookmarkToggle(widget.newsList[0]),
                onReadMode: () => widget.onReadMode(0),
                // Minimal addition for the Explore button:
                onExploreTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExplorePage(newsList: widget.newsList),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
