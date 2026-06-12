import 'package:flutter/foundation.dart'; // 引入 kIsWeb
import 'package:flutter/material.dart';
// 💡 以下兩個是 Dart 與 Flutter Web 內建的庫，不需要在 pubspec.yaml 裝額外套件
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class UniversalImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const UniversalImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // 💡 1. 如果不是 Web 環境（例如跑 Android/iOS 模擬器），就用一般正常的 Image.network
    if (!kIsWeb) {
      return Image.network(imageUrl, width: width, height: height, fit: fit);
    }

    // 💡 2. 如果是 Web 環境，利用雜湊值建立一個唯一的 ID
    final String viewId = 'web-img-${imageUrl.hashCode}';

    // 💡 3. 向瀏覽器註冊一個原生的 HTML <img> 標籤，這樣就不會被 CORS 擋住
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      return html.ImageElement()
        ..src = imageUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _getHtmlObjectFit(fit);
    });

    return SizedBox(
      width: width,
      height: height,
      child: HtmlElementView(viewType: viewId),
    );
  }

  // 將 Flutter 的 BoxFit 轉換為 CSS 的 object-fit 屬性
  String _getHtmlObjectFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return 'cover';
      case BoxFit.contain:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      default:
        return 'cover';
    }
  }
}
