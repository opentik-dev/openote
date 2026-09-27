import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/notes_home_screen.dart';
import 'services/app_private_storage.dart';
import 'services/preferences_service.dart';
import 'state/notes_state_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize preferences
  final prefsService = await PreferencesService.create();

  // Initialize storage
  final storageService = AppPrivateStorage();

  // Initialize central state notifier
  final notesNotifier = NotesStateNotifier(
    storage: storageService,
    prefs: prefsService,
  );

  // Load initial notes from disk
  await notesNotifier.loadNotes();

  runApp(OpeNoteApp(notesNotifier: notesNotifier));
}

class OpeNoteApp extends StatelessWidget {
  final NotesStateNotifier notesNotifier;

  const OpeNoteApp({
    super.key,
    required this.notesNotifier,
  });

  static const List<String> _fontFallbacks = [
    'NotoSansArabic',
    'NotoSansOldSouthArabian',
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notesNotifier,
      builder: (context, _) {
        ThemeMode themeMode;
        switch (notesNotifier.themeMode) {
          case 'light':
            themeMode = ThemeMode.light;
            break;
          case 'dark':
            themeMode = ThemeMode.dark;
            break;
          default:
            themeMode = ThemeMode.system;
        }

        Locale? appLocale;
        if (notesNotifier.localeCode == 'ar') {
          appLocale = const Locale('ar');
        } else if (notesNotifier.localeCode == 'en') {
          appLocale = const Locale('en');
        } else {
          appLocale = null; // Follow system locale
        }

        return MaterialApp(
          title: 'OpeNote',
          debugShowCheckedModeBanner: false,
          locale: appLocale,
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'NotoSansArabic',
            fontFamilyFallback: _fontFallbacks,
            brightness: Brightness.light,
            colorSchemeSeed: const Color(0xFF2563EB),
            scaffoldBackgroundColor: const Color(0xFFF9FAFB),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 1,
              backgroundColor: Color(0xFFF9FAFB),
              centerTitle: false,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: 'NotoSansArabic',
            fontFamilyFallback: _fontFallbacks,
            brightness: Brightness.dark,
            colorSchemeSeed: const Color(0xFF3B82F6),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 1,
              backgroundColor: Color(0xFF121212),
              centerTitle: false,
            ),
          ),
          home: NotesHomeScreen(notifier: notesNotifier),
        );
      },
    );
  }
}
