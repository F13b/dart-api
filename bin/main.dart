import 'dart:io';
import 'package:api_project/api_project.dart' as api_project;
import 'package:conduit/conduit.dart';
import 'package:api_project/api_project.dart';


void main() async {
  final port = int.parse(Platform.environment["PORT"] ?? '8888');
  final service = Application<AppService>()
    ..options.port = port
    ..options.configurationFilePath = 'config.yaml';

    await service.start(numberOfInstances: 3, consoleLogging: true);
}
