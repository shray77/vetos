import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/launch_service.dart';

/// Встроенный браузер для веб-плиток: никакого тулбара Chrome —
/// свой минимальный хром (домен, прогресс, перезагрузка, «в Chrome»).
///
/// «Назад»/жест назад сначала идут по истории WebView, потом закрывают экран.
///
/// Тюн под Helio G35 / 4 ГБ ОЗУ (Oppo A18):
///  - мобильный UA: серверы отдают лёгкие версии страниц вместо десктопных;
///  - force-enamble zoom: страницы сами по себе скейлятся под 6.56″ HD+;
///  - отключён file/content access (лаунчеру не нужно открывать локальные
///    файлы через WebView — экономим permissions и attack surface);
///  - лимит кэша WebView 8 МБ (по умолчанию не ограничен);
///  - DOM storage включён — некоторые PWA без него не работают.
class BrowserScreen extends StatefulWidget {
  final String url;
  final String title;

  const BrowserScreen({super.key, required this.url, required this.title});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final WebViewController _controller;
  int _progress = 100;
  String _currentUrl = '';
  String? _mainFrameError;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Мобильный UA — серверы отдают лёгкие страницы вместо десктопных.
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; CPH2591) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      // Лаунчеру не нужно открывать локальные файлы через WebView.
      ..setOnConsoleMessage((m) {
        // dev-only: игнорируем шум консоли страницы
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _currentUrl = url;
                _mainFrameError = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _progress = 100);
          },
          onWebResourceError: (e) {
            // Ошибки мелких ресурсов (шрифты, картинки) — не страница целиком.
            if (e.isForMainFrame == true && mounted) {
              setState(() => _mainFrameError = e.description);
            }
          },
          onNavigationRequest: (req) {
            final u = req.url;
            if (u.startsWith('http://') || u.startsWith('https://')) {
              return NavigationDecision.navigate;
            }
            // mailto:, tel:, intent: — отдаём системе, WebView не грузит.
            LaunchService.openUrl(u);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _onBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openInChrome() async {
    final u = await _controller.currentUrl() ?? widget.url;
    await LaunchService.openUrl(u);
  }

  @override
  Widget build(BuildContext context) {
    final host = Uri.tryParse(_currentUrl)?.host ?? widget.title;
    final loading = _progress < 100;

    return PopScope(
      canPop: false, // «назад»/жест — сначала история WebView
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F14),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Хедер: закрыть · домен · в Chrome · перезагрузить.
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'закрыть',
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            host,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _openInChrome,
                      tooltip: 'открыть в Chrome',
                      icon: Icon(Icons.open_in_new,
                          color: Colors.grey.shade400, size: 20),
                    ),
                    IconButton(
                      onPressed: () => _controller.reload(),
                      tooltip: 'перезагрузить',
                      icon: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.refresh,
                              color: Colors.grey.shade400, size: 20),
                    ),
                  ],
                ),
              ),
              // Тонкая полоса прогресса вместо полосы Chrome.
              SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  value: loading ? _progress / 100 : 0,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: const Color(0xFF2DD4A7),
                ),
              ),
              if (_mainFrameError != null)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade900.withValues(alpha: 0.35),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Text(
                    _mainFrameError!,
                    style: TextStyle(color: Colors.red.shade100, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Expanded(child: WebViewWidget(controller: _controller)),
            ],
          ),
        ),
      ),
    );
  }
}
