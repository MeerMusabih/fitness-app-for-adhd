import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/dopamine.dart';
import 'core/notification.dart';
import 'core/state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  final controller = Di.controller;
  await controller.init();
  Dopamine.instance.sync(controller.settings);
  runApp(const ProviderScope(child: ProjectReforgeApp()));
}
