import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:go_router/go_router.dart';
import 'package:netshare/ui/common_view/confirm_dialog.dart';
import 'package:provider/provider.dart';

import 'package:netshare/config/styles.dart';
import 'package:netshare/di/di.dart';
import 'package:netshare/plugin_management/plugins.dart';
import 'package:netshare/provider/connection_provider.dart';
import 'package:netshare/provider/db_provider.dart';
import 'package:netshare/provider/file_provider.dart';
import 'package:netshare/ui/client/scan_qr_widget.dart';
import 'package:netshare/ui/navigation_widget.dart';
import 'package:netshare/ui/client/client_widget.dart';
import 'package:netshare/ui/receive/receive_widget.dart';
import 'package:netshare/ui/send/send_widget.dart';
import 'package:netshare/ui/server/server_widget.dart';
import 'package:netshare/util/utility_functions.dart';
import 'package:netshare/config/constants.dart';
import 'package:netshare/ui/send/uploading_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initPlugins();
  setupDI();
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final GoRouter _router = GoRouter(
    navigatorKey: _navigatorKey,
    errorBuilder: (BuildContext context, GoRouterState state) => ErrorWidget(state.error!),
    routes: <GoRoute>[
      GoRoute(
        path: mRootPath,
        redirect: (context, state) {
          if (UtilityFunctions.isMobile) {
            return '/$mClientPath';
          } else {
            return '/$mServerPath';
          }
        },
      ),
      GoRoute(
        name: mNavigationPath,
        path: '/$mNavigationPath',
        builder: (context, state) => const NavigationWidget(),
      ),
      GoRoute(
        name: mServerPath,
        path: '/$mServerPath',
        builder: (context, state) => const ServerWidget(),
      ),
      GoRoute(
        name: mClientPath,
        path: '/$mClientPath',
        builder: (context, state) => const ClientWidget(),
        routes: [
          GoRoute(
            name: mSendPath,
            path: mSendPath,
            builder: (BuildContext context, GoRouterState state) => const SendWidget(),
            routes: [
              GoRoute(
                name: mUploadingPath,
                path: mUploadingPath,
                builder: (context, state) => const UploadingWidget(),
              )
            ],
          ),
          GoRoute(
            name: mReceivePath,
            path: mReceivePath,
            builder: (BuildContext context, GoRouterState state) => const ReceiveWidget(),
          ),
          GoRoute(
            name: mScanningPath,
            path: mScanningPath,
            builder: (BuildContext context, GoRouterState state) => const ScanQRWidget(),
          ),
        ],
      ),
    ],
  );
  bool _isKeyboardListenerEnabled = true;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => FileProvider()),
        ChangeNotifierProvider(create: (context) => DatabaseProvider()),
        ChangeNotifierProvider(create: (context) => ConnectionProvider()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'NetShare',
        theme: ThemeData(
          useMaterial3: true,
          appBarTheme: const AppBarTheme(color: backgroundColor),
          colorScheme: ColorScheme.fromSeed(seedColor: seedColor, background: backgroundColor),
        ),
        routerConfig: _router,
        builder: (context, child) {
          // Handle keyboard listener here
          RawKeyboard.instance.addListener((RawKeyEvent value) => _handleKeyEvent(value));
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }

  void _handleKeyEvent(RawKeyEvent value) async {
    if (!_isKeyboardListenerEnabled)  return;

    // If user pressed Command/Control + W keys, quit the app
    if (value.isMetaPressed && value.logicalKey == LogicalKeyboardKey.keyW ||
        value.isControlPressed && value.logicalKey == LogicalKeyboardKey.keyW) {

      if(_navigatorKey.currentContext == null) return;

      // show confirm dialog
      _showQuitAppConfirmationDialog(_navigatorKey.currentContext!, (confirmCallback) {
        if (confirmCallback) {
          SystemNavigator.pop(); // Quit the app
        }
        // listen keyboard again
        _isKeyboardListenerEnabled = true;
      });
    }
  }

  void _showQuitAppConfirmationDialog(BuildContext context, Function(bool)? confirmCallback) {
    // Disable the keyboard listener.
    _isKeyboardListenerEnabled = false;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (dialogContext) {
        return ConfirmDialog(
          dialogWidth: MediaQuery.of(dialogContext).size.width / 2,
          header: Text(
            'Quit App',
            style: Theme.of(dialogContext).textTheme.headlineMedium?.copyWith(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          body: const Text(
            'Are you sure you want to quit the app?',
            textAlign: TextAlign.center,
          ),
          cancelButtonTitle: 'No',
          okButtonTitle: 'Yes, I\'m sure',
          onCancel: () => confirmCallback?.call(false),
          onConfirm: () => confirmCallback?.call(true),
        );
      },
    );
  }
}
