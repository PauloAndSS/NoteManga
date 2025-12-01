// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Opção 1: pelo nome do pacote (ajuste para o seu name do pubspec.yaml)
// import 'package:mangatracker/main.dart';
// Opção 2: caminho relativo para lib (funciona em qualquer nome de pacote)
import '../lib/main.dart';

void main() {
  testWidgets('Renderiza tela inicial do MangaTracker', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verifica AppBar
    expect(find.text('MangaTracker – MangaDex'), findsOneWidget);

    // Verifica campo de busca
    expect(find.byType(TextField), findsOneWidget);

    // Verifica estado inicial de lista vazia
    expect(find.text('Nenhum mangá encontrado'), findsOneWidget);
  });
}
