import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/manga/manga_search_page.dart';
import 'pages/manga/manga_lists_page.dart';
import 'pages/welcome_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MangaTracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF8B4A5C),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF3A3A3A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8B4A5C),
          elevation: 0,
        ),
      ),

      /// Tela de inicialização da aplicação
      home: const WelcomePage(),

      /// Rotas globais
      routes: {
        '/home': (_) => const HomePage(),
        '/search': (_) => const MangaSearchPage(),
        '/lists': (_) => const MangaListsPage(),
      },
    );
  }
}
