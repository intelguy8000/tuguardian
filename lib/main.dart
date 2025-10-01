import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/home/home_screen.dart';
import 'shared/providers/sms_provider.dart';
import 'shared/providers/theme_provider.dart';
import 'core/app_colors.dart';

void main() {
  runApp(const TuGuardianApp());
}

class TuGuardianApp extends StatelessWidget {
  const TuGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SMSProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'TuGuardian',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: AppColors.primary,
              brightness: Brightness.light,
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: AppColors.primary,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: AppColors.darkBackground,
              appBarTheme: AppBarTheme(
                backgroundColor: AppColors.darkBackground,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: HomeScreen(), // SIN CONST
          );
        },
      ),
    );
  }
}