import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/theme.dart';
import 'package:lactosure_connect_app/lactosure/screens/authen/login.dart';
import 'package:lactosure_connect_app/lactosure/widgets/confirmdialog.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';
import 'package:lactosure_connect_app/services/authen_service.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();

  /// SECTION TITLE
  static Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Color.fromARGB(255, 104, 103, 103),
      ),
    );
  }
}

class _SettingsState extends State<Settings> {
  bool _isLoading = false;
  Future<void> logout() async {
    setState(() => _isLoading = true);

    try {
      await AuthService.logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logout failed. Please try again.")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          /// ===== APPEARANCE =====
          Settings._sectionTitle("Appearance"),
          const SizedBox(height: 10),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color:  Theme.of(context).colorScheme.primary,
            child: SwitchListTile(
              value: themeProvider.isDarkMode,
              activeColor: Theme.of(context).colorScheme.background,
              secondary: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              title: Text(
                themeProvider.isDarkMode ? "Dark Mode" : "Light Mode",
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              subtitle: Text(
                "Toggle application theme",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
            ),
          ),

          const SizedBox(height: 40),
          Center(
            child: CustomButton(
              text: "LOGOUT",

              onPressed: _isLoading
                  ? null
                  : () async {
                      bool? confirmed = await showConfirmDialog(
                        context,
                        "Logout",
                        "this account",
                      );
                      if (confirmed == true) {
                        logout();
                      }
                    },
              isLoading: _isLoading,
              buttonclr: Theme.of(context).colorScheme.error,
              txtclr: Theme.of(context).colorScheme.onPrimary,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
