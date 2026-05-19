import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';

Future<ui.Image> getImageFromPath(String imagePath) async {
  ByteData imageBytesBuffer = await rootBundle.load(imagePath);
  Uint8List imageBytes = imageBytesBuffer.buffer.asUint8List();
  final Completer<ui.Image> completer = Completer();

  ui.decodeImageFromList(imageBytes, (ui.Image img) {
    return completer.complete(img);
  });

  return completer.future;
}
