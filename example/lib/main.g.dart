part of 'main.dart';

class MainSchema extends DatabaseDefinition {
  final tables = {
    'accounts': AccountsDefinition(),
  };
}

class AccountsDefinition extends TableDefinition<Accounts> {
  final table = Accounts();

  late final columns = {
    'id': table.id,
  };

  final views = {
    UserAccountsViewDefinition(),
  };
}

class UserAccountsViewDefinition extends ViewDefinition<Accounts, UserAccountsView> {
  final view = UserAccountsView();

  late final columns = {
    'invoices': view.invoices,
  };
}

class Account extends Entity {
  String id;
  String name;
  LatLng location;
  Company company;
  List<Invoice> invoices;

  Account(this.id, this.name, this.location, this.company, this.invoices);
}

class UserAccount extends Entity {
  String id;
  int nameLength;
  MemberCompany company;
  List<OwnerInvoice> invoices;

  UserAccount(this.id, this.nameLength, this.company, this.invoices);
}

class Company extends Entity {}

class MemberCompany extends Entity {}

class Invoice extends Entity {}

class OwnerInvoice extends Entity {}
