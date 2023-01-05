
late AccountReference a;

void main() async {

  var user = a.ref(1).user.get();

  var user2 = (await a.add(0)).user.get();


}

class AccountReference extends AddableTableReference<int, AccountModelReference> {

  @override
  AccountModelReference ref(int key) {
    return AccountModelReference._(key, this);
  }

  @override
  Future<AccountModelReference> add(request) {
    // TODO: implement add
    throw UnimplementedError();
  }
}

class AccountModelReference extends ModelReference<int, AccountView, AccountReference> {
  AccountModelReference._(super.key, super.table);


  UserAccountViewReference get user;

  @override
  Future<void> delete() {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<bool> exists() {
    // TODO: implement exists
    throw UnimplementedError();
  }

  @override
  Future<AccountView> get() {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future<void> update() {
    // TODO: implement update
    throw UnimplementedError();
  }


}

abstract class AccountView {

}

abstract class UserAccountViewReference extends ViewReference {

}



abstract class TableReference {


}

abstract class KeyedTableReference<Key, Ref extends ModelReference, BatchRef extends BatchModelReference> extends TableReference {

  Ref ref(Key key);

  BatchRef batch(List<Key> keys);

}

abstract class AddableTableReference<Key, Ref extends ModelReference> extends KeyedTableReference<Key, Ref> {

  Future<Ref> add(dynamic request);

}

abstract class ModelReference<Key, T, Table extends TableReference> {

  ModelReference(this.key, this.table);

  final Key key;
  final Table table;

  Future<T> get();

  Future<bool> exists();

  Future<void> update();

  Future<void> delete();
}

abstract class BatchModelReference<Key, T, Table extends TableReference> {

  BatchModelReference(this.keys, this.table);

  final List<Key> keys;
  final Table table;

  Future<T> get();

  Future<bool> exists();

  Future<void> update();

  Future<void> delete();
}

abstract class CreatableModelReference<Key, T, Table extends TableReference> extends ModelReference<Key, T, Table> {

  Future<void> create();
}

abstract class ViewReference<T, Model extends ModelReference> {

  Model get model;

  Future<T> get();
}