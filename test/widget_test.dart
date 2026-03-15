import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/main.dart';

void main() {
  testWidgets('CHATZY app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ChatzyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
