import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../qr_login/qr_login_payload.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/qr_instructions_sheet.dart';
import '../widgets/qr_scanner_overlay.dart';
import 'qr_approve_screen.dart';

class QrScannerScreen extends StatefulWidget {
  /// Injected by the debug-only "Use test code" button.
  static const String testCode =
      'gamevault://login?session=test123&device=Windows%20PC';

  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  // True while a valid code is being handled, so it's never pushed twice.
  bool handlingCode = false;
  // Last rejected camera value, so the same bad code doesn't spam SnackBars.
  String? lastInvalidCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(controller.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from Settings after granting camera access.
    final bool deniedBefore = controller.value.error?.errorCode ==
        MobileScannerErrorCode.permissionDenied;
    if (state == AppLifecycleState.resumed && deniedBefore) {
      unawaited(startCamera());
    }
  }

  Future<void> startCamera() async {
    try {
      await controller.start();
    } on MobileScannerException {
      // Shown by the scanner's errorBuilder.
    }
  }

  Future<void> stopCamera() async {
    try {
      await controller.stop();
    } on MobileScannerException {
      // Camera wasn't running (e.g. no camera on the Simulator).
    }
  }

  void onDetect(BarcodeCapture capture) {
    for (final Barcode barcode in capture.barcodes) {
      final String? raw = barcode.rawValue;
      if (raw != null) {
        handleCode(raw, fromCamera: true);
        return;
      }
    }
  }

  Future<void> handleCode(String raw, {bool fromCamera = false}) async {
    if (handlingCode) return;

    final QrLoginPayload? payload = QrLoginPayload.tryParse(raw);
    if (payload == null) {
      if (fromCamera && raw == lastInvalidCode) return;
      lastInvalidCode = raw;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("This isn't a GameVault sign-in code")),
        );
      return;
    }

    handlingCode = true;
    await stopCamera();
    await HapticFeedback.mediumImpact();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QrApproveScreen(payload: payload),
      ),
    );

    // Only reached when the user backs out of the approve screen;
    // approve/deny pop all the way to the start.
    if (!mounted) return;
    handlingCode = false;
    lastInvalidCode = null;
    await startCamera();
  }

  Future<void> enterCodeManually() async {
    final String? code = await showDialog<String>(
      context: context,
      builder: (_) => const _ManualCodeDialog(),
    );
    if (code != null && code.trim().isNotEmpty && mounted) {
      await handleCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: onDetect,
            errorBuilder: (context, error) => _CameraErrorView(error: error),
          ),
          Column(
            children: [
              Expanded(
                child: ValueListenableBuilder<MobileScannerState>(
                  valueListenable: controller,
                  builder: (context, state, _) => Stack(
                    fit: StackFit.expand,
                    children: [
                      if (state.error == null) const QrScannerOverlay(),
                      SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            buildTopBar(state.torchState),
                            const SizedBox(height: 24),
                            if (state.error == null)
                              const Text(
                                'Point your camera at the QR code',
                                style: TextStyle(
                                  color: Color(0xFFC7D5E0),
                                  fontSize: 15,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              QrInstructionsSheet(
                onEnterManually: enterCodeManually,
                onUseTestCode: () => handleCode(QrScannerScreen.testCode),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTopBar(TorchState torchState) {
    final bool torchAvailable = torchState != TorchState.unavailable;
    final bool torchOn = torchState == TorchState.on;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.close,
            tooltip: 'Close',
            background: Colors.black45,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Scan QR code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          CircleIconButton(
            icon: torchOn ? Icons.flashlight_on : Icons.flashlight_off,
            tooltip: torchOn ? 'Turn flashlight off' : 'Turn flashlight on',
            background: torchOn ? AppColors.accent : Colors.black45,
            foreground: torchOn
                ? AppColors.darkBackground
                : (torchAvailable
                    ? AppColors.textPrimary
                    : AppColors.textSecondary),
            onPressed: torchAvailable ? controller.toggleTorch : null,
          ),
        ],
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  final MobileScannerException error;

  const _CameraErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    final bool denied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    return ColoredBox(
      color: AppColors.darkBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 96, 32, 0),
          child: Column(
            children: [
              Icon(
                denied ? Icons.no_photography_outlined : Icons.videocam_off,
                size: 48,
                color: AppColors.accent,
              ),
              const SizedBox(height: 16),
              Text(
                denied ? 'Camera access is off' : 'Camera unavailable',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                denied
                    ? 'Allow GameVault to use the camera to scan sign-in '
                        'codes, or enter the code manually below.'
                    : "We couldn't start the camera on this device. "
                        'You can still enter the code manually below.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              if (denied) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => AppSettings.openAppSettings(),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Open settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.darkBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualCodeDialog extends StatefulWidget {
  const _ManualCodeDialog();

  @override
  State<_ManualCodeDialog> createState() => _ManualCodeDialogState();
}

class _ManualCodeDialogState extends State<_ManualCodeDialog> {
  final TextEditingController codeController = TextEditingController();

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  void submit() => Navigator.of(context).pop(codeController.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: const Text(
        'Enter sign-in code',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: TextField(
        controller: codeController,
        autofocus: true,
        autocorrect: false,
        maxLength: 512,
        style: const TextStyle(color: AppColors.textPrimary),
        cursorColor: AppColors.accent,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => submit(),
        decoration: const InputDecoration(
          hintText: 'gamevault://login?session=…',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.inputFill,
          border: OutlineInputBorder(borderSide: BorderSide.none),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: submit, child: const Text('Continue')),
      ],
    );
  }
}
