import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(const LawyerApp());
}
