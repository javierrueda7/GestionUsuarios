// ignore_for_file: library_private_types_in_public_api, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:ui' as ui; // Use for web platform view

class DashboardPage extends StatefulWidget {
  final String link;
  final String name;

  const DashboardPage({required this.link, required this.name, super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();

    // Register an iframe element for displaying the dashboard link
    ui.platformViewRegistry.registerViewFactory(
      'iframeElement',
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
      body: const SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: HtmlElementView(
          viewType: 'iframeElement', // View type identifier
        ),
      ),
    );
  }
}
