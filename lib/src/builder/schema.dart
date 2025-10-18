import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'elements/join_table_element.dart';
import 'elements/table_element.dart';
import 'generators/join_json_generator.dart';
import 'generators/table_json_generator.dart';
import 'utils.dart';

final schemaResource = Resource<SchemaState>(() => SchemaState());

class SchemaState {
  final Map<AssetId, AssetState> _assets = {};
  bool _didFinalize = false;

  Map<Element, TableElement> get tables =>
      _assets.values.map((a) => a.tables).fold({}, (a, b) => a..addAll(b));
  Map<String, JoinTableElement> get joinTables =>
      _assets.values.map((a) => a.joinTables).fold({}, (a, b) => a..addAll(b));

  bool hasAsset(AssetId assetId) {
    return _assets.containsKey(assetId);
  }

  AssetState createForAsset(AssetId assetId) {
    assert(!_didFinalize, 'Schema was already finalized.');
    var asset = AssetState(p.basename(assetId.path));
    return _assets[assetId] = asset;
  }

  AssetState? getForAsset(AssetId assetId) {
    finalize();
    return _assets[assetId];
  }

  void finalize() {
    if (!_didFinalize) {
      for (var element in tables.values) {
        element.prepareColumns();
      }
      for (var element in tables.values) {
        element.sortColumns();
      }
      for (var element in tables.values) {
        element.analyzeViews();
      }
      _didFinalize = true;
    }
  }
}

class AssetState {
  final String filename;

  Map<Element, TableElement> tables = {};
  Map<String, JoinTableElement> joinTables = {};

  AssetState(this.filename);

  Map<String, dynamic> getJsonData() {
    return <String, dynamic>{
      for (var element in tables.values) //
        element.tableName: TableJsonGenerator().generateJsonSchema(element),
      for (var element in joinTables.values) //
        element.tableName: JoinJsonGenerator().generateJsonSchema(element),
    };
  }
}

class BuilderState {
  GlobalOptions options;
  SchemaState schema;
  AssetState asset;

  BuilderState(this.options, this.schema, this.asset);
}
