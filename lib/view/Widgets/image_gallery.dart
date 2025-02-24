import 'dart:math' as math;
import 'dart:io'; // for File
import 'package:flutter/material.dart';

// Additional imports for file sharing
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ImageGalleryScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialShareCount; // e.g., 1194

  const ImageGalleryScreen({
    Key? key,
    required this.imageUrls,
    this.initialShareCount = 0,
  }) : super(key: key);

  @override
  _ImageGalleryScreenState createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  late int _shareCount;

  static const int maxDots = 7; // Maximum number of dots

  @override
  void initState() {
    super.initState();
    _pageController = PageController()
      ..addListener(() {
        setState(() {});
      });
    _shareCount = widget.initialShareCount;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Download the image to a file and share that file
  Future<void> _shareCurrentImageFile() async {
    final currentImageUrl = widget.imageUrls[_currentIndex];

    try {
      // 1. Create a temporary file path to save the image
      final tempDir = await getTemporaryDirectory();
      final fileName = p.basename(currentImageUrl);
      final filePath = p.join(tempDir.path, fileName);

      // 2. Download the image using Dio
      await Dio().download(currentImageUrl, filePath);

      // 3. Share the downloaded image
      setState(() {
        _shareCount++;
      });

      // With share_plus 4.0.0 or higher:
      await Share.shareXFiles(
        [XFile(filePath)],
        text: '',
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing image: $error')),
      );
    }
  }

  List<Widget> _buildDots(double page) {
    int total = widget.imageUrls.length;
    if (total <= maxDots) {
      return List.generate(total, (index) => _buildDot(index, page));
    } else {
      int start = math.max(0, _currentIndex - (maxDots ~/ 2));
      int end = start + maxDots - 1;
      if (end >= total) {
        end = total - 1;
        start = end - (maxDots - 1);
      }
      return List.generate(end - start + 1, (i) {
        int index = start + i;
        return _buildDot(index, page);
      });
    }
  }

  Widget _buildDot(int index, double page) {
    double diff = (index - page).abs();
    double selectedness = 1 - diff.clamp(0.0, 1.0);
    double dotSize = 6 + (10 - 6) * selectedness;
    bool isActive = _currentIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: dotSize,
      height: dotSize,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? Colors.black
            : Colors.black.withOpacity(0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double page = _pageController.hasClients
        ? (_pageController.page ?? _currentIndex.toDouble())
        : _currentIndex.toDouble();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.imageUrls.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  },
                ),
              ),
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Dots
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(children: _buildDots(page)),
                      ),
                    ),
                    // Center: WhatsApp Icon
                    GestureDetector(
                      onTap: _shareCurrentImageFile,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    // Right: Share Count (only if > 0)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _shareCount > 0
                            ? Text(
                          '$_shareCount SHARES',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Close button at top right
          Positioned(
            top: 40, // adjust if you have a SafeArea
            right: 16,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}