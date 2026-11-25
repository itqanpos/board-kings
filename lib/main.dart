import 'package:flutter/material.dart';

import 'app/board_kings_app.dart';
import 'core/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const BoardKingsApp());
}
