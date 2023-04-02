import '../config/docker.dart';
import 'delete.dart';
import 'insert.dart';
import 'update.dart';

void main() {
  usePostgresDocker();
  testInsert();
  testUpdate();
  testDelete();
}
