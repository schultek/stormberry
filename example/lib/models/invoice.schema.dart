// ignore_for_file: annotate_overrides

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
      'INSERT INTO "invoices" ( "id", "title", "invoice_id", "account_id", "company_id" )\n'
      'VALUES ${requests.map((r) => '( ${values.add(r.id)}:text, ${values.add(r.title)}:text, ${values.add(r.invoiceId)}:text, ${values.add(r.accountId)}:int8, ${values.add(r.companyId)}:text )').join(', ')}\n',
      values.values,
    );
  }

  @override
  Future<void> update(List<InvoiceUpdateRequest> requests) async {
    if (requests.isEmpty) return;
    var values = QueryValues();
    await db.query(
      'UPDATE "invoices"\n'
      'SET "title" = COALESCE(UPDATED."title", "invoices"."title"), "invoice_id" = COALESCE(UPDATED."invoice_id", "invoices"."invoice_id"), "account_id" = COALESCE(UPDATED."account_id", "invoices"."account_id"), "company_id" = COALESCE(UPDATED."company_id", "invoices"."company_id")\n'
      'FROM ( VALUES ${requests.map((r) => '( ${values.add(r.id)}:text, ${values.add(r.title)}:text, ${values.add(r.invoiceId)}:text, ${values.add(r.accountId)}:int8, ${values.add(r.companyId)}:text )').join(', ')} )\n'
      'AS UPDATED("id", "title", "invoice_id", "account_id", "company_id")\n'
      'WHERE "invoices"."id" = UPDATED."id"',
      values.values,
    );
  }
}

class InvoiceInsertRequest {
  InvoiceInsertRequest({
    required this.id,
    required this.title,
    required this.invoiceId,
    this.accountId,
    this.companyId,
  });

  final String id;
  final String title;
  final String invoiceId;
  final int? accountId;
  final String? companyId;
}

class InvoiceUpdateRequest {
  InvoiceUpdateRequest({
    required this.id,
    this.title,
    this.invoiceId,
    this.accountId,
    this.companyId,
  });

  final String id;
  final String? title;
  final String? invoiceId;
  final int? accountId;
  final String? companyId;
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
  OwnerInvoiceView decode(TypedMap map) => OwnerInvoiceView(
      id: map.get('id'), title: map.get('title'), invoiceId: map.get('invoice_id'));
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
