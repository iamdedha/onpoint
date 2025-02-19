import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NewsWebView extends StatefulWidget {
  final String url;
  const NewsWebView({Key? key, required this.url}) : super(key: key);

  @override
  State<NewsWebView> createState() => _NewsWebViewState();
}

class _NewsWebViewState extends State<NewsWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the device is in dark mode.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Use your dark mode combination: dark gray and light beige.
    final appBarBackgroundColor = isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey;
    final textColor = isDarkMode ? const Color(0xFFEDE0D4) : Colors.white;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: appBarBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Full Article',
          style: TextStyle(
            color: textColor,
            fontFamily: 'SF Pro Display',
          ),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
