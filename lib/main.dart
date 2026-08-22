import 'dart:async';
import 'package:campus_event_hub/app/env.dart';
import 'package:campus_event_hub/app/providers.dart';
import 'package:campus_event_hub/app/router.dart';
import 'package:campus_event_hub/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();

  if (!Env.isDemoMode) {
    // Only touch Supabase when real credentials are configured — demo
    // mode must run with zero backend calls, per spec section 24.
    await Supabase.initialize(
        url: Env.supabaseUrl, publishableKey: Env.supabaseAnonKey);
  }

  runApp(const ProviderScope(child: CampusEventHubApp()));
}

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class CampusEventHubApp extends ConsumerStatefulWidget {
  const CampusEventHubApp({super.key});

  @override
  ConsumerState<CampusEventHubApp> createState() => _CampusEventHubAppState();
}

class _CampusEventHubAppState extends ConsumerState<CampusEventHubApp> {
  StreamSubscription<String?>? _notificationSub;

  @override
  void initState() {
    super.initState();
    _notificationSub = ref
        .read(notificationServiceProvider)
        .onNotificationTapped
        .listen((eventId) {
      if (!mounted) return;
      if (eventId != null) {
        ref.read(routerProvider).push('/event/$eventId');
      } else {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('This event is no longer available.')),
        );
      }
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Campus Event Hub',
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) => TapRegion(
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
