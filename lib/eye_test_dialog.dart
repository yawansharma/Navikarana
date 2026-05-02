import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EyeTestDialog extends StatefulWidget {
  const EyeTestDialog({super.key});

  @override
  State<EyeTestDialog> createState() => _EyeTestDialogState();
}

class _EyeTestDialogState extends State<EyeTestDialog> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final htmlPath =
        '${Directory.current.path}\\windows\\runner\\resources\\camera.html';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.file(htmlPath));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 800,
        height: 500,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                color: Colors.black87,
              ),
              child: const Row(
                children: [
                  Icon(Icons.visibility, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "Eye Test",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}
