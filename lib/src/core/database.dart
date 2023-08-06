import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:postgres/postgres.dart' show ReplicationMode;
import 'package:postgres/postgres_v3_experimental.dart';

import 'default_values.dart';

/// {@category Introduction}
/// {@category Database}
/// {@category Repositories}
/// {@category Migration}
class Database {
  bool debugPrint;

  final String host;
  final String database;
  final String user;
  final String password;
  final int port;
  final bool useSSL;
  final int timeoutInSeconds;
  final String timeZone;
  final int queryTimeoutInSeconds;
  final bool isUnixSocket;
  final bool allowClearTextPassword;
  final ReplicationMode replicationMode;

  static PgConnection? _cachedConnection;
  static bool _isInTransaction = false;

  Database({
    this.debugPrint = false,
    String? host,
    int? port,
    String? database,
    String? user,
    String? password,
    bool? useSSL,
    this.timeoutInSeconds = 30,
    this.queryTimeoutInSeconds = 30,
    this.timeZone = 'UTC',
    bool? isUnixSocket,
    this.allowClearTextPassword = false,
    this.replicationMode = ReplicationMode.none,
  })  : host =
            host ?? Platform.environment['DB_HOST_ADDRESS'] ?? DB_HOST_ADDRESS,
        port = port ??
            int.tryParse(Platform.environment['DB_PORT'] ?? '') ??
            DB_PORT,
        database = database ?? Platform.environment['DB_NAME'] ?? DB_NAME,
        user = user ?? Platform.environment['DB_USERNAME'] ?? DB_USERNAME,
        password =
            password ?? Platform.environment['DB_PASSWORD'] ?? DB_PASSWORD,
        useSSL = useSSL ?? (Platform.environment['DB_SSL'] != DB_SSL),
        isUnixSocket =
            isUnixSocket ?? (Platform.environment['DB_SOCKET'] == DB_SOCKET);

  Future<PgConnection> connection() async {
    return PgConnection.open(
      PgEndpoint(
        host: host,
        port: port,
        database: database,
        username: user,
        password: password,
        requireSsl: useSSL,
        isUnixSocket: isUnixSocket,
        allowCleartextPassword: allowClearTextPassword,
      ),
      sessionSettings: PgSessionSettings(
        timeZone: timeZone,
        connectTimeout: Duration(seconds: timeoutInSeconds),
      ),
    );
  }

  Future<void> open() => _tryOpen();
  Future<void> close() async {
    final connection = _cachedConnection;

    if (connection != null) {
      _cachedConnection = null;
      await connection.close();
    }
  }

  Future<void> _tryOpen() async {
    if (_cachedConnection != null) {
      return;
    }

    print('Database: connecting to $database at $host...');

    _cachedConnection = await connection();
    print('Database: connected');
  }

  Future<PgResult> query(String query, [List<PgTypedParameter>? values]) async {
    await _tryOpen();
    if (debugPrint) {
      _printQuery(query, values);
    }

    final session = _cachedConnection!;
    return await session.execute(
      PgSql(
        query,
        types: [
          if (values != null)
            for (final value in values) value.type,
        ],
      ),
      parameters: values,
    );
  }

  void _printQuery(String query, [List<PgTypedParameter>? values]) {
    var offset = 0;
    var q = query
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) => l.replaceAll(RegExp(r'\s+'), ' '))
        .reduce((v, s) {
      if (s.startsWith('SELECT')) offset += 2;
      if (s.startsWith(')')) offset -= 2;
      return "$v\n${" " * offset}$s";
    });
    print(
        '---\n$q with params ${values?.map((p) => '${p.value}::${p.type.nameForSubstitution}')}');
  }

  Future<void> startTransaction() async {
    await _tryOpen();

    if (!_isInTransaction) {
      await _cachedConnection!.execute('BEGIN', ignoreRows: true);
    }
  }

  Future<void> cancelTransaction() async {
    if (_isInTransaction) {
      await _cachedConnection!.execute('ROLLBACK', ignoreRows: true);
      _isInTransaction = false;
    }
  }

  Future<bool> finishTransaction() async {
    try {
      await _cachedConnection!.execute('COMMIT', ignoreRows: true);
      return true;
    } catch (e) {
      print('Transaction finished with error: $e');
      return false;
    }
  }

  Future<T> runTransaction<T>(FutureOr<T> Function() run) async {
    if (_isInTransaction) {
      try {
        var result = await run();
        return result;
      } catch (e) {
        cancelTransaction();
        rethrow;
      }
    }
    await startTransaction();
    try {
      var result = await run();
      await finishTransaction();
      return result;
    } catch (e) {
      cancelTransaction();
      rethrow;
    }
  }
}

extension RowToMap on PgResultRow {
  Map<String, Object?> toColumnMap() {
    final columns = schema.columns;
    final map = <String, Object?>{};

    for (var i = 0; i < columns.length; i++) {
      final name = columns[i].columnName;
      if (name != null) {
        map[name] = this[i];
      }
    }

    return map;
  }
}
