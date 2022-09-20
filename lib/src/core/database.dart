import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';

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
    this.isUnixSocket = false,
    this.allowClearTextPassword = false,
    this.replicationMode = ReplicationMode.none,
  })  : host = host ?? Platform.environment['DB_HOST_ADDRESS'] ?? '127.0.0.1',
        port = port ?? int.tryParse(Platform.environment['DB_PORT'] ?? '') ?? 5432,
        database = database ?? Platform.environment['DB_NAME'] ?? 'postgres',
        user = user ?? Platform.environment['DB_USERNAME'] ?? 'postgres',
        password = password ?? Platform.environment['DB_PASSWORD'] ?? 'root',
        useSSL = useSSL ?? Platform.environment['DB_SSL']?.startsWith('true') ?? true {
    _cachedConnection ??= connection();
  }

  PostgreSQLConnection connection() {
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

  String get name => _cachedConnection!.databaseName;

  Future<void> open() => _tryOpen();
  Future<void> close() async => !_cachedConnection!.isClosed ? await _cachedConnection!.close() : null;

  Future<void> _tryOpen() async {
    if (_cachedConnection!.isClosed) {
      print('Database: connecting to ${_cachedConnection!.databaseName} at ${_cachedConnection!.host}...');
      try {
        await _cachedConnection!.open();
      } catch (e) {
        print('Error on connection: $e');
        print('Database: retrying connecting...');
        _cachedConnection = connection();
        await _cachedConnection!.open();
      }
      print('Database: connected');
    }
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
