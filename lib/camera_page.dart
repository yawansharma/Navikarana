import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  WebViewController? _controller; // ❗ nullable (important)

  @override
  void initState() {
    super.initState();

    // 🔴 SAFETY CHECK (Windows only)
    if (!Platform.isWindows) return;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_cameraHtml);

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) {
      return const Scaffold(
        body: Center(child: Text("Camera only supported on Windows here")),
      );
    }

    // ⛑️ Prevent null crash
    if (_controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Camera")),
      body: WebViewWidget(controller: _controller!),
    );
  }
}

/// 🔴 HTML with LIVE CAMERA
const String _cameraHtml = """
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;background:black;">
<video id="video" autoplay playsinline style="width:100%;height:100%;object-fit:cover;"></video>

<script>
navigator.mediaDevices.getUserMedia({ video: true })
  .then(stream => {
    document.getElementById('video').srcObject = stream;
  })
  .catch(err => {
    document.body.innerHTML = '<h2 style="color:white;">Camera error: ' + err + '</h2>';
  });
</script>

</body>
</html>
""";
