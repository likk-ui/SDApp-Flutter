import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/api_service.dart';

class Section2Screen extends StatefulWidget {
  const Section2Screen({super.key});

  @override
  State<Section2Screen> createState() => _Section2ScreenState();
}

class _Section2ScreenState extends State<Section2Screen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() => _isLoading = true),
          onPageFinished: (url) => setState(() {
            _isLoading = false;
            _currentUrl = url;
          }),
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('在线播放器'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showAnimList,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _pickVideo,
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          if (_currentUrl.isEmpty && !_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline, size: 64, color: Colors.white54),
                  SizedBox(height: 16),
                  Text('点击右上角选择动画片', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAnimList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AnimListSheet(onSelect: (videoUrl) {
        Navigator.pop(context);
        _playVideo(videoUrl);
      }),
    );
  }

  void _playVideo(String videoUrl) {
    String processedUrl = videoUrl;
    if (videoUrl.contains('bilibili.com') || videoUrl.contains('b23.tv')) {
      final bvPattern = RegExp(r'BV[\w]{10}');
      final match = bvPattern.firstMatch(videoUrl);
      if (match != null) {
        processedUrl = 'https://player.bilibili.com/player.html?bvid=${match.group()}&high_quality=1&danmaku=0';
      }
    }
    _webViewController.loadRequest(Uri.parse(processedUrl));
  }

  void _pickVideo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请在网页中点击选择视频文件按钮')),
    );
    _webViewController.runJavaScript('''
      if (typeof Android !== 'undefined' && Android.pickFile) {
        Android.pickFile();
      }
    ''');
  }
}

class _AnimListSheet extends StatefulWidget {
  final Function(String) onSelect;

  const _AnimListSheet({required this.onSelect});

  @override
  State<_AnimListSheet> createState() => _AnimListSheetState();
}

class _AnimListSheetState extends State<_AnimListSheet> {
  List<Map<String, String>> _animations = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadAnimations();
  }

  Future<void> _loadAnimations() async {
    final result = await ApiService.getAnimations();
    if (!mounted) return;

    if (result['success'] == true) {
      final anims = result['animations'] as List;
      setState(() {
        _animations = anims.map((a) => {
          'name': a['name'] ?? '未知',
          'video_url': a['video_url'] ?? '',
          'image_url': a['image_url'] ?? '',
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = '加载失败';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 80) / 5;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('动画片列表', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(child: Text(_error, style: const TextStyle(color: Colors.white54)))
                    : _animations.isEmpty
                        ? const Center(child: Text('暂无动画片', style: TextStyle(color: Colors.white54)))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _animations.length,
                            itemBuilder: (context, index) {
                              final anim = _animations[index];
                              return GestureDetector(
                                onTap: () {
                                  if (anim['video_url']!.isNotEmpty) {
                                    widget.onSelect(anim['video_url']!);
                                  }
                                },
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF333333),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.movie, color: Colors.white54),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      anim['name']!,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
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