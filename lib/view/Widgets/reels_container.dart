// reels_container.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '/video_model.dart';
import '/view/home.dart'; // Ensure this import is correct

class ReelsContainer extends StatefulWidget {
  final VideoModel video;
  const ReelsContainer({Key? key, required this.video}) : super(key: key);

  @override
  _ReelsContainerState createState() => _ReelsContainerState();
}

class _ReelsContainerState extends State<ReelsContainer> {
  late YoutubePlayerController _controller;
  double _sliderValue = 0.0;
  bool _isLiked = false;
  int _likeCount = 0;
  DateTime? _lastHapticFeedback;
  bool _initialLoadComplete = false;

  // Accumulate horizontal drag distance.
  double _dragDx = 0.0;

  @override
  void initState() {
    super.initState();
    _initialLoadComplete = false;
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: true,
        hideControls: true,
      ),
    );

    _controller.addListener(() {
      if (mounted) {
        final position = _controller.value.position;
        final duration = _controller.metadata.duration;
        if (duration.inSeconds > 0) {
          final newSliderValue = position.inSeconds / duration.inSeconds;
          final clampedValue = newSliderValue.clamp(0.0, 1.0);
          if ((clampedValue - _sliderValue).abs() > 0.01) {
            setState(() {
              _sliderValue = clampedValue;
            });
          }
        }
        if (_controller.value.playerState == PlayerState.playing && !_initialLoadComplete) {
          setState(() {
            _initialLoadComplete = true;
          });
        }
        if (_controller.value.playerState == PlayerState.ended) {
          _controller.seekTo(Duration.zero);
          _controller.play();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _onSliderChanged(double value) {
    final clampedValue = value.clamp(0.0, 1.0) as double;
    final duration = _controller.metadata.duration;
    final newPosition = Duration(seconds: (duration.inSeconds * clampedValue).round());
    _controller.seekTo(newPosition);
    final now = DateTime.now();
    if (_lastHapticFeedback == null ||
        now.difference(_lastHapticFeedback!) > const Duration(milliseconds: 85)) {
      HapticFeedback.selectionClick();
      _lastHapticFeedback = now;
    }
  }

  void _toggleLike() {
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likeCount = _likeCount > 0 ? _likeCount - 1 : 0;
      } else {
        _isLiked = true;
        _likeCount++;
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _shareVideo() {
    final videoUrl = "https://youtu.be/${widget.video.videoId}";
    Share.share(videoUrl);
  }

  void _navigateHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Override system back gesture.
      onWillPop: () async {
        _navigateHome();
        return false;
      },
      child: GestureDetector(
        // Accumulate horizontal drag updates.
        onHorizontalDragUpdate: (details) {
          _dragDx += details.delta.dx;
          if (_dragDx.abs() > 100) {
            _navigateHome();
          }
        },
        onHorizontalDragEnd: (_) {
          _dragDx = 0.0;
        },
        child: Stack(
          children: [
            // Video player.
            RepaintBoundary(
              child: SizedBox.expand(
                child: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: false,
                ),
              ),
            ),
            // Full-screen area for toggling play/pause.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _togglePlayPause,
                child: Container(),
              ),
            ),
            // Overlay until video loads.
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _initialLoadComplete,
                child: AnimatedOpacity(
                  opacity: _initialLoadComplete ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Heading overlay.
            Positioned(
              left: 20,
              right: 20,
              bottom: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      HtmlUnescape().convert(widget.video.title),
                      style: const TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ),
            ),
            // Slider at the bottom.
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white38,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.2),
                ),
                child: Slider(
                  value: _sliderValue.clamp(0.0, 1.0) as double,
                  onChanged: (value) {
                    final clampedValue = value.clamp(0.0, 1.0) as double;
                    setState(() {
                      _sliderValue = clampedValue;
                    });
                    _onSliderChanged(clampedValue);
                  },
                ),
              ),
            ),
            // Like and Share buttons.
            Positioned(
              right: 16,
              bottom: 180,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : Colors.white,
                      size: 24,
                    ),
                    onPressed: _toggleLike,
                  ),
                  Text(
                    '$_likeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  IconButton(
                    icon: Transform.rotate(
                      angle: -0.7,
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    onPressed: _shareVideo,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
