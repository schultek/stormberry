import '../../core/case_style.dart';
import '../schema.dart';
import '../elements/table_element.dart';
import 'delete_generator.dart';
import 'insert_generator.dart';
import 'update_generator.dart';
import 'view_generator.dart';

class RepositoryGenerator {
  String generateRepositories(AssetState state) {
    return '''
    extension Repositories on Database {
      ${state.tables.values.map((b) => '  ${b.element.name}Repository get ${CaseStyle.camelCase.transform(b.className)} => ${b.element.name}Repository._(this);\n').join()}
    }
    
    final registry = ModelRegistry();
    
    ${state.tables.values.map((t) => generateRepository(t)).join()}
    
    ${state.tables.values.map((t) => InsertGenerator().generateInsertRequest(t)).join()}
    
    ${state.tables.values.map((t) => UpdateGenerator().generateUpdateRequest(t)).join()}
    
    ${state.tables.values.map((t) => ViewGenerator().generateViewClasses(t)).join()}
  ''';
  }

  String generateRepository(TableElement table) {
    var repoName = '${table.element.name}Repository';

    var keyType = table.primaryKeyColumn?.dartType;
    var hasKeyAutoInc = table.primaryKeyColumn?.isAutoIncrement ?? false;

    return '''
      abstract class $repoName implements ModelRepository, 
        ${hasKeyAutoInc ? 'Keyed' : ''}ModelRepositoryInsert<${table.element.name}InsertRequest>, 
        ModelRepositoryUpdate<${table.element.name}UpdateRequest>
        ${keyType != null ? ', ModelRepositoryDelete<$keyType>' : ''} {
        factory $repoName._(Database db) = _$repoName;
         
        ${ViewGenerator().generateRepositoryMethods(table, abstract: true)} 
      }
      
      class _$repoName extends BaseRepository with 
        ${hasKeyAutoInc ? 'Keyed' : ''}RepositoryInsertMixin<${table.element.name}InsertRequest>, 
        RepositoryUpdateMixin<${table.element.name}UpdateRequest>
        ${keyType != null ? ', RepositoryDeleteMixin<$keyType>' : ''} 
        implements $repoName {
        _$repoName(Database db): super(db: db);
        
        ${ViewGenerator().generateRepositoryMethods(table)}
        
        ${InsertGenerator().generateInsertMethod(table)}
        
        ${UpdateGenerator().generateUpdateMethod(table)}
        
        ${DeleteGenerator().generateDeleteMethod(table)}
      }
    ''';
  }
}
