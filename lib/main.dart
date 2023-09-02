import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:three_dart_playground/viewer.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final data = await rootBundle.load('assets/mercy.png');

  runApp(SkinViewer(
      options: SkinViewerOptions(
    width: 200,
    height: 200,
    skin: data,
  )));
}
