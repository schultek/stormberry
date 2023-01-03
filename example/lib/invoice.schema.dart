part of 'invoice.dart';

extension Repositories on Database {
  InvoiceRepository get invoices => InvoiceRepository._(this);
}

final registry = ModelRegistry();

abstract class InvoiceRepository
    implements
        ModelRepository,
        ModelRepositoryInsert<InvoiceInsertRequest>,
        ModelRepositoryUpdate<InvoiceUpdateRequest>,
        ModelRepositoryDelete<String> {
  factory InvoiceRepository._(Database db) = _InvoiceRepository;

  Future<OwnerInvoiceView?> queryOwnerView(String id);
  Future<List<OwnerInvoiceView>> queryOwnerViews([QueryParams? params]);
}

class _InvoiceRepository extends BaseRepository
    with
        RepositoryInsertMixin<InvoiceInsertRequest>,
        RepositoryUpdateMixin<InvoiceUpdateRequest>,
        RepositoryDeleteMixin<String>
    implements InvoiceRepository {
  _InvoiceRepository(Database db) : super(db: db);

  @override
  Future<OwnerInvoiceView?> queryOwnerView(String id) {
    return queryOne(id, OwnerInvoiceViewQueryable());
  }

  @override
  Future<List<OwnerInvoiceView>> queryOwnerViews([QueryParams? params]) {
    return queryMany(OwnerInvoiceViewQueryable(), params);
  }

  @override
  Future<void> insert(Database db, List<InvoiceInsertRequest> requests) async {
    if (requests.isEmpty) return;

    await db.query(
      'INSERT INTO "invoices" ( "id", "title", "invoice_id", "account_id", "company_id" )\n'
      'VALUES ${requests.map((r) => '( ${registry.encode(r.id)}, ${registry.encode(r.title)}, ${registry.encode(r.invoiceId)}, ${registry.encode(r.accountId)}, ${registry.encode(r.companyId)} )').join(', ')}\n'
      'ON CONFLICT ( "id" ) DO UPDATE SET "title" = EXCLUDED."title", "invoice_id" = EXCLUDED."invoice_id", "account_id" = EXCLUDED."account_id", "company_id" = EXCLUDED."company_id"',
    );
  }

  @override
  Future<void> update(Database db, List<InvoiceUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    await db.query(
      'UPDATE "invoices"\n'
      'SET "title" = COALESCE(UPDATED."title"::text, "invoices"."title"), "invoice_id" = COALESCE(UPDATED."invoice_id"::text, "invoices"."invoice_id"), "account_id" = COALESCE(UPDATED."account_id"::int8, "invoices"."account_id"), "company_id" = COALESCE(UPDATED."company_id"::text, "invoices"."company_id")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${registry.encode(r.id)}, ${registry.encode(r.title)}, ${registry.encode(r.invoiceId)}, ${registry.encode(r.accountId)}, ${registry.encode(r.companyId)} )').join(', ')} )\n'
      'AS UPDATED("id", "title", "invoice_id", "account_id", "company_id")\n'
      'WHERE "invoices"."id" = UPDATED."id"',
    );
  }

  @override
  Future<void> delete(Database db, List<String> keys) async {
    if (keys.isEmpty) return;
    await db.query(
      'DELETE FROM "invoices"\n'
      'WHERE "invoices"."id" IN ( ${keys.map((k) => registry.encode(k)).join(',')} )',
    );
  }
}

class InvoiceInsertRequest {
  InvoiceInsertRequest(
      {required this.id, required this.title, required this.invoiceId, this.accountId, this.companyId});
  String id;
  String title;
  String invoiceId;
  int? accountId;
  String? companyId;
}

class InvoiceUpdateRequest {
  InvoiceUpdateRequest({required this.id, this.title, this.invoiceId, this.accountId, this.companyId});
  String id;
  String? title;
  String? invoiceId;
  int? accountId;
  String? companyId;
}

class OwnerInvoiceViewQueryable extends KeyedViewQueryable<OwnerInvoiceView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => registry.encode(key);

  @override
  String get tableName => 'owner_invoices_view';

  @override
  String get tableAlias => 'invoices';

  @override
  OwnerInvoiceView decode(TypedMap map) => OwnerInvoiceView(
      id: map.get('id', registry.decode),
      title: map.get('title', registry.decode),
      invoiceId: map.get('invoice_id', registry.decode));
}

class OwnerInvoiceView {
  OwnerInvoiceView({
    required this.id,
    required this.title,
    required this.invoiceId,
  });

  final String id;
  final String title;
  final String invoiceId;
}
