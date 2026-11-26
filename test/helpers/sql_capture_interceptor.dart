import 'package:drift/drift.dart';

/// Shared Drift [QueryInterceptor] capturing executed `SELECT` statements and
/// bind arguments for SQL projection and query-shape assertions.
class SqlCaptureInterceptor extends QueryInterceptor {
  /// Optional async hook invoked before each `SELECT` executes (e.g. to pause
  /// an in-flight query in concurrency/coalescing tests).
  final Future<void> Function(String statement, List<Object?> args)?
      onBeforeSelect;

  final List<(String sql, List<Object?> args)> executedSelects = [];

  SqlCaptureInterceptor({this.onBeforeSelect});

  List<String> get executedSql =>
      executedSelects.map((entry) => entry.$1).toList(growable: false);

  void clear() => executedSelects.clear();

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    if (onBeforeSelect != null) {
      await onBeforeSelect!(statement, args);
    }
    executedSelects.add((statement, List<Object?>.unmodifiable(args)));
    return super.runSelect(executor, statement, args);
  }
}
