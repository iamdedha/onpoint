import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For CupertinoIcons
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For WhatsApp icon
import '/view/Widgets/news_webview.dart';
import 'read_mode.dart'; // Import so we can reference AppSettings

class NewsContainer extends StatefulWidget {
  final String imgUrl;
  final String imgDesc;
  final String newsDesc;
  final String newsUrl;
  final String newsHead;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback? onReadMode; // Callback for entering read mode

  const NewsContainer({
    Key? key,
    required this.imgUrl,
    required this.imgDesc,
    required this.newsDesc,
    required this.newsHead,
    required this.newsUrl,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    this.onReadMode,
  }) : super(key: key);

  @override
  State<NewsContainer> createState() => _NewsContainerState();
}

class _NewsContainerState extends State<NewsContainer> {
  bool _hasTriggeredLeftSwipe = false;
  Offset? _initialPosition;

  void _openFullArticle() {
    // Check if the news URL is empty.
    if (widget.newsUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("There is no full news for this article."),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => NewsWebView(url: widget.newsUrl),
          transitionsBuilder: (_, animation, __, child) {
            final tween =
            Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      );
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _initialPosition = event.position;
    _hasTriggeredLeftSwipe = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_initialPosition != null && !_hasTriggeredLeftSwipe) {
      final dx = event.position.dx - _initialPosition!.dx;
      if (dx < -100) {
        _hasTriggeredLeftSwipe = true;
        _openFullArticle();
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _initialPosition = null;
    _hasTriggeredLeftSwipe = false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.globalDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        // Use Kindle-style colors for dark mode.
        final backgroundColor = isDarkMode ? const Color(0xFF2C2C2C) : Colors.white;
        final textColor = isDarkMode ? const Color(0xFFEDE0D4) : Colors.black87;

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            color: backgroundColor,
            child: Stack(
              children: [
                Column(
                  children: [
                    // Top image section.
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: SizedBox(
                        height: 350,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.network(
                                widget.imgUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.center,
                                    colors: [Colors.black45, Colors.transparent],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Scrollable text area.
                    Expanded(
                      child: Transform.translate(
                        offset: const Offset(0, -24),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                            child: GestureDetector(
                              onTap: () {
                                if (widget.newsUrl.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("There is no full news for this article."),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  if (widget.onReadMode != null) {
                                    widget.onReadMode!();
                                  }
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.newsHead,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.newsDesc.isEmpty ? widget.imgDesc : widget.newsDesc,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: textColor,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // "OnPoint" badge.
                Positioned(
                  top: 310,
                  left: 16,
                  child: GestureDetector(
                    onTap: () {
                      if (widget.newsUrl.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("There is no full news for this article."),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        if (widget.onReadMode != null) {
                          widget.onReadMode!();
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "OnPoint",
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : const Color(0xFF424242),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                // Bookmark button.
                Positioned(
                  top: 40,
                  left: 20,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onBookmarkToggle();
                    },
                    child: _buildCircleButton(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          key: ValueKey<bool>(widget.isBookmarked),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                // Share button.
                Positioned(
                  top: 40,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      Share.share('${widget.newsHead}\n\n${widget.newsUrl}');
                    },
                    child: _buildCircleButton(
                      child: Transform.rotate(
                        angle: -0.8,
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                // Dark mode toggle at bottom center.
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Hero(
                      tag: 'darkModeToggle',
                      child: Material(
                        color: Colors.transparent,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            AppSettings.globalDarkModeNotifier.value = !AppSettings.globalDarkModeNotifier.value;
                          },
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (child, animation) {
                              return RotationTransition(
                                turns: Tween(begin: 0.0, end: 1.0).animate(animation),
                                child: FadeTransition(opacity: animation, child: child),
                              );
                            },
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  if (currentChild != null) currentChild,
                                  ...previousChildren,
                                ],
                              );
                            },
                            child: isDarkMode
                                ? SizedBox(
                              key: const ValueKey('moon'),
                              width: 34,
                              height: 34,
                              child: Center(
                                child: Icon(
                                  Icons.bedtime,
                                  color: Colors.blueGrey,
                                  size: 32,
                                ),
                              ),
                            )
                                : SizedBox(
                              key: const ValueKey('sun'),
                              width: 32,
                              height: 32,
                              child: Center(
                                child: Icon(
                                  Icons.wb_sunny,
                                  color: Colors.amber[700],
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Forward arrow button.
                Positioned(
                  bottom: 40,
                  right: 20,
                  child: IconButton(
                    onPressed: _openFullArticle,
                    icon: Icon(
                      CupertinoIcons.forward,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                      size: 28,
                    ),
                  ),
                ),
                // WhatsApp button at bottom left with extra left margin.
                Positioned(
                  bottom: 40,
                  left: 30, // increased margin from left
                  child: GestureDetector(
                    onTap: () {
                      // Placeholder for WhatsApp action.
                    },
                    child: FaIcon(
                      FontAwesomeIcons.whatsapp,
                      color: isDarkMode ? Colors.blueGrey : Colors.green,
                      size: 30, // adjust size as desired
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircleButton({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
