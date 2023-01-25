import 'dart:io';
import 'package:api_project/controllers/api_auth_controller.dart';
import 'package:api_project/controllers/app_token_controllers.dart';
import 'package:api_project/controllers/app_user_controllers.dart';
import 'package:conduit/conduit.dart';
import 'model/note.dart';
import 'model/category.dart';

class AppService extends ApplicationChannel {
  late final ManagedContext managedContext;

  @override
  Future prepare() {
    final persistentStore = _initDatabase();

    managedContext = ManagedContext(
      ManagedDataModel.fromCurrentMirrorSystem(), persistentStore
    );
    return super.prepare();
  }

  @override
  Controller get entryPoint => Router()
    ..route('token/[:refresh]').link(() => AppAuthController(managedContext),)
    ..route('user')
      .link(AppTokenController.new)!
      .link(() => AppUserControllers(managedContext));

  PersistentStore _initDatabase() {
    final username = Platform.environment['DB_USERNAME'] ?? 'postgres';
    final password = Platform.environment['DB_PASSWORD'] ?? '123';
    final host = Platform.environment['DB_HOST'] ?? '127.0.0.1';
    final port = int.parse(Platform.environment['DB_PORT'] ?? '5432');
    final databaseName = Platform.environment['DB_NAME'] ?? 'postgres';
    return PostgreSQLPersistentStore(
      username, password, host, port, databaseName
    );
  }
}