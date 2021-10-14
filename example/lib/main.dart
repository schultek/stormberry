import 'package:stormberry/stormberry.dart';

part 'main.g.dart';

class Accounts extends Table<Account> {
  static final id = text().primaryKey();
  static final name = text();
  static final location = latLng();
}

class AccountsCompanies extends Table<Entity> {
  static final account_id = ref(Accounts.id);
  static final company_id = ref(Companies.id);
}

class Companies extends Table<Company> {
  static final id = text().primaryKey();
}

class Invoices extends Table<Invoice> {
  static final id = text().primaryKey();
}

class LatLng {}

Column<LatLng> latLng() => text().transform(LatLngTransformer());

class UserAccountsView extends View<Accounts, UserAccount> {
  final companies =
}

class CompanyAccountsView extends View<Accounts, CompanyAccount> {
  static final company = Accounts.company.hidden();
}

class MemberCompaniesView extends View<Companies, MemberCompany> {
  static final members = Companies.members.viewAs<CompanyAccountsView>();
}

class OwnerInvoicesView extends View<Invoices, OwnerInvoice> {}

class LatLngTransformer extends Transformer<String, LatLng> {}

class StrLengthTransformer extends Transformer<String, int> {}
