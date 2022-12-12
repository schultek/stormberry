
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'utils.dart';

import 'elements/join_table_element.dart';
import 'elements/table_element.dart';

final schemaResource = Resource<SchemaState>(() => SchemaState());

class SchemaState {
  final Map<AssetId, AssetState> _assets = {};
  bool _didPrepareColumns = false;

  Map<Element, TableElement> get tables => _assets.values.map((a) => a.tables).reduce((a, b) => {...a, ...b});
  Map<String, JoinTableElement> get joinTables => _assets.values.map((a) => a.joinTables).reduce((a, b) => {...a, ...b});

  AssetState createForAsset(AssetId assetId) {
    var asset = AssetState();
    return _assets[assetId] = asset;
  }

  AssetState? getForAsset(AssetId assetId) {
    if (!_didPrepareColumns) {
      for (var element in tables.values) {
        element.prepareColumns();
      }
      _didPrepareColumns = true;
    }
    return _assets[assetId];
  }

}

class AssetState {
  Map<Element, TableElement> tables = {};
  Map<String, JoinTableElement> joinTables = {};
}

class BuilderState {
  GlobalOptions options;
  SchemaState schema;
  AssetState asset;

  BuilderState(this.options, this.schema, this.asset);
}