import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import '../utilities/utilities.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  String? _senderDeviceToken;
  String? _receiverDeviceToken;
  late Stream<String> _tokenStream;

  void setToken(String? token) {
    debugPrint('Mobile Device Token: $token');
    setState(() {
      _senderDeviceToken = token;
    });
  }

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.getToken().then(setToken);
    _tokenStream = FirebaseMessaging.instance.onTokenRefresh;
    _tokenStream.listen(setToken);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text('QR Scanner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Text(
              'Scan the QR code showing in web',
              style: textTheme.titleLarge,
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 1.5,
              child: MobileScanner(
                fit: BoxFit.contain,
                onDetect: (capture) async {
                  final data = capture.barcodes.first.rawValue ?? '';

                  // Restrict to accept scanned data one time only
                  if (_receiverDeviceToken == data ||
                      _senderDeviceToken == null) {
                    return;
                  }

                  _receiverDeviceToken = data;

                  debugPrint('Receiver Device Token - $_receiverDeviceToken');

                  await sendMessageToWeb();
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Warning: Once logged in web then session is active for only 15 min. Some functionality might not work once session expires',
              style: textTheme.labelLarge!.copyWith(color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> sendMessageToWeb() async {
    try {
      if (_receiverDeviceToken?.isEmpty ?? true) {
        showErrorMessage(
          context,
          message: 'Something went wrong on getting receiver/web device token',
        );
        return;
      }

      if (_senderDeviceToken?.isEmpty ?? true) {
        showErrorMessage(
          context,
          message:
              'Something went wrong on generating sender/mobile device token',
        );
        return;
      }

      final userToken = await context.read<AuthProvider>().generateJWT();

      debugPrint('User Token - $userToken');

      if (userToken?.isEmpty ?? true) {
        showErrorMessage(
          context,
          message: 'Something went wrong on generating jwt / user token',
        );
        return;
      }

      await context.read<AuthProvider>().sendNotificationToWeb(
            token: _receiverDeviceToken!,
            userToken: userToken!,
            deviceToken: _senderDeviceToken!,
          );

      context.pop();
    } catch (error, stackTrace) {
      showErrorMessage(context, message: error.toString());
      debugPrint('Error $error occurred at stackTrace $stackTrace');
    }
  }
}
