// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class DashboardPage extends StatefulWidget {
  final String link;
  final String name;

  const DashboardPage({required this.link, required this.name, super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late String uniqueViewType;

  @override
  void initState() {
    super.initState();
    // Generate a unique view type for each dashboard link
    uniqueViewType = 'iframeElement-${widget.link.hashCode}';

    // Register the iframe view with a unique view type
    ui.platformViewRegistry.registerViewFactory(
      uniqueViewType,
      (int viewId) => html.IFrameElement()
        ..src = widget.link
        ..style.border = 'none' // Remove border
        ..width = '100%'
        ..height = '100%',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("MODELO - ${widget.name}")),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: HtmlElementView(
          viewType: uniqueViewType, // Use unique view type for each dashboard
        ),
      ),
    );
  }
}
