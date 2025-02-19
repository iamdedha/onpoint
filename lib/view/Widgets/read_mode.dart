// read_mode.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '/../news_model.dart';

/// Global settings for the app.
class AppSettings {
  static final ValueNotifier<bool> globalDarkModeNotifier = ValueNotifier<bool>(false);
}

class ReadModePage extends StatefulWidget {
  final List<NewsModel> newsList;
  final int initialIndex;

  const ReadModePage({
    Key? key,
    required this.newsList,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<ReadModePage> createState() => _ReadModePageState();
}

class _ReadModePageState extends State<ReadModePage> {
  double textScale = 1.0;
  bool showControls = false;
  late final PageController _pageController;
  bool isNightMode = false;

  @override
  void initState() {
    super.initState();
    // Initialize dark mode from the global notifier.
    isNightMode = AppSettings.globalDarkModeNotifier.value;
    AppSettings.globalDarkModeNotifier.addListener(_updateDarkMode);
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void _updateDarkMode() {
    setState(() {
      isNightMode = AppSettings.globalDarkModeNotifier.value;
    });
  }

  @override
  void dispose() {
    AppSettings.globalDarkModeNotifier.removeListener(_updateDarkMode);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kindle-style themes.
    // Light mode: warm off-white background with dark brown text.
    // Dark mode: warm dark gray background with light beige text.
    final backgroundColor = isNightMode ? const Color(0xFF2C2C2C) : const Color(0xFFFBF2E7);
    final textColor = isNightMode ? const Color(0xFFEDE0D4) : Colors.brown[900];

    final headerTextStyle = TextStyle(
      fontFamily: 'Georgia',
      fontSize: 28 * textScale,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
    final bodyTextStyle = TextStyle(
      fontFamily: 'Georgia',
      fontSize: 20 * textScale,
      height: 1.6,
      color: textColor,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: GestureDetector(
        onTap: () {
          setState(() {
            showControls = !showControls;
          });
        },
        child: Stack(
          children: [
            // Vertical PageView for articles.
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: widget.newsList.length,
              itemBuilder: (context, index) {
                final news = widget.newsList[index];
                return Container(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  color: backgroundColor,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(news.head, style: headerTextStyle),
                        const SizedBox(height: 24),
                        Text(
                          news.desc.isEmpty ? news.head : news.desc,
                          style: bodyTextStyle,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Bottom control bar with slider and dark mode toggle.
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isNightMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: textScale,
                          min: 0.8,
                          max: 1.3, // Maximum 130%
                          divisions: 10,
                          label: "${(textScale * 100).round()}%",
                          onChanged: (value) {
                            setState(() {
                              textScale = value;
                            });
                          },
                          onChangeEnd: (value) {
                            HapticFeedback.selectionClick();
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Toggle global dark mode.
                          AppSettings.globalDarkModeNotifier.value = !AppSettings.globalDarkModeNotifier.value;
                          HapticFeedback.selectionClick();
                        },
                        icon: Icon(
                          isNightMode ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // iOS left arrow at bottom left to go back.
            Positioned(
              bottom: 40,
              left: 20,
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  CupertinoIcons.back,
                  color: textColor,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
