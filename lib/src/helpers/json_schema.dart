import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../core/transformer.dart';

String buildJsonSchema(Map<String, dynamic> schema) {
  var out = <String, dynamic>{};
  for (var key in schema.keys) {
    var table = schema[key];
    out[key] = {
      ...table,
      'views': table['views']?.map((view) {
        return buildViewSchema(view as Map<String, dynamic>);
      }).toList(),
    };
  }
  return jsonEncode(out);
}

Map<String, dynamic> buildViewSchema(Map<String, dynamic> map) {
  var definition = buildViewQuery(
    map['table_name'] as String,
    map['primary_key_name'] as String?,
    (map['columns'] as List).map((c) => ViewColumnSchema.fromMap(c as Map<String, dynamic>)).toList(),
  );

  var hash = sha1.convert(utf8.encode(definition)).toString();

  definition += "\nWHERE '_#$hash#_' IS NOT NULL";

  return {
    'name': map['name'],
    'definition': definition,
    'hash': hash,
  };
}

class ViewColumnSchema {
  String type;

  String? paramName;
  String? tableName;
  String? columnName;

  String? linkPrimaryKeyName;
  String? refColumnName;
  String? linkTableName;

  String? joinTableName;
  String? parentForeignKeyName;
  String? linkForeignKeyName;

  Transformer? transformer;

  ViewColumnSchema({
    required this.type,
    required this.paramName,
    this.tableName,
    this.columnName,
    this.linkPrimaryKeyName,
    this.refColumnName,
    this.linkTableName,
    this.joinTableName,
    this.parentForeignKeyName,
    this.linkForeignKeyName,
    this.transformer,
  });

  factory ViewColumnSchema.fromMap(Map<String, dynamic> map) {
    return ViewColumnSchema(
      type: map['type'] as String,
      paramName: map['param_name'] as String?,
      tableName: map['table_name'] as String?,
      columnName: map['column_name'] as String?,
      linkPrimaryKeyName: map['link_primary_key_name'] as String?,
      refColumnName: map['ref_column_name'] as String?,
      linkTableName: map['link_table_name'] as String?,
      joinTableName: map['join_table_name'] as String?,
      parentForeignKeyName: map['parent_foreign_key_name'] as String?,
      linkForeignKeyName: map['link_foreign_key_name'] as String?,
      transformer: map['transformer'] as Transformer?,
    );
  }
}

String buildViewQuery(String tableName, String? primaryKeyName, List<ViewColumnSchema> columns) {
  var joins = <MapEntry<String, String>>[];

  for (var column in columns) {
    var transform = column.transformer?.transform(column.paramName!, tableName);

    if (column.type == 'foreign_column') {
      joins.add(MapEntry(
        transform ?? 'row_to_json("${column.paramName}".*) as "${column.paramName}"',
        'LEFT JOIN "${column.tableName}" "${column.paramName}"\n'
        'ON "$tableName"."${column.columnName}" = "${column.paramName}"."${column.linkPrimaryKeyName}"',
      ));
    } else if (column.type == 'reference_column') {
      joins.add(MapEntry(
        transform ?? 'row_to_json("${column.paramName}".*) as "${column.paramName}"',
        'LEFT JOIN "${column.tableName}" "${column.paramName}"\n'
        'ON "$tableName"."$primaryKeyName" = "${column.paramName}"."${column.refColumnName}"',
      ));
    } else if (column.type == 'multi_reference_column') {
      joins.add(MapEntry(
        transform ?? '"${column.paramName}"."data" as "${column.paramName}"',
        'LEFT JOIN (\n'
        '  SELECT "${column.linkTableName}"."${column.refColumnName}",\n'
        '    to_jsonb(array_agg("${column.linkTableName}".*)) as data\n'
        '  FROM "${column.tableName}" "${column.linkTableName}"\n'
        '  GROUP BY "${column.linkTableName}"."${column.refColumnName}"\n'
        ') "${column.paramName}"\n'
        'ON "$tableName"."$primaryKeyName" = "${column.paramName}"."${column.refColumnName}"',
      ));
    } else if (column.type == 'join_column') {
      joins.add(MapEntry(
        transform ?? '"${column.paramName}"."data" as "${column.paramName}"',
        'LEFT JOIN (\n'
        '  SELECT "${column.joinTableName}"."${column.parentForeignKeyName}",\n'
        '    to_jsonb(array_agg("${column.linkTableName}".*)) as data\n'
        '  FROM "${column.joinTableName}"\n'
        '  LEFT JOIN "${column.tableName}" "${column.linkTableName}"\n'
        '  ON "${column.linkTableName}"."${column.linkPrimaryKeyName}" = "${column.joinTableName}"."${column.linkForeignKeyName}"\n'
        '  GROUP BY "${column.joinTableName}"."${column.parentForeignKeyName}"\n'
        ') "${column.paramName}"\n'
        'ON "$tableName"."$primaryKeyName" = "${column.paramName}"."${column.parentForeignKeyName}"',
      ));
    }
  }

  return 'SELECT "$tableName".*${joins.map((j) => ', ${j.key}').join()}\n'
      'FROM "$tableName"${joins.isNotEmpty ? '\n' : ''}'
      '${joins.map((j) => j.value).join('\n')}';
}
