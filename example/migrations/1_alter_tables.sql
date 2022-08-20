ALTER TABLE "accounts"
  ADD PRIMARY KEY ( "id" );

ALTER TABLE "billing_addresses"
  ADD UNIQUE ( "account_id" );

ALTER TABLE "companies"
  ADD PRIMARY KEY ( "id" );

ALTER TABLE "invoices"
  ADD PRIMARY KEY ( "id" );

ALTER TABLE "parties"
  ADD PRIMARY KEY ( "id" );

ALTER TABLE "accounts_parties"
  ADD PRIMARY KEY ( "account_id", "party_id" );

ALTER TABLE "accounts"
  ADD FOREIGN KEY ( "company_id" ) REFERENCES companies ( "id" ) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "billing_addresses"
  ADD FOREIGN KEY ( "account_id" ) REFERENCES accounts ( "id" ) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD FOREIGN KEY ( "company_id" ) REFERENCES companies ( "id" ) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "invoices"
  ADD FOREIGN KEY ( "account_id" ) REFERENCES accounts ( "id" ) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD FOREIGN KEY ( "company_id" ) REFERENCES companies ( "id" ) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "parties"
  ADD FOREIGN KEY ( "sponsor_id" ) REFERENCES companies ( "id" ) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "accounts_parties"
  ADD FOREIGN KEY ( "account_id" ) REFERENCES accounts ( "id" ) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD FOREIGN KEY ( "party_id" ) REFERENCES parties ( "id" ) ON DELETE CASCADE ON UPDATE CASCADE;