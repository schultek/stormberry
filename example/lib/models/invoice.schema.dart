part of 'invoice.dart';

extension InvoiceRepositories on Database {
  InvoiceRepository get invoices => InvoiceRepository._(this);
}

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
  _InvoiceRepository(super.db) : super(tableName: 'invoices', keyName: 'id');

  @override
  Future<OwnerInvoiceView?> queryOwnerView(String id) {
    return queryOne(id, OwnerInvoiceViewQueryable());
  }

  @override
  Future<List<OwnerInvoiceView>> queryOwnerViews([QueryParams? params]) {
    return queryMany(OwnerInvoiceViewQueryable(), params);
  }

  @override
  Future<void> insert(List<InvoiceInsertRequest> requests) async {
    if (requests.isEmpty) return;

    var values = QueryValues();
    await db.query(
      'INSERT INTO "invoices" ( "account_id", "id", "title", "invoice_id", "company_id" )\n'
      'VALUES ${requests.map((r) => '( ${values.add(r.accountId)}, ${values.add(r.id)}, ${values.add(r.title)}, ${values.add(r.invoiceId)}, ${values.add(r.companyId)} )').join(', ')}\n',
      values.values,
    );
  }

  @override
  Future<void> update(List<InvoiceUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.query(
      'UPDATE "invoices"\n'
      'SET "account_id" = COALESCE(UPDATED."account_id"::int8, "invoices"."account_id"), "title" = COALESCE(UPDATED."title"::text, "invoices"."title"), "invoice_id" = COALESCE(UPDATED."invoice_id"::text, "invoices"."invoice_id"), "company_id" = COALESCE(UPDATED."company_id"::text, "invoices"."company_id")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.accountId)}, ${values.add(r.id)}, ${values.add(r.title)}, ${values.add(r.invoiceId)}, ${values.add(r.companyId)} )').join(', ')} )\n'
      'AS UPDATED("account_id", "id", "title", "invoice_id", "company_id")\n'
      'WHERE "invoices"."id" = UPDATED."id"',
      values.values,
    );
  }
}

class InvoiceInsertRequest {
  InvoiceInsertRequest({
    this.accountId,
    required this.id,
    required this.title,
    required this.invoiceId,
    this.companyId,
  });

  int? accountId;
  String id;
  String title;
  String invoiceId;
  String? companyId;
}

class InvoiceUpdateRequest {
  InvoiceUpdateRequest({
    this.accountId,
    required this.id,
    this.title,
    this.invoiceId,
    this.companyId,
  });

  int? accountId;
  String id;
  String? title;
  String? invoiceId;
  String? companyId;
}

class OwnerInvoiceViewQueryable extends KeyedViewQueryable<OwnerInvoiceView, String> {
  @override
  String get keyName => 'id';

  @override
  String encodeKey(String key) => TextEncoder.i.encode(key);

  @override
  String get query => 'SELECT "invoices".*'
      'FROM "invoices"';

  @override
  String get tableAlias => 'invoices';

  @override
  OwnerInvoiceView decode(TypedMap map) =>
      OwnerInvoiceView(id: map.get('id'), title: map.get('title'), invoiceId: map.get('invoice_id'));
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
