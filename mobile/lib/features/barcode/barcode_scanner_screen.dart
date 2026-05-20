import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../api/api_client.dart';
import '../../features/history/viewed_food_history_store.dart';
import '../shared/permission_helper.dart';
import 'barcode_result_sheet.dart';
import 'widgets/flash_toggle.dart';
import 'widgets/scanner_overlay.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final NutriFitApi api;
  final ViewedFoodHistoryStore history;
  final VoidCallback? onGoToSearch;
  const BarcodeScannerScreen(
      {super.key, required this.api, required this.history, this.onGoToSearch});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _hasPermission = false;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await PermissionHelper.requestCamera(context);
    if (mounted) setState(() => _hasPermission = granted);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_hasPermission && !_sheetOpen) _controller.start();
      case AppLifecycleState.paused:
        _controller.stop();
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_sheetOpen) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    _controller.stop();
    HapticFeedback.heavyImpact();

    setState(() => _sheetOpen = true);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BarcodeResultSheet(
        barcode: barcode,
        api: widget.api,
        history: widget.history,
        onScanAgain: _resumeScanning,
        onEnterManually: widget.onGoToSearch,
      ),
    ).then((_) => _resumeScanning());
  }

  void _resumeScanning() {
    if (!mounted) return;
    setState(() => _sheetOpen = false);
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return _PermissionDeniedView(onOpenSettings: () async {
        await openAppSettings();
        await _checkPermission();
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title:
            const Text('Scan barcode', style: TextStyle(color: Colors.white)),
        actions: [
          FlashToggle(controller: _controller),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          const ScannerOverlay(),
        ],
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const _PermissionDeniedView({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Camera access is required to scan barcodes.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onOpenSettings,
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
