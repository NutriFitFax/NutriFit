import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/haptics.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../api/api_client.dart';
import '../../app/nutri_colors.dart';
import '../../db/daily_log.dart';
import '../../features/history/viewed_food_history_store.dart';
import '../shared/permission_helper.dart';
import 'barcode_result_sheet.dart';
import 'widgets/scanner_overlay.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final NutriFitApi api;
  final ViewedFoodHistoryStore history;
  final DailyLogStore store;
  final VoidCallback? onGoToSearch;

  const BarcodeScannerScreen({
    super.key,
    required this.api,
    required this.history,
    required this.store,
    this.onGoToSearch,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _hasPermission = false;
  bool _sheetOpen = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(autoStart: false);
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await PermissionHelper.requestCamera(context);
    if (!mounted) return;
    setState(() => _hasPermission = granted);
    if (granted) _controller.start();
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
    Haptics.heavyImpact();

    setState(() => _sheetOpen = true);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).extension<NutriColors>()!.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => BarcodeResultSheet(
        barcode: barcode,
        api: widget.api,
        history: widget.history,
        store: widget.store,
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

  Future<void> _toggleTorch() async {
    Haptics.selectionClick();
    await _controller.toggleTorch();
    if (mounted) setState(() => _torchOn = !_torchOn);
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          const ScannerOverlay(),

          // Top controls — sit above the SafeArea inset.
          Positioned(
            top: 8, left: 12, right: 12,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  _RoundIcon(
                    icon: Icons.close,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'SCANNING',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'Point at a barcode',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white, fontSize: 17,
                              ),
                        ),
                      ],
                    ),
                  ),
                  _RoundIcon(
                    icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                    active: _torchOn,
                    onTap: _toggleTorch,
                  ),
                ],
              ),
            ),
          ),

          // Bottom helper text + secondary actions
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hold steady · Align barcode within the frame',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: widget.onGoToSearch,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(alpha: 0.06),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          icon: const Icon(Icons.search, size: 16),
                          label: const Text('Search instead'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _RoundIcon({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? Colors.white : Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40, height: 40,
          child: Icon(icon, color: active ? Colors.black87 : Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const _PermissionDeniedView({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final c = context.nutri;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('Scan barcode')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_outlined, size: 64, color: c.ink2),
              const SizedBox(height: 16),
              const Text('Camera access is required to scan barcodes.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: onOpenSettings, child: const Text('Open Settings')),
            ],
          ),
        ),
      ),
    );
  }
}
