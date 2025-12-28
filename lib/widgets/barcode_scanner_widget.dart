import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:meditrack/style/colors.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final Function(String barcode) onBarcodeScanned;

  const BarcodeScannerWidget({
    super.key,
    required this.onBarcodeScanned,
  });

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture barcodeCapture) {
    if (!_isScanning) return;

    final barcode = barcodeCapture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isScanning = false);

    // Call the callback with the scanned barcode
    widget.onBarcodeScanned(barcode!.rawValue!);

    // Close the scanner
    Navigator.pop(context, barcode.rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: AppColors.primary,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),

          // Instructions overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.black54,
              child: const Text(
                'Point camera at medicine barcode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Scanning frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Manual entry button at bottom
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}