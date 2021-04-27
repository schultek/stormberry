import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';
// ignore: implementation_imports
import 'package:postgres/src/text_codec.dart';

class Database {
  bool debugPrint;

  static String get hostAddress =>
      Platform.environment['DB_HOST_ADDRESS'] ?? '127.0.0.1';

  static String get databaseName =>
      Platform.environment['DB_NAME'] ?? 'postgres';
  static int get databasePort =>
      int.tryParse(Platform.environment['DB_PORT'] ?? '') ?? 5432;
  static String get userName =>
      Platform.environment['DB_USERNAME'] ?? 'postgres';
  static String get password => Platform.environment['DB_PASSWORD'] ?? 'root';

  static PostgreSQLConnection? _cachedConnection;

  String? dbName;

  Database({this.debugPrint = true, this.dbName}) {
    _cachedConnection ??= connection();
  }

  PostgreSQLConnection connection() {
    return PostgreSQLConnection(
      hostAddress,
      databasePort,
      dbName ?? databaseName,
      username: userName,
      password: password,
      useSSL: true,
    );
  }

  String get name => _cachedConnection!.databaseName;

  Future<void> open() => _tryOpen();
  Future<void> close() async =>
      !_cachedConnection!.isClosed ? await _cachedConnection!.close() : null;

  Future<void> _tryOpen() async {
    if (_cachedConnection!.isClosed) {
      print(
          'Database: connecting to ${_cachedConnection!.databaseName} at ${_cachedConnection!.host}...');
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

  Future<PostgreSQLResult> query(String query,
      [Map<String, dynamic>? values]) async {
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
    await startTransaction();
    try {
      var result = run();
      await finishTransaction();
      return result;
    } catch (e) {
      cancelTransaction();
      rethrow;
    }
  }

  T decodeRow<T>(Map<String, dynamic> row) {
    return row as T; // TODO custom json decoder
  }

  dynamic dec(dynamic value) {}

  String enc(dynamic value) {
    return PostgresTextEncoder().convert(value); // todo: custom json encoder
  }
}
