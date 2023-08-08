import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';

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

  static PostgreSQLConnection? _cachedConnection;

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
  })  : host = host ?? Platform.environment['DB_HOST_ADDRESS'] ?? DB_HOST_ADDRESS,
        port = port ?? int.tryParse(Platform.environment['DB_PORT'] ?? '') ?? DB_PORT,
        database = database ?? Platform.environment['DB_NAME'] ?? DB_NAME,
        user = user ?? Platform.environment['DB_USERNAME'] ?? DB_USERNAME,
        password = password ?? Platform.environment['DB_PASSWORD'] ?? DB_PASSWORD,
        useSSL = useSSL ?? (Platform.environment['DB_SSL'] != DB_SSL),
        isUnixSocket = isUnixSocket ?? (Platform.environment['DB_SOCKET'] == DB_SOCKET);

  PostgreSQLConnection? get connection => _cachedConnection;

  PostgreSQLConnection _connection() {
    return PostgreSQLConnection(
      host,
      port,
      database,
      username: user,
      password: password,
      useSSL: useSSL,
      timeoutInSeconds: timeoutInSeconds,
      queryTimeoutInSeconds: queryTimeoutInSeconds,
      timeZone: timeZone,
      isUnixSocket: isUnixSocket,
      allowClearTextPassword: allowClearTextPassword,
      replicationMode: replicationMode,
    );
  }

  Future<PostgreSQLConnection> open() async {
    await _tryOpen();
    return _cachedConnection!;
  }

  Future<void> close() async {
    if (_cachedConnection != null && !_cachedConnection!.isClosed) {
      await _cachedConnection!.close();
      _cachedConnection = null;
    }
  }

  Future<void> _tryOpen() async {
    if (_cachedConnection != null && !_cachedConnection!.isClosed) {
      return;
    }

    var c = _connection();
    print('Database: connecting to ${c.databaseName} at ${c.host}...');
    await c.open();
    _cachedConnection = c;
    print('Database: connected');
  }

  Future<PostgreSQLResult> query(String query, [Map<String, dynamic>? values]) async {
    await _tryOpen();
    if (debugPrint) {
      _printQuery(query);
    }
    if (transactionContext != null) {
      return transactionContext!.query(query, substitutionValues: values);
    } else {
      return _cachedConnection!.query(query, substitutionValues: values);
    }
  }

  void _printQuery(String query) {
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
    print('---\n$q');
  }

  Future? transactionFuture;
  Completer<bool>? transactionCompleter;
  PostgreSQLExecutionContext? transactionContext;

  Future<void> startTransaction() async {
    await _tryOpen();
    if (transactionContext != null) {
      return;
    }
    transactionCompleter = Completer();
    var transactionStarted = Completer();
    transactionFuture = _cachedConnection!.transaction((context) async {
      transactionContext = context;
      transactionStarted.complete();
      return transactionCompleter!.future;
    });
    await transactionStarted.future;
  }

  void cancelTransaction() {
    try {
      transactionContext?.cancelTransaction();
    } catch (_) {}
    transactionCompleter?.complete(false);
    transactionCompleter = null;
  }

  Future<bool> finishTransaction() async {
    transactionCompleter?.complete(true);
    transactionContext = null;
    try {
      var result = await transactionFuture;
      return result as bool;
    } catch (e) {
      print('Transaction finished with error: $e');
      return false;
    }
  }

  Future<T> runTransaction<T>(FutureOr<T> Function() run) async {
    if (transactionContext != null) {
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
