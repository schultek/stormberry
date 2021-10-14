import '../table_builder.dart';
import 'action_builder.dart';

class SingleDeleteActionBuilder extends DeleteActionBuilder {
  SingleDeleteActionBuilder(TableBuilder table) : super(table);

  @override
  String generateActionMethod() {
    return 'Future<void> deleteOne(${table.primaryKeyColumn!.dartType} ${table.primaryKeyColumn!.paramName}) {\n'
        '  return run(${table.element.name}DeleteAction(), [${table.primaryKeyColumn!.paramName}]);\n'
        '}';
  }
}

class MultiDeleteActionBuilder extends DeleteActionBuilder {
  MultiDeleteActionBuilder(TableBuilder table) : super(table);

  @override
  String generateActionMethod() {
    return 'Future<void> deleteMany(List<${table.primaryKeyColumn!.dartType}> keys) {\n'
        '  return run(${table.element.name}DeleteAction(), keys);\n'
        '}';
  }
}

abstract class DeleteActionBuilder extends ActionBuilder {
  DeleteActionBuilder(TableBuilder table) : super(table);

  @override
  String? generateActionClass() {
    return _generateDeleteAction();
  }

  bool _didGenerateDeleteAction = false;
  String? _generateDeleteAction() {
    if (_didGenerateDeleteAction) {
      return null;
    }
    _didGenerateDeleteAction = true;

    var requestClassName = table.primaryKeyColumn!.dartType;
    var actionClassName = '${table.element.name}DeleteAction';

    return 'class $actionClassName implements Action<List<$requestClassName>> {\n'
        '  @override\n'
        '  Future<void> apply(Database db, List<$requestClassName> keys) async {\n'
        '    if (keys.isEmpty) return;\n'
        '    await db.query("""\n'
        '      DELETE FROM "${table.tableName}"\n'
        '      WHERE "${table.tableName}"."${table.primaryKeyColumn!.columnName}" IN ( \${keys.map((k) => _encode(k)).join(\',\')} )\n'
        '    """);\n'
        '  }\n'
        '}';
  }
}
