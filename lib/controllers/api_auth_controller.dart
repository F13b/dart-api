import 'dart:io';

import 'package:api_project/model/model_response.dart';
import 'package:api_project/model/user.dart';
import 'package:api_project/utils/api_utils.dart';
import 'package:api_project/utils/app_response.dart';
import 'package:conduit/conduit.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';


class AppAuthController extends ResourceController {
  AppAuthController(this.managedContext);

  final ManagedContext managedContext;

  @Operation.post()
  Future<Response> signIn(@Bind.body() User user) async {
    if (user.password == null && user.username == null) {
      return Response.badRequest(
          body: ModelResponse(message: "Поля password username обязательны"));
    }
    try {
      final qFindUser = Query<User>(managedContext)
        ..where((element) => element.username).equalTo(user.username)
        ..returningProperties(
          (element) => [
            element.id,
            element.salt,
            element.hashPassword,
          ],
        );
      final findUser = await qFindUser.fetchOne();
      if (findUser == null) {
        throw QueryException.input('Пользователь не найден', []);
      }
      final requestHashPassword =
          generatePasswordHash(user.password ?? '', findUser.salt ?? '');
      if (requestHashPassword == findUser.hashPassword) {
        _updateToken(findUser.id ?? -1, managedContext);
        final newUser =
            await managedContext.fetchObjectWithID<User>(findUser.id);
        return Response.ok(ModelResponse(
            data: newUser!.backing.contents, message: 'Успешная авторизация'));
      } else {
        throw QueryException.input('Неверный пароль', []);
      }
    } on QueryException catch (e) {
      return Response.serverError(body: ModelResponse(message: e.message));
    }
  }

  @Operation.put()
  Future<Response> signUp(@Bind.body() User user) async {
    if (user.password == null && user.username == null || user.email == null) {
      return Response.badRequest(
        body:
            ModelResponse(message: 'Поля password username email обязательны'),
      );
    }

    final salt = generateRandomSalt();

    final hashPassword = generatePasswordHash(user.password!, salt);

    try {
      late final int id;

      await managedContext.transaction((transaction) async {
        final qCreateUser = Query<User>(transaction)
          ..values.username = user.username
          ..values.email = user.email
          ..values.salt = salt
          ..values.hashPassword = hashPassword;

        final createdUser = await qCreateUser.insert();

        id = createdUser.id!;

        _updateToken(id, transaction);
      });

      final userData = await managedContext.fetchObjectWithID<User>(id);
      return Response.ok(
        ModelResponse(
          data: userData!.backing.contents,
          message: 'Пользователь успешно зарегистрировался',
        ),
      );
    } on QueryException catch (e) {
      return Response.serverError(body: ModelResponse(message: e.message));
    }
  }

  @Operation.post('refresh')
  Future<Response> refreshToken(
      @Bind.path('refresh') String refreshToken) async {
    try {
      final id = AppUtils.getIdFromToken(refreshToken);
      final user = await managedContext.fetchObjectWithID<User>(id);
      if (user!.refreshToken != refreshToken) {
        return Response.unauthorized(body: 'Token не валидный');
      }

      _updateToken(id, managedContext);

      return Response.ok(
        ModelResponse(
            data: user.backing.contents, message: 'Token успешно обновлён'),
      );
    } catch (e) {
      return AppResponse.serverError(e);
    }
  }

  void _updateToken(int id, ManagedContext transcation) async {
    final Map<String, String> tokens = _getTokens(id);
    final qUpdateTolens = Query<User>(transcation)
      ..where((x) => x.id).equalTo(id)
      ..values.accessToken = tokens['access']
      ..values.refreshToken = tokens['refresh'];

    await qUpdateTolens.updateOne();
  }

  Map<String, String> _getTokens(int id) {
    final key = Platform.environment['SECRET_KEY'] ?? 'SECRET_KEY';
    final accessClaimSet = JwtClaim(
      maxAge: const Duration(hours: 1),
      otherClaims: {'id': id},
    );

    final refreshClaimSet = JwtClaim(
      otherClaims: {'id': id},
    );

    final tokens = <String, String>{};
    tokens['access'] = issueJwtHS256(accessClaimSet, key);
    tokens['refresh'] = issueJwtHS256(refreshClaimSet, key);

    return tokens;
  }
}