import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final bool returnResult;
  const BarcodeScannerScreen({super.key, this.returnResult = false});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.code128],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define the scan window size
    final double scanWindowWidth = 380.0;
    final double scanWindowHeight = 100.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            // Restrict scanning to this window
            scanWindow: null,
            onDetect: (capture) {
              if (_isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  if (!mounted) return;
                  _isProcessing = true; // Prevent further processing

                  if (widget.returnResult) {
                    Navigator.pop(context, code);
                  } else {
                    _showResultDialog(code);
                  }
                }
              }
            },
          ),
          // Visual Overlay
          // Instruction Text
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              'Please have the barcode close to the camera to avoid any errors.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(String code) {
    // _isProcessing is already true here from onDetect
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Barcode Found'),
        content: Text(code),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isProcessing = false;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;

  ScannerOverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)),
      );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    // Draw dark background with hole
    canvas.drawPath(backgroundWithCutout, backgroundPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
