import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'force_update_service.dart';

class ForceUpdateGate extends StatefulWidget {
  const ForceUpdateGate({required this.child, super.key});

  final Widget child;

  @override
  State<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends State<ForceUpdateGate> {
  final ForceUpdateService _forceUpdateService = ForceUpdateService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForceUpdate());
  }

  Future<void> _checkForceUpdate() async {
    final shouldForceUpdate = await _forceUpdateService.shouldForceUpdate();
    if (!mounted || !shouldForceUpdate) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('アップデートが必要です'),
          content: const Text('最新バージョンにアップデートしてからご利用ください。'),
          actions: [
            TextButton(
              onPressed: _openAppStore,
              child: const Text('アップデートする'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAppStore() async {
    final uri = Uri.parse(ForceUpdateService.appStoreUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
