import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './theme/app_theme.dart';
import './screens/main_screen.dart';
import './services/audio_handler.dart';
import './services/config_service.dart';
import './bloc/config_bloc.dart';
import './bloc/auth_bloc.dart';

late AudioHandler _audioHandler;

const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://bgztfukvlxnmprnlisad.supabase.co',
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJnenRmdWt2bHhubXBybmxpc2FkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3MjAwNzgsImV4cCI6MjA5MTI5NjA3OH0.np-4GpjhI9B8iFxtvJrq7wgFarzTLjypUMnOlPRURQU',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase using dart-define env vars
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  // Configure audio session
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  _audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mycompany.myapp.channel.audio',
      androidNotificationChannelName: 'Mara FM',
      androidStopForegroundOnPause: true,
    ),
  );
  runApp(MaraFMApp(audioHandler: _audioHandler));
}

class MaraFMApp extends StatelessWidget {
  final AudioHandler audioHandler;
  const MaraFMApp({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ConfigBloc(ConfigService())..add(LoadConfigRequested())),
        BlocProvider(create: (context) => AuthBloc()),
      ],
      child: MaterialApp(
        title: 'Mara FM',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Container(
          color: Colors.black, // Add a background color for the margins
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child!,
            ),
          ),
        );
      },
      home: const MainScreen(),
    ));
  }
}

class CrtOverlay extends StatelessWidget {
  final Widget child;

  const CrtOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Scanlines
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: List.generate(
                  200,
                  (index) => index % 2 == 0 ? Colors.black.withValues(alpha: 0.05) : Colors.transparent,
                ),
                stops: List.generate(200, (index) => index / 200),
              ),
            ),
          ),
        ),
        // Vignette
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.2),
                ],
                stops: const [0.7, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
