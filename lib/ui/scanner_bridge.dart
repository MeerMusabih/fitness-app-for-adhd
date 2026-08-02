import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Isolated wrapper around mobile_scanner so the rest of the app does not
/// need camera hardware at build time.
Widget mobileScannerBuilder(void Function(String) onDetect, VoidCallback onError) {
  return MobileScanner(
    onDetect: (capture) {
      final codes = capture.barcodes;
      if (codes.isNotEmpty && codes.first.rawValue != null) {
        onDetect(codes.first.rawValue!);
      }
    },
    errorBuilder: (context, error) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onError());
      return const SizedBox.shrink();
    },
  );
}
