import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamevault/data/memory_store_repository.dart';
import 'package:gamevault/screens/home_screen.dart';

Future<MemoryStoreRepository> pumpHome(
  WidgetTester tester, {
  bool guard = true,
  Size size = const Size(390, 844),
  MemoryStoreRepository? repository,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final MemoryStoreRepository repo = repository ?? MemoryStoreRepository();
  await tester.pumpWidget(
    MaterialApp(home: HomeScreen(repository: repo, showGuardTab: guard)),
  );
  await tester.pumpAndSettle();
  return repo;
}

Finder navItem(String label) => find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text(label),
    );
