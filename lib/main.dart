import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'data/datasources/firestore_seeder.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[MAIN_ERROR] Firebase initialization error: $e');
  }

  // Always invoke runApp immediately so the UI is NEVER left on a blank white page!
  runApp(const ProviderScope(child: KrishiMitraApp()));

  // Perform optional demo/sample seeding asynchronously in the background AFTER runApp
  FirestoreSeeder.seedIfEmpty(FirebaseFirestore.instance).catchError((e) {
    debugPrint('[SEEDER_NOTICE] Optional background seeding skipped: $e');
  });
}
