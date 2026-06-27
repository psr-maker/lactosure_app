import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/theme.dart';
import 'package:lactosure_connect_app/lactosure/admin/adminscren.dart';
import 'package:lactosure_connect_app/lactosure/screens/authen/register.dart';
import 'package:lactosure_connect_app/lactosure/splash.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const SplashScreen(),
            //home: const AdminScreen(),
            // home: RegisterUser(),
          );
        },
      ),
    );
  }
}
