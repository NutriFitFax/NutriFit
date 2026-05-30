import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/haptics.dart';

class FlashToggle extends StatefulWidget {
  final MobileScannerController controller;
  const FlashToggle({super.key, required this.controller});

  @override
  State<FlashToggle> createState() => _FlashToggleState();
}

class _FlashToggleState extends State<FlashToggle> {
  bool _torchOn = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
      color: Colors.white,
      tooltip: _torchOn ? 'Turn off flash' : 'Turn on flash',
      onPressed: () {
        Haptics.selectionClick();
        widget.controller.toggleTorch();
        setState(() => _torchOn = !_torchOn);
      },
    );
  }
}
