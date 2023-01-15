import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;
import 'package:build/build.dart';
import 'utils.dart';

import 'elements/join_table_element.dart';
import 'elements/table_element.dart';

final schemaResource = Resource<SchemaState>(() => SchemaState());

class SchemaState {
  final Map<AssetId, AssetState> _assets = {};
  bool _didFinalize = false;

  Map<Element, TableElement> get tables => _assets.values.map((a) => a.tables).reduce((a, b) => {...a, ...b});
  Map<String, JoinTableElement> get joinTables =>
      _assets.values.map((a) => a.joinTables).reduce((a, b) => {...a, ...b});

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
      _didFinalize = true;
    }
  }
}

class AssetState {
  final String filename;

  Map<Element, TableElement> tables = {};
  Map<String, JoinTableElement> joinTables = {};

  AssetState(this.filename);
}

class BuilderState {
  GlobalOptions options;
  SchemaState schema;
  AssetState asset;

  BuilderState(this.options, this.schema, this.asset);
}
