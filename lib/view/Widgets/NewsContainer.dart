import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For CupertinoIcons
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/view/Widgets/news_webview.dart';
import 'read_mode.dart'; // Contains AppSettings and read mode
import 'image_gallery.dart'; // Import the updated image gallery screen

class NewsContainer extends StatefulWidget {
  final String imgUrl;
  final String imgDesc;
  final String newsDesc;
  final String newsUrl;
  final String newsHead;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback? onReadMode;     // Callback for entering read mode

  // NEW: Add a callback for tapping the Explore button
  final VoidCallback? onExploreTap;   // <--- THIS LINE

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
    this.onExploreTap,               // <--- THIS LINE
  }) : super(key: key);

  @override
  State<NewsContainer> createState() => _NewsContainerState();
}

class _NewsContainerState extends State<NewsContainer> {
  bool _hasTriggeredLeftSwipe = false;
  Offset? _initialPosition;

  void _openFullArticle() {
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
            final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
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
        final backgroundColor =
        isDarkMode ? const Color(0xFF2C2C2C) : Colors.white;
        final textColor =
        isDarkMode ? const Color(0xFFEDE0D4) : Colors.black87;

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
                // Main content with image and text.
                Column(
                  children: [
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
                                    widget.newsDesc.isEmpty
                                        ? widget.imgDesc
                                        : widget.newsDesc,
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
                // Bottom icons row: WhatsApp, Explore, Dark Mode Toggle, Forward Arrow.
                Positioned(
                  bottom: 40,
                  left: 30,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // WhatsApp Icon.
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 300),
                              pageBuilder: (_, __, ___) => ImageGalleryScreen(
                                imageUrls: [
                                  "https://nis-gs.pix.in/inshorts/images/v1/variants/webp/xs/2025/02_feb/17_mon/img_1739789086138_136.webp",
                                  "https://nis-gs.pix.in/inshorts/images/v1/variants/webp/xs/2025/02_feb/17_mon/img_1739777276234_68.webp",
                                  "https://nis-gs.pix.in/inshorts/images/v1/variants/webp/xs/2025/02_feb/17_mon/img_1739765481462_303.webp",
                                  "https://nis-gs.pix.in/inshorts/images/v1/variants/webp/xs/2025/02_feb/17_mon/img_1739761899561_190.webp",
                                  "https://nis-gs.pix.in/inshorts/images/v1/variants/webp/xs/2025/02_feb/17_mon/img_1739761854764_294.webp",
                                  "https://nis-gs.pix.in/inshorts/images/v1/variants/webp/xs/2025/02_feb/17_mon/img_1739761183324_194.webp",
                                  "https://nis-gs.pix.in/inshorts/images/v1/variants/webp/xs/2025/02_feb/17_mon/img_1739761182237_422.webp",
                                  "https://nis-gs.pix.in/inshorts/images/v1/variants/webp/xs/2025/02_feb/17_mon/img_1739761122379_235.webp",
                                  "https://nis-gs.pix.in/inshorts/images/v1/variants/webp/xs/2025/02_feb/17_mon/img_1739759658069_123.webp",
                                ],
                              ),
                              transitionsBuilder: (_, animation, __, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: isDarkMode ? Colors.blueGrey : Colors.green,
                          size: 30,
                        ),
                      ),
                      // Explore / Magnifying Glass Icon.
                      GestureDetector(
                        onTap: widget.onExploreTap,  // <--- CALLS THE NEW CALLBACK
                        child: Icon(
                          Icons.search,
                          color: isDarkMode ? Colors.blueGrey : Colors.blue,
                          size: 32,
                        ),
                      ),
                      // Dark Mode Toggle.
                      Material(
                        color: Colors.transparent,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            AppSettings.globalDarkModeNotifier.value =
                            !AppSettings.globalDarkModeNotifier.value;
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
                                children: <Widget>[currentChild!, ...previousChildren],
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
                                  color: Colors.amber,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Forward Arrow Icon.
                      IconButton(
                        onPressed: _openFullArticle,
                        icon: Icon(
                          CupertinoIcons.forward,
                          color: isDarkMode ? Colors.white54 : Colors.black54,
                          size: 28,
                        ),
                      ),
                    ],
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
