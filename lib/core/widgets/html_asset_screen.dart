import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Displays a bundled HTML asset inside the app.
class HtmlAssetScreen extends StatefulWidget {
  final String title;
  final String assetPath;
  const HtmlAssetScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<HtmlAssetScreen> createState() => _HtmlAssetScreenState();
}

class _HtmlAssetScreenState extends State<HtmlAssetScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            // Open mailto:, tel: and web links outside the app.
            if (!request.url.startsWith('file:') &&
                !request.url.startsWith('about:') &&
                !request.url.startsWith('data:')) {
              launchUrl(Uri.parse(request.url),
                  mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadFlutterAsset(widget.assetPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1B2B6B),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
