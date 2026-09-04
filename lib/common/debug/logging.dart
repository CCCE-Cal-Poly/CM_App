import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> _writeLog(String message) async {
  final dir = await getApplicationDocumentsDirectory();
  final logFile = File('${dir.path}/app_debug.log');

  final timestamp = DateTime.now().toIso8601String();
  await logFile.writeAsString(
    '[$timestamp] $message\n',
    mode: FileMode.append,
    flush: true,
  );

  

  debugPrint('Log saved to: ${logFile.path}');
}

